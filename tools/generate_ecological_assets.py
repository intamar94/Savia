#!/usr/bin/env python3
"""
Script para generar assets ecológicos desde Blender automáticamente
Ejecutar: blender --background --python generate_ecological_assets.py
"""

import bpy
import os
import math
import random
from mathutils import Vector

# Configuración
EXPORT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "blender_exports")
os.makedirs(EXPORT_DIR, exist_ok=True)

# Limpiar escena
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# ============================================================================
# UTILIDADES
# ============================================================================
def create_simple_material(name, color):
    """Crea un material simple"""
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color  # (R, G, B, Alpha)
    return mat

# ============================================================================
# 1. CREAR RAÍCES
# ============================================================================
def create_roots():
    """Crea un sistema de raíces procedural"""
    
    mat_root = create_simple_material("RootMaterial", (0.3, 0.2, 0.1, 1.0))
    
    # Raíz principal
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.3,
        depth=4,
        vertices=8,
        location=(0, 0, -2)
    )
    root_main = bpy.context.active_object
    root_main.name = "RootMain"
    root_main.data.materials.append(mat_root)
    
    # Raíces secundarias
    for i in range(5):
        angle = (i / 5) * math.pi * 2
        x = math.cos(angle) * 1.5
        y = math.sin(angle) * 1.5
        z = -1 - (i * 0.3)
        
        bpy.ops.mesh.primitive_cylinder_add(
            radius=0.15,
            depth=2,
            vertices=6,
            location=(x, y, z)
        )
        root_sec = bpy.context.active_object
        root_sec.name = f"RootSecondary_{i}"
        root_sec.rotation_euler = (angle, 0.3, 0)
        root_sec.data.materials.append(mat_root)
    
    print("  ✓ Raíces creadas")

# ============================================================================
# 2. CREAR MICROORGANISMOS
# ============================================================================
def create_microorganisms():
    """Crea microorganismos como esferas"""
    
    mat_micro = create_simple_material("MicroMaterial", (0.2, 0.8, 0.2, 1.0))
    
    random.seed(42)
    for i in range(15):
        x = random.uniform(-2, 2)
        y = random.uniform(-2, 2)
        z = random.uniform(-4, -1)
        
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=random.uniform(0.05, 0.15),
            location=(x, y, z)
        )
        micro = bpy.context.active_object
        micro.name = f"Bacterium_{i}"
        micro.data.materials.append(mat_micro)
    
    print("  ✓ Microorganismos creados")

# ============================================================================
# 3. CREAR INSECTOS
# ============================================================================
def create_insects():
    """Crea insectos simples"""
    
    mat_insect = create_simple_material("InsectMaterial", (0.8, 0.4, 0.1, 1.0))
    
    random.seed(123)
    for i in range(3):
        x = random.uniform(-1.5, 1.5)
        y = random.uniform(-1.5, 1.5)
        z = random.uniform(0.5, 2)
        
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.3,
            location=(x, y, z)
        )
        body = bpy.context.active_object
        body.name = f"Insect_Body_{i}"
        body.scale = (0.8, 0.5, 1.2)
        body.data.materials.append(mat_insect)
        
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.15,
            location=(x, y, z + 0.5)
        )
        head = bpy.context.active_object
        head.name = f"Insect_Head_{i}"
        head.data.materials.append(mat_insect)
    
    print("  ✓ Insectos creados")

# ============================================================================
# EXPORTAR
# ============================================================================
def export_by_pattern(filename, pattern):
    """Exporta objetos con patrón en nombre"""
    
    bpy.ops.object.select_all(action='DESELECT')
    
    matching_objects = [obj for obj in bpy.context.scene.objects if pattern in obj.name]
    
    if not matching_objects:
        print(f"  ⚠ No objects for: {pattern}")
        return False
    
    for obj in matching_objects:
        obj.select_set(True)
    
    bpy.context.view_layer.objects.active = matching_objects[0]
    
    filepath = os.path.join(EXPORT_DIR, f"{filename}.glb")
    
    try:
        bpy.ops.export_scene.gltf(
            filepath=filepath,
            use_selection=True,
            export_format='GLB'
        )
        print(f"  ✓ {filename}.glb")
        return True
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False

# ============================================================================
# EJECUTAR
# ============================================================================
print("=" * 60)
print("Generando assets ecológicos...")
print("=" * 60)

create_roots()
create_microorganisms()
create_insects()

bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))

print("\nExportando a .glb...")
export_by_pattern("roots", "Root")
export_by_pattern("microorganisms", "Bacterium")
export_by_pattern("insects", "Insect")

print("\n" + "=" * 60)
print("✓ Assets listos en: " + EXPORT_DIR)
print("=" * 60)
