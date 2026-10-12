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
