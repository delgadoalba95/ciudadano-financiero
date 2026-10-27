-- El email de bienvenida pasa por la función protegida
-- -----------------------------------------------------------------------
-- Antes: la base de datos llamaba a send-waitlist-welcome, que aceptaba a
-- cualquiera, y además el disparador llevaba escrita dentro una clave de
-- servicio (la que se salta todas las reglas).
--
-- Ahora: el texto del email se arma aquí y se manda con enviar-email, que
-- exige la cabecera x-cf-clave. La clave de servicio ya no hace falta.
-- send-waitlist-welcome se ha borrado.

create or replace function public.trigger_waitlist_welcome_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
declare
  k text;
  interna text;
  nombre text;
  cuerpo text;
begin
  if not (NEW.is_waitlist and NEW.waitlist_welcome_sent_at is null) then
    return NEW;
  end if;

  select valor into k       from public.ajustes where clave = 'clave_publicable';
  select valor into interna from public.ajustes where clave = 'clave_interna_email';

  -- Solo el nombre de pila, como en el resto de emails.
  nombre := split_part(trim(coalesce(NEW.name, '')), ' ', 1);
  if nombre = '' then nombre := 'hola'; end if;

  cuerpo :=
    '<p>Hola ' || nombre || ',</p>' ||
    '<p>Ya estás en la lista de espera de Ciudadano Financiero. La primera edición está en marcha ahora mismo; en cuanto abra la siguiente serás de las primeras personas en saberlo.</p>' ||
    '<p>Mientras tanto, si quieres saber cuál es tu relación con el dinero, aquí tienes el test:<br>' ||
    '<a href="https://ciudadanofinanciero.com/test.html">ciudadanofinanciero.com/test.html</a></p>' ||
    '<p>Un abrazo,<br>Alba</p>';

  perform net.http_post(
    url := 'https://srhopldaiqdyybomnhsh.supabase.co/functions/v1/enviar-email',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', k,
      'Authorization', 'Bearer ' || k,
      'x-cf-clave', interna
    ),
    body := jsonb_build_object(
      'contacts', jsonb_build_array(jsonb_build_object('email', NEW.email, 'name', nombre)),
      'subject',  'Estás en la lista de espera de Ciudadano Financiero',
      'template', 'waitlist_welcome',
      'html',     cuerpo
    )
  );

  update public.contacts set waitlist_welcome_sent_at = now() where id = NEW.id;
  return NEW;
end;
$fn$;
