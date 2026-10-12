-- Instalador de MejorasUX (generado por generar_instalador.py; no editar a mano).
-- 1. Abrí tu juego en Roblox Studio, SIN darle Play.
-- 2. View > Command Bar.
-- 3. Pegá TODO este texto en la Command Bar y apretá Enter.
-- Crea o actualiza los scripts. Si Integracion ya existe, no la toca (ahí van tus cambios).
-- Se puede deshacer con Ctrl+Z.

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local function base(nombre)
	if nombre == "StarterPlayerScripts" then
		return game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	end
	return game:GetService(nombre)
end

local ARCHIVOS = {
	{ Base = "ReplicatedStorage", Nombre = "Config", Clase = "ModuleScript", NoPisar = false, Codigo = [=[
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
]=] },
	{ Base = "ReplicatedStorage", Nombre = "Numeros", Clase = "ModuleScript", NoPisar = false, Codigo = [=[
-- Números fáciles de leer para chicos: abreviaturas, comparaciones y "te faltan".
--
--   Numeros.Abreviar(1600000)                 --> "1,6 M"
--   Numeros.Comparar(200, 100, "fuerte")      --> "¡x2 más fuerte!"
--   Numeros.Comparar(130, 100, "rápido")      --> "¡+30% más rápido!"
--   Numeros.Faltan(700, 1000, 100, "bolsa", "bolsas") --> "Te faltan 3 bolsas"
--   Numeros.Progreso(700, 1000)               --> 0.7 (para barras)

local Numeros = {}

local SUFIJOS = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg",
}

local function conComa(texto: string): string
	return (string.gsub(texto, "%.", ","))
end

-- Margen para errores de coma flotante (1.6e30 / 1e30 da 1.5999...).
local MARGEN = 1e-9

-- Redondea hacia abajo con un decimal, así 999.96 K no se muestra como "1000 K".
local function unDecimal(valor: number): string
	local texto = string.format("%.1f", math.floor(valor * 10 + MARGEN) / 10)
	return conComa((string.gsub(texto, "%.0$", "")))
end

function Numeros.Abreviar(n: number): string
	if n ~= n then
		return "0"
	end
	if n == math.huge then
		return "∞"
	end

	local signo = n < 0 and "-" or ""
	n = math.abs(n)
	if n < 1000 then
		return signo .. tostring(math.floor(n))
	end

	local indice = math.min(math.floor(math.log10(n) / 3), #SUFIJOS - 1)
	local valor = n / 10 ^ (indice * 3)
	-- Corrige errores de redondeo de log10 en los bordes (1000, 1e6, ...).
	if valor >= 1000 and indice < #SUFIJOS - 1 then
		indice += 1
		valor /= 1000
	elseif valor < 1 then
		indice -= 1
		valor *= 1000
	end

	local texto = valor >= 100 and tostring(math.floor(valor + MARGEN)) or unDecimal(valor)
	return signo .. texto .. " " .. SUFIJOS[indice + 1]
end

-- "x2", "x2,5", "x15" o "+30%" cuando la diferencia es chica. nil si no se puede comparar.
function Numeros.Veces(nuevo: number, actual: number): string?
	if actual <= 0 then
		return nil
	end
	local razon = nuevo / actual
	if razon < 1.5 then
		return "+" .. math.floor((razon - 1) * 100 + 0.5) .. "%"
	end
	if razon >= 10 then
		return "x" .. Numeros.Abreviar(razon)
	end
	return "x" .. unDecimal(razon)
end

-- Texto listo para mostrar en una tienda: "¡x2 más fuerte!".
function Numeros.Comparar(nuevo: number, actual: number, adjetivo: string): string
	if nuevo <= actual then
		return "No es mejor que el tuyo"
	end
	local veces = Numeros.Veces(nuevo, actual)
	if not veces then
		return "¡Más " .. adjetivo .. "!"
	end
	return "¡" .. veces .. " más " .. adjetivo .. "!"
end

-- "Te faltan 3 bolsas" si se conoce el valor de una bolsa; si no, "Te faltan 1,2 K".
function Numeros.Faltan(actual: number, meta: number, valorUnidad: number?, singular: string?, plural: string?): string
	local falta = meta - actual
	if falta <= 0 then
		return "¡Ya te alcanza!"
	end
	if valorUnidad and valorUnidad > 0 and singular and plural then
		local unidades = math.ceil(falta / valorUnidad)
		if unidades == 1 then
			return "Te falta 1 " .. singular
		end
		return "Te faltan " .. Numeros.Abreviar(unidades) .. " " .. plural
	end
	return "Te faltan " .. Numeros.Abreviar(falta)
end

-- Fracción entre 0 y 1 para llenar una barra.
function Numeros.Progreso(actual: number, meta: number): number
	if meta <= 0 then
		return 1
	end
	return math.clamp(actual / meta, 0, 1)
end

return Numeros
]=] },
	{ Base = "ServerScriptService", Nombre = "Integracion", Clase = "ModuleScript", NoPisar = true, Codigo = [=[
-- ÚNICO archivo que hay que adaptar al juego: conecta las mejoras con tus
-- sistemas de dinero, mochila y venta. Todo esto corre en el servidor.
-- Cada función está protegida: si falla, se avisa en el Output y el juego sigue.

local Integracion = {}

-- Lee una moneda. Por defecto la busca en leaderstats (por ejemplo leaderstats.Dinero).
function Integracion.ObtenerMoneda(jugador: Player, moneda: string): number
	local stats = jugador:FindFirstChild("leaderstats")
	local valor = stats and stats:FindFirstChild(moneda)
	if valor and (valor:IsA("IntValue") or valor:IsA("NumberValue")) then
		return valor.Value
	end
	if valor and valor:IsA("StringValue") then
		return tonumber(valor.Value) or 0
	end
	return 0
end

-- Da el premio de una misión de la guía. Si el dinero se guarda en otro lado
-- (ProfileService, una tabla, etc.), reemplazá esto por tu función de sumar dinero.
function Integracion.DarPremio(jugador: Player, moneda: string, cantidad: number): boolean
	local stats = jugador:FindFirstChild("leaderstats")
	local valor = stats and stats:FindFirstChild(moneda)
	if valor and (valor:IsA("IntValue") or valor:IsA("NumberValue")) then
		valor.Value += cantidad
		return true
	end
	warn("[MejorasUX] No se pudo dar el premio: no existe leaderstats." .. moneda .. ". Revisá Integracion.DarPremio.")
	return false
end

-- Vende la mochila. Llamá acá a la MISMA función que usa la venta del lobby.
-- Ejemplo: return require(game.ServerScriptService.Venta).Vender(jugador)
function Integracion.Vender(jugador: Player): boolean
	warn("[MejorasUX] Falta conectar Integracion.Vender (ver roblox/README.md).")
	return false
end

-- Cuánto lleva la mochila y cuánto le entra. Devolvé nil, nil si no aplica.
-- Ejemplo con atributos: return jugador:GetAttribute("Mochila"), jugador:GetAttribute("MochilaMax")
function Integracion.ObtenerMochila(jugador: Player): (number?, number?)
	return nil, nil
end

-- Cuánto dinero da vender una mochila llena. Sirve para "Te faltan 3 mochilas".
-- Devolvé nil para mostrar la cantidad de dinero que falta.
function Integracion.ValorMochilaLlena(jugador: Player): number?
	return nil
end

-- Se consulta una sola vez por jugador, si todavía no tiene la guía guardada.
-- Devolvé false para no mostrársela a quien ya jugaba antes de esta actualización.
-- Ejemplo: return Integracion.ObtenerMoneda(jugador, "Renacimientos") == 0
function Integracion.MostrarGuia(jugador: Player): boolean
	return true
end

-- Metas en orden. Se muestra la primera que no esté Hecha, con barra de progreso.
-- Ejemplo (borrá los guiones del principio y adaptá los nombres):
Integracion.Metas = {
	-- {
	-- 	Texto = "Comprá el Pico de Hierro",
	-- 	Moneda = "Dinero",
	-- 	Precio = 5000,
	-- 	Hecha = function(jugador) return (jugador:GetAttribute("NivelPico") or 1) >= 2 end,
	-- },
	-- {
	-- 	Texto = "Entrá a la Mina de Cristal",
	-- 	Moneda = "Dinero",
	-- 	Precio = 25000,
	-- 	Hecha = function(jugador) return jugador:GetAttribute("MinaCristal") == true end,
	-- },
	-- {
	-- 	Texto = "Renacé",
	-- 	Moneda = "Dinero",
	-- 	Precio = 1000000,
	-- 	Hecha = function(jugador) return false end, -- siempre hay un próximo renacimiento
	-- },
}

-- Devuelve la próxima meta del jugador o nil. Se llama una vez por segundo.
-- Si tus metas no se pueden escribir como lista, reemplazá esta función.
function Integracion.ProximaMeta(jugador: Player)
	for _, meta in Integracion.Metas do
		if not meta.Hecha(jugador) then
			return {
				Texto = meta.Texto,
				Moneda = meta.Moneda,
				Precio = meta.Precio,
				Actual = Integracion.ObtenerMoneda(jugador, meta.Moneda),
			}
		end
	end
	return nil
end

return Integracion
]=] },
	{ Base = "ServerScriptService", Nombre = "API", Clase = "ModuleScript", NoPisar = false, Codigo = [=[
-- Lógica del servidor: guía, próxima meta, mochila llena, venta en minas y ofertas.
-- Desde tus scripts solo hace falta:
--   local MejorasUX = require(game.ServerScriptService.MejorasUX.API)
--   MejorasUX.Registrar(jugador, "Minar")      -- o "Vender", "ComprarPico", ...
-- El estado se comparte con los clientes con atributos del jugador (UX_...).

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartido = ReplicatedStorage:WaitForChild("MejorasUX")
local Config = require(Compartido:WaitForChild("Config"))
local Integracion = require(script.Parent:WaitForChild("Integracion"))

local MejorasUX = {}

local TOTAL_PASOS = #Config.Pasos

local estado = {} -- [Player] = datos de la sesión
local remotos: Folder
local almacen: DataStore?
local iniciado = false

local avisados = {}
local function avisarUnaVez(clave: string, mensaje: string)
	if not avisados[clave] then
		avisados[clave] = true
		warn("[MejorasUX] " .. mensaje)
	end
end

local function crearRemotos(): Folder
	local carpeta = Compartido:FindFirstChild("Remotos") or Instance.new("Folder")
	carpeta.Name = "Remotos"
	for _, nombre in { "Premio", "PedirVenta", "MostrarOferta" } do
		if not carpeta:FindFirstChild(nombre) then
			local remoto = Instance.new("RemoteEvent")
			remoto.Name = nombre
			remoto.Parent = carpeta
		end
	end
	carpeta.Parent = Compartido
	return carpeta
end

---------------------------------------------------------------------------
-- Pases
---------------------------------------------------------------------------

local function tienePase(jugador: Player, id: number): boolean
	local est = estado[jugador]
	if not est then
		return false
	end
	if est.Pases[id] == nil then
		local ok, tiene = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, jugador.UserId, id)
		if not ok then
			return false -- sin cachear: se vuelve a intentar la próxima vez
		end
		est.Pases[id] = tiene
	end
	return est.Pases[id]
end

---------------------------------------------------------------------------
-- Ofertas
---------------------------------------------------------------------------

local function momento(jugador: Player, nombre: string)
	local est = estado[jugador]
	if not est or not est.Paso or est.Paso <= TOTAL_PASOS then
		return -- nunca durante la guía
	end
	local ahora = os.clock()
	if ahora - est.Entrada < Config.OfertasEsperaInicial then
		return
	end
	if ahora - est.UltimaOferta < Config.OfertasEntreCadaUna then
		return
	end
	for indice, oferta in Config.Ofertas do
		if oferta.Momento == nombre and oferta.Id ~= 0 then
			local ultima = est.OfertasMostradas[indice]
			local yaTiene = oferta.Tipo == "Pase" and tienePase(jugador, oferta.Id)
			if not yaTiene and (not ultima or ahora - ultima >= Config.OfertasRepetirMisma) then
				est.UltimaOferta = ahora
				est.OfertasMostradas[indice] = ahora
				remotos.MostrarOferta:FireClient(jugador, indice)
				return
			end
		end
	end
end

---------------------------------------------------------------------------
-- Guía
---------------------------------------------------------------------------

local function guardarGuia(jugador: Player)
	local est = estado[jugador]
	if not est or not est.PuedeGuardar or not almacen or est.Paso == est.PasoGuardado then
		return
	end
	local paso = est.Paso
	local ok, err = pcall(function()
		almacen:SetAsync("Guia_" .. jugador.UserId, { Paso = paso, Terminada = paso > TOTAL_PASOS })
	end)
	if ok then
		est.PasoGuardado = paso
	else
		warn("[MejorasUX] No se pudo guardar la guía de " .. jugador.Name .. ": " .. tostring(err))
	end
end

local function ponerPaso(jugador: Player, paso: number)
	estado[jugador].Paso = paso
	jugador:SetAttribute("UX_GuiaCuenta", 0)
	jugador:SetAttribute("UX_GuiaPaso", paso)
end

local function cargarGuia(jugador: Player)
	local est = estado[jugador]
	local ok, datos = false, nil
	if almacen then
		ok, datos = pcall(function()
			return almacen:GetAsync("Guia_" .. jugador.UserId)
		end)
		if not ok then
			warn("[MejorasUX] No se pudo leer la guía de " .. jugador.Name .. "; esta sesión no se guarda.")
		end
	end
	if not jugador.Parent then
		return
	end
	est.PuedeGuardar = ok

	local paso
	if ok and typeof(datos) == "table" and datos.Terminada then
		paso = TOTAL_PASOS + 1
	elseif ok and typeof(datos) == "table" and typeof(datos.Paso) == "number" then
		paso = math.clamp(datos.Paso, 1, TOTAL_PASOS + 1)
	else
		-- Sin datos guardados: Integracion decide si es nuevo (puede usar leaderstats).
		jugador:WaitForChild("leaderstats", 10)
		local okM, mostrar = pcall(Integracion.MostrarGuia, jugador)
		if not okM then
			avisarUnaVez("MostrarGuia", "Error en Integracion.MostrarGuia: " .. tostring(mostrar))
		end
		paso = (okM and mostrar == false) and TOTAL_PASOS + 1 or 1
	end
	est.PasoGuardado = ok and typeof(datos) == "table" and paso or nil
	ponerPaso(jugador, paso)
end

local function avanzarGuia(jugador: Player, accion: string, cantidad: number)
	local est = estado[jugador]
	local paso = est and est.Paso
	if not paso or paso > TOTAL_PASOS then
		return
	end
	local datos = Config.Pasos[paso]
	if datos.Accion ~= accion then
		return
	end

	local cuenta = (jugador:GetAttribute("UX_GuiaCuenta") or 0) + cantidad
	if cuenta < datos.Cantidad then
		jugador:SetAttribute("UX_GuiaCuenta", cuenta)
		return
	end

	-- Paso completo: primero se avanza, así un segundo aviso no cobra el premio dos veces.
	ponerPaso(jugador, paso + 1)
	local premio = datos.Premio
	if premio then
		local ok, err = pcall(Integracion.DarPremio, jugador, premio.Moneda, premio.Cantidad)
		if not ok then
			avisarUnaVez("DarPremio", "Error en Integracion.DarPremio: " .. tostring(err))
		end
	end
	remotos.Premio:FireClient(jugador, premio and premio.Moneda, premio and premio.Cantidad)
	guardarGuia(jugador)
end

-- Avisa que el jugador hizo algo. Se puede llamar desde cualquier script del
-- servidor; no frena a quien la llama.
function MejorasUX.Registrar(jugador: Player, accion: string, cantidad: number?)
	if not estado[jugador] then
		return
	end
	task.spawn(function()
		momento(jugador, accion) -- antes de avanzar, así terminar la guía no dispara una oferta
		avanzarGuia(jugador, accion, cantidad or 1)
	end)
end

---------------------------------------------------------------------------
-- Venta
---------------------------------------------------------------------------

local function vender(jugador: Player)
	local est = estado[jugador]
	if not est then
		return
	end
	local ahora = os.clock()
	if ahora - est.UltimaVenta < Config.EsperaEntreVentas then
		return
	end
	est.UltimaVenta = ahora
	local ok, err = pcall(Integracion.Vender, jugador)
	if not ok then
		avisarUnaVez("Vender", "Error en Integracion.Vender: " .. tostring(err))
	end
end

local function crearCartelVenta(parte: BasePart)
	if parte:FindFirstChild("CartelVenta") then
		return
	end
	local cartel = Instance.new("BillboardGui")
	cartel.Name = "CartelVenta"
	cartel.Size = UDim2.fromScale(6, 2)
	cartel.StudsOffset = Vector3.new(0, parte.Size.Y / 2 + 2, 0)
	cartel.MaxDistance = 120
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.FredokaOne
	texto.Text = "💰 VENDER"
	texto.TextScaled = true
	texto.TextColor3 = Color3.fromRGB(255, 221, 64)
	texto.TextStrokeTransparency = 0
	texto.Parent = cartel
	cartel.Parent = parte
end

local function conectarPuntoDeVenta(instancia: Instance)
	if not instancia:IsA("BasePart") then
		return
	end
	crearCartelVenta(instancia)
	instancia.Touched:Connect(function(otra)
		local personaje = otra:FindFirstAncestorOfClass("Model")
		local jugador = personaje and Players:GetPlayerFromCharacter(personaje)
		local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
		if jugador and humanoide and humanoide.Health > 0 then
			vender(jugador)
		end
	end)
end

---------------------------------------------------------------------------
-- Mochila y próxima meta (una vez por segundo)
---------------------------------------------------------------------------

local function actualizarJugador(jugador: Player)
	local est = estado[jugador]
	if not est then
		return
	end

	local ok, actual, capacidad = pcall(Integracion.ObtenerMochila, jugador)
	if not ok then
		avisarUnaVez("ObtenerMochila", "Error en Integracion.ObtenerMochila: " .. tostring(actual))
	end
	if ok and typeof(actual) == "number" and typeof(capacidad) == "number" and capacidad > 0 then
		local llena = actual >= capacidad
		jugador:SetAttribute("UX_MochilaLlena", llena)
		if llena and not est.MochilaLlena then
			task.spawn(momento, jugador, "MochilaLlena")
		end
		est.MochilaLlena = llena
	else
		jugador:SetAttribute("UX_MochilaLlena", nil)
	end

	local okMeta, meta = pcall(Integracion.ProximaMeta, jugador)
	if not okMeta then
		avisarUnaVez("ProximaMeta", "Error en Integracion.ProximaMeta: " .. tostring(meta))
	end
	if okMeta and typeof(meta) == "table" then
		local okValor, valor = pcall(Integracion.ValorMochilaLlena, jugador)
		jugador:SetAttribute("UX_MetaTexto", meta.Texto)
		jugador:SetAttribute("UX_MetaMoneda", meta.Moneda)
		jugador:SetAttribute("UX_MetaActual", meta.Actual)
		jugador:SetAttribute("UX_MetaPrecio", meta.Precio)
		jugador:SetAttribute("UX_MetaValorMochila", okValor and typeof(valor) == "number" and valor or nil)
	else
		jugador:SetAttribute("UX_MetaTexto", nil)
	end
end

---------------------------------------------------------------------------
-- Inicio
---------------------------------------------------------------------------

local function alEntrar(jugador: Player)
	estado[jugador] = {
		Entrada = os.clock(),
		UltimaOferta = -math.huge,
		UltimaVenta = -math.huge,
		OfertasMostradas = {},
		Pases = {},
	}
	-- Permite cambiar el paso a mano para probar (ver README).
	jugador:GetAttributeChangedSignal("UX_GuiaPaso"):Connect(function()
		local est = estado[jugador]
		local paso = jugador:GetAttribute("UX_GuiaPaso")
		if est and typeof(paso) == "number" then
			est.Paso = paso
		end
	end)
	if Config.PaseVenderId ~= 0 then
		jugador:SetAttribute("UX_PaseVender", tienePase(jugador, Config.PaseVenderId))
	end
	cargarGuia(jugador)
end

local function alSalir(jugador: Player)
	guardarGuia(jugador)
	estado[jugador] = nil
end

function MejorasUX.Iniciar()
	if iniciado then
		return
	end
	iniciado = true
	remotos = crearRemotos()

	local ok, resultado = pcall(DataStoreService.GetDataStore, DataStoreService, "MejorasUX_Guia")
	if ok then
		almacen = resultado
	else
		warn("[MejorasUX] DataStore no disponible (en Studio: activá el acceso a las API); la guía no se guarda.")
	end

	remotos.PedirVenta.OnServerEvent:Connect(function(jugador)
		local est = estado[jugador]
		if est and Config.PaseVenderId ~= 0 and est.Pases[Config.PaseVenderId] then
			vender(jugador)
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(jugador, id, compro)
		local est = estado[jugador]
		if compro and est then
			est.Pases[id] = true
			if id == Config.PaseVenderId then
				jugador:SetAttribute("UX_PaseVender", true)
			end
		end
	end)

	for _, parte in CollectionService:GetTagged(Config.TagPuntoDeVenta) do
		conectarPuntoDeVenta(parte)
	end
	CollectionService:GetInstanceAddedSignal(Config.TagPuntoDeVenta):Connect(conectarPuntoDeVenta)

	Players.PlayerAdded:Connect(alEntrar)
	Players.PlayerRemoving:Connect(alSalir)
	for _, jugador in Players:GetPlayers() do
		task.spawn(alEntrar, jugador)
	end

	game:BindToClose(function()
		local pendientes = 0
		for jugador in estado do
			pendientes += 1
			task.spawn(function()
				guardarGuia(jugador)
				pendientes -= 1
			end)
		end
		local limite = os.clock() + 20
		while pendientes > 0 and os.clock() < limite do
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		while true do
			for jugador in estado do
				task.spawn(actualizarJugador, jugador)
			end
			task.wait(1)
		end
	end)
end

return MejorasUX
]=] },
	{ Base = "ServerScriptService", Nombre = "Servidor", Clase = "Script", NoPisar = false, Codigo = [=[
-- Arranca las mejoras de UX. La lógica está en el módulo API.
require(script.Parent:WaitForChild("API")).Iniciar()
]=] },
	{ Base = "StarterPlayerScripts", Nombre = "Cliente", Clase = "LocalScript", NoPisar = false, Codigo = [=[
-- Interfaz de las mejoras: un solo cartel arriba (misión de la guía, mochila llena
-- o próxima meta), la flecha hacia el objetivo, el aviso de premio y el botón VENDER.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local jugador = Players.LocalPlayer
local Compartido = ReplicatedStorage:WaitForChild("MejorasUX")
local Config = require(Compartido:WaitForChild("Config"))
local Numeros = require(Compartido:WaitForChild("Numeros"))
local Remotos = Compartido:WaitForChild("Remotos")

local TOTAL_PASOS = #Config.Pasos
local FUENTE = Enum.Font.FredokaOne
local AMARILLO = Color3.fromRGB(255, 221, 64)
local VERDE = Color3.fromRGB(88, 214, 96)
local OSCURO = Color3.fromRGB(28, 36, 56)
local DISTANCIA_LLEGADA = 12 -- a esta distancia del objetivo se oculta la flecha

local function crear(clase: string, propiedades)
	local objeto = Instance.new(clase)
	for clave, valor in propiedades do
		if clave ~= "Parent" then
			objeto[clave] = valor
		end
	end
	objeto.Parent = propiedades.Parent
	return objeto
end

local function texto(propiedades)
	propiedades.BackgroundTransparency = 1
	propiedades.Font = FUENTE
	propiedades.TextScaled = true
	propiedades.TextColor3 = propiedades.TextColor3 or Color3.new(1, 1, 1)
	return crear("TextLabel", propiedades)
end

local pantalla = crear("ScreenGui", {
	Name = "MejorasUX",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = jugador:WaitForChild("PlayerGui"),
})

---------------------------------------------------------------------------
-- Cartel de arriba
---------------------------------------------------------------------------

local cartel = crear("Frame", {
	Name = "Cartel",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.new(0.9, 0, 0, 68),
	BackgroundColor3 = OSCURO,
	BackgroundTransparency = 0.15,
	Visible = false,
	Parent = pantalla,
})
crear("UISizeConstraint", { MaxSize = Vector2.new(400, 68), Parent = cartel })
crear("UICorner", { CornerRadius = UDim.new(0, 14), Parent = cartel })
crear("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.6, Parent = cartel })

local icono = texto({ Position = UDim2.fromOffset(8, 9), Size = UDim2.fromOffset(50, 50), Parent = cartel })
local titulo = texto({
	Position = UDim2.fromOffset(64, 5),
	Size = UDim2.new(1, -74, 0, 15),
	TextColor3 = AMARILLO,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = cartel,
})
local descripcion = texto({
	Position = UDim2.fromOffset(64, 21),
	Size = UDim2.new(1, -74, 0, 22),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = cartel,
})
local barra = crear("Frame", {
	Position = UDim2.fromOffset(64, 47),
	Size = UDim2.new(1, -74, 0, 15),
	BackgroundColor3 = Color3.fromRGB(10, 14, 24),
	Parent = cartel,
})
crear("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barra })
local relleno = crear("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = VERDE, Parent = barra })
crear("UICorner", { CornerRadius = UDim.new(1, 0), Parent = relleno })
local textoBarra = texto({ Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = barra })
crear("UIStroke", { Thickness = 1.5, Parent = textoBarra })

local function mostrarCartel(emoji: string, encabezado: string, cuerpo: string, progreso: number, enBarra: string)
	cartel.Visible = true
	icono.Text = emoji
	titulo.Text = encabezado
	descripcion.Text = cuerpo
	textoBarra.Text = enBarra
	TweenService:Create(relleno, TweenInfo.new(0.3), { Size = UDim2.fromScale(math.clamp(progreso, 0, 1), 1) }):Play()
end

---------------------------------------------------------------------------
-- Botón VENDER (con pase y mochila llena)
---------------------------------------------------------------------------

local botonVender = crear("TextButton", {
	Name = "Vender",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.fromOffset(190, 58),
	BackgroundColor3 = VERDE,
	Font = FUENTE,
	Text = "💰 VENDER",
	TextScaled = true,
	TextColor3 = Color3.new(1, 1, 1),
	Visible = false,
	Parent = pantalla,
})
crear("UICorner", { CornerRadius = UDim.new(0, 14), Parent = botonVender })
crear("UIStroke", { Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = botonVender })
crear("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = botonVender })
botonVender.Activated:Connect(function()
	Remotos.PedirVenta:FireServer()
end)

---------------------------------------------------------------------------
-- Aviso de premio
---------------------------------------------------------------------------

local aviso = crear("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.fromOffset(280, 90),
	BackgroundColor3 = OSCURO,
	BackgroundTransparency = 0.1,
	Visible = false,
	Parent = pantalla,
})
crear("UICorner", { CornerRadius = UDim.new(0, 16), Parent = aviso })
crear("UIStroke", { Color = AMARILLO, Thickness = 3, Parent = aviso })
local escalaAviso = crear("UIScale", { Parent = aviso })
texto({ Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, 36), Text = "¡Misión cumplida!", Parent = aviso })
local textoPremio = texto({
	Position = UDim2.fromOffset(10, 48),
	Size = UDim2.new(1, -20, 0, 32),
	TextColor3 = AMARILLO,
	Parent = aviso,
})

local avisoId = 0
Remotos.Premio.OnClientEvent:Connect(function(moneda: string?, cantidad: number?)
	avisoId += 1
	local miAviso = avisoId
	textoPremio.Text = cantidad and ("+" .. Numeros.Abreviar(cantidad) .. " " .. (Config.IconoMoneda[moneda] or moneda or "")) or "⭐"
	aviso.Visible = true
	escalaAviso.Scale = 0.3
	TweenService:Create(escalaAviso, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(2.5, function()
		if avisoId == miAviso then
			aviso.Visible = false
		end
	end)
end)

---------------------------------------------------------------------------
-- Flecha hacia el objetivo
---------------------------------------------------------------------------

local objetivoTags: { string }? = nil

-- El rayo vive en el personaje y el adjunto del objetivo en la parte apuntada;
-- los dos se crean de nuevo si su dueño desaparece (respawn, piedra rota).
local rayo: Beam? = nil
local adjuntoObjetivo: Attachment? = nil

local marcador = crear("BillboardGui", {
	Size = UDim2.fromScale(4, 4),
	AlwaysOnTop = true,
	Enabled = false,
	Parent = pantalla,
})
texto({ Size = UDim2.fromScale(1, 1), Text = "▼", TextColor3 = AMARILLO, Parent = marcador })
local alturaMarcador = 0

local function alAparecer(personaje: Model)
	local raiz = personaje:WaitForChild("HumanoidRootPart", 10)
	if not raiz then
		return
	end
	local origen = crear("Attachment", { Name = "OrigenGuia", Parent = raiz })
	rayo = crear("Beam", {
		Name = "FlechaGuia",
		Color = ColorSequence.new(AMARILLO),
		Transparency = NumberSequence.new(0.25),
		LightEmission = 1,
		Width0 = 0.5,
		Width1 = 0.5,
		FaceCamera = true,
		Segments = 20,
		Attachment0 = origen,
		Enabled = false,
		Parent = raiz,
	})
end
jugador.CharacterAdded:Connect(alAparecer)
if jugador.Character then
	task.spawn(alAparecer, jugador.Character)
end

local function apuntarA(parte: BasePart?)
	if not rayo or not rayo.Parent then
		marcador.Enabled = false
		return
	end
	if not parte then
		rayo.Enabled = false
		marcador.Enabled = false
		return
	end
	if not adjuntoObjetivo or adjuntoObjetivo.Parent ~= parte then
		if adjuntoObjetivo then
			adjuntoObjetivo:Destroy()
		end
		adjuntoObjetivo = crear("Attachment", { Name = "ObjetivoGuia", Parent = parte })
	end
	rayo.Attachment1 = adjuntoObjetivo
	rayo.Enabled = true
	marcador.Adornee = parte
	marcador.Enabled = true
	alturaMarcador = parte.Size.Y / 2 + 3
end

local function parteDe(instancia: Instance): BasePart?
	if instancia:IsA("BasePart") then
		return instancia
	end
	if instancia:IsA("Model") then
		return instancia.PrimaryPart or instancia:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function masCercano(tags: { string }, desde: Vector3): BasePart?
	local mejor, mejorDistancia = nil, math.huge
	for _, tag in tags do
		for _, instancia in CollectionService:GetTagged(tag) do
			local parte = instancia:IsDescendantOf(workspace) and parteDe(instancia)
			if parte then
				local distancia = (parte.Position - desde).Magnitude
				if distancia < mejorDistancia then
					mejor, mejorDistancia = parte, distancia
				end
			end
		end
	end
	return mejor
end

task.spawn(function()
	while true do
		local personaje = jugador.Character
		local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
		local parte = objetivoTags and raiz and masCercano(objetivoTags, raiz.Position)
		if parte and (parte.Position - raiz.Position).Magnitude > DISTANCIA_LLEGADA then
			apuntarA(parte)
		else
			apuntarA(nil)
		end
		task.wait(0.25)
	end
end)

RunService.RenderStepped:Connect(function()
	if marcador.Enabled then
		marcador.StudsOffset = Vector3.new(0, alturaMarcador + math.sin(os.clock() * 4) * 0.6, 0)
	end
end)

---------------------------------------------------------------------------
-- Qué muestra el cartel: guía > mochila llena > próxima meta
---------------------------------------------------------------------------

local function actualizar()
	local tienePase = jugador:GetAttribute("UX_PaseVender") == true
	local mochilaLlena = jugador:GetAttribute("UX_MochilaLlena") == true
	botonVender.Visible = tienePase and mochilaLlena

	local paso = jugador:GetAttribute("UX_GuiaPaso")
	if paso and paso <= TOTAL_PASOS then
		local datos = Config.Pasos[paso]
		local cuenta = jugador:GetAttribute("UX_GuiaCuenta") or 0
		mostrarCartel(
			"🎯",
			string.format("MISIÓN %d DE %d", paso, TOTAL_PASOS),
			datos.Texto,
			cuenta / datos.Cantidad,
			string.format("%d / %d", cuenta, datos.Cantidad)
		)
		objetivoTags = datos.Objetivo
		return
	end

	if mochilaLlena then
		if tienePase then
			mostrarCartel("🎒", "¡MOCHILA LLENA!", "Tocá VENDER", 1, "LLENA")
			objetivoTags = nil
		else
			mostrarCartel("🎒", "¡MOCHILA LLENA!", "Andá a vender tus piedras", 1, "LLENA")
			objetivoTags = { Config.TagPuntoDeVenta, "Guia_Venta" }
		end
		return
	end

	objetivoTags = nil
	local meta = jugador:GetAttribute("UX_MetaTexto")
	if meta then
		local actual = jugador:GetAttribute("UX_MetaActual") or 0
		local precio = jugador:GetAttribute("UX_MetaPrecio") or 0
		local moneda = jugador:GetAttribute("UX_MetaMoneda") or ""
		local valorMochila = jugador:GetAttribute("UX_MetaValorMochila")
		local enBarra
		if actual >= precio then
			enBarra = "¡Ya te alcanza!"
		elseif valorMochila then
			enBarra = Numeros.Faltan(actual, precio, valorMochila, Config.UnidadSingular, Config.UnidadPlural)
		else
			enBarra = Numeros.Abreviar(actual) .. " / " .. Numeros.Abreviar(precio) .. " " .. (Config.IconoMoneda[moneda] or "")
		end
		mostrarCartel("⭐", "PRÓXIMA META", meta, Numeros.Progreso(actual, precio), enBarra)
		return
	end

	cartel.Visible = false
end

jugador.AttributeChanged:Connect(function(nombre)
	if string.sub(nombre, 1, 3) == "UX_" then
		actualizar()
	end
end)
actualizar()
]=] },
	{ Base = "StarterPlayerScripts", Nombre = "Ofertas", Clase = "LocalScript", NoPisar = false, Codigo = [=[
-- Muestra una oferta cuando el servidor elige el momento (mochila llena, renacer...).
-- Lee el precio real de Roblox, así nunca muestra uno desactualizado.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local jugador = Players.LocalPlayer
local Compartido = ReplicatedStorage:WaitForChild("MejorasUX")
local Config = require(Compartido:WaitForChild("Config"))
local Remotos = Compartido:WaitForChild("Remotos")

local FUENTE = Enum.Font.FredokaOne
local AMARILLO = Color3.fromRGB(255, 221, 64)
local VERDE = Color3.fromRGB(88, 214, 96)
local GRIS = Color3.fromRGB(90, 98, 120)
local OSCURO = Color3.fromRGB(28, 36, 56)

local function crear(clase: string, propiedades)
	local objeto = Instance.new(clase)
	for clave, valor in propiedades do
		if clave ~= "Parent" then
			objeto[clave] = valor
		end
	end
	objeto.Parent = propiedades.Parent
	return objeto
end

local pantalla = crear("ScreenGui", {
	Name = "MejorasUXOfertas",
	ResetOnSpawn = false,
	DisplayOrder = 5,
	Parent = jugador:WaitForChild("PlayerGui"),
})

local tarjeta = crear("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(300, 180),
	BackgroundColor3 = OSCURO,
	Visible = false,
	Parent = pantalla,
})
crear("UICorner", { CornerRadius = UDim.new(0, 16), Parent = tarjeta })
crear("UIStroke", { Color = AMARILLO, Thickness = 3, Parent = tarjeta })
local escala = crear("UIScale", { Parent = tarjeta })

local titulo = crear("TextLabel", {
	Position = UDim2.fromOffset(12, 10),
	Size = UDim2.new(1, -24, 0, 34),
	BackgroundTransparency = 1,
	Font = FUENTE,
	TextScaled = true,
	TextColor3 = AMARILLO,
	Parent = tarjeta,
})
local texto = crear("TextLabel", {
	Position = UDim2.fromOffset(12, 48),
	Size = UDim2.new(1, -24, 0, 60),
	BackgroundTransparency = 1,
	Font = FUENTE,
	TextSize = 18,
	TextWrapped = true,
	TextColor3 = Color3.new(1, 1, 1),
	Parent = tarjeta,
})

local function boton(etiqueta: string, color: Color3, x: number)
	local b = crear("TextButton", {
		Position = UDim2.new(x, 6, 1, -60),
		Size = UDim2.new(0.5, -12, 0, 48),
		BackgroundColor3 = color,
		Font = FUENTE,
		Text = etiqueta,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Parent = tarjeta,
	})
	crear("UICorner", { CornerRadius = UDim.new(0, 12), Parent = b })
	crear("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), Parent = b })
	return b
end
local botonVer = boton("Ver", VERDE, 0.5)
local botonNo = boton("Ahora no", GRIS, 0)

local precios = {}
local function precioDe(oferta): number?
	if precios[oferta.Id] == nil then
		local tipo = oferta.Tipo == "Pase" and Enum.InfoType.GamePass or Enum.InfoType.Product
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, oferta.Id, tipo)
		precios[oferta.Id] = ok and info and info.PriceInRobux or false
	end
	return precios[oferta.Id] or nil
end

local actual = nil
local ofertaId = 0

local function cerrar()
	tarjeta.Visible = false
	actual = nil
end

botonNo.Activated:Connect(cerrar)
botonVer.Activated:Connect(function()
	local oferta = actual
	cerrar()
	if not oferta then
		return
	end
	if oferta.Tipo == "Pase" then
		MarketplaceService:PromptGamePassPurchase(jugador, oferta.Id)
	else
		MarketplaceService:PromptProductPurchase(jugador, oferta.Id)
	end
end)

Remotos.MostrarOferta.OnClientEvent:Connect(function(indice: number)
	local oferta = Config.Ofertas[indice]
	if not oferta or tarjeta.Visible then
		return
	end
	local precio = precioDe(oferta)
	if not precio then
		return -- sin precio no se ofrece nada
	end

	ofertaId += 1
	local miOferta = ofertaId
	actual = oferta
	titulo.Text = oferta.Titulo
	texto.Text = oferta.Texto
	botonVer.Text = "Ver · R$ " .. precio
	tarjeta.Visible = true
	escala.Scale = 0.3
	TweenService:Create(escala, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	task.delay(Config.OfertasDuracion, function()
		if ofertaId == miOferta then
			cerrar()
		end
	end)
end)
]=] },
}

local okGrabacion, grabacion = pcall(ChangeHistoryService.TryBeginRecording, ChangeHistoryService, "Instalar MejorasUX")
if not okGrabacion then
	grabacion = nil
	ChangeHistoryService:SetWaypoint("Antes de instalar MejorasUX")
end

for _, archivo in ARCHIVOS do
	local padre = base(archivo.Base)
	local carpeta = padre:FindFirstChild("MejorasUX")
	if not carpeta then
		carpeta = Instance.new("Folder")
		carpeta.Name = "MejorasUX"
		carpeta.Parent = padre
	end

	local existente = carpeta:FindFirstChild(archivo.Nombre)
	if existente and existente.ClassName ~= archivo.Clase then
		existente:Destroy()
		existente = nil
	end

	if existente and archivo.NoPisar then
		print("[MejorasUX] " .. existente:GetFullName() .. " ya existe; se dejó como estaba.")
	else
		local script = existente or Instance.new(archivo.Clase)
		script.Name = archivo.Nombre
		script.Source = archivo.Codigo
		script.Parent = carpeta
		print("[MejorasUX] " .. (existente and "Actualizado: " or "Creado: ") .. script:GetFullName())
	end
end

if grabacion then
	ChangeHistoryService:FinishRecording(grabacion, Enum.FinishRecordingOperation.Commit)
else
	ChangeHistoryService:SetWaypoint("Instalar MejorasUX")
end
print("[MejorasUX] Listo. Ahora completá ServerScriptService > MejorasUX > Integracion (ver README).")
