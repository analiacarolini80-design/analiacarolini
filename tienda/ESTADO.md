# Estado del proyecto — Analia Carolini Belleza

- Tienda (panel): analiacarolinibelleza.myshopify.com
- Tienda (dominio permanente, usar en TODOS los comandos): bys-user-store-858101-jd1yhknb.myshopify.com
- Carpeta: /home/user/analiacarolini/tienda (repo GitHub analiacarolini80-design/analiacarolini, rama claude/tienda-shopify-v2-t1yt1d)
- Tema base: Dawn (git clone, 2026-10-06). Tema activo actual de la tienda: Horizon #160844742771
- Entorno: nube Linux, Node 22, Shopify CLI 4.8.5 — OK
  - Ejecutar el CLI con NODE_USE_ENV_PROXY=1 (proxy de red)
  - store auth: el callback va a 127.0.0.1:13387 → la usuaria pega la URL de error y se le hace curl local
- Tema de trabajo (NO publicado): "Analia Carolini (Claude)" #164349444211
- Última publicación: subida base Dawn 2026-10-06 (sin diseño aún)

## Fases completadas
- [x] 0 Entorno
- [x] 1 Conexión (tema + datos de tienda, 2026-10-06)
- [x] 2 Proyecto
- [x] 3 Diseño (aprobado tal cual: estilo spa luminoso)
- [x] 4 Construcción
- [x] 5 Páginas (producto asignado; legales pendientes de la usuaria)
- [ ] 6 Publicación (subido al tema de trabajo; falta OK para publicar)

## Producto leído
- id: gid://shopify/Product/10334159143027
- handle: mascara-led-renova-7-colores-rostro-y-cuello-descripcion
- Título actual: "Máscara LED Renova 7 Colores · Rostro y Cuello  Descripción:" (sobra "Descripción:")
- Precio: 45.00 (variante única gid://shopify/ProductVariant/66805781594227), inventario 0, no disponible para venta
- Descripción: en español rioplatense (vos). 7 colores (rojo antiedad, azul granitos, amarillo luminosidad, verde pieles mixtas, violeta/celeste/blanco calmar), rostro+cuello, inalámbrica, botones táctiles, ritual 10-15 min, 2-3 veces/semana, regalo.
- Fotos: fotos-producto/producto-1.jpg (mujer en spa con máscara encendida), producto-2.jpg (7 máscaras de colores + máscara y collar). Estilo IA, marca de agua ✦ abajo a la derecha; la 2 tiene un cartel "LUCID SKIN REJUVENATION" (otra marca).

## Decisiones de diseño
- Estilo "spa luminoso": fondo marfil #F7F3EE, 2º fondo #EFE8DF, carbón #2F2B29, texto #2B2724, dorado #B89B7A
- Tipos: Cormorant Garamond (títulos, Google Fonts) + Jost (texto); en ajustes globales cormorant_n5 / jost_n4
- Firma: halo conic con los 7 colores, usado con moderación; botones píldora; radios 22px
- Idioma: español rioplatense (vos). Textos del tema en locales/en.default.json sustituidos por los de es.json (la tienda tiene inglés como idioma principal)
- Sin fotos IA (no dio clave): se recortaron sus fotos para quitar marca de agua y el cartel "LUCID SKIN"
- Producto: título corregido, SEO escrito, plantilla `ac` asignada, venta sin stock (CONTINUE), galería = 3 fotos limpias (las originales solo desvinculadas, siguen en Archivos)
- Moneda: la usuaria quiere USD 45 (cambió la moneda de la tienda; el carrito ya muestra USD)

## Secciones creadas (prefijo ac-)
- ac-hero: apertura con precio dinámico, 2 botones, garantías, etiqueta y halo
- ac-ventajas: tarjetas con icono (bloques)
- ac-colores: selector interactivo "7 colores, 7 cuidados" (bloques color, autoplay)
- ac-ritual: pasos numerados con imagen fija
- ac-comparacion: tabla cabina vs Renova (bloques fila)
- ac-faq: preguntas desplegables + datos para Google
- ac-cierre: tarjeta oscura de regalo con añadir al carrito
- ac-producto: página de producto (galería, variantes, cantidad, carrito lateral, garantías, desplegables, barra fija móvil)
- header.liquid: logo propio + nombre de marca; footer.liquid reescrito en español
- Plantillas: templates/index.json, templates/product.ac.json
- assets: ac-styles.css, ac-scripts.js, ac-favicon.png, fotos ac-*.jpg; snippet ac-icon

## Pendiente
- Menú principal en inglés (Home/Catalog/Contact): pedido permiso de navegación para traducirlo
- Políticas legales: la usuaria debe crearlas en Configuración → Políticas
- Nombre de la tienda aparece como "bys-user-store-858101" en la pestaña: cambiar en Configuración → Detalles de la tienda
- Idioma principal de la tienda: inglés → el pago (checkout) sale en inglés; cambiar a español en Configuración → Idiomas
- Publicar el tema "Analia Carolini (Claude)" #164349444211 con OK de la usuaria
