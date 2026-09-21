extends Node3D

var camera: Camera3D
var world_root: Node3D
var menu_layer: CanvasLayer
var menu_root: Control
var info_panel: PanelContainer
var info_title: Label
var info_body: Label
var hint_label: Label
var time := 0.0
var menu_open := true
var fireflies: Array[Node3D] = []
var grass_blades: Array[Node3D] = []
var wildlife: Array[Node3D] = []
var birds: Array[Node3D] = []
var light_particles: Array[Node3D] = []
var leaf_particles: Array[Node3D] = []
var root_nodes: Array[Node3D] = []
var nature_asset_cache: Dictionary = {}
var nature_asset_files: Array[String] = []

const BG := Color("#07110d")
const GLASS := Color(0.025, 0.065, 0.045, 0.72)
const GLASS_LIGHT := Color(0.055, 0.12, 0.08, 0.82)
const TEXT := Color("#e6f0e1")
const MUTED := Color("#9bb29f")
const ACCENT := Color("#b7d98d")
const ACCENT_2 := Color("#7db59a")
const LINE := Color("#496b52")

func _ready() -> void:
    _build_world()
    _build_interface()

func _process(delta: float) -> void:
    time += delta
    _animate_world()
    if menu_root and menu_open:
        var breathe := 0.5 + sin(time * 0.65) * 0.5
        hint_label.modulate.a = 0.72 + breathe * 0.22

func _build_world() -> void:
    world_root = Node3D.new()
    world_root.name = "LivingBiome"
    add_child(world_root)

    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#163b2b")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#d8f0c2")
    environment.ambient_light_energy = 1.35
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    environment.glow_intensity = 0.72
    environment.glow_bloom = 0.16
    environment.fog_enabled = true
    environment.fog_light_color = Color("#6fa878")
    environment.fog_density = 0.0010
    environment.fog_sky_affect = 0.45
    env.environment = environment
    world_root.add_child(env)

    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-42, -32, 0)
    moon.light_energy = 2.15
    moon.light_color = Color("#fff6d8")
    moon.shadow_enabled = true
    world_root.add_child(moon)

    camera = Camera3D.new()
    camera.position = Vector3(5.4, 2.8, 10.8)
    camera.fov = 43.0
    camera.current = true
    world_root.add_child(camera)
    camera.look_at(Vector3(0.0, 1.9, -6.8), Vector3.UP)

    _index_nature_assets()
    _create_ground()
    _create_distant_forest()
    _create_foreground_forest()
    _create_real_tree_grove()
    _create_central_tree()
    _create_fireflies()
    _create_mushroom_cluster()
    _create_fern_beds()
    _create_flower_beds()
    _create_mushroom_assets()
    _create_insect_swarm()
    _create_savia_hero()
    _create_fruit_cluster()
    _create_root_showcase()
    _create_leaf_particles()
    _create_bio_particles()

func _index_nature_assets() -> void:
    nature_asset_files.clear()
    var root := "res://assets/vendor/quaternius/stylized_nature_megakit"
    _scan_asset_directory(root)

func _scan_asset_directory(path: String) -> void:
    var dir := DirAccess.open(path)
    if not dir:
        return
    for file_name in dir.get_files():
        var lower := file_name.to_lower()
        if lower.ends_with(".gltf") or lower.ends_with(".glb"):
            nature_asset_files.append(path.path_join(file_name))
    for dir_name in dir.get_directories():
        _scan_asset_directory(path.path_join(dir_name))

func _load_gltf_asset(candidates: Array[String]) -> Node3D:
    # Runtime GLTF loading bypasses assumptions about Godot's imported
    # PackedScene representation. This is used only for the external asset
    # pack and keeps the game independent from editor import state.
    for path in nature_asset_files:
        var filename := path.get_file().to_lower()
        for candidate in candidates:
            if filename == candidate.get_file().to_lower():
                var document := GLTFDocument.new()
                var state := GLTFState.new()
                var err := document.append_from_file(path, state)
                if err != OK:
                    print("SAVIA GLTF ERROR: ", err, " -> ", path)
                    continue
                var scene := document.generate_scene(state)
                if scene:
                    print("SAVIA GLTF OK: ", path)
                    return scene
                print("SAVIA GLTF GENERATE FAILED: ", path)
    return null

