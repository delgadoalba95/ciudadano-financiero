-- Programar el envío de un email a una hora concreta.
--
-- El panel guarda aquí el email ya montado (asunto, html y destinatarios) y un
-- trabajo de pg_cron revisa cada minuto si toca mandar alguno. Cuando toca,
-- llama a la misma función de siempre (send-manual-email), así que el email
-- sale igual que si se hubiera pulsado Enviar y queda registrado en email_log.

create extension if not exists pg_cron;

create table if not exists public.emails_programados (
  id            uuid primary key default gen_random_uuid(),
  creado_en     timestamptz not null default now(),
  enviar_en     timestamptz not null,
  asunto        text not null,
  html          text not null,
  destinatarios jsonb not null,
  estado        text not null default 'programado',
  enviado_en    timestamptz
);

create index if not exists emails_programados_pendientes_idx
  on public.emails_programados (enviar_en) where estado = 'programado';

alter table public.emails_programados enable row level security;

-- Solo desde el panel.
drop policy if exists "emails_programados_admin" on public.emails_programados;
create policy "emails_programados_admin" on public.emails_programados
  for all to authenticated using (true) with check (true);

grant select, insert, update, delete on public.emails_programados to authenticated;

create or replace function public.enviar_emails_programados()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  fila record;
  cuantos integer := 0;
begin
  for fila in
    select * from public.emails_programados
    where estado = 'programado' and enviar_en <= now()
    order by enviar_en
    limit 20
  loop
    perform net.http_post(
      url := 'https://srhopldaiqdyybomnhsh.supabase.co/functions/v1/send-manual-email',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'apikey', 'sb_publishable_NN--xuNPdjUxQ4_TVaA7LA_KUKJMOci',
        'Authorization', 'Bearer sb_publishable_NN--xuNPdjUxQ4_TVaA7LA_KUKJMOci'
      ),
      body := jsonb_build_object(
        'contacts', fila.destinatarios,
        'subject',  fila.asunto,
        'html',     fila.html
      )
    );

    update public.emails_programados
       set estado = 'enviado', enviado_en = now()
     where id = fila.id;

    cuantos := cuantos + 1;
  end loop;
  return cuantos;
end;
$$;

-- Que no la pueda disparar cualquiera desde fuera.
revoke all on function public.enviar_emails_programados() from public, anon, authenticated;

select cron.unschedule('enviar-emails-programados')
  where exists (select 1 from cron.job where jobname = 'enviar-emails-programados');

select cron.schedule('enviar-emails-programados', '* * * * *',
                     $$select public.enviar_emails_programados();$$);
