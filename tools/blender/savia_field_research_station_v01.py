"""
SAVIA — Field Research Station v0.1
Blender 4.x procedural asset generator.

Purpose:
- Build the first unique SAVIA "hero" environment asset.
- Keep the scientific field-lab aesthetic grounded, tactile and nature-integrated.
- Generate: field table, microscope, soil core, sample tray, jars, soil sensor,
  scientific lamp, SAVIA Core, root sample and mycorrhiza display.
- Designed for Godot via glTF 2.0.

Run inside Blender's Scripting workspace:
1. Open this file.
2. Run Script.
3. Watch the collection build in the viewport.
4. The script saves a .blend and exports a .glb next to it.

No external Python packages are required.
"""

import bpy
import math
import os
import time
from mathutils import Vector

# -----------------------------
# CONFIG
# -----------------------------
LIVE_BUILD = True
STEP_DELAY = 0.08
EXPORT_GLB = True
SAVE_BLEND = True

ROOT_NAME = "SAVIA_Field_Research_Station_v01"
COLLECTION_NAME = "SAVIA_Field_Research_Station"

# Palette: natural materials + restrained scientific emission.
COLORS = {
    "wood": (0.16, 0.09, 0.045, 1.0),
    "wood_light": (0.30, 0.18, 0.09, 1.0),
    "metal": (0.16, 0.19, 0.18, 1.0),
    "metal_dark": (0.055, 0.065, 0.06, 1.0),
    "glass": (0.18, 0.38, 0.34, 1.0),
    "soil_o": (0.10, 0.055, 0.025, 1.0),
    "soil_a": (0.20, 0.10, 0.035, 1.0),
    "soil_b": (0.30, 0.17, 0.075, 1.0),
    "soil_c": (0.42, 0.31, 0.20, 1.0),
    "root": (0.30, 0.16, 0.065, 1.0),
    "leaf": (0.08, 0.22, 0.11, 1.0),
    "fungus": (0.38, 0.31, 0.20, 1.0),
    "paper": (0.72, 0.69, 0.57, 1.0),
    "amber": (0.80, 0.38, 0.08, 1.0),
    "bio": (0.12, 0.65, 0.42, 1.0),
    "water": (0.08, 0.32, 0.42, 1.0),
    "white": (0.82, 0.84, 0.79, 1.0),
}

# -----------------------------
# UTILITIES
# -----------------------------
def live_step(label):
    print("[SAVIA]", label)
    if not LIVE_BUILD:
        return
    try:
        bpy.context.view_layer.update()
        bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)
        time.sleep(STEP_DELAY)
    except Exception:
        pass


