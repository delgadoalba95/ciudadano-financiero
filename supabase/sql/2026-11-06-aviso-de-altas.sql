-- Aviso a Alba cada vez que alguien se apunta a la lista de espera
-- -----------------------------------------------------------------------
-- Se añade dentro del disparador que ya mandaba la bienvenida, en vez de
-- crear otro. Así el aviso sale exactamente en el mismo momento y con la
-- misma condición (waitlist_welcome_sent_at is null), y no hay forma de
-- que lleguen dos avisos por la misma persona aunque vuelva a apuntarse.

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
  cabeceras jsonb;
  cuantos integer;
begin
  if not (NEW.is_waitlist and NEW.waitlist_welcome_sent_at is null) then
    return NEW;
  end if;

  select valor into k       from public.ajustes where clave = 'clave_publicable';
  select valor into interna from public.ajustes where clave = 'clave_interna_email';

  cabeceras := jsonb_build_object(
    'Content-Type', 'application/json',
    'apikey', k,
    'Authorization', 'Bearer ' || k,
    'x-cf-clave', interna
  );

  -- Solo el nombre de pila, como en el resto de emails.
  nombre := split_part(trim(coalesce(NEW.name, '')), ' ', 1);
  if nombre = '' then nombre := 'hola'; end if;

  -- 1) La bienvenida, a quien se apunta.
  cuerpo :=
    '<p>Hola ' || nombre || ',</p>' ||
    '<p>Ya estás en la lista de espera de Ciudadano Financiero. La primera edición está en marcha ahora mismo; en cuanto abra la siguiente serás de las primeras personas en saberlo.</p>' ||
    '<p>Mientras tanto, si quieres saber cuál es tu relación con el dinero, aquí tienes el test:<br>' ||
    '<a href="https://ciudadanofinanciero.com/test.html">ciudadanofinanciero.com/test.html</a></p>' ||
    '<p>Un abrazo,<br>Alba</p>';

  perform net.http_post(
    url := 'https://srhopldaiqdyybomnhsh.supabase.co/functions/v1/enviar-email',
    headers := cabeceras,
    body := jsonb_build_object(
      'contacts', jsonb_build_array(jsonb_build_object('email', NEW.email, 'name', nombre)),
      'subject',  'Estás en la lista de espera de Ciudadano Financiero',
      'template', 'waitlist_welcome',
      'html',     cuerpo
    )
  );

  -- 2) El aviso, a Alba.
  select count(*) into cuantos from public.contacts where is_waitlist;

  perform net.http_post(
    url := 'https://srhopldaiqdyybomnhsh.supabase.co/functions/v1/enviar-email',
    headers := cabeceras,
    body := jsonb_build_object(
      'contacts', jsonb_build_array(
        jsonb_build_object('email', 'hola@ciudadanofinanciero.com', 'name', 'Alba')
      ),
      'subject',  'Nueva en la lista de espera: ' || NEW.email,
      'template', 'aviso_waitlist',
      'html',
        '<p>Se acaba de apuntar <strong>' ||
          replace(replace(coalesce(NEW.name, '(sin nombre)'), '<', '&lt;'), '>', '&gt;') ||
        '</strong>.</p>' ||
        '<p>Email: <a href="mailto:' || NEW.email || '">' || NEW.email || '</a></p>' ||
        coalesce('<p>WhatsApp: ' || NEW.whatsapp || '</p>', '') ||
        '<p style="color:#777;font-size:13px">Ya sois ' || cuantos || ' en la lista de espera.</p>'
    )
  );

  update public.contacts set waitlist_welcome_sent_at = now() where id = NEW.id;
  return NEW;
end;
$fn$;
