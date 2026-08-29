-- Ejecutar una sola vez en el SQL Editor de Supabase (proyecto srhopldaiqdyybomnhsh).
-- Crea el acceso de alumnos (lista de emails autorizados) y el guardado de su Balance.

-- ---------------------------------------------------------------------------
-- 1. Admins: quién puede gestionar el CRM (contactos, alumnos autorizados...).
--    Hasta ahora "contacts" y "email_log" probablemente dejan pasar a
--    cualquier usuario autenticado, porque el único usuario que existía eras
--    tú. Ahora que los alumnos también tendrán cuenta, hay que distinguir
--    admin de alumno explícitamente.
-- ---------------------------------------------------------------------------
create table if not exists public.admins (
  email text primary key
);

insert into public.admins (email)
values ('delgadoalba95@gmail.com')
on conflict (email) do nothing;

alter table public.admins enable row level security;
-- Sin policies de select/insert/update/delete a propósito: nadie puede leer
-- ni tocar esta tabla desde el cliente, solo la función is_admin() de abajo
-- (que es SECURITY DEFINER y por tanto la puede consultar igualmente).

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admins a where a.email = auth.jwt()->>'email'
  );
$$;

-- ---------------------------------------------------------------------------
-- 2. IMPORTANTE — revisar a mano:
--    Busca las policies actuales de "contacts" y "email_log" (Database >
--    Policies en el dashboard de Supabase) y comprueba que exigen
--    `public.is_admin()` y no solo "authenticated". Si dejan pasar a
--    cualquier usuario logueado, un alumno con su cuenta nueva podría ver
--    la lista de contactos del CRM. Ejemplo de cómo debería quedar una
--    policy de solo-lectura para admins:
--
--      drop policy if exists "authenticated can select contacts" on public.contacts;
--      create policy "admins can select contacts" on public.contacts
--        for select using (public.is_admin());
--
--    (Ajusta el nombre de la policy antigua al que tengas realmente.)
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 3. Alumnos autorizados: la lista que tú controlas. Solo estos emails
--    pueden guardar/leer un Balance.
-- ---------------------------------------------------------------------------
create table if not exists public.alumnos_autorizados (
  email text primary key,
  nombre text,
  created_at timestamptz not null default now()
);

alter table public.alumnos_autorizados enable row level security;

create policy "admins manage alumnos autorizados"
  on public.alumnos_autorizados
  for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "un alumno puede comprobar su propia autorizacion"
  on public.alumnos_autorizados
  for select
  using (email = auth.jwt()->>'email');

-- ---------------------------------------------------------------------------
-- 4. Balance del alumno: una fila por alumno, todo el balance en JSON
--    (mismo formato que ya usa la interfaz: activo, pasivo, líneas propias).
-- ---------------------------------------------------------------------------
create table if not exists public.balances (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.balances enable row level security;

create policy "un alumno autorizado gestiona su propio balance"
  on public.balances
  for all
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.alumnos_autorizados a
      where a.email = auth.jwt()->>'email'
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.alumnos_autorizados a
      where a.email = auth.jwt()->>'email'
    )
  );

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists balances_set_updated_at on public.balances;
create trigger balances_set_updated_at
  before update on public.balances
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 5. Comprueba en Authentication > Providers > Email que el proveedor de
--    Email está activado (ya debería estarlo, es lo que usa panel.html).
--    El enlace mágico usa el mismo proveedor, no hace falta nada más.
-- ---------------------------------------------------------------------------
