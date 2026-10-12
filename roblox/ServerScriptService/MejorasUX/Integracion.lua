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
