-- Lecciones que todavía no se han abierto a las alumnas
-- -----------------------------------------------------------------------
-- El módulo I está en el HTML de alumno.html porque es público para quien
-- tiene acceso. Los módulos cerrados NO están en el HTML a propósito: si
-- estuvieran, cualquier alumna podría leer el código de la página, sacar los
-- enlaces de Loom y verlos antes de tiempo.
--
-- Esta tabla guarda esas lecciones y solo la puede leer Alba (is_admin()).
-- Así ella revisa un módulo cerrado desde su propia cuenta sin abrirlo para
-- nadie más, y los enlaces de Loom nunca llegan al navegador de una alumna.

create table if not exists public.lecciones_ocultas (
  id         uuid primary key default gen_random_uuid(),
  modulo     integer not null,
  orden      integer not null,
  nombre     text    not null,
  loom_id    text    not null,
  duracion   text    not null,
  miniatura  text,
  creado_en  timestamptz not null default now()
);

create unique index if not exists lecciones_ocultas_orden_idx
  on public.lecciones_ocultas (modulo, orden);

alter table public.lecciones_ocultas enable row level security;

-- Las alumnas también están autenticadas: "authenticated" a secas no vale.
drop policy if exists "lecciones_ocultas_admin" on public.lecciones_ocultas;
create policy "lecciones_ocultas_admin" on public.lecciones_ocultas
  for all to authenticated using (is_admin()) with check (is_admin());

-- Grants explícitos: Supabase ya no los concede solo. A anon, nada.
grant select, insert, update, delete on public.lecciones_ocultas to authenticated;
grant select, insert, update, delete on public.lecciones_ocultas to service_role;

-- Módulo II, en su orden.
insert into public.lecciones_ocultas (modulo, orden, nombre, loom_id, duracion, miniatura) values
  (2, 1, 'Activos y Pasivos en tus finanzas personales', '8c22301d7f7644e88fd06586f8ea0541', '36:29', '8c22301d7f7644e88fd06586f8ea0541-90c72ff7b1a491d1'),
  (2, 2, 'Tu flujo de caja personal',                     '6c18e26ffb064a9a8deff8d4b734366f', '07:19', '6c18e26ffb064a9a8deff8d4b734366f-b482e44398f82fde'),
  (2, 3, 'Tu balance personal',                           'bc3f8fafd83742c3bcfa6c93efcbaa18', '08:12', 'bc3f8fafd83742c3bcfa6c93efcbaa18-a81ef2187ced3482')
on conflict (modulo, orden) do nothing;

select modulo, orden, nombre, duracion from public.lecciones_ocultas order by modulo, orden;
