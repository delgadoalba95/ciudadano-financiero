-- Cerrar el envío de emails
-- -----------------------------------------------------------------------
-- Problema: la función send-manual-email aceptaba la clave "publishable",
-- que está a la vista en la web. Cualquiera podía llamarla y mandar correos
-- desde ciudadanofinanciero.com. El ajuste "Verify JWT" del panel no lo
-- arregla: el propio Supabase avisa de que la clave anon lo satisface.
--
-- Solución: una función nueva (enviar-email) que exige una cabecera
-- x-cf-clave con un valor que NO está en ningún sitio público. Ese valor
-- vive en los secretos del proyecto (CF_CLAVE_INTERNA) y en public.ajustes,
-- que no tiene permisos para anon ni authenticated.

create table if not exists public.ajustes (
  clave text primary key,
  valor text not null
);

alter table public.ajustes enable row level security;

-- Sin políticas y sin grants: no se puede leer desde fuera. Las funciones
-- security definer sí la leen, porque corren como dueñas de la tabla.
revoke all on public.ajustes from anon, authenticated;

-- Los valores se meten a mano desde el editor SQL; aquí no se escriben.
--   insert into public.ajustes (clave, valor) values ('clave_publicable', '…');
--   insert into public.ajustes (clave, valor) values ('clave_interna_email', '…');

-- Las dos funciones que mandan correo pasan ahora por enviar-email y le
-- añaden la cabecera x-cf-clave. Ver los archivos:
--   2026-10-07-emails-programados.sql
--   2026-10-25-buzon-de-dudas.sql
