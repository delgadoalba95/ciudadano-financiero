-- Respuestas de las tareas, solo para Alba
-- -----------------------------------------------------------------------
-- La tabla balances solo tiene una política: cada alumno gestiona el suyo.
-- Alba no puede leer los de los demás, y está bien que sea así.
--
-- Para que el panel pueda enseñar las tareas sin abrir los datos financieros
-- de nadie, esta función devuelve ÚNICAMENTE los textos de las tareas y
-- cuántas lecciones lleva marcadas cada uno. Ni balance, ni flujo, ni test.
-- El filtro is_admin() va dentro: a cualquier otra persona le devuelve cero
-- filas aunque llame a la función directamente (comprobado).

create or replace function public.respuestas_de_tareas()
returns table (
  email        text,
  tarea1       text,
  tarea2       text,
  tarea3       text,
  tarea4       text,
  marcadas     integer,
  actualizado  timestamptz
)
language sql
security definer
set search_path = public
as $fn$
  select b.email,
         nullif(btrim(coalesce(b.data->>'estrategia','')), ''),
         nullif(btrim(coalesce(b.data->>'tareaMod2','')), ''),
         nullif(btrim(coalesce(b.data->>'tareaMod3','')), ''),
         nullif(btrim(coalesce(b.data->>'tareaMod4','')), ''),
         (select count(*)::int from jsonb_object_keys(coalesce(b.data->'tareas','{}'::jsonb))),
         b.updated_at
  from public.balances b
  where public.is_admin()
  order by b.updated_at desc nulls last;
$fn$;

revoke all on function public.respuestas_de_tareas() from public, anon;
grant execute on function public.respuestas_de_tareas() to authenticated;
