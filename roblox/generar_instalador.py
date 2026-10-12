"""Genera Instalador.lua: un solo texto para pegar en la Command Bar de Roblox Studio
que crea (o actualiza) todos los scripts de MejorasUX.

Uso: python3 roblox/generar_instalador.py
"""
from pathlib import Path

RAIZ = Path(__file__).parent

# (archivo, servicio base, nombre, clase, no pisar si ya existe)
ARCHIVOS = [
    ("ReplicatedStorage/MejorasUX/Config.lua", "ReplicatedStorage", "Config", "ModuleScript", False),
    ("ReplicatedStorage/MejorasUX/Numeros.lua", "ReplicatedStorage", "Numeros", "ModuleScript", False),
    ("ServerScriptService/MejorasUX/Integracion.lua", "ServerScriptService", "Integracion", "ModuleScript", True),
    ("ServerScriptService/MejorasUX/API.lua", "ServerScriptService", "API", "ModuleScript", False),
    ("ServerScriptService/MejorasUX/Servidor.server.lua", "ServerScriptService", "Servidor", "Script", False),
    ("StarterPlayerScripts/MejorasUX/Cliente.client.lua", "StarterPlayerScripts", "Cliente", "LocalScript", False),
    ("StarterPlayerScripts/MejorasUX/Ofertas.client.lua", "StarterPlayerScripts", "Ofertas", "LocalScript", False),
]

CABECERA = """\
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
"""

PIE = """\
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
"""


def cadena_larga(texto: str) -> str:
    nivel = 1
    while f"]{'=' * nivel}]" in texto:
        nivel += 1
    iguales = "=" * nivel
    # Luau descarta el primer salto de línea después de [==[
    return f"[{iguales}[\n{texto}]{iguales}]"


def main() -> None:
    partes = [CABECERA]
    for ruta, servicio, nombre, clase, no_pisar in ARCHIVOS:
        codigo = (RAIZ / ruta).read_text(encoding="utf-8")
        partes.append(
            f'\t{{ Base = "{servicio}", Nombre = "{nombre}", Clase = "{clase}", '
            f"NoPisar = {'true' if no_pisar else 'false'}, Codigo = {cadena_larga(codigo)} }},\n"
        )
    partes.append(PIE)
    (RAIZ / "Instalador.lua").write_text("".join(partes), encoding="utf-8")


if __name__ == "__main__":
    main()
