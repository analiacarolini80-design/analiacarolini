-- Configuración de las mejoras de UX. La leen el servidor y los clientes.
-- Acá se cambian textos, cantidades, premios y ofertas sin tocar el resto del código.

local Config = {}

---------------------------------------------------------------------------
-- Guía de los primeros minutos
---------------------------------------------------------------------------
-- Cada paso se completa cuando tus scripts llaman
--   MejorasUX.Registrar(jugador, Accion, cantidad)
-- hasta sumar "Cantidad".
-- Objetivo: lista de Tags. La flecha apunta al objeto con alguno de esos Tags
-- que esté más cerca del jugador. Con una lista vacía no se muestra flecha.
Config.Pasos = {
	{
		Texto = "Rompé 5 piedras",
		Accion = "Minar",
		Cantidad = 5,
		Objetivo = { "Guia_Mina" },
		Premio = { Moneda = "Dinero", Cantidad = 50 },
	},
	{
		Texto = "Vendé tus piedras",
		Accion = "Vender",
		Cantidad = 1,
		Objetivo = { "PuntoDeVenta", "Guia_Venta" },
		Premio = { Moneda = "Dinero", Cantidad = 100 },
	},
	{
		Texto = "Comprá el Pico de Piedra",
		Accion = "ComprarPico",
		Cantidad = 1,
		Objetivo = { "Guia_TiendaPicos" },
		Premio = { Moneda = "Dinero", Cantidad = 150 },
	},
	{
		Texto = "Abrí un huevo",
		Accion = "AbrirHuevo",
		Cantidad = 1,
		Objetivo = { "Guia_Huevos" },
		Premio = { Moneda = "Dinero", Cantidad = 200 },
	},
	{
		Texto = "Renacé por primera vez",
		Accion = "Renacer",
		Cantidad = 1,
		Objetivo = { "Guia_Renacer" },
		Premio = { Moneda = "Dinero", Cantidad = 500 },
	},
}

-- Emoji que acompaña a cada moneda en los carteles.
Config.IconoMoneda = {
	Dinero = "💰",
	Fuerza = "💪",
}

-- Cómo se llama una carga completa en los textos tipo "Te faltan 3 mochilas".
Config.UnidadSingular = "mochila"
Config.UnidadPlural = "mochilas"

---------------------------------------------------------------------------
-- Venta en las minas
---------------------------------------------------------------------------
-- Las partes con este Tag venden la mochila al tocarlas.
-- Poné una a la salida de cada mina.
Config.TagPuntoDeVenta = "PuntoDeVenta"
Config.EsperaEntreVentas = 2 -- segundos

-- Pase que muestra el botón "VENDER" cuando la mochila está llena.
-- 0 = desactivado.
Config.PaseVenderId = 0

---------------------------------------------------------------------------
-- Ofertas en el momento justo
---------------------------------------------------------------------------
-- Momento: "MochilaLlena" o cualquier Accion que registres (por ejemplo "Renacer").
-- Tipo: "Pase" (Game Pass) o "Producto" (Developer Product).
-- Las ofertas con Id = 0 no se muestran.
Config.Ofertas = {
	{
		Momento = "MochilaLlena",
		Tipo = "Pase",
		Id = 0,
		Titulo = "¡Mochila llena!",
		Texto = "Con este pase vendés desde cualquier lugar, sin volver caminando.",
	},
	{
		Momento = "Renacer",
		Tipo = "Pase",
		Id = 0,
		Titulo = "¡Renaciste!",
		Texto = "Con este pase eclosionás 3 huevos a la vez.",
	},
}

Config.OfertasEsperaInicial = 600 -- sin ofertas en los primeros 10 minutos
Config.OfertasEntreCadaUna = 300 -- al menos 5 minutos entre una oferta y otra
Config.OfertasRepetirMisma = 1200 -- la misma oferta, como mucho cada 20 minutos
Config.OfertasDuracion = 15 -- segundos que queda visible si no la tocan

return Config
