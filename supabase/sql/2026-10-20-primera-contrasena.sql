-- Saber si un alumno ya tiene contraseña puesta
-- -----------------------------------------------------------------------
-- La pantalla de acceso necesita distinguir dos casos:
--   · ya tiene cuenta  -> "Contraseña"
--   · es su primera vez -> "Nueva contraseña" + confirmarla
-- Solo responde para emails que ya están en la lista de alumnos, que es
-- información que la propia pantalla ya consulta con email_autorizado().

create or replace function public.alumno_tiene_clave(p_email text)
returns boolean
language sql
security definer
set search_path = public, auth
as $$
  select exists (
           select 1 from public.alumnos_autorizados a
            where lower(a.email) = lower(trim(p_email))
         )
     and exists (
           select 1 from auth.users u
            where lower(u.email) = lower(trim(p_email))
         );
$$;

revoke all on function public.alumno_tiene_clave(text) from public;
grant execute on function public.alumno_tiene_clave(text) to anon, authenticated;

-- Eneko Zarraga: alumno de la primera edición.
insert into public.contacts (name, email, whatsapp, consent, is_waitlist, is_test, cohorte, alumno)
values ('Eneko Zarraga', 'enekozarra@gmail.com', null, false, false, false, 1, true)
on conflict (email) do update set cohorte = 1, alumno = true;

insert into public.alumnos_autorizados (email, nombre)
values ('enekozarra@gmail.com', 'Eneko Zarraga')
on conflict (email) do nothing;

select a.email, a.nombre from public.alumnos_autorizados a order by a.created_at desc;
