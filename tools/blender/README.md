# SAVIA — Blender Asset Pipeline

## Field Research Station v0.1

Script:
`tools/blender/savia_field_research_station_v01.py`

### Intended result

A unique SAVIA hero asset built as a real in-world field research station:

- Field table
- Microscope
- Soil Core with O/A/B/C horizons
- Sample tray
- Petri dishes
- Specimen jars
- Soil sensor
- Scientific lamp
- Root sample
- Mycorrhizal display
- SAVIA Core
- Research notebook
- Staging camera and lights

### Live Blender workflow

Open Blender on desktop, open the script in **Scripting**, and run it.

The script builds the collection progressively and forces viewport redraws between stages so the construction can be observed.

It saves:

- `assets/blender/SAVIA_Field_Research_Station_v01.blend`
- `assets/blender/SAVIA_Field_Research_Station_v01.glb`

The GLB is the runtime handoff to Godot.

### Design constraints

The station is deliberately not a generic laboratory:
- field-research character
- natural materials
- restrained scientific lighting
- tactile equipment
- no cyberpunk styling
- biological visualization uses subtle emission only
- scientific elements remain physically plausible

### Godot handoff

Godot's recommended 3D interchange format is glTF 2.0, including binary `.glb`. Direct `.blend` import works on desktop when Blender is installed, but it requires Blender to perform the glTF conversion. The Android/web editors cannot call Blender, so SAVIA should use the generated GLB for the mobile runtime.

Source: https://docs.godotengine.org/en/latest/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html