func _get_nature_asset(candidates: Array[String]) -> PackedScene:
    var key := "|".join(candidates)
    if nature_asset_cache.has(key):
        return nature_asset_cache[key]

    # Search the complete imported asset tree. We do not assume that the
    # package has one fixed folder layout.
    for path in nature_asset_files:
        var filename := path.get_file().to_lower()
        for candidate in candidates:
            var wanted := candidate.get_file().to_lower()
            if filename == wanted:
                var exact := ResourceLoader.load(path, "PackedScene")
                if exact is PackedScene:
                    nature_asset_cache[key] = exact
                    return exact
                print("SAVIA asset load failed: ", path, " type=", typeof(exact))

    # Semantic fallback for variants such as CommonTree_1 / CommonTree_2.
    var tokens: Array[String] = []
    for candidate in candidates:
        var stem := candidate.get_file().get_basename().to_lower()
        if stem.begins_with("commontree"):
            tokens.append("commontree")
        elif stem.begins_with("deadtree"):
            tokens.append("deadtree")
        elif stem.begins_with("plant"):
            tokens.append("plant")
        elif stem.begins_with("grass"):
            tokens.append("grass")
        elif stem.begins_with("bush"):
            tokens.append("bush")
        elif stem.begins_with("fern"):
            tokens.append("fern")
        elif stem.begins_with("flower"):
            tokens.append("flower")
        elif stem.begins_with("mushroom"):
            tokens.append("mushroom")
        elif stem.begins_with("rock") or stem.begins_with("pebble"):
            tokens.append("rock")
            tokens.append("pebble")

    for path in nature_asset_files:
        var filename := path.get_file().to_lower()
        for token in tokens:
            if token in filename:
                var found := ResourceLoader.load(path, "PackedScene")
                if found is PackedScene:
                    nature_asset_cache[key] = found
                    return found
                print("SAVIA semantic asset load failed: ", path, " type=", typeof(found))

    print("SAVIA asset not found for candidates: ", candidates)
    nature_asset_cache[key] = null
    return null

func _add_nature_asset(candidates: Array[String], pos: Vector3, scale_factor: float) -> Node3D:
    var scene := _get_nature_asset(candidates)
    var node: Node3D = null
    if scene:
        node = scene.instantiate()
    else:
        node = _load_gltf_asset(candidates)

    if not node:
        return null
    node.position = pos
    node.scale = Vector3.ONE * scale_factor
    world_root.add_child(node)
    return node


func _create_ground() -> void:
    # The ground is built around a shallow natural cutaway. The soil view is
    # part of the same terrain, not a floating laboratory panel.
    var strips := [
        [Vector3(-10.5, -0.42, -11.0), Vector2(21.0, 28.0)],
        [Vector3(16.5, -0.42, -11.0), Vector2(23.0, 28.0)],
        [Vector3(3.0, -0.42, 2.0), Vector2(9.0, 10.0)],
        [Vector3(3.0, -0.42, -21.0), Vector2(9.0, 18.0)]
    ]
    for data in strips:
        var ground := MeshInstance3D.new()
        var mesh := PlaneMesh.new()
        mesh.size = data[1]
        ground.mesh = mesh
        ground.position = data[0]
        ground.material_override = _mat(Color("#4f914d"), 0.98)
        world_root.add_child(ground)

    # Soft patches make the terrain read as a living forest floor.
    var patch_data := [
        [Vector3(-5.5, -0.39, -4.2), 1.8],
        [Vector3(6.5, -0.39, -4.0), 1.5],
        [Vector3(-8.0, -0.39, -9.0), 2.1],
        [Vector3(9.0, -0.39, -10.5), 2.0]
    ]
    for data in patch_data:
        var patch := MeshInstance3D.new()
        var patch_mesh := CylinderMesh.new()
        patch_mesh.top_radius = data[1]
        patch_mesh.bottom_radius = data[1] * 1.12
        patch_mesh.height = 0.035
        patch.mesh = patch_mesh
        patch.position = data[0]
        patch.material_override = _mat(Color("#3f7d42"), 0.98)
        world_root.add_child(patch)

func _add_profile_root(parent: Node3D, a: Vector3, b: Vector3) -> void:
    var root := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.035
    mesh.bottom_radius = 0.065
    mesh.height = a.distance_to(b)
    mesh.radial_segments = 7
    root.mesh = mesh
    root.position = (a + b) * 0.5
    root.look_at(b, Vector3.UP)
    root.rotate_object_local(Vector3.RIGHT, PI * 0.5)
    root.material_override = _glow_mat(Color("#c7a86a"), Color("#e1c477"), 0.7, 0.95)
    parent.add_child(root)
    root_nodes.append(root)


func _create_distant_forest() -> void:
    # Background vegetation frames the ecosystem without competing with the
    # protagonist plant and its visible underground system.
    var positions := [
        Vector3(-12.0, 0, -13.0), Vector3(-8.0, 0, -16.0),
        Vector3(8.0, 0, -14.0), Vector3(12.0, 0, -17.0),
        Vector3(-15.0, 0, -20.0), Vector3(15.0, 0, -21.0)
    ]
    for i in range(positions.size()):
        _create_tree(positions[i], 0.78 + float(i % 2) * 0.12, true)


func _create_foreground_forest() -> void:
    var positions := [
        Vector3(-9.5, 0, -5.5), Vector3(-6.8, 0, -8.5),
        Vector3(7.0, 0, -7.0), Vector3(9.5, 0, -10.0),
        Vector3(-10.5, 0, -13.5), Vector3(10.8, 0, -15.0)
    ]
    for i in range(positions.size()):
        _create_tree(positions[i], 0.86 + float(i % 3) * 0.12, false)

