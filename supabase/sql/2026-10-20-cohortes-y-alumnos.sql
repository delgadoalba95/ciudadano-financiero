-- Cohortes y alumnos en la lista de espera
-- -----------------------------------------------------------------------
-- La primera edición del curso ya tiene su gente: todos los contactos que
-- hay ahora son de la cohorte 1. A partir de este cambio, quien se apunte
-- entra como cohorte 2 (segunda edición), sin tocar nada más.
--
-- "alumno" marca a quien ya ha pagado y está matriculado. Es solo una
-- etiqueta para el panel: NO da acceso al área de alumnas. El acceso
-- sigue dependiendo de la tabla alumnos_autorizados.

-- 1) Columnas nuevas. El default 1 hace que las filas que ya existen
--    queden en la cohorte 1 sin tener que recorrerlas.
alter table public.contacts
  add column if not exists cohorte integer not null default 1,
  add column if not exists alumno  boolean not null default false;

-- 2) A partir de ahora, quien se apunte entra en la cohorte 2.
alter table public.contacts alter column cohorte set default 2;

-- 3) Los cuatro que ya han pagado la primera edición.
update public.contacts
   set alumno = true
 where lower(email) in (
   'jrmguitar@gmail.com',
   'ruben.delosbueis@gmail.com',
   'kulikun1204@gmail.com',
   'gliranzo@gmail.com'
 );

-- 4) Comprobación: cuántos hay en cada grupo.
select cohorte,
       alumno,
       count(*) as cuantos
  from public.contacts
 group by cohorte, alumno
 order by cohorte, alumno;
