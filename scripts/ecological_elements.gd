extends Node3D
class_name EcologicalElements

# =====================================================================
# GENERADOR DE ELEMENTOS ECOLÓGICOS NATIVO DE GODOT
# =====================================================================
# Este script crea elementos 3D procedurales sin dependencias de Blender

# =====================================================================
# 1. ÁRBOLES
# =====================================================================
func create_stylized_tree(position: Vector3, scale_factor: float = 1.0) -> Node3D:
	"""Crea un árbol estilizado con tronco y copa"""
	var tree = Node3D.new()
	tree.position = position
	tree.name = "StylizedTree"
	
	# Material del tronco
	var trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color("#5c4033")
	
	# Tronco principal
	var trunk = MeshInstance3D.new()
	trunk.mesh = CylinderMesh.new()
	trunk.mesh.top_radius = 0.3 * scale_factor
	trunk.mesh.bottom_radius = 0.4 * scale_factor
	trunk.mesh.height = 4.0 * scale_factor
	trunk.set_surface_override_material(0, trunk_material)
	trunk.position.y = 2.0 * scale_factor
	tree.add_child(trunk)
	
	# Copa del árbol (esfera)
	var canopy_material = StandardMaterial3D.new()
	canopy_material.albedo_color = Color("#2d5016")
	
	var canopy = MeshInstance3D.new()
	canopy.mesh = SphereMesh.new()
	canopy.mesh.radius = 2.5 * scale_factor
	canopy.mesh.height = 5.0 * scale_factor
	canopy.set_surface_override_material(0, canopy_material)
	canopy.position.y = 4.0 * scale_factor
	tree.add_child(canopy)
	
	# Raíces visibles
	_add_visible_roots(tree, position, scale_factor)
	
	return tree

func _add_visible_roots(parent: Node3D, base_pos: Vector3, scale_factor: float) -> void:
	"""Agrega raíces visibles al árbol"""
	var root_material = StandardMaterial3D.new()
	root_material.albedo_color = Color("#3d2817")
	
	for i in range(6):
		var angle = (i / 6.0) * TAU
		var offset_x = cos(angle) * 1.2 * scale_factor
		var offset_z = sin(angle) * 1.2 * scale_factor
		
		var root = MeshInstance3D.new()
		root.mesh = BoxMesh.new()
		root.mesh.size = Vector3(0.3 * scale_factor, 0.2 * scale_factor, 1.2 * scale_factor)
		root.set_surface_override_material(0, root_material)
		root.position = Vector3(offset_x, -0.1 * scale_factor, offset_z)
		root.rotation_degrees = Vector3(0, angle * 57.3, 0)
		parent.add_child(root)

# =====================================================================
# 2. RAÍCES SUBTERRÁNEAS
# =====================================================================
func create_root_system(position: Vector3, scale_factor: float = 1.0) -> Node3D:
	"""Crea un sistema de raíces subterráneas"""
	var roots = Node3D.new()
	roots.position = position
	roots.name = "RootSystem"
	
	var root_material = StandardMaterial3D.new()
	root_material.albedo_color = Color("#6b4423")
	
	# Raíz principal
	var main_root = MeshInstance3D.new()
	main_root.mesh = CylinderMesh.new()
	main_root.mesh.radius = 0.4 * scale_factor
	main_root.mesh.height = 3.0 * scale_factor
	main_root.set_surface_override_material(0, root_material)
	main_root.position.y = -1.5 * scale_factor
	roots.add_child(main_root)
	
	# Raíces secundarias
	for i in range(5):
		var angle = (i / 5.0) * TAU
		var x = cos(angle) * 1.5 * scale_factor
		var z = sin(angle) * 1.5 * scale_factor
		
		var secondary = MeshInstance3D.new()
		secondary.mesh = CylinderMesh.new()
		secondary.mesh.radius = 0.15 * scale_factor
		secondary.mesh.height = 2.0 * scale_factor
		secondary.set_surface_override_material(0, root_material)
		secondary.position = Vector3(x, -2.0 * scale_factor, z)
		secondary.rotation = Vector3(angle * 0.3, 0, 0)
		roots.add_child(secondary)
	
	return roots

# =====================================================================
# 3. MICROORGANISMOS
# =====================================================================
func create_microorganism_cluster(position: Vector3, count: int = 10) -> Node3D:
	"""Crea un cluster de microorganismos"""
	var cluster = Node3D.new()
	cluster.position = position
	cluster.name = "MicroorganismCluster"
	
	var micro_material = StandardMaterial3D.new()
	micro_material.albedo_color = Color("#2ecc71")
	micro_material.emission_enabled = true
	micro_material.emission = Color("#2ecc71") * 0.3
	
	for i in range(count):
		var x = randf_range(-1.0, 1.0)
		var y = randf_range(-0.5, 0.5)
		var z = randf_range(-1.0, 1.0)
		var radius = randf_range(0.05, 0.15)
		
		var micro = MeshInstance3D.new()
		micro.mesh = SphereMesh.new()
		micro.mesh.radius = radius
		micro.set_surface_override_material(0, micro_material)
		micro.position = Vector3(x, y, z)
		cluster.add_child(micro)
	
	return cluster