func _create_tree(pos: Vector3, scale_factor: float, distant: bool) -> void:
    # Prefer real Quaternius vegetation. Procedural geometry remains only as a
    # safe fallback when the external pack has not been installed yet.
    var candidates := [
        "CommonTree_4.gltf",
        "CommonTree_3.gltf",
        "NormalTree_1.gltf",
        "NormalTree_2.gltf",
        "CommonTree_5.gltf",
        "CommonTree_1.gltf",
        "CommonTree_2.gltf",
        "Pine_2.gltf"
    ]
    var real_tree := _add_nature_asset(candidates, pos, scale_factor * (0.95 if not distant else 0.78))
    if real_tree:
        return

    var tree := Node3D.new()
    tree.position = pos
    tree.scale = Vector3.ONE * scale_factor
    world_root.add_child(tree)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.16
    trunk_mesh.bottom_radius = 0.29
    trunk_mesh.height = 3.0
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.5
    trunk.material_override = _mat(Color("#493a2d"), 0.96)
    tree.add_child(trunk)

    for j in range(3):
        var crown := MeshInstance3D.new()
        var crown_mesh := SphereMesh.new()
        crown_mesh.radius = 1.25 - j * 0.16
        crown_mesh.height = 2.3
        crown.mesh = crown_mesh
        crown.position = Vector3((j - 1) * 0.42, 2.65 + j * 0.48, 0)
        crown.scale = Vector3(1.25, 0.72, 1.0)
        crown.material_override = _mat(Color("#31563b") if not distant else Color("#274633"), 0.92)
        tree.add_child(crown)


func _create_real_tree_grove() -> void:
    # Background framing. The center stays open for SAVIA's living tree.
    var positions := [
        Vector3(-10.0, 0.0, -12.0), Vector3(-7.0, 0.0, -15.5),
        Vector3(7.5, 0.0, -13.5), Vector3(11.0, 0.0, -17.0),
        Vector3(-13.0, 0.0, -19.0), Vector3(14.0, 0.0, -21.0)
    ]
    for i in range(positions.size()):
        var tree := _add_nature_asset(
            ["CommonTree_%d.gltf" % (i + 1), "DeadTree_%d.gltf" % (i + 1), "Tree_%d.gltf" % (i + 1)],
            positions[i], 0.70 + float(i % 3) * 0.10
        )
        if tree:
            tree.rotation.y = float(i) * 0.9

func _create_central_tree() -> void:
    # One large real tree becomes the visual anchor.
    var trunk := _add_nature_asset(
        ["CommonTree_3.gltf", "CommonTree_4.gltf", "CommonTree_5.gltf", "DeadTree_3.gltf"],
        Vector3(0.0, -0.05, -7.2), 2.55
    )
    if trunk:
        trunk.rotation.y = 0.12
    for i in range(7):
        var mound := MeshInstance3D.new()
        var mm := CylinderMesh.new()
        mm.top_radius = 0.9 + float(i % 3) * 0.25
        mm.bottom_radius = mm.top_radius * 1.12
        mm.height = 0.16
        mound.mesh = mm
        mound.position = Vector3(-2.4 + i * 0.8, -0.31, -6.6 - float(i % 2) * 0.5)
        mound.material_override = _mat(Color("#315d35"), 0.98)
        world_root.add_child(mound)

func _create_fireflies() -> void:
    for i in range(42):
        var dot := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.025 + float(i % 3) * 0.012
        mesh.height = mesh.radius * 2.0
        dot.mesh = mesh
        dot.position = Vector3(-13.0 + float((i * 17) % 28), 0.4 + float((i * 11) % 30) * 0.12, -3.5 - float((i * 19) % 28) * 0.48)
        dot.material_override = _glow_mat(Color("#b8e99a"), Color("#caff9b"), 1.8, 0.82)
        world_root.add_child(dot)
        fireflies.append(dot)
        if i % 7 == 0:
            var glow := OmniLight3D.new()
            glow.position = dot.position
            glow.light_color = Color("#b8f28c")
            glow.light_energy = 0.35
            glow.omni_range = 2.2
            world_root.add_child(glow)

func _create_mushroom_cluster() -> void:
    for i in range(9):
        var mush := Node3D.new()
        mush.position = Vector3(-11 + float(i % 4) * 0.55, 0, -4.5 - float(i / 4) * 0.55)
        mush.scale = Vector3.ONE * (0.55 + float(i % 3) * 0.14)
        world_root.add_child(mush)

        var stem := MeshInstance3D.new()
        var stem_mesh := CylinderMesh.new()
        stem_mesh.top_radius = 0.06
        stem_mesh.bottom_radius = 0.1
        stem_mesh.height = 0.35
        stem.mesh = stem_mesh
        stem.position.y = 0.18
        stem.material_override = _mat(Color("#c8c1a8"), 0.9)
        mush.add_child(stem)

        var cap := MeshInstance3D.new()
        var cap_mesh := SphereMesh.new()
        cap_mesh.radius = 0.25
        cap_mesh.height = 0.2
        cap.mesh = cap_mesh
        cap.position.y = 0.38
        cap.scale = Vector3(1.0, 0.45, 1.0)
        cap.material_override = _mat(Color("#9d6b55"), 0.78)
        mush.add_child(cap)

