-- Dos cosas que hacen falta para el panel:
--   1) el almacén de fotos de los emails
--   2) la tabla donde se guarda el comportamiento de quien entra en la web
--
-- Lo de la tabla es anónimo a propósito: no se guarda IP, ni nombre, ni email,
-- ni nada que identifique a una persona. Solo qué secciones ha visto, hasta
-- dónde ha bajado y dónde ha hecho clic.

-- ---------- 1. Fotos de los emails ----------
insert into storage.buckets (id, name, public)
values ('email-fotos', 'email-fotos', true)
on conflict (id) do update set public = true;

-- Subir fotos: solo quien ha entrado en el panel.
drop policy if exists "email_fotos_sube_admin" on storage.objects;
create policy "email_fotos_sube_admin" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'email-fotos');

drop policy if exists "email_fotos_actualiza_admin" on storage.objects;
create policy "email_fotos_actualiza_admin" on storage.objects
  for update to authenticated
  using (bucket_id = 'email-fotos');

-- Verlas no necesita política: al ser un bucket público, la URL
-- .../object/public/email-fotos/... sirve el archivo sin pasar por RLS.
-- Dar un select abierto sobre storage.objects dejaría además que cualquiera
-- listase todos los archivos del almacén, así que no se pone.
drop policy if exists "email_fotos_lee_todos" on storage.objects;

-- ---------- 2. Comportamiento en la web ----------
create table if not exists public.web_visitas (
  id            uuid primary key default gen_random_uuid(),
  creado_en     timestamptz not null default now(),
  pagina        text not null,
  dispositivo   text,
  origen        text,
  segundos      integer,
  scroll_max    integer,
  ultima_seccion text,
  secciones     jsonb not null default '[]'::jsonb,
  clics         jsonb not null default '[]'::jsonb
);

create index if not exists web_visitas_creado_en_idx on public.web_visitas (creado_en desc);

alter table public.web_visitas enable row level security;

-- Quien visita la web solo puede añadir su propia fila, nunca leer las demás.
drop policy if exists "web_visitas_inserta_cualquiera" on public.web_visitas;
create policy "web_visitas_inserta_cualquiera" on public.web_visitas
  for insert to anon, authenticated
  with check (true);

-- Leerlas, solo desde el panel.
drop policy if exists "web_visitas_lee_admin" on public.web_visitas;
create policy "web_visitas_lee_admin" on public.web_visitas
  for select to authenticated
  using (true);

grant insert on public.web_visitas to anon, authenticated;
grant select on public.web_visitas to authenticated;
