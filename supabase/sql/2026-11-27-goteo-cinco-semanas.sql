-- Goteo de cinco semanas, por alumno
-- -----------------------------------------------------------------------
-- Cada alumno tiene su propia fecha de inicio. El módulo I está disponible
-- desde el primer momento (vive en el HTML). El II, III, IV y V se abren a
-- los 7, 14, 21 y 28 días, siempre a las 9:00 de España. Dos semanas
-- después de abrirse el módulo V se acaba el acceso.
--
-- La primera edición (los que ya estaban dentro) lleva acceso_total: lo ven
-- todo desde el principio y hasta el 20/10/2027.
--
-- OJO al ejecutar esto en el editor de Supabase: NO mezclar la creación de
-- funciones con pruebas que acaben en rollback. El editor envuelve todo el
-- script en una transacción, así que el rollback también deshace el CREATE.

alter table public.alumnos_autorizados
  add column if not exists inicio       timestamptz not null default now(),
  add column if not exists acceso_total boolean     not null default false,
  add column if not exists acceso_hasta timestamptz;

update public.alumnos_autorizados
   set acceso_total = true,
       inicio       = timestamptz '2026-10-20 09:00:00+02',
       acceso_hasta = timestamptz '2027-10-20 09:00:00+02'
 where created_at < timestamptz '2026-11-27 00:00:00+01';

create or replace function public.apertura_modulo(p_inicio timestamptz, p_modulo integer)
returns timestamptz
language sql
stable
as $fn$
  select ((date(p_inicio at time zone 'Europe/Madrid') + (7 * (p_modulo - 1)))::timestamp
          + time '09:00') at time zone 'Europe/Madrid';
$fn$;

create or replace function public.fin_de_acceso(p_inicio timestamptz, p_hasta timestamptz)
returns timestamptz
language sql
stable
as $fn$
  select coalesce(p_hasta, public.apertura_modulo(p_inicio, 5) + interval '14 days');
$fn$;

create or replace function public.mi_acceso()
returns table (inicio timestamptz, acceso_total boolean, acceso_hasta timestamptz, activo boolean)
language sql
security definer
set search_path = public
as $fn$
  select a.inicio,
         a.acceso_total,
         public.fin_de_acceso(a.inicio, a.acceso_hasta),
         now() <= public.fin_de_acceso(a.inicio, a.acceso_hasta)
  from public.alumnos_autorizados a
  where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''));
$fn$;

revoke all on function public.mi_acceso() from public, anon;
grant execute on function public.mi_acceso() to authenticated;

-- Las lecciones tal y como las ve cada alumno. Devuelve SIEMPRE nombre y
-- duración, para que vea lo que le viene, pero el enlace de Loom y la
-- miniatura solo cuando su módulo ya está abierto. Caducado el acceso, nada.
create or replace function public.lecciones_del_alumno()
returns table (
  modulo     integer,
  orden      integer,
  nombre     text,
  duracion   text,
  miniatura  text,
  loom_id    text,
  abierta    boolean,
  se_abre    timestamptz
)
language sql
security definer
set search_path = public
as $fn$
  with yo as (
    select a.inicio,
           a.acceso_total,
           public.fin_de_acceso(a.inicio, a.acceso_hasta) as hasta
    from public.alumnos_autorizados a
    where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  ),
  calc as (
    select l.*,
           case when yo.acceso_total then yo.inicio
                else public.apertura_modulo(yo.inicio, l.modulo) end as ap,
           yo.hasta
    from public.lecciones_ocultas l
    cross join yo
  )
  select modulo, orden, nombre, duracion,
         case when now() >= ap then miniatura end,
         case when now() >= ap then loom_id end,
         now() >= ap,
         ap
  from calc
  where now() <= hasta
  order by modulo, orden;
$fn$;

revoke all on function public.lecciones_del_alumno() from public, anon;
grant execute on function public.lecciones_del_alumno() to authenticated;
