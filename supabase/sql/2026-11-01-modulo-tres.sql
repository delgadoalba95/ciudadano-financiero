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
-- De momento solo existe el primer vídeo. Los otros dos se añaden aquí
-- mismo (orden 2 y 3) cuando estén grabados.

insert into public.lecciones_ocultas (modulo, orden, nombre, loom_id, duracion, miniatura, publicar_en) values
  (3, 1, 'Productos financieros de alta rentabilidad', 'ab50f2f3c0c646c0889ce17a58254d40', '19:25', 'ab50f2f3c0c646c0889ce17a58254d40-f009ddc4909657fd', null)
on conflict (modulo, orden) do update
  set nombre    = excluded.nombre,
      loom_id   = excluded.loom_id,
      duracion  = excluded.duracion,
      miniatura = excluded.miniatura;

select modulo, orden, nombre, duracion, publicar_en from public.lecciones_ocultas order by modulo, orden;
