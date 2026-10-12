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
