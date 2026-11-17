-- Módulo V: sus dos lecciones, abiertas desde el primer momento
-- -----------------------------------------------------------------------
-- La tarea del módulo V ya estaba escrita en alumno.html y aparece sola en
-- cuanto estas filas son visibles. Las duraciones son las reales medidas en
-- el reproductor, no las que devuelve la API pública de Loom.

insert into public.lecciones_ocultas (modulo, orden, nombre, loom_id, duracion, miniatura, publicar_en) values
  (5, 1, 'Contexto de mercado', '8f888c0480084c1281040e71c9f44b36', '17:42', '8f888c0480084c1281040e71c9f44b36-239cb05de6a92a69', now()),
  (5, 2, 'Casos de uso y estrategia de cartera', '672104240e64499d8af0cc1b213c32b3', '25:34', '672104240e64499d8af0cc1b213c32b3-3e9e19431e79b8f9', now())
on conflict (modulo, orden) do update
  set nombre      = excluded.nombre,
      loom_id     = excluded.loom_id,
      duracion    = excluded.duracion,
      miniatura   = excluded.miniatura,
      publicar_en = excluded.publicar_en;

select modulo, orden, nombre, duracion, publicar_en from public.lecciones_ocultas order by modulo, orden;
