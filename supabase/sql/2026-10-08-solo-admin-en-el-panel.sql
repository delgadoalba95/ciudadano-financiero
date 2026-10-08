-- Las alumnas también tienen cuenta de Supabase para entrar en alumno.html,
-- así que una política "to authenticated" las incluía a todas. Con esto, la
-- lista de espera y el historial de emails solo los ve quien esté en la tabla
-- admins (is_admin()).

drop policy if exists "authenticated can read contacts" on public.contacts;
drop policy if exists "solo admin lee contacts" on public.contacts;
create policy "solo admin lee contacts" on public.contacts
  for select to authenticated using (is_admin());

drop policy if exists "authenticated can read email_log" on public.email_log;
drop policy if exists "solo admin lee email_log" on public.email_log;
create policy "solo admin lee email_log" on public.email_log
  for select to authenticated using (is_admin());

-- El panel pregunta "¿soy admin?" antes de enseñar nada.
grant execute on function public.is_admin() to authenticated;

-- Comprobación: haciéndose pasar por una alumna, todo sale a cero.
--   select set_config('request.jwt.claims','{"email":"alumna@ejemplo.com","role":"authenticated"}', true);
--   set local role authenticated;
--   select is_admin(), (select count(*) from public.contacts);
