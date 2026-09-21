# SAVIA — Blender Live Mode

## Objetivo

Este flujo conecta el repositorio con una instancia gráfica de Blender.

**No se usa Blender en background.** Blender abre su ventana normal para que puedas ver la construcción.

### Flujo

```
VS Code / GitHub
       |
       | guardar .py
       v
savia_field_research_station_v01.py
       |
       v
live_bridge.py
       |
       | detecta cambio
       v
BLENDER
       |
       +--> reconstruye estación
       +--> actualiza viewport
       +--> guarda .blend
       +--> exporta .glb
       |
       v
GODOT
```

## Inicio rápido en Windows

Doble clic en:

`tools/blender/START_SAVIA_BLENDER_LIVE.bat`

Se abrirá Blender normalmente.

La primera ejecución construye la estación automáticamente.

Después, cuando se modifica y guarda:

`tools/blender/savia_field_research_station_v01.py`

el bridge detecta el cambio y vuelve a construir la estación.

## Si Blender está instalado en otra ruta

Editar la variable:

`BLENDER=`

en el archivo BAT.

## Importante

- El modo Live está pensado para desarrollo.
- No debe usarse como sistema final de ejecución del juego.
- El runtime de SAVIA seguirá usando los GLB/escenas importados por Godot.
- El bridge solo automatiza la iteración Blender → Godot.