# =====================================================================
# 4. INSECTOS
# =====================================================================
func create_insect(position: Vector3, scale_factor: float = 1.0) -> Node3D:
	"""Crea un insecto estilizado"""
	var insect = Node3D.new()
	insect.position = position
	insect.name = "Insect"
	
	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color("#d4af37")
	
	# Cuerpo
	var body = MeshInstance3D.new()
	body.mesh = CapsuleMesh.new()
	body.mesh.radius = 0.2 * scale_factor
	body.mesh.height = 0.6 * scale_factor
	body.set_surface_override_material(0, body_material)
	insect.add_child(body)
	
	# Cabeza
	var head = MeshInstance3D.new()
	head.mesh = SphereMesh.new()
	head.mesh.radius = 0.15 * scale_factor
	head.set_surface_override_material(0, body_material)
	head.position.y = 0.4 * scale_factor
	insect.add_child(head)
	
	# Alas (2 rectángulos)
	var wing_material = StandardMaterial3D.new()
	wing_material.albedo_color = Color("#87ceeb")
	wing_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wing_material.alpha_scissor = BaseMaterial3D.ALPHA_SCISSOR_OPAQUE
	
	for side in [-1, 1]:
		var wing = MeshInstance3D.new()
		wing.mesh = BoxMesh.new()
		wing.mesh.size = Vector3(0.3 * scale_factor, 0.1 * scale_factor, 0.5 * scale_factor)
		wing.set_surface_override_material(0, wing_material)
		wing.position.x = 0.25 * side * scale_factor
		wing.position.y = 0.1 * scale_factor
		insect.add_child(wing)
	
	return insect

# =====================================================================
# 5. SUELO Y VEGETACIÓN
# =====================================================================
func create_soil_patch(position: Vector3, size: Vector3) -> Node3D:
	"""Crea un parche de suelo"""
	var soil = MeshInstance3D.new()
	soil.position = position
	soil.name = "SoilPatch"
	soil.mesh = BoxMesh.new()
	soil.mesh.size = size
	
	var soil_material = StandardMaterial3D.new()
	soil_material.albedo_color = Color("#4a3728")
	soil.set_surface_override_material(0, soil_material)
	
	return soil

func create_grass_patch(position: Vector3, width: float = 2.0, length: float = 2.0) -> Node3D:
	"""Crea un parche de hierba"""
	var grass = Node3D.new()
	grass.position = position
	grass.name = "GrassPatch"
	
	var blade_material = StandardMaterial3D.new()
	blade_material.albedo_color = Color("#27ae60")
	
	for x in range(int(width / 0.3)):
		for z in range(int(length / 0.3)):
			for blade_index in range(3):
				var blade = MeshInstance3D.new()
				blade.mesh = BoxMesh.new()
				blade.mesh.size = Vector3(0.05, 0.3, 0.1)
				blade.set_surface_override_material(0, blade_material)
				blade.position.x = x * 0.3 + randf_range(-0.1, 0.1)
				blade.position.z = z * 0.3 + randf_range(-0.1, 0.1)
				blade.rotation_degrees.z = randf_range(-15, 15)
				grass.add_child(blade)
	
	return grass

# =====================================================================
# 6. COMPOSICIÓN COMPLETA
# =====================================================================
func create_complete_ecosystem(position: Vector3) -> Node3D:
	"""Crea un ecosistema completo con todos los elementos"""
	var ecosystem = Node3D.new()
	ecosystem.position = position
	ecosystem.name = "CompleteEcosystem"
	
	# Árbol principal
	var tree = create_stylized_tree(Vector3(0, 0, 0), 1.0)
	ecosystem.add_child(tree)
	
	# Sistema de raíces
	var roots = create_root_system(Vector3(0, -0.5, 0), 0.8)
	ecosystem.add_child(roots)
	
	# Microorganismos
	var microbes = create_microorganism_cluster(Vector3(0.5, -1.0, 0.5), 8)
	ecosystem.add_child(microbes)
	
	# Insectos alrededor
	for i in range(3):
		var angle = (i / 3.0) * TAU
		var x = cos(angle) * 2.5
		var z = sin(angle) * 2.5
		var insect = create_insect(Vector3(x, 1.5, z), 0.6)
		ecosystem.add_child(insect)
	
	# Suelo
	var soil = create_soil_patch(Vector3(0, -2.0, 0), Vector3(6, 0.5, 6))
	ecosystem.add_child(soil)
	
	# Hierba
	var grass = create_grass_patch(Vector3(0, -1.75, 0), 6.0, 6.0)
	ecosystem.add_child(grass)
	
	return ecosystem
