# -
Поправка / Курсова работа

## Open a Portal: Roblox game code (Rojo)

The game's scripts live in `src/` and sync into Roblox Studio with [Rojo](https://rojo.space).

| Folder | Lands in Studio as |
|---|---|
| `src/server` | `ServerScriptService.Server` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared` | `ReplicatedStorage.Shared` |

Rojo only manages those three folders. Everything else in the place (maps, models, parts, scripts you made directly in Studio) is left alone.

File names decide the script type: `*.server.luau` is a Script, `*.client.luau` is a LocalScript, plain `*.luau` is a ModuleScript, and `init.*.luau` makes the folder itself that script.

### First-time setup (Windows)

1. In PowerShell, from this folder: `powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1`
2. Restart Roblox Studio.

### Every session

1. Run `rojo serve` (or `scripts\serve.ps1`) and leave it open.
2. In Studio, open the place, then Plugins > Rojo > Connect.
3. Edit files in `src/`; Studio updates live. Save/publish the place from Studio as usual.
