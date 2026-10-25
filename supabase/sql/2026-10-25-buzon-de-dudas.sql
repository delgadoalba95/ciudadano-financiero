-- Buzón de dudas del área de alumnas
-- -----------------------------------------------------------------------
-- La alumna escribe su duda desde el curso y a Alba le llega un email a
-- hola@ciudadanofinanciero.com. Las dudas quedan guardadas por si quiere
-- repasarlas o convertirlas en preguntas frecuentes.
--
-- El alta NO se hace con un insert desde el navegador: se hace llamando a
-- enviar_duda(), que saca el email de quien pregunta del propio token. Así
-- nadie puede mandar una duda haciéndose pasar por otra persona.

create table if not exists public.dudas (
  id         uuid primary key default gen_random_uuid(),
  creado_en  timestamptz not null default now(),
  email      text not null,
  mensaje    text not null,
  origen     text,
  atendida   boolean not null default false
);

create index if not exists dudas_recientes_idx on public.dudas (creado_en desc);

alter table public.dudas enable row level security;

-- Las alumnas también están autenticadas: solo Alba puede leerlas.
drop policy if exists "dudas_admin" on public.dudas;
create policy "dudas_admin" on public.dudas
  for all to authenticated using (is_admin()) with check (is_admin());

-- Grants explícitos. A anon, nada: el buzón vive dentro del área de alumnas.
grant select, insert, update, delete on public.dudas to authenticated;
grant select, insert, update, delete on public.dudas to service_role;

create or replace function public.enviar_duda(p_mensaje text, p_origen text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  quien text;
  texto text;
begin
  quien := lower(trim(coalesce(auth.jwt() ->> 'email', '')));
  if quien = '' then
    raise exception 'Hay que haber entrado para escribir una duda.';
  end if;
  if not public.email_autorizado(quien) then
    raise exception 'Esta cuenta no tiene acceso al curso.';
  end if;

  texto := trim(coalesce(p_mensaje, ''));
  if length(texto) < 5 then
    raise exception 'Escribe un poco más para que se entienda la duda.';
  end if;
  texto := left(texto, 4000);

  insert into public.dudas (email, mensaje, origen) values (quien, texto, p_origen);

  perform net.http_post(
    url := 'https://srhopldaiqdyybomnhsh.supabase.co/functions/v1/send-manual-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', 'sb_publishable_NN--xuNPdjUxQ4_TVaA7LA_KUKJMOci',
      'Authorization', 'Bearer sb_publishable_NN--xuNPdjUxQ4_TVaA7LA_KUKJMOci'
    ),
    body := jsonb_build_object(
      'contacts', jsonb_build_array(
        jsonb_build_object('email', 'hola@ciudadanofinanciero.com', 'name', 'Alba')
      ),
      'subject', 'Duda de ' || quien,
      'html',
        '<p><strong>' || quien || '</strong> pregunta:</p>' ||
        '<p style="white-space:pre-wrap">' ||
          replace(replace(replace(texto, '&', '&amp;'), '<', '&lt;'), '>', '&gt;') ||
        '</p>' ||
        coalesce('<p style="color:#777;font-size:13px">Desde: ' || p_origen || '</p>', '') ||
        '<p style="color:#777;font-size:13px">Responde directamente a ' || quien || '.</p>'
    )
  );
end;
$$;

revoke all on function public.enviar_duda(text, text) from public, anon;
grant execute on function public.enviar_duda(text, text) to authenticated;
