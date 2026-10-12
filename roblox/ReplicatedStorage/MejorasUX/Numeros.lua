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