func _create_fern_beds() -> void:
    for i in range(12):
        var real_plant := _add_nature_asset(["Fern_1.gltf", "Grass_Common_Short.gltf", "Bush_Common.gltf", "Plant_7.gltf"], Vector3(-16 + float((i * 9) % 27), 0, -2.0 - float((i * 11) % 22)), 0.32 + float(i % 3) * 0.08)
        if real_plant:
            continue
        var fern := Node3D.new()
        fern.position = Vector3(-16 + float((i * 9) % 27), 0, -2.0 - float((i * 11) % 22))
        world_root.add_child(fern)
        for j in range(5):
            var leaf := MeshInstance3D.new()
            var mesh := BoxMesh.new()
            mesh.size = Vector3(0.035, 0.75 + float(j % 2) * 0.18, 0.07)
            leaf.mesh = mesh
            leaf.position = Vector3((j - 2) * 0.12, 0.35, 0)
            leaf.rotation_degrees = Vector3(0, 0, -35 + j * 17)
            leaf.material_override = _mat(Color("#50785a"), 0.9)
            fern.add_child(leaf)
            grass_blades.append(leaf)


func _create_flower_beds() -> void:
    # Flowers cluster around the protagonist, giving the insects a reason to
    # be here instead of looking like unrelated decorations.
    var spots := [
        Vector3(-0.9, -0.05, -5.0),
        Vector3(-1.45, -0.05, -5.7),
        Vector3(2.0, -0.05, -5.15),
        Vector3(2.25, -0.05, -5.9)
    ]
    for i in range(spots.size()):
        var flower := _add_nature_asset(
            ["Flower_%d_Single.gltf" % (3 + i % 2), "Flower_3_Single.gltf", "Flower_4_Single.gltf"],
            spots[i],
            0.11
        )
        if flower:
            flower.rotation.y = float(i) * 1.7


func _create_mushroom_assets() -> void:
    # Fungi stay at the moist edge of the root zone.
    var spots := [
        Vector3(-2.5, -0.05, -6.2),
        Vector3(-2.1, -0.05, -6.6),
        Vector3(2.8, -0.05, -6.4)
    ]
    for i in range(spots.size()):
        var mushroom := _add_nature_asset(
            ["Mushroom_Common.gltf", "Mushroom_1.gltf", "Mushroom_2.gltf"],
            spots[i],
            0.20 + float(i % 2) * 0.04
        )
        if mushroom:
            mushroom.rotation.y = float(i) * 1.7


func _create_insect_swarm() -> void:
    # Pollinators follow the flower cluster around the hero plant.
    var positions := [
        Vector3(-0.85, 1.15, -5.0), Vector3(-0.20, 1.45, -5.55),
        Vector3(1.75, 1.30, -5.10), Vector3(2.05, 0.92, -5.75)
    ]
    for i in range(positions.size()):
        var insect := Node3D.new()
        insect.position = positions[i]
        insect.scale = Vector3.ONE * 1.65
        world_root.add_child(insect)
        wildlife.append(insect)

        var body := MeshInstance3D.new()
        var body_mesh := CapsuleMesh.new()
        body_mesh.radius = 0.045
        body_mesh.height = 0.28
        body.mesh = body_mesh
        body.rotation_degrees.z = 90
        body.material_override = _mat(Color("#2f251c"), 0.62)
        insect.add_child(body)

        for side in [-1.0, 1.0]:
            var wing := MeshInstance3D.new()
            var wing_mesh := QuadMesh.new()
            wing_mesh.size = Vector2(0.20, 0.13)
            wing.mesh = wing_mesh
            wing.position = Vector3(0, 0.02, side * 0.10)
            wing.rotation_degrees.y = 24.0 * side
            wing.material_override = _glow_mat(
                Color("#b9e7d0") if i % 2 == 0 else Color("#f0c86a"),
                Color("#d1ffe5") if i % 2 == 0 else Color("#ffe19a"),
                1.0, 0.84
            )
            insect.add_child(wing)

        var eye := MeshInstance3D.new()
        var eye_mesh := SphereMesh.new()
        eye_mesh.radius = 0.024
        eye_mesh.height = 0.048
        eye.mesh = eye_mesh
        eye.position = Vector3(0.16, 0.0, 0)
        eye.material_override = _glow_mat(Color("#e8ff9c"), Color("#f5ffbd"), 1.5, 0.9)
        insect.add_child(eye)