def clean_collection():
    old = bpy.data.collections.get(COLLECTION_NAME)
    if old:
        for obj in list(old.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(old)

    col = bpy.data.collections.new(COLLECTION_NAME)
    bpy.context.scene.collection.children.link(col)
    return col


COL = clean_collection()


def link_only(obj):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    COL.objects.link(obj)
    return obj


def mat(name, color, metallic=0.0, roughness=0.55, emission=None, emission_strength=0.0, transmission=0.0):
    m = bpy.data.materials.get("SAVIA_" + name)
    if not m:
        m = bpy.data.materials.new("SAVIA_" + name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if "Transmission Weight" in bsdf.inputs:
        bsdf.inputs["Transmission Weight"].default_value = transmission
    elif "Transmission" in bsdf.inputs:
        bsdf.inputs["Transmission"].default_value = transmission
    if emission:
        bsdf.inputs["Emission Color"].default_value = emission
        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = emission_strength
    return m


MATS = {
    k: mat(k, v) for k, v in COLORS.items()
}
MATS["metal"] = mat("metal", COLORS["metal"], metallic=0.72, roughness=0.30)
MATS["metal_dark"] = mat("metal_dark", COLORS["metal_dark"], metallic=0.82, roughness=0.24)
MATS["glass"] = mat("glass", COLORS["glass"], roughness=0.12, transmission=0.72)
MATS["bio"] = mat("bio", COLORS["bio"], roughness=0.35,
                  emission=COLORS["bio"], emission_strength=1.7)
MATS["amber"] = mat("amber", COLORS["amber"], roughness=0.35,
                    emission=COLORS["amber"], emission_strength=1.2)
MATS["water"] = mat("water", COLORS["water"], roughness=0.08, transmission=0.45)
MATS["paper"] = mat("paper", COLORS["paper"], roughness=0.88)


def cube(name, loc, scale, material, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = link_only(bpy.context.object)
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        mod = o.modifiers.new("Soft_Edges", "BEVEL")
        mod.width = bevel
        mod.segments = 3
    o.data.materials.append(MATS[material] if isinstance(material, str) else material)
    return o


def cyl(name, loc, radius, depth, material, vertices=32, rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc,
                                        rotation=rotation or (0, 0, 0))
    o = link_only(bpy.context.object)
    o.name = name
    o.data.materials.append(MATS[material] if isinstance(material, str) else material)
    return o


def sphere(name, loc, radius, material, segments=24, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=radius, location=loc)
    o = link_only(bpy.context.object)
    o.name = name
    o.data.materials.append(MATS[material] if isinstance(material, str) else material)
    return o


def torus(name, loc, major, minor, material, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                     major_segments=32, minor_segments=10,
                                     location=loc, rotation=rotation)
    o = link_only(bpy.context.object)
    o.name = name
    o.data.materials.append(MATS[material] if isinstance(material, str) else material)
    return o


def curve_tube(name, points, radius, material):
    cu = bpy.data.curves.new("SAVIA_" + name, type='CURVE')
    cu.dimensions = '3D'
    cu.bevel_depth = radius
    cu.bevel_resolution = 2
    sp = cu.splines.new('BEZIER')
    sp.bezier_points.add(len(points) - 1)
    for bp, p in zip(sp.bezier_points, points):
        bp.co = p
        bp.handle_left_type = 'AUTO'
        bp.handle_right_type = 'AUTO'
    obj = bpy.data.objects.new(name, cu)
    COL.objects.link(obj)
    obj.data.materials.append(MATS[material] if isinstance(material, str) else material)
    return obj


def text_obj(name, body, loc, size=0.18, material="paper"):
    bpy.ops.object.text_add(location=loc, rotation=(math.radians(72), 0, 0))
    o = link_only(bpy.context.object)
    o.name = name
    o.data.body = body
    o.data.align_x = 'CENTER'
    o.data.size = size
    o.data.extrude = 0.005
    o.data.materials.append(MATS[material])
    return o


def parent(obj, root):
    obj.parent = root


def make_root():
    root = bpy.data.objects.new(ROOT_NAME, None)
    COL.objects.link(root)
    root.empty_display_type = 'CUBE'
    root.empty_display_size = 0.2
    root.hide_render = True
    return root


ROOT = make_root()


# -----------------------------
# FLOOR / STAGING
# -----------------------------
live_step("01/10 — preparando superficie de la estación")

cube("Station_Platform", (0, -0.10, 0), (3.8, 0.10, 2.7), "soil_b", bevel=0.10)

# Timber frame
for x in (-3.35, 3.35):
    for z in (-2.25, 2.25):
        cube("Platform_Leg", (x, -1.0, z), (0.18, 0.9, 0.18), "wood", bevel=0.05)

# -----------------------------
# FIELD TABLE
# -----------------------------
live_step("02/10 — construyendo mesa de campo")

table = cube("SAVIA_Field_Table_Top", (0.9, 1.25, -0.15), (1.95, 0.10, 1.10), "wood", bevel=0.09)
parent(table, ROOT)

for x in (0.9 - 1.65, 0.9 + 1.65):
    for z in (-0.15 - 0.78, -0.15 + 0.78):
        leg = cube("Table_Leg", (x, 0.35, z), (0.11, 0.90, 0.11), "metal_dark", bevel=0.03)
        parent(leg, ROOT)

# lower brace
brace = cube("Table_Brace", (0.9, 0.05, -0.15), (1.55, 0.07, 0.07), "metal", bevel=0.02)
parent(brace, ROOT)

# -----------------------------
# MICROSCOPE
# -----------------------------
live_step("03/10 — ensamblando microscopio")

mic = bpy.data.objects.new("SAVIA_Microscope", None)
COL.objects.link(mic)
mic.empty_display_size = 0.15
parent(mic, ROOT)

base = cube("Microscope_Base", (0.10, 1.51, -0.05), (0.62, 0.08, 0.48), "metal_dark", bevel=0.08)
parent(base, mic)
column = cube("Microscope_Column", (-0.28, 1.92, -0.05), (0.08, 0.48, 0.08), "metal", bevel=0.03)
parent(column, mic)

arm = curve_tube("Microscope_Arm", [(-0.28, 2.25, -0.05), (-0.10, 2.55, -0.05),
                                    (0.18, 2.68, -0.05), (0.40, 2.52, -0.05)], 0.075, "metal")
parent(arm, mic)

tube = cyl("Microscope_Tube", (0.40, 2.58, -0.05), 0.12, 0.48, "metal_dark",
           rotation=(0, math.radians(-12), 0))
parent(tube, mic)

ocular = cyl("Microscope_Ocular", (0.44, 2.86, -0.05), 0.10, 0.22, "metal",
             rotation=(0, math.radians(-12), 0))
parent(ocular, mic)

stage = cube("Microscope_Stage", (0.10, 1.72, -0.05), (0.42, 0.055, 0.34), "metal", bevel=0.035)
parent(stage, mic)

for i, x in enumerate((0.02, 0.18, 0.34)):
    obj = cyl(f"Objective_{i+1}", (x, 1.92, -0.05), 0.055, 0.18, "metal_dark",
              rotation=(0, math.radians(90), 0))
    parent(obj, mic)

lamp = cyl("Microscope_Lamp", (0.10, 1.52, -0.05), 0.10, 0.08, "bio")
parent(lamp, mic)

# -----------------------------
# SOIL CORE
# -----------------------------
live_step("04/10 — creando Soil Core con horizontes O/A/B/C")

core_root = bpy.data.objects.new("SAVIA_Soil_Core", None)
COL.objects.link(core_root)
parent(core_root, ROOT)

# Transparent sleeve
sleeve = cyl("Soil_Core_Glass", (-1.85, 1.42, -0.05), 0.34, 1.65, "glass", vertices=48)
parent(sleeve, core_root)

layers = [
    ("O", "soil_o", 0.20, 2.08),
    ("A", "soil_a", 0.43, 1.76),
    ("B", "soil_b", 0.50, 1.30),
    ("C", "soil_c", 0.42, 0.82),
]

for label, material, height, y in layers:
    layer = cyl(f"Soil_Horizon_{label}", (-1.85, y, -0.05), 0.305, height, material, vertices=40)
    parent(layer, core_root)
    text_obj(f"Horizon_Label_{label}", label, (-2.25, y, -0.38), 0.12, "paper")

# tiny stones / organic fragments
for i, (x, y, z, r, m) in enumerate([
    (-1.98, 2.18, 0.00, 0.055, "wood_light"),
    (-1.72, 2.12, 0.02, 0.035, "leaf"),
    (-1.92, 1.65, -0.10, 0.045, "wood_light"),
    (-1.66, 1.40, 0.06, 0.05, "soil_c"),
]):
    s = sphere(f"Core_Fragment_{i}", (x, y, z), r, m, segments=12, rings=6)
    parent(s, core_root)

# -----------------------------
# SAMPLE TRAY + PETRI + JARS
# -----------------------------
live_step("05/10 — colocando bandeja y muestras")

tray = cube("SAVIA_Sample_Tray", (2.70, 1.43, 0.10), (0.72, 0.07, 0.52), "metal_dark", bevel=0.08)
parent(tray, ROOT)

for i, x in enumerate((2.35, 2.72, 3.09)):
    dish = cyl(f"Petri_Dish_{i+1}", (x, 1.57, 0.10), 0.14, 0.035, "glass", vertices=32)
    parent(dish, ROOT)
    sample = sphere(f"Petri_Sample_{i+1}", (x, 1.60, 0.10), 0.075,
                    ["soil_a", "root", "fungus"][i], segments=16, rings=8)
    parent(sample, ROOT)

# specimen jars
for i, x in enumerate((2.30, 2.70, 3.10)):
    jar = cyl(f"Specimen_Jar_{i+1}", (x, 0.80, 0.10), 0.12, 0.40, "glass", vertices=32)
    parent(jar, ROOT)
    cap = cyl(f"Jar_Cap_{i+1}", (x, 1.02, 0.10), 0.125, 0.055, "metal", vertices=32)
    parent(cap, ROOT)

# -----------------------------
# SOIL SENSOR
# -----------------------------
live_step("06/10 — construyendo sensor de suelo")

sensor_root = bpy.data.objects.new("SAVIA_Soil_Sensor", None)
COL.objects.link(sensor_root)
parent(sensor_root, ROOT)

handle = cyl("Sensor_Handle", (1.95, 0.92, 0.72), 0.085, 0.75, "metal_dark",
             rotation=(math.radians(8), 0, 0))
parent(handle, sensor_root)
tip = cyl("Sensor_Tip", (1.86, 0.53, 0.72), 0.035, 0.40, "metal",
          rotation=(math.radians(8), 0, 0))
parent(tip, sensor_root)
display = cube("Sensor_Display", (1.95, 1.28, 0.72), (0.18, 0.045, 0.11), "metal", bevel=0.025)
parent(display, sensor_root)
screen = cube("Sensor_Display_Glow", (1.95, 1.285, 0.72), (0.12, 0.012, 0.06), "bio", bevel=0.01)
parent(screen, sensor_root)

# -----------------------------
# SCIENTIFIC LAMP
# -----------------------------
live_step("07/10 — instalando lámpara científica")

lamp_arm = curve_tube("Lab_Lamp_Arm", [(3.25, 1.45, -0.75), (3.40, 2.20, -0.75),
                                       (3.10, 2.60, -0.75)], 0.055, "metal")
parent(lamp_arm, ROOT)
shade = cyl("Lab_Lamp_Shade", (3.10, 2.54, -0.75), 0.24, 0.20, "metal_dark")
parent(shade, ROOT)
bulb = sphere("Lab_Lamp_Bulb", (3.10, 2.43, -0.75), 0.09, "amber", segments=20, rings=10)
parent(bulb, ROOT)

# -----------------------------
# ROOT SAMPLE + MYCORRHIZA DISPLAY
# -----------------------------
live_step("08/10 — creando muestra de raíz y red micorrícica")

root_display = bpy.data.objects.new("SAVIA_Root_Mycorrhiza_Display", None)
COL.objects.link(root_display)
parent(root_display, ROOT)

glass = cyl("Root_Display_Glass", (-0.15, 1.20, -1.45), 0.55, 1.20, "glass", vertices=48)
parent(glass, root_display)

# Root architecture
root_paths = [
    [(-0.15, 1.55, -1.45), (-0.15, 1.30, -1.45), (-0.22, 1.05, -1.48),
     (-0.38, 0.82, -1.50)],
    [(-0.15, 1.28, -1.45), (0.04, 1.02, -1.42), (0.15, 0.82, -1.40)],
    [(-0.25, 1.04, -1.48), (-0.48, 0.92, -1.30), (-0.55, 0.74, -1.18)],
]
for i, pts in enumerate(root_paths):
    r = curve_tube(f"Root_Branch_{i}", pts, 0.035 if i == 0 else 0.022, "root")
    parent(r, root_display)

# Mycorrhizal network
myco_paths = [
    [(-0.15, 1.15, -1.45), (-0.55, 1.02, -1.48), (-0.78, 0.88, -1.38)],
    [(-0.10, 1.05, -1.45), (0.32, 0.90, -1.48), (0.58, 0.78, -1.35)],
    [(-0.30, 0.95, -1.48), (-0.42, 0.70, -1.50), (-0.22, 0.55, -1.42)],
    [(0.12, 0.98, -1.44), (0.30, 0.70, -1.36), (0.48, 0.52, -1.30)],
]
for i, pts in enumerate(myco_paths):
    m = curve_tube(f"Mycorrhiza_{i}", pts, 0.009, "bio")
    parent(m, root_display)

for i, p in enumerate([
    (-0.55, 1.02, -1.48), (0.32, 0.90, -1.48), (-0.42, 0.70, -1.50),
    (0.30, 0.70, -1.36), (0.48, 0.52, -1.30)
]):
    dot = sphere(f"Bio_Activity_{i}", p, 0.026, "bio", segments=12, rings=6)
    parent(dot, root_display)

# -----------------------------
# SAVIA CORE
# -----------------------------
live_step("09/10 — ensamblando SAVIA Core")

core = bpy.data.objects.new("SAVIA_Core", None)
COL.objects.link(core)
parent(core, ROOT)

base = cube("Core_Base", (0.55, 1.10, 1.45), (0.62, 0.12, 0.62), "metal_dark", bevel=0.10)
parent(base, core)

stone = sphere("Core_Organic_Stone", (0.55, 1.42, 1.45), 0.40, "soil_c", segments=32, rings=16)
stone.scale = (1.0, 0.78, 1.0)
parent(stone, core)

# organic fiber wraps
for i, angle in enumerate((0.0, 1.15, 2.30, 3.45, 4.60, 5.75)):
    a = angle
    pts = []
    for j in range(6):
        t = j / 5.0
        y = 1.16 + 0.48 * t
        r = 0.37 + 0.025 * math.sin(j * 1.7 + i)
        pts.append((0.55 + r * math.cos(a + t * 0.5),
                    y,
                    1.45 + r * math.sin(a + t * 0.5)))
    fiber = curve_tube(f"Core_Fiber_{i}", pts, 0.012, "bio")
    parent(fiber, core)

# scientific ring
ring = torus("Core_Activity_Ring", (0.55, 1.43, 1.45), 0.47, 0.012, "amber")
ring.rotation_euler.x = math.radians(90)
parent(ring, core)

# small status nodes
for i, x in enumerate((0.20, 0.55, 0.90)):
    node = sphere(f"Core_Status_{i}", (x, 0.98, 1.45), 0.035, "bio", segments=12, rings=6)
    parent(node, core)

# -----------------------------
# NOTEBOOK + LABELS
# -----------------------------
notebook = cube("Research_Notebook", (2.00, 1.49, -1.00), (0.48, 0.035, 0.34), "paper", bevel=0.025)
parent(notebook, ROOT)

text_obj("Notebook_Title", "SAVIA / FIELD NOTES", (2.00, 1.54, -1.00), 0.10, "metal_dark")

# -----------------------------
# STAGING LIGHTS + CAMERA
# -----------------------------
live_step("10/10 — preparando vista de revisión")

# Ground markers / subtle path
for i in range(7):
    x = -2.8 + i * 0.85
    stone = sphere(f"Path_Stone_{i}", (x, 0.04, -2.0 - 0.05 * (i % 2)), 0.11 + 0.02 * (i % 3), "soil_c",
                   segments=12, rings=6)
    parent(stone, ROOT)

# Camera
cam_data = bpy.data.cameras.new("SAVIA_Station_Camera")
cam = bpy.data.objects.new("SAVIA_Station_Camera", cam_data)
COL.objects.link(cam)
cam.location = (7.2, 5.7, 9.0)
cam.data.lens = 48
bpy.context.scene.camera = cam


def point_camera(camera, target):
    direction = Vector(target) - camera.location
    camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()


point_camera(cam, (0.5, 1.25, -0.2))

# Lights
ld = bpy.data.lights.new("SAVIA_Key", type='AREA')
ld.energy = 900
ld.shape = 'DISK'
ld.size = 5.0
key = bpy.data.objects.new("SAVIA_Key", ld)
COL.objects.link(key)
key.location = (1.5, 6.0, 3.5)
point_camera(key, (0.5, 1.0, 0.0))

ld2 = bpy.data.lights.new("SAVIA_Bio_Fill", type='AREA')
ld2.energy = 220
ld2.color = (0.20, 0.70, 0.48)
ld2.size = 3.0
fill = bpy.data.objects.new("SAVIA_Bio_Fill", ld2)
COL.objects.link(fill)
fill.location = (-3.0, 2.5, -1.0)
point_camera(fill, (0, 1.0, -1.0))

# World
world = bpy.context.scene.world
if world is None:
    world = bpy.data.worlds.new("SAVIA_World")
    bpy.context.scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
bg.inputs["Color"].default_value = (0.008, 0.014, 0.012, 1.0)
bg.inputs["Strength"].default_value = 0.22

# Render
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE_NEXT'
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
scene.render.resolution_percentage = 100

# Select the station root and frame it.
bpy.ops.object.select_all(action='DESELECT')
ROOT.select_set(True)
bpy.context.view_layer.objects.active = ROOT

# Save
project_dir = os.path.dirname(bpy.data.filepath) if bpy.data.filepath else os.getcwd()
out_dir = os.path.join(project_dir, "assets", "blender")
os.makedirs(out_dir, exist_ok=True)

blend_path = os.path.join(out_dir, ROOT_NAME + ".blend")
glb_path = os.path.join(out_dir, ROOT_NAME + ".glb")

if SAVE_BLEND:
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)

if EXPORT_GLB:
    bpy.ops.object.select_all(action='DESELECT')
    for obj in COL.objects:
        if obj.type in {'MESH', 'CURVE', 'FONT', 'EMPTY'}:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = ROOT
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        use_selection=True,
        export_apply=True,
        export_lights=True,
        export_cameras=True,
    )

print("")
print("==============================================")
print(" SAVIA FIELD RESEARCH STATION v0.1 COMPLETE")
print("==============================================")
print("BLEND:", blend_path)
print("GLB  :", glb_path)
print("Collection:", COLLECTION_NAME)
print("==============================================")
