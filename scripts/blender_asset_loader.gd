# Script para cargar y gestionar assets generados desde Blender
extends Node3D
class_name BlenderAssetLoader

# Cache de modelos cargados
var loaded_assets: Dictionary = {}
var project_root: String = ""

func _ready() -> void:
	# Obtener la raíz del proyecto
	project_root = ProjectSettings.globalize_path("res://")
	print("📁 Raíz del proyecto: ", project_root)

# Cargar un asset .glb usando GLTFDocument
func load_gltf_asset(key: String, filename: String) -> Node3D:
	var filepath = project_root + "assets/blender_exports/" + filename
	
	# Verificar que el archivo existe en el filesystem
	if not FileAccess.file_exists(filepath):
		print("⚠ Archivo no encontrado: ", filepath)
		return null
	
	print("📦 Cargando: ", filename)
	
	# Cargar usando GLTFDocument (funciona con .glb en tiempo de ejecución)
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var err := document.append_from_file(filepath, state)
	
	if err != OK:
		print("✗ Error al cargar: ", filepath, " Código: ", err)
		return null
	
	var scene := document.generate_scene(state)
	if scene:
		loaded_assets[key] = scene
		print("✓ Cargado: ", key)
		return scene
	else:
		print("✗ Error generando escena para: ", key)
		return null

# Cargar todos los assets
func load_all_assets() -> void:
	print("\n" + "=".repeat(60))
	print("🌱 Cargando assets de Blender...")
	print("=".repeat(60))
	
	load_gltf_asset("roots", "roots.glb")
	load_gltf_asset("microorganisms", "microorganisms.glb")
	load_gltf_asset("insects", "insects.glb")
	
	print("✓ Assets listos: ", loaded_assets.keys())
	print("=".repeat(60) + "\n")

# Obtener y clonar un asset
func get_asset_copy(key: String) -> Node3D:
	if key in loaded_assets:
		var asset = loaded_assets[key]
		if asset:
			return asset.instantiate()
	print("✗ Asset no existe o no es válido: ", key)
	return null

# Agregar raíces a la escena
func add_roots_to_scene(parent: Node3D) -> Node3D:
	print("➕ Agregando raíces...")
	var roots = get_asset_copy("roots")
	if roots:
		roots.position.y = -2.0
		roots.scale = Vector3.ONE * 0.8
		parent.add_child(roots)
		print("✓ Raíces agregadas")
		return roots
	else:
		print("✗ No se pudieron agregar las raíces")
	return null

# Agregar microorganismos a la escena
func add_microorganisms_to_scene(parent: Node3D) -> Node3D:
	print("➕ Agregando microorganismos...")
	var microorganisms = get_asset_copy("microorganisms")
	if microorganisms:
		microorganisms.position.y = -1.5
		microorganisms.scale = Vector3.ONE * 0.5
		parent.add_child(microorganisms)
		print("✓ Microorganismos agregados")
		return microorganisms
	else:
		print("✗ No se pudieron agregar los microorganismos")
	return null

# Agregar insectos a la escena
func add_insects_to_scene(parent: Node3D) -> Node3D:
	print("➕ Agregando insectos...")
	var insects = get_asset_copy("insects")
	if insects:
		insects.position.y = 0.5
		insects.scale = Vector3.ONE * 0.6
		parent.add_child(insects)
		print("✓ Insectos agregados")
		return insects
	else:
		print("✗ No se pudieron agregar los insectos")
	return null