func _create_savia_hero() -> void:
    # One protagonist plant anchors the whole composition.
    var hero := _add_nature_asset(
        ["Fern_1.gltf", "Plant_7.gltf", "Plant_6.gltf", "Bush_Common.gltf"],
        Vector3(0.45, -0.05, -5.25),
        0.78
    )
    if not hero:
        var stem := MeshInstance3D.new()
        var stem_mesh := CylinderMesh.new()
        stem_mesh.top_radius = 0.065
        stem_mesh.bottom_radius = 0.11
        stem_mesh.height = 2.15
        stem.mesh = stem_mesh
        stem.position = Vector3(0.45, 1.02, -5.25)
        stem.material_override = _mat(Color("#5c984b"), 0.72)
        world_root.add_child(stem)
        for i in range(8):
            var leaf := MeshInstance3D.new()
            var leaf_mesh := QuadMesh.new()
            leaf_mesh.size = Vector2(0.62, 0.30)
            leaf.mesh = leaf_mesh
            leaf.position = Vector3(
                0.45 + sin(i * 0.9) * 0.42,
                0.65 + i * 0.22,
                -5.25 + cos(i * 0.8) * 0.22
            )
            leaf.rotation_degrees = Vector3(-10 + i * 3, -24 + i * 28, -20 + i * 7)
            leaf.material_override = _glow_mat(Color("#74b85e"), Color("#7bd66d"), 0.9, 0.82)
            world_root.add_child(leaf)

    var plant_light := OmniLight3D.new()
    plant_light.position = Vector3(0.45, 1.0, -5.25)
    plant_light.light_color = Color("#bfff8d")
    plant_light.light_energy = 0.75
    plant_light.omni_range = 3.5
    world_root.add_child(plant_light)


func _create_fruit_cluster() -> void:
    # Fruits hang from the same hero plant; they are deliberately small so
    # they read as part of the plant rather than floating spheres.
    var spots := [
        Vector3(0.00, 1.25, -5.35),
        Vector3(0.78, 1.48, -5.22),
        Vector3(-0.15, 1.70, -5.10)
    ]
    for i in range(spots.size()):
        var fruit := Node3D.new()
        fruit.position = spots[i]
        fruit.scale = Vector3.ONE * 0.12
        world_root.add_child(fruit)

        var body := MeshInstance3D.new()
        var body_mesh := SphereMesh.new()
        body_mesh.radius = 0.9
        body_mesh.height = 1.15
        body.mesh = body_mesh
        body.material_override = _mat(Color("#d46a43") if i != 1 else Color("#e2a044"), 0.70)
        fruit.add_child(body)

        var stem := MeshInstance3D.new()
        var stem_mesh := CylinderMesh.new()
        stem_mesh.top_radius = 0.02
        stem_mesh.bottom_radius = 0.03
        stem_mesh.height = 0.30
        stem.mesh = stem_mesh
        stem.position.y = 0.55
        stem.rotation_degrees.z = -12
        stem.material_override = _mat(Color("#4d813f"), 0.82)
        fruit.add_child(stem)

func _create_bio_particles() -> void:
    for i in range(58):
        var particle := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.010 + float(i % 4) * 0.005
        mesh.height = mesh.radius * 2.0
        particle.mesh = mesh
        particle.position = Vector3(-4.5 + float((i * 17) % 90) * 0.10, 0.15 + float((i * 11) % 28) * 0.12, -5.0 - float((i * 7) % 22) * 0.32)
        particle.material_override = _glow_mat(Color("#b9ef9a"), Color("#d2ffb2"), 1.6, 0.72)
        world_root.add_child(particle)
        light_particles.append(particle)

func _create_light_beam() -> void:
    # Soft light particles; the atmosphere-to-root path will later become a
    # true volumetric effect once the asset composition is stable.
    for i in range(32):
        var particle := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 0.012 + float(i % 4) * 0.007
        sphere.height = sphere.radius * 2.0
        particle.mesh = sphere
        particle.position = Vector3(-4.0 + float((i * 17) % 52) * 0.16, 0.4 + float((i * 11) % 28) * 0.16, -3.5 - float((i * 7) % 24) * 0.38)
        particle.material_override = _glow_mat(Color("#b8ef78"), Color("#d9ff9c"), 2.0, 0.78)
        world_root.add_child(particle)
        light_particles.append(particle)

