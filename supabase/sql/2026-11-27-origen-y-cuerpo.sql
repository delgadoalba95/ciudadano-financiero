-- De dónde viene cada contacto, y el texto de cada email enviado
-- -----------------------------------------------------------------------
-- Las tres puertas de entrada (formulario de la web, ventana emergente y
-- página del vídeo de las 3 habilidades) mandaban todas la misma etiqueta,
-- y además no se guardaba en ningún sitio: era imposible distinguirlas.
--
-- email_log tampoco guardaba el cuerpo, solo el asunto. De los envíos
-- anteriores a esta migración no se puede recuperar el texto.

alter table public.contacts  add column if not exists origen text;
alter table public.email_log add column if not exists cuerpo text;

create or replace function public.submit_contact(
  p_name text, p_email text, p_whatsapp text, p_consent boolean, p_source text,
  p_test_answers jsonb default null, p_test_result_top text default null,
  p_test_result_second text default null)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
begin
  insert into public.contacts (
    name, email, whatsapp, consent, is_waitlist, is_test,
    test_answers, test_result_top, test_result_second, origen
  ) values (
    p_name, lower(trim(p_email)), p_whatsapp, p_consent,
    (p_source in ('waitlist', 'aviso', 'vsl')),
    (p_source = 'test'),
    p_test_answers, p_test_result_top, p_test_result_second, p_source
  )
  on conflict (email) do update set
    name               = excluded.name,
    whatsapp           = excluded.whatsapp,
    consent            = public.contacts.consent or excluded.consent,
    is_waitlist        = public.contacts.is_waitlist or excluded.is_waitlist,
    is_test            = public.contacts.is_test or excluded.is_test,
    test_answers       = coalesce(excluded.test_answers, public.contacts.test_answers),
    test_result_top    = coalesce(excluded.test_result_top, public.contacts.test_result_top),
    test_result_second = coalesce(excluded.test_result_second, public.contacts.test_result_second),
    -- se conserva la primera puerta por la que entró
    origen             = coalesce(public.contacts.origen, excluded.origen),
    updated_at         = now();
end;
$fn$;

-- El grupo al que iba dirigido cada envío, para verlo luego en el panel.
alter table public.emails_programados add column if not exists grupo text;
alter table public.email_log          add column if not exists grupo text;

-- El cron se lo pasa a la función de envío, que lo guarda en el historial
-- junto con el cuerpo del email (eso se cambió en la propia función
-- enviar-email, que vive en el panel de Supabase, no en este repositorio).
create or replace function public.enviar_emails_programados()
returns integer
language plpgsql
security definer
set search_path = public
as $fn$
declare
  fila record;
  cuantos integer := 0;
  k text;
  interna text;
begin
  select valor into k from public.ajustes where clave = 'clave_publicable';
  select valor into interna from public.ajustes where clave = 'clave_interna_email';

  for fila in
    select * from public.emails_programados
    where estado = 'programado' and enviar_en <= now()
    order by enviar_en
    limit 20
  loop
    perform net.http_post(
      url := 'https://srhopldaiqdyybomnhsh.supabase.co/functions/v1/enviar-email',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'apikey', k,
        'Authorization', 'Bearer ' || k,
        'x-cf-clave', interna
      ),
      body := jsonb_build_object(
        'contacts', fila.destinatarios,
        'subject',  fila.asunto,
        'html',     fila.html,
        'grupo',    fila.grupo
      )
    );

    update public.emails_programados
       set estado = 'enviado', enviado_en = now()
     where id = fila.id;

    cuantos := cuantos + 1;
  end loop;
  return cuantos;
end;
$fn$;

revoke all on function public.enviar_emails_programados() from public, anon, authenticated;
