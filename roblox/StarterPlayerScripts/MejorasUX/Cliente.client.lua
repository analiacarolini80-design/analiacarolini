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
