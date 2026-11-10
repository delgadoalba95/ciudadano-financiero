-- Módulo IV: Análisis Técnico, todavía oculto para todos
-- -----------------------------------------------------------------------
-- Con publicar_en a null no lo ve nadie: ni las alumnas (la política
-- lecciones_publicadas exige fecha pasada) ni Alba (el navegador pide las
-- lecciones con el filtro publicar_en <= now()). Cuando toque abrirlo:
--
--   update public.lecciones_ocultas
--      set publicar_en = timestamptz '2026-11-XX 10:00:00+01'
--    where modulo = 4;
--
-- La duración es la real del archivo (60:11), no la que devuelve la API
-- pública de Loom (61:27), que es la de antes del recorte.

insert into public.lecciones_ocultas (modulo, orden, nombre, loom_id, duracion, miniatura, publicar_en) values
  (4, 1, 'Análisis Técnico', '61e50f3178904a589dd39831ab571e72', '60:11', '61e50f3178904a589dd39831ab571e72-022c43c0b1e9a43e', null)
on conflict (modulo, orden) do update
  set nombre    = excluded.nombre,
      loom_id   = excluded.loom_id,
      duracion  = excluded.duracion,
      miniatura = excluded.miniatura;

select modulo, orden, nombre, duracion, publicar_en from public.lecciones_ocultas order by modulo, orden;
