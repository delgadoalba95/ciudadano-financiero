-- Ejecutado en el SQL Editor de Supabase el 30/08/2026.
--
-- 1) Comprobar si un email está autorizado ANTES de iniciar sesión.
--    Es SECURITY DEFINER porque quien pregunta todavía no tiene cuenta.
--    Solo devuelve true/false: nunca expone la lista de alumnos.
create or replace function public.email_autorizado(p_email text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.alumnos_autorizados a
    where lower(a.email) = lower(trim(p_email))
  );
$$;

revoke all on function public.email_autorizado(text) from public;
grant execute on function public.email_autorizado(text) to anon, authenticated;

-- 2) Permisos base sobre las tablas nuevas.
--    Las políticas RLS deciden QUÉ FILAS ve cada usuario, pero sin el GRANT
--    de tabla PostgREST devuelve 42501 "permission denied". Eso hacía que el
--    alumno iniciara sesión correctamente y acto seguido volviera al login.
grant select on public.alumnos_autorizados to authenticated;
grant insert, update, delete on public.alumnos_autorizados to authenticated;
grant select, insert, update, delete on public.balances to authenticated;
