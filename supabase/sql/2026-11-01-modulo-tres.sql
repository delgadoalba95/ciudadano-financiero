-- Módulo III: solo lo ve Alba hasta que se le ponga fecha
-- -----------------------------------------------------------------------
-- Con publicar_en a null, la política "lecciones_publicadas" no devuelve
-- nada a las alumnas: la fila solo la lee quien pasa is_admin(). Cuando el
-- módulo esté listo se le pone fecha, igual que se hizo con el módulo II:
--
--   update public.lecciones_ocultas
--      set publicar_en = timestamptz '2026-11-XX 10:00:00+01'
--    where modulo = 3;
--
-- Las tres lecciones ya están grabadas; solo falta ponerle fecha al módulo.

insert into public.lecciones_ocultas (modulo, orden, nombre, loom_id, duracion, miniatura, publicar_en) values
  (3, 1, 'Productos financieros de alta rentabilidad', 'ab50f2f3c0c646c0889ce17a58254d40', '19:25', 'ab50f2f3c0c646c0889ce17a58254d40-f009ddc4909657fd', null),
  (3, 2, 'Inmuebles y vehículos', '0bff715fb72745ac87ef61569efc9bb9', '20:34', '0bff715fb72745ac87ef61569efc9bb9-6dc200883c5af10f', null),
  (3, 3, 'ETFs y ETCs', '1134249d473646fc839b53558b92ccd5', '34:39', '1134249d473646fc839b53558b92ccd5-1441f3c12aa37977', null)
on conflict (modulo, orden) do update
  set nombre    = excluded.nombre,
      loom_id   = excluded.loom_id,
      duracion  = excluded.duracion,
      miniatura = excluded.miniatura;

select modulo, orden, nombre, duracion, publicar_en from public.lecciones_ocultas order by modulo, orden;
