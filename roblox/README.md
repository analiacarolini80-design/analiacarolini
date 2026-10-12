# Mejoras de UX para el simulador de minería

Cuatro mejoras pensadas para chicos de 8 a 10 años:

1. **Guía y próxima meta.** Hay 5 misiones con una flecha que lleva al objetivo y un premio en cada una. Cuando se terminan, el mismo cartel muestra la próxima meta con una barra de progreso.
2. **Números legibles.** Comparaciones como "¡x2 más fuerte!" o "Te faltan 3 mochilas", además de abreviaturas como "1,6 No".
3. **Venta en las minas.** Una parte con el Tag `PuntoDeVenta` vende la mochila al tocarla. Con un pase, cuando la mochila está llena aparece el botón **VENDER**. Sin pase, la flecha lleva al punto de venta más cercano.
4. **Ofertas en el momento justo.** Aparecen solo al llenar la mochila o al renacer. Nunca salen durante la guía ni en los primeros 10 minutos, y dejan al menos 5 minutos entre una y otra.

## 1. Copiar los scripts a Studio

Creá estos objetos con **exactamente** estos nombres y pegá en cada uno el contenido del archivo indicado:

| Dónde | Objeto | Tipo | Archivo |
|---|---|---|---|
| ReplicatedStorage | `MejorasUX` | Folder | — |
| ReplicatedStorage › MejorasUX | `Config` | ModuleScript | `ReplicatedStorage/MejorasUX/Config.lua` |
| ReplicatedStorage › MejorasUX | `Numeros` | ModuleScript | `ReplicatedStorage/MejorasUX/Numeros.lua` |
| ServerScriptService | `MejorasUX` | Folder | — |
| ServerScriptService › MejorasUX | `Integracion` | ModuleScript | `ServerScriptService/MejorasUX/Integracion.lua` |
| ServerScriptService › MejorasUX | `API` | ModuleScript | `ServerScriptService/MejorasUX/API.lua` |
| ServerScriptService › MejorasUX | `Servidor` | Script | `ServerScriptService/MejorasUX/Servidor.server.lua` |
| StarterPlayer › StarterPlayerScripts | `MejorasUXCliente` | LocalScript | `StarterPlayerScripts/MejorasUX/Cliente.client.lua` |
| StarterPlayer › StarterPlayerScripts | `MejorasUXOfertas` | LocalScript | `StarterPlayerScripts/MejorasUX/Ofertas.client.lua` |

Si usás Rojo, `default.project.json` ya arma esta estructura.

## 2. Avisar lo que hace el jugador (una línea en cada script)

En los scripts del **servidor** donde pasa cada cosa:

```lua
local MejorasUX = require(game.ServerScriptService.MejorasUX.API)

MejorasUX.Registrar(jugador, "Minar")        -- al romper una piedra
MejorasUX.Registrar(jugador, "Vender")       -- en la función que vende la mochila
MejorasUX.Registrar(jugador, "ComprarPico")  -- al comprar un pico
MejorasUX.Registrar(jugador, "AbrirHuevo")   -- al abrir un huevo
MejorasUX.Registrar(jugador, "Renacer")      -- al renacer
```

Registrá cada acción **en un solo lugar**, donde realmente ocurre. Por ejemplo, "Vender" va dentro de tu función de venta, así cuenta igual si se vende en el lobby, en la mina o con el botón.

## 3. Completar `Integracion`

Es el único archivo que hay que adaptar al juego. Cada función tiene un ejemplo:

- `Vender`: llamá a la misma función que usa la venta del lobby.
- `ObtenerMochila`: devolvé cuánto lleva la mochila y cuánto le entra.
- `ValorMochilaLlena` (opcional): con esto la meta dice "Te faltan 3 mochilas" en vez de "Te faltan 1,2 K".
- `DarPremio` y `ObtenerMoneda`: por defecto usan `leaderstats`. Si guardás el dinero en otro lado, cambialos.
- `MostrarGuia`: devolvé `false` para jugadores que ya jugaban, así no ven la guía.
- `Metas`: sacá los guiones de los ejemplos y poné tus picos, minas y renacimiento en orden.

## 4. Poner los Tags

En Studio, seleccioná la parte y agregá el Tag en Properties › Tags.

| Tag | Dónde |
|---|---|
| `PuntoDeVenta` | Una parte a la salida de cada mina. Vende al tocarla y muestra "💰 VENDER". **No** se la pongas a la venta del lobby si ya tiene su propio script. |
| `Guia_Venta` | La venta del lobby, para que la flecha también la encuentre. |
| `Guia_Mina` | La entrada de la primera mina. |
| `Guia_TiendaPicos` | La tienda de picos. |
| `Guia_Huevos` | Los huevos. |
| `Guia_Renacer` | El lugar o NPC para renacer. Si es solo un botón de la interfaz, dejalo sin Tag. |

Si el juego usa **StreamingEnabled**, los objetos lejanos no existen en el cliente y la flecha no los encuentra. A los modelos con Tag de guía ponele `ModelStreamingMode = Persistent`.

## 5. Ofertas

1. En `Config.Ofertas` poné el Id de cada pase o producto. Las que tienen `Id = 0` no aparecen.
2. Si usás el botón VENDER, poné el mismo pase en `Config.PaseVenderId`.
3. Sacá o escondé los botones de ofertas que hoy están siempre en pantalla.

El precio se lee de Roblox en el momento, así nunca se muestra uno desactualizado. Los Developer Products se siguen entregando con tu `ProcessReceipt` de siempre.

## 6. Usar los números legibles en tus tiendas

```lua
local Numeros = require(game.ReplicatedStorage.MejorasUX.Numeros)

Numeros.Abreviar(1.6e30)                          --> "1,6 No"
Numeros.Comparar(fuerzaNueva, fuerzaActual, "fuerte") --> "¡x2 más fuerte!"
Numeros.Faltan(dinero, precio, valorBolsa, "bolsa", "bolsas") --> "Te faltan 3 bolsas"
Numeros.Progreso(dinero, precio)                  --> 0.7 (para una barra)
```

## Probar en Studio

- Activá **Game Settings › Security › Enable Studio Access to API Services** para que la guía se guarde.
- Para repetir la guía, en la Command Bar durante el Play (vista del servidor) escribí:
  `game.Players.TuNombre:SetAttribute("UX_GuiaPaso", 1)`
- Si algo de `Integracion` falla, aparece una sola vez en el Output con el prefijo `[MejorasUX]`.