func _add_glowing_segment(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
    var segment := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius * 1.35
    mesh.height = a.distance_to(b)
    mesh.radial_segments = 8
    segment.mesh = mesh
    segment.position = (a + b) * 0.5
    segment.look_at(b, Vector3.UP)
    segment.rotate_object_local(Vector3.RIGHT, PI * 0.5)
    segment.material_override = _glow_mat(color, color, 2.6, 0.9)
    world_root.add_child(segment)
    root_nodes.append(segment)


func _create_root_showcase() -> void:
    # No panel: the luminous network is physically attached to the central tree.
    var paths := [
        [Vector3(-0.15, 2.15, -6.55), Vector3(-0.85, 1.35, -6.35), Vector3(-1.90, 0.65, -6.10)],
        [Vector3(0.10, 2.35, -6.55), Vector3(0.65, 1.55, -6.45), Vector3(1.80, 0.75, -6.20)],
        [Vector3(-0.30, 1.65, -6.48), Vector3(-1.45, 0.75, -6.80), Vector3(-3.10, 0.25, -7.00)],
        [Vector3(0.35, 1.55, -6.48), Vector3(1.55, 0.80, -6.75), Vector3(3.10, 0.25, -7.15)],
        [Vector3(-0.65, 0.95, -6.35), Vector3(-1.05, 0.10, -6.00), Vector3(-1.55, -0.20, -5.65)],
        [Vector3(0.55, 0.90, -6.35), Vector3(0.95, 0.05, -6.05), Vector3(1.65, -0.20, -5.75)]
    ]
    for path in paths:
        _add_glowing_segment(path[0], path[1], 0.07, Color("#a7e69a"))
        _add_glowing_segment(path[1], path[2], 0.045, Color("#8edb9d"))
    for i in range(30):
        var a := Vector3(-2.7 + float((i * 13) % 54) * 0.10, 0.05 + float((i * 7) % 15) * 0.11, -7.05 + sin(i * 1.7) * 0.18)
        var b := a + Vector3(sin(i * 2.1) * 0.45, 0.16 + float(i % 3) * 0.12, cos(i * 1.3) * 0.28)
        _add_glowing_segment(a, b, 0.018, Color("#c4f5ad"))
    for i in range(12):
        var node := MeshInstance3D.new()
        var nm := SphereMesh.new()
        nm.radius = 0.035 + float(i % 2) * 0.018
        nm.height = nm.radius * 2.0
        node.mesh = nm
        node.position = Vector3(-2.1 + float((i * 7) % 30) * 0.14, 0.12 + float((i * 5) % 11) * 0.12, -6.95 + sin(i * 1.9) * 0.22)
        node.material_override = _glow_mat(Color("#d9ffb7"), Color("#e7ffc9"), 2.2, 0.92)
        world_root.add_child(node)
    var root_light := OmniLight3D.new()
    root_light.position = Vector3(0, 1.35, -7.0)
    root_light.light_color = Color("#b7f19b")
    root_light.light_energy = 2.0
    root_light.omni_range = 5.5
    world_root.add_child(root_light)

func _create_leaf_particles() -> void:
    for i in range(14):
        var leaf := MeshInstance3D.new()
        var mesh := QuadMesh.new()
        mesh.size = Vector2(0.16 + float(i % 3) * 0.04, 0.10 + float(i % 2) * 0.03)
        leaf.mesh = mesh
        leaf.position = Vector3(-8.0 + float((i * 17) % 25) * 0.55, 1.0 + float((i * 11) % 16) * 0.18, -4.0 - float((i * 7) % 20) * 0.5)
        leaf.rotation_degrees = Vector3(0, float(i * 37), float(i * 23))
        leaf.material_override = _glow_mat(Color("#739f58"), Color("#8acb6a"), 0.35, 0.78)
        world_root.add_child(leaf)
        leaf_particles.append(leaf)

func _glow_mat(color: Color, emission: Color, emission_energy: float, alpha: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(color.r, color.g, color.b, alpha)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    material.emission_enabled = true
    material.emission = emission
    material.emission_energy_multiplier = emission_energy
    material.roughness = 0.35
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func _animate_world() -> void:
    if camera:
        var target := Vector3(sin(time * 0.045) * 0.25, 1.75 + sin(time * 0.17) * 0.05, -6.9)
        camera.position.x = 5.4 + sin(time * 0.035) * 0.45
        camera.position.y = 2.8 + sin(time * 0.12) * 0.05
        camera.look_at(target, Vector3.UP)

    for i in range(fireflies.size()):
        var f := fireflies[i]
        var base := f.position
        f.position = base + Vector3(sin(time * (0.5 + i * 0.01) + i) * 0.012, sin(time * 1.3 + i) * 0.018, cos(time * 0.6 + i) * 0.012)
        var glow := 0.35 + 0.35 * sin(time * 1.8 + i)
        f.scale = Vector3.ONE * (0.8 + glow)

    for i in range(wildlife.size()):
        var animal := wildlife[i]
        animal.position.y += sin(time * (0.8 + i * 0.03) + i) * 0.0007
        if i % 4 == 0:
            animal.rotation.y = sin(time * 0.12 + i) * 0.05

    for i in range(birds.size()):
        var bird := birds[i]
        bird.position.x += 0.004 + i * 0.0004
        bird.position.y += sin(time * 0.8 + i) * 0.002
        if bird.position.x > 16.0:
            bird.position.x = -16.0

    for i in range(grass_blades.size()):
        grass_blades[i].rotation_degrees.z += sin(time * 0.6 + i) * 0.002

    for i in range(light_particles.size()):
        var p := light_particles[i]
        p.position.y += sin(time * 0.45 + i * 0.7) * 0.0015
        if i >= 7:
            var pulse := 0.82 + 0.25 * sin(time * 2.0 + i)
            p.scale = Vector3.ONE * pulse

    for i in range(leaf_particles.size()):
        var leaf := leaf_particles[i]
        leaf.position.x += sin(time * 0.25 + i) * 0.0025
        leaf.position.y += cos(time * 0.55 + i) * 0.002
        leaf.rotation_degrees.y += 0.08

    for i in range(root_nodes.size()):
        var root := root_nodes[i]
        var pulse := 0.92 + 0.12 * sin(time * 1.5 + i)
        root.scale = Vector3.ONE * pulse

func _build_interface() -> void:
    menu_layer = CanvasLayer.new()
    add_child(menu_layer)

    var vignette := ColorRect.new()
    vignette.color = Color(0.0, 0.015, 0.008, 0.20)
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(vignette)

    menu_root = Control.new()
    menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(menu_root)

    # Title is centered on the tree, as in the reference composition.
    var brand := VBoxContainer.new()
    brand.position = Vector2(455, 38)
    brand.custom_minimum_size = Vector2(360, 125)
    brand.alignment = BoxContainer.ALIGNMENT_CENTER
    brand.add_theme_constant_override("separation", 0)
    menu_root.add_child(brand)

    var title := Label.new()
    title.text = "SAVIA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 64)
    title.add_theme_color_override("font_color", Color("#edf4df"))
    brand.add_child(title)

    var line := Label.new()
    line.text = "LA VIDA BAJO LA PIEL DEL BOSQUE"
    line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    line.add_theme_font_size_override("font_size", 12)
    line.add_theme_color_override("font_color", ACCENT)
    brand.add_child(line)

    # Menu stays on the right and remains transparent.
    var nav := VBoxContainer.new()
    nav.position = Vector2(875, 235)
    nav.custom_minimum_size = Vector2(330, 320)
    nav.add_theme_constant_override("separation", 5)
    menu_root.add_child(nav)
    _add_main_action(nav, "INICIAR SIMBIOSIS", "comenzar una nueva investigación", _enter_world, true)
    _add_main_action(nav, "CONTINUAR VIAJE", "volver a un ecosistema activo", _my_biomes, false)
    _add_main_action(nav, "CATÁLOGO VIVO", "consultar lo que has descubierto", _atlas, false)
    _add_main_action(nav, "EXPEDICIONES", "explorar otros biomas", _expeditions, false)
    _add_main_action(nav, "AJUSTES ORGÁNICOS", "configurar percepción y accesibilidad", _show_settings, false)

    var nora := PanelContainer.new()
    nora.position = Vector2(52, 640)
    nora.size = Vector2(390, 65)
    nora.add_theme_stylebox_override("panel", _box(Color(0.01, 0.035, 0.022, 0.28), 10, Color(0.55, 0.78, 0.48, 0.22), 1))
    menu_root.add_child(nora)
    var nb := VBoxContainer.new()
    nb.add_theme_constant_override("separation", 2)
    nora.add_child(nb)
    var nn := Label.new()
    nn.text = "NORA  ·  PRESENCIA DE CAMPO"
    nn.add_theme_font_size_override("font_size", 10)
    nn.add_theme_color_override("font_color", ACCENT)
    nb.add_child(nn)
    var nm := Label.new()
    nm.text = "La red responde bajo la corteza."
    nm.add_theme_font_size_override("font_size", 12)
    nm.add_theme_color_override("font_color", TEXT)
    nb.add_child(nm)

    hint_label = Label.new()
    hint_label.text = "●  SIMBIOSIS ACTIVA"
    hint_label.position = Vector2(54, 698)
    hint_label.add_theme_font_size_override("font_size", 10)
    hint_label.add_theme_color_override("font_color", ACCENT_2)
    menu_root.add_child(hint_label)

    info_panel = PanelContainer.new()
    info_panel.position = Vector2(770, 535)
    info_panel.size = Vector2(420, 118)
    info_panel.visible = false
    info_panel.add_theme_stylebox_override("panel", _box(GLASS_LIGHT, 16, LINE, 1))
    menu_root.add_child(info_panel)
    var info_box := VBoxContainer.new()
    info_box.add_theme_constant_override("separation", 5)
    info_panel.add_child(info_box)
    info_title = Label.new()
    info_title.add_theme_font_size_override("font_size", 19)
    info_title.add_theme_color_override("font_color", TEXT)
    info_box.add_child(info_title)
    info_body = Label.new()
    info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info_body.add_theme_font_size_override("font_size", 12)
    info_body.add_theme_color_override("font_color", MUTED)
    info_box.add_child(info_body)
    var close := Button.new()
    close.text = "CERRAR"
    close.custom_minimum_size = Vector2(100, 30)
    close.add_theme_font_size_override("font_size", 11)
    close.pressed.connect(_close_info)
    info_box.add_child(close)

func _add_main_action(parent: VBoxContainer, title_text: String, hint: String, action: Callable, primary: bool) -> void:
    var row := HBoxContainer.new()
    row.custom_minimum_size = Vector2(330, 48)
    parent.add_child(row)
    var button := Button.new()
    button.text = title_text
    button.custom_minimum_size = Vector2(300 if primary else 275, 44)
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.add_theme_font_size_override("font_size", 17 if primary else 14)
    button.add_theme_color_override("font_color", TEXT if primary else Color("#d0ddc9"))
    button.add_theme_color_override("font_hover_color", Color("#f2f8dc"))
    button.add_theme_stylebox_override("normal", _box(Color(0.01, 0.025, 0.015, 0.0), 8, Color(0,0,0,0), 0))
    button.add_theme_stylebox_override("hover", _box(Color(0.18, 0.30, 0.16, 0.25), 8, Color("#b7d98d"), 1))
    button.add_theme_stylebox_override("pressed", _box(Color(0.16, 0.27, 0.14, 0.35), 8, Color("#d4efad"), 1))
    button.tooltip_text = hint
    button.pressed.connect(action)
    row.add_child(button)
    var arrow := Label.new()
    arrow.text = "›"
    arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    arrow.add_theme_font_size_override("font_size", 20)
    arrow.add_theme_color_override("font_color", ACCENT_2)
    row.add_child(arrow)

func _show_settings() -> void:
    _show_info("AJUSTES ORGÁNICOS", "Percepción, escala visual e intensidad de señales biológicas.")

func _enter_world() -> void:
    menu_open = false
    menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(menu_root, "modulate:a", 0.0, 0.65)
    tween.tween_property(camera, "fov", 58.0, 0.8)
    tween.set_parallel(false)
    tween.tween_callback(_show_field_prompt)

func _show_field_prompt() -> void:
    menu_open = false
    var prompt := PanelContainer.new()
    prompt.position = Vector2(54, 560)
    prompt.size = Vector2(390, 96)
    prompt.add_theme_stylebox_override("panel", _box(GLASS, 14, LINE, 1))
    menu_layer.add_child(prompt)

    var box := VBoxContainer.new()
    prompt.add_child(box)

    var title := Label.new()
    title.text = "LA INVESTIGACIÓN COMIENZA AQUÍ"
    title.add_theme_font_size_override("font_size", 14)
    title.add_theme_color_override("font_color", ACCENT)
    box.add_child(title)

    var body := Label.new()
    body.text = "No intervengas todavía. Escucha el suelo."
    body.add_theme_font_size_override("font_size", 16)
    body.add_theme_color_override("font_color", TEXT)
    box.add_child(body)

    var back := Button.new()
    back.text = "VOLVER AL CAMPAMENTO"
    back.custom_minimum_size = Vector2(1, 34)
    back.pressed.connect(func():
        prompt.queue_free()
        menu_root.modulate.a = 1.0
        menu_root.mouse_filter = Control.MOUSE_FILTER_STOP
        menu_open = true
        camera.fov = 45.0
    )
    box.add_child(back)

func _my_biomes() -> void:
    _show_info("MIS MUNDOS", "Cada bioma conserva clima, suelo, organismos, observaciones y memoria ambiental. No hay porcentaje de finalización.")

func _atlas() -> void:
    _show_info("ATLAS VIVO", "Aquí se reúnen especies, fenómenos, anomalías, hipótesis y conceptos que hayas documentado. Las preguntas abiertas permanecen abiertas.")

func _expeditions() -> void:
    _show_info("EXPEDICIONES", "Cuando tu simbiosis pueda adaptarse a otros perfiles de suelo, podrás viajar a humedales, tundras, desiertos, costas, montañas y bosques tropicales.")

func _show_info(title_text: String, body_text: String) -> void:
    info_title.text = title_text
    info_body.text = body_text
    info_panel.visible = true

func _close_info() -> void:
    info_panel.visible = false

func _box(color: Color, radius: int, border_color: Color, border_width: int) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    box.corner_radius_top_left = radius
    box.corner_radius_top_right = radius
    box.corner_radius_bottom_left = radius
    box.corner_radius_bottom_right = radius
    box.border_width_left = border_width
    box.border_width_right = border_width
    box.border_width_top = border_width
    box.border_width_bottom = border_width
    box.border_color = border_color
    box.content_margin_left = 16
    box.content_margin_right = 16
    box.content_margin_top = 12
    box.content_margin_bottom = 12
    return box

func _mat(color: Color, roughness := 0.8) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    return material
