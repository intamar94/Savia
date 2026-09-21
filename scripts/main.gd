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
    environment.background_color = Color("#0b1b16")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#b8d5a0")
    environment.ambient_light_energy = 0.82
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    environment.glow_intensity = 1.0
    environment.glow_bloom = 0.22
    environment.fog_enabled = true
    environment.fog_light_color = Color("#47745d")
    environment.fog_density = 0.0022
    environment.fog_sky_affect = 0.45
    env.environment = environment
    world_root.add_child(env)

    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-42, -32, 0)
    moon.light_energy = 1.65
    moon.light_color = Color("#fff0c8")
    moon.shadow_enabled = true
    world_root.add_child(moon)

    camera = Camera3D.new()
    camera.position = Vector3(7.0, 4.3, 11.5)
    camera.fov = 48.0
    world_root.add_child(camera)
    camera.look_at(Vector3(0.4, 1.0, -7.2), Vector3.UP)

    _index_nature_assets()
    _create_ground()
    _create_soil_layers()
    _create_water()
    _create_distant_forest()
    _create_foreground_forest()
    _create_real_tree_grove()
    _create_research_station()
    _create_fireflies()
    _create_mushroom_cluster()
    _create_fern_beds()
    _create_flower_beds()
    _create_mushroom_assets()
    _create_insect_swarm()
    _create_savia_hero()
    _create_fruit_cluster()
    _create_root_network()
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
    # Keep the ground visually clean: the menu should communicate life,
    # not look like a field of repeated rocks.
    var ground := MeshInstance3D.new()
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(70, 70)
    ground.mesh = mesh
    ground.position = Vector3(0, -0.42, -10)
    ground.material_override = _mat(Color("#203d2a"), 0.96)
    world_root.add_child(ground)

    # Organic patches add variation without competing with roots and plants.
    for i in range(8):
        var patch := MeshInstance3D.new()
        var patch_mesh := CylinderMesh.new()
        patch_mesh.top_radius = 0.45 + float(i % 3) * 0.12
        patch_mesh.bottom_radius = patch_mesh.top_radius * 1.1
        patch_mesh.height = 0.025
        patch.mesh = patch_mesh
        patch.position = Vector3(-12.0 + float((i * 7) % 24), -0.40, -3.0 - float((i * 11) % 22))
        patch.material_override = _mat(Color("#315b38"), 0.98)
        world_root.add_child(patch)

func _create_soil_layers() -> void:
    # A stylized exposed soil profile keeps the scientific layers visible from
    # the menu: surface litter, O/A/B/C horizons and bedrock.
    var panel := Node3D.new()
    panel.name = "SoilProfile"
    # Raise the scientific cutaway so the horizons and roots are actually visible.
    panel.position = Vector3(3.0, 1.65, -7.4)
    world_root.add_child(panel)

    var layers := [
        ["O · HOJARASCA", 0.34, Color("#5b4430")],
        ["A · HUMUS", 0.48, Color("#6f4b31")],
        ["B · MINERAL", 0.56, Color("#805b3c")],
        ["C · MATERIAL", 0.62, Color("#9a7650")],
        ["R · ROCA", 0.52, Color("#5c6460")]
    ]
    var y := 0.0
    for i in range(layers.size()):
        var layer := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(5.4, layers[i][1], 0.32)
        layer.mesh = mesh
        layer.position = Vector3(0, y - layers[i][1] * 0.5, 0)
        layer.material_override = _mat(layers[i][2], 0.92)
        panel.add_child(layer)

        var stripe := MeshInstance3D.new()
        var stripe_mesh := BoxMesh.new()
        stripe_mesh.size = Vector3(0.055, layers[i][1] * 0.8, 0.025)
        stripe.mesh = stripe_mesh
        stripe.position = Vector3(-2.45, layer.position.y, -0.22)
        stripe.material_override = _glow_mat(ACCENT if i < 2 else ACCENT_2, ACCENT, 0.45, 0.72)
        panel.add_child(stripe)
        y -= layers[i][1]

    # Root system inside the exposed profile.
    var roots := [
        [Vector3(-1.2, -0.18, -0.24), Vector3(-0.5, -0.75, -0.24)],
        [Vector3(-0.5, -0.75, -0.24), Vector3(-1.8, -1.25, -0.24)],
        [Vector3(-0.5, -0.75, -0.24), Vector3(0.9, -1.15, -0.24)],
        [Vector3(0.9, -1.15, -0.24), Vector3(2.2, -1.65, -0.24)],
        [Vector3(0.9, -1.15, -0.24), Vector3(1.4, -2.05, -0.24)]
    ]
    for pair in roots:
        _add_profile_root(panel, pair[0], pair[1])

    # Mycorrhizal "spark" points and soil life.
    for i in range(30):
        var life := MeshInstance3D.new()
        var m := SphereMesh.new()
        m.radius = 0.018 + float(i % 3) * 0.009
        m.height = m.radius * 2.0
        life.mesh = m
        life.position = Vector3(-3.0 + float((i * 17) % 58) * 0.10, -0.28 - float((i * 13) % 23) * 0.085, -0.25)
        life.material_override = _glow_mat(Color("#75c9a0") if i % 2 == 0 else Color("#b49cff"), Color("#8ef0b5") if i % 2 == 0 else Color("#b9a2ff"), 2.0, 0.78)
        panel.add_child(life)
        root_nodes.append(life)

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

func _create_water() -> void:
    var river := MeshInstance3D.new()
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(4.2, 70)
    river.mesh = mesh
    river.position = Vector3(6.8, -0.12, -11)
    river.rotation_degrees.y = -5
    river.material_override = _mat(Color("#1d6970"), 0.18)
    world_root.add_child(river)

    for i in range(10):
        var reed := Node3D.new()
        reed.position = Vector3(1.0 + float(i % 5) * 0.75, 0, -5.0 - float(i * 3))
        world_root.add_child(reed)
        for j in range(3):
            var blade := MeshInstance3D.new()
            var blade_mesh := BoxMesh.new()
            blade_mesh.size = Vector3(0.035, 0.85 + j * 0.15, 0.07)
            blade.mesh = blade_mesh
            blade.position = Vector3((j - 1) * 0.08, 0.38, 0)
            blade.rotation_degrees.z = -12 + j * 10
            blade.material_override = _mat(Color("#537d5d"), 0.8)
            reed.add_child(blade)

func _create_distant_forest() -> void:
    for i in range(20):
        var x := -20.0 + float((i * 13) % 40)
        var z := -18.0 - float((i * 7) % 25)
        _create_tree(Vector3(x, 0, z), 0.65 + float(i % 5) * 0.08, true)

func _create_foreground_forest() -> void:
    for i in range(9):
        var x := -17.0 + float((i * 19) % 32)
        var z := -1.0 - float((i * 29) % 23)
        if abs(x - 4.5) < 4.0:
            x -= 6.0
        _create_tree(Vector3(x, 0, z), 0.82 + float(i % 4) * 0.12, false)

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
    # Force several real tree variants into the hero background. This is the
    # visual proof that the Quaternius pipeline is active.
    var positions := [
        Vector3(-10.5, 0.0, -10.5),
        Vector3(-7.5, 0.0, -13.0),
        Vector3(7.8, 0.0, -12.5),
        Vector3(11.0, 0.0, -15.0),
        Vector3(-13.0, 0.0, -17.0)
    ]
    for i in range(positions.size()):
        var tree := _add_nature_asset(
            ["CommonTree_%d.gltf" % (i + 1), "NormalTree_%d.gltf" % (i + 1), "Tree_%d.gltf" % (i + 1), "DeadTree_%d.gltf" % (i + 1)],
            positions[i],
            0.75 + float(i % 3) * 0.12
        )
        if tree:
            tree.rotation.y = float(i) * 0.8

func _create_research_station() -> void:
    var station := Node3D.new()
    station.position = Vector3(-4.2, 0, 0.4)
    world_root.add_child(station)

    var table := MeshInstance3D.new()
    var table_mesh := BoxMesh.new()
    table_mesh.size = Vector3(3.0, 0.22, 1.25)
    table.mesh = table_mesh
    table.position.y = 1.25
    table.material_override = _mat(Color("#594838"), 0.88)
    station.add_child(table)

    for x in [-1.2, 1.2]:
        for z in [-0.42, 0.42]:
            var leg := MeshInstance3D.new()
            var leg_mesh := CylinderMesh.new()
            leg_mesh.top_radius = 0.07
            leg_mesh.bottom_radius = 0.09
            leg_mesh.height = 1.25
            leg.mesh = leg_mesh
            leg.position = Vector3(x, 0.62, z)
            leg.material_override = _mat(Color("#46372d"), 0.95)
            station.add_child(leg)

    var lamp := OmniLight3D.new()
    lamp.position = Vector3(0, 2.0, 0)
    lamp.light_color = Color("#d6e8ad")
    lamp.light_energy = 1.2
    lamp.omni_range = 5.5
    station.add_child(lamp)

    var jar := MeshInstance3D.new()
    var jar_mesh := CylinderMesh.new()
    jar_mesh.top_radius = 0.18
    jar_mesh.bottom_radius = 0.18
    jar_mesh.height = 0.48
    jar.mesh = jar_mesh
    jar.position = Vector3(-0.7, 1.58, 0)
    jar.material_override = _mat(Color("#8eb9a1"), 0.18)
    station.add_child(jar)

    var microscope := Node3D.new()
    microscope.position = Vector3(0.45, 1.4, 0)
    station.add_child(microscope)
    var base := MeshInstance3D.new()
    var base_mesh := BoxMesh.new()
    base_mesh.size = Vector3(0.65, 0.1, 0.42)
    base.mesh = base_mesh
    base.material_override = _mat(Color("#26372f"), 0.45)
    microscope.add_child(base)
    var scope := MeshInstance3D.new()
    var scope_mesh := CylinderMesh.new()
    scope_mesh.top_radius = 0.08
    scope_mesh.bottom_radius = 0.11
    scope_mesh.height = 0.7
    scope.mesh = scope_mesh
    scope.rotation_degrees.z = -22
    scope.position = Vector3(0, 0.32, 0)
    scope.material_override = _mat(Color("#8a9b8e"), 0.35)
    microscope.add_child(scope)

func _create_fireflies() -> void:
    for i in range(26):
        var dot := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.035
        mesh.height = 0.07
        dot.mesh = mesh
        dot.position = Vector3(-16 + float((i * 17) % 32), 0.8 + float((i * 7) % 30) * 0.12, -3 - float((i * 19) % 28))
        dot.material_override = _mat(Color("#bfe79b"), 0.15)
        world_root.add_child(dot)
        fireflies.append(dot)

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
    var spots := [
        Vector3(-7.5, 0, -7.5), Vector3(-5.8, 0, -10.0),
        Vector3(5.5, 0, -9.0), Vector3(8.0, 0, -11.0),
        Vector3(-10.0, 0, -12.0), Vector3(10.5, 0, -17.0)
    ]
    for i in range(spots.size()):
        var flower := _add_nature_asset(["Flower_%d_Single.gltf" % (3 + i % 2), "Flower_3_Single.gltf", "Flower_4_Single.gltf"], spots[i], 0.28 + float(i % 2) * 0.08)
        if flower:
            flower.rotation.y = float(i) * 1.4

func _create_mushroom_assets() -> void:
    var spots := [
        Vector3(-9.0, 0, -5.0), Vector3(-8.4, 0, -5.5),
        Vector3(6.5, 0, -7.5), Vector3(7.1, 0, -7.9)
    ]
    for i in range(spots.size()):
        var mushroom := _add_nature_asset(["Mushroom_Common.gltf", "Mushroom_1.gltf", "Mushroom_2.gltf"], spots[i], 0.24 + float(i % 2) * 0.06)
        if mushroom:
            mushroom.rotation.y = float(i) * 1.7

func _create_insect_swarm() -> void:
    # Small, colored points/wing silhouettes add motion at plant scale.
    for i in range(18):
        var insect := Node3D.new()
        insect.position = Vector3(-10.0 + float((i * 19) % 21), 0.35 + float((i * 7) % 13) * 0.13, -5.0 - float((i * 11) % 20) * 0.5)
        world_root.add_child(insect)
        wildlife.append(insect)
        var body := MeshInstance3D.new()
        var body_mesh := SphereMesh.new()
        body_mesh.radius = 0.035 + float(i % 2) * 0.015
        body_mesh.height = body_mesh.radius * 2.0
        body.mesh = body_mesh
        body.material_override = _glow_mat(Color("#d5b45d") if i % 3 == 0 else Color("#6ec9a1"), Color("#f1d87b") if i % 3 == 0 else Color("#7ee5ba"), 1.2, 0.9)
        insect.add_child(body)

func _create_wildlife() -> void:
    # Small groups of real forest fauna give the scene a living food web.
    _create_deer(Vector3(8.0, 0, -13.0), 0.9)
    _create_deer(Vector3(10.0, 0, -15.5), 0.62)
    _create_rabbit(Vector3(-6.0, 0, -7.0), 0.7)
    _create_rabbit(Vector3(-7.2, 0, -8.0), 0.55)
    _create_beetle(Vector3(0.5, 0.04, -4.5), 0.45)
    _create_beetle(Vector3(1.1, 0.04, -4.9), 0.3)
    _create_butterfly(Vector3(-2.5, 1.4, -5.5), 0.7)
    _create_butterfly(Vector3(-1.4, 1.8, -8.5), 0.5)

func _create_deer(pos: Vector3, s: float) -> void:
    var deer := Node3D.new()
    deer.position = pos
    deer.scale = Vector3.ONE * s
    world_root.add_child(deer)
    wildlife.append(deer)

    var body := MeshInstance3D.new()
    var body_mesh := SphereMesh.new()
    body_mesh.radius = 0.62
    body_mesh.height = 1.1
    body.mesh = body_mesh
    body.position.y = 1.05
    body.scale = Vector3(1.55, 0.9, 0.72)
    body.material_override = _mat(Color("#72563e"), 0.95)
    deer.add_child(body)

    var neck := MeshInstance3D.new()
    var neck_mesh := CylinderMesh.new()
    neck_mesh.top_radius = 0.18
    neck_mesh.bottom_radius = 0.28
    neck_mesh.height = 0.85
    neck.mesh = neck_mesh
    neck.position = Vector3(0.38, 1.48, 0)
    neck.rotation_degrees.z = -18
    neck.material_override = _mat(Color("#795d43"), 0.95)
    deer.add_child(neck)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.3
    head_mesh.height = 0.52
    head.mesh = head_mesh
    head.position = Vector3(0.68, 1.86, 0)
    head.scale = Vector3(1.2, 0.9, 0.9)
    head.material_override = _mat(Color("#72543b"), 0.95)
    deer.add_child(head)

    for x in [-0.38, 0.34]:
        for z in [-0.27, 0.27]:
            var leg := MeshInstance3D.new()
            var leg_mesh := CylinderMesh.new()
            leg_mesh.top_radius = 0.055
            leg_mesh.bottom_radius = 0.075
            leg_mesh.height = 0.92
            leg.mesh = leg_mesh
            leg.position = Vector3(x, 0.47, z)
            leg.material_override = _mat(Color("#5d4533"), 0.95)
            deer.add_child(leg)

func _create_rabbit(pos: Vector3, s: float) -> void:
    var rabbit := Node3D.new()
    rabbit.position = pos
    rabbit.scale = Vector3.ONE * s
    world_root.add_child(rabbit)
    wildlife.append(rabbit)

    var body := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.34
    mesh.height = 0.55
    body.mesh = mesh
    body.position.y = 0.32
    body.scale = Vector3(1.35, 0.8, 0.9)
    body.material_override = _mat(Color("#9a917c"), 0.98)
    rabbit.add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.22
    head_mesh.height = 0.4
    head.mesh = head_mesh
    head.position = Vector3(0.3, 0.52, 0)
    head.material_override = _mat(Color("#a39a85"), 0.98)
    rabbit.add_child(head)

    for z in [-0.09, 0.09]:
        var ear := MeshInstance3D.new()
        var ear_mesh := CapsuleMesh.new()
        ear_mesh.radius = 0.055
        ear_mesh.height = 0.42
        ear.mesh = ear_mesh
        ear.position = Vector3(0.28, 0.82, z)
        ear.rotation_degrees.z = -8
        ear.material_override = _mat(Color("#8e866f"), 0.98)
        rabbit.add_child(ear)

func _create_beetle(pos: Vector3, s: float) -> void:
    var beetle := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.12
    mesh.height = 0.18
    beetle.mesh = mesh
    beetle.position = pos
    beetle.scale = Vector3(1.5, 0.55, 1.0) * s
    beetle.material_override = _mat(Color("#202922"), 0.8)
    world_root.add_child(beetle)
    wildlife.append(beetle)

func _create_butterfly(pos: Vector3, s: float) -> void:
    var butterfly := Node3D.new()
    butterfly.position = pos
    butterfly.scale = Vector3.ONE * s
    world_root.add_child(butterfly)
    wildlife.append(butterfly)

    var body := MeshInstance3D.new()
    var body_mesh := CylinderMesh.new()
    body_mesh.top_radius = 0.025
    body_mesh.bottom_radius = 0.035
    body_mesh.height = 0.22
    body.mesh = body_mesh
    body.rotation_degrees.z = 90
    body.material_override = _mat(Color("#40352c"), 0.9)
    butterfly.add_child(body)

    for side in [-1.0, 1.0]:
        var wing := MeshInstance3D.new()
        var wing_mesh := QuadMesh.new()
        wing_mesh.size = Vector2(0.28, 0.18)
        wing.mesh = wing_mesh
        wing.position = Vector3(0, 0.0, side * 0.12)
        wing.rotation_degrees.y = 18 * side
        wing.material_override = _mat(Color("#b48a61"), 0.75)
        butterfly.add_child(wing)

func _create_birds() -> void:
    for i in range(5):
        var bird := Node3D.new()
        bird.position = Vector3(-11 + i * 5.0, 5.5 + (i % 2) * 1.3, -16 - (i % 3) * 3)
        world_root.add_child(bird)
        birds.append(bird)

        for side in [-1.0, 1.0]:
            var wing := MeshInstance3D.new()
            var mesh := QuadMesh.new()
            mesh.size = Vector2(0.7, 0.16)
            wing.mesh = mesh
            wing.position = Vector3(0, 0, side * 0.28)
            wing.rotation_degrees = Vector3(0, 0, side * 12)
            wing.material_override = _mat(Color("#202c25"), 0.95)
            bird.add_child(wing)


func _create_savia_hero() -> void:
    # Hero plant: a real pack asset when available, with a subtle luminous
    # scientific treatment that visually connects leaf -> stem -> soil.
    # Compact botanical hero: avoid the oversized flower silhouette.
    var hero := _add_nature_asset(["Fern_1.gltf", "Plant_7.gltf", "Plant_6.gltf", "Bush_Common.gltf"], Vector3(0.8, -0.05, -5.2), 0.92)
    if not hero:
        var stem := MeshInstance3D.new()
        var stem_mesh := CylinderMesh.new()
        stem_mesh.top_radius = 0.07
        stem_mesh.bottom_radius = 0.12
        stem_mesh.height = 2.05
        stem.mesh = stem_mesh
        stem.position = Vector3(1.2, 1.1, -5.2)
        stem.material_override = _mat(Color("#6f9d58"), 0.72)
        world_root.add_child(stem)
        for i in range(7):
            var leaf := MeshInstance3D.new()
            var leaf_mesh := QuadMesh.new()
            leaf_mesh.size = Vector2(0.62, 0.32)
            leaf.mesh = leaf_mesh
            leaf.position = Vector3(1.2 + sin(i * 0.9) * 0.45, 0.72 + i * 0.23, -5.2 + cos(i * 0.8) * 0.22)
            leaf.rotation_degrees = Vector3(-12 + i * 3, -24 + i * 28, -22 + i * 7)
            leaf.material_override = _glow_mat(Color("#7fbe69"), Color("#72d66f"), 1.15, 0.76)
            world_root.add_child(leaf)

    # A small warm source at the plant makes the biological path readable.
    var plant_light := OmniLight3D.new()
    plant_light.position = Vector3(1.2, 1.15, -5.2)
    plant_light.light_color = Color("#c8ff9a")
    plant_light.light_energy = 1.4
    plant_light.omni_range = 4.0
    world_root.add_child(plant_light)

func _create_fruit_cluster() -> void:
    # A readable fruiting stage connects flower -> fruit -> seed.
    var spots := [
        Vector3(0.42, 1.05, -5.30),
        Vector3(1.12, 1.34, -5.22),
        Vector3(0.30, 1.52, -5.10)
    ]
    for i in range(spots.size()):
        var fruit := Node3D.new()
        fruit.position = spots[i]
        fruit.scale = Vector3.ONE * (0.14 + float(i % 2) * 0.025)
        world_root.add_child(fruit)

        var body := MeshInstance3D.new()
        var body_mesh := SphereMesh.new()
        body_mesh.radius = 0.9
        body_mesh.height = 1.25
        body.mesh = body_mesh
        body.scale = Vector3(0.82, 1.0, 0.82)
        body.material_override = _mat(Color("#c85a4b") if i != 1 else Color("#d89a45"), 0.72)
        fruit.add_child(body)

        var stem := MeshInstance3D.new()
        var stem_mesh := CylinderMesh.new()
        stem_mesh.top_radius = 0.025
        stem_mesh.bottom_radius = 0.035
        stem_mesh.height = 0.34
        stem.mesh = stem_mesh
        stem.position.y = 0.56
        stem.rotation_degrees.z = -10
        stem.material_override = _mat(Color("#4d7c3f"), 0.82)
        fruit.add_child(stem)

        var signal := MeshInstance3D.new()
        var signal_mesh := SphereMesh.new()
        signal_mesh.radius = 0.045
        signal_mesh.height = 0.09
        signal.mesh = signal_mesh
        signal.position = Vector3(0, 0.02, 0.78)
        signal.material_override = _glow_mat(Color("#ffbf65"), Color("#ffd68a"), 1.8, 0.8)
        fruit.add_child(signal)
        light_particles.append(signal)

func _create_bio_particles() -> void:
    # Pollen, spores, moisture and fluorescence-like observation points.
    for i in range(46):
        var particle := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.012 + float(i % 4) * 0.006
        mesh.height = mesh.radius * 2.0
        particle.mesh = mesh
        particle.position = Vector3(
            -7.0 + float((i * 17) % 18) * 0.55,
            0.45 + float((i * 11) % 22) * 0.11,
            -3.5 - float((i * 7) % 22) * 0.52
        )
        var tone := i % 3
        if tone == 0:
            particle.material_override = _glow_mat(Color("#d8f58c"), Color("#e7ffab"), 2.2, 0.78)
        elif tone == 1:
            particle.material_override = _glow_mat(Color("#75d8b1"), Color("#8ff0c5"), 1.7, 0.72)
        else:
            particle.material_override = _glow_mat(Color("#b79cff"), Color("#c7b0ff"), 1.5, 0.68)
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

func _create_root_network() -> void:
    # Visible underground layer: branching luminous roots and mycorrhizal
    # threads. It is an interpretive scientific visualization, not a new
    # biological rule.
    var points := [
        [Vector3(1.2, -0.02, -5.2), Vector3(0.7, -0.38, -5.8)],
        [Vector3(0.7, -0.38, -5.8), Vector3(-0.2, -0.55, -6.8)],
        [Vector3(-0.2, -0.55, -6.8), Vector3(-1.8, -0.64, -7.3)],
        [Vector3(0.7, -0.38, -5.8), Vector3(1.7, -0.66, -6.7)],
        [Vector3(1.7, -0.66, -6.7), Vector3(3.4, -0.73, -7.0)],
        [Vector3(1.7, -0.66, -6.7), Vector3(2.3, -0.8, -8.3)],
        [Vector3(-0.2, -0.55, -6.8), Vector3(-2.4, -0.82, -8.6)]
    ]
    for pair in points:
        _add_glowing_segment(pair[0], pair[1], 0.045, Color("#d8ff91"))
    for i in range(14):
        var node := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.045 + float(i % 2) * 0.018
        mesh.height = mesh.radius * 2.0
        node.mesh = mesh
        node.position = Vector3(-2.0 + float((i * 13) % 48) * 0.12, -0.55 - float(i % 4) * 0.07, -6.0 - float((i * 9) % 28) * 0.1)
        node.material_override = _glow_mat(Color("#9f7cff"), Color("#a98cff"), 2.2, 0.8)
        world_root.add_child(node)
        root_nodes.append(node)

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
        var target := Vector3(0.2 + sin(time * 0.045) * 1.1, 1.45 + sin(time * 0.17) * 0.08, -7.8)
        camera.position.x = 7.6 + sin(time * 0.035) * 1.2
        camera.position.y = 4.7 + sin(time * 0.12) * 0.1
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

    # The UI sits inside the ecosystem instead of behaving like a dashboard.
    var vignette := ColorRect.new()
    vignette.color = Color(0.0, 0.01, 0.005, 0.16)
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(vignette)

    menu_root = Control.new()
    menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(menu_root)

    var brand := VBoxContainer.new()
    brand.position = Vector2(52, 38)
    brand.custom_minimum_size = Vector2(360, 120)
    brand.add_theme_constant_override("separation", 2)
    menu_root.add_child(brand)

    var title := Label.new()
    title.text = "SAVIA"
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", TEXT)
    brand.add_child(title)

    var line := Label.new()
    line.text = "UN MUNDO QUE RESPIRA"
    line.add_theme_font_size_override("font_size", 13)
    line.add_theme_color_override("font_color", ACCENT)
    brand.add_child(line)

    var location := Label.new()
    location.text = "BOSQUE TEMPLADO  ·  PRIMAVERA"
    location.add_theme_font_size_override("font_size", 12)
    location.add_theme_color_override("font_color", MUTED)
    brand.add_child(location)

    var nav := VBoxContainer.new()
    nav.position = Vector2(52, 275)
    nav.custom_minimum_size = Vector2(350, 290)
    nav.add_theme_constant_override("separation", 10)
    menu_root.add_child(nav)

    _add_main_action(nav, "ENTRAR EN EL BOSQUE", "continuar la investigación", _enter_world, true)
    _add_main_action(nav, "MIS MUNDOS", "ecosistemas que siguen vivos", _my_biomes, false)
    _add_main_action(nav, "ATLAS VIVO", "lo que has descubierto", _atlas, false)
    _add_main_action(nav, "EXPEDICIONES", "otros biomas y regiones", _expeditions, false)

    # NORA appears as an observation note, not as a chatbot.
    var nora := PanelContainer.new()
    nora.position = Vector2(845, 42)
    nora.size = Vector2(330, 116)
    nora.add_theme_stylebox_override("panel", _box(Color(0.01, 0.035, 0.022, 0.70), 16, Color(0.38, 0.62, 0.42, 0.45), 1))
    menu_root.add_child(nora)

    var nora_box := VBoxContainer.new()
    nora_box.add_theme_constant_override("separation", 5)
    nora.add_child(nora_box)

    var nora_name := Label.new()
    nora_name.text = "NORA  ·  PRESENCIA DE CAMPO"
    nora_name.add_theme_font_size_override("font_size", 11)
    nora_name.add_theme_color_override("font_color", ACCENT)
    nora_box.add_child(nora_name)

    var nora_msg := Label.new()
    nora_msg.text = "La señal recorre la planta.\nHay actividad bajo la hojarasca.\nTodavía no sé qué significa."
    nora_msg.add_theme_font_size_override("font_size", 13)
    nora_msg.add_theme_color_override("font_color", TEXT)
    nora_box.add_child(nora_msg)

    # Scale rail: the same living world, from leaf to microbial life.
    var rail := VBoxContainer.new()
    rail.position = Vector2(1110, 275)
    rail.custom_minimum_size = Vector2(105, 300)
    rail.add_theme_constant_override("separation", 12)
    menu_root.add_child(rail)

    var rail_title := Label.new()
    rail_title.text = "ESCALA VIVA"
    rail_title.add_theme_font_size_override("font_size", 10)
    rail_title.add_theme_color_override("font_color", MUTED)
    rail.add_theme_horizontal_alignment(HORIZONTAL_ALIGNMENT_RIGHT)
    rail.add_child(rail_title)

    var levels := ["LUZ", "HOJA", "FLOR", "FRUTO", "RAÍCES", "SUELO", "MICELIO", "INSECTOS", "MICRO VIDA"]
    for i in range(levels.size()):
        var level := HBoxContainer.new()
        level.alignment = BoxContainer.ALIGNMENT_END
        level.add_theme_constant_override("separation", 8)
        rail.add_child(level)
        var dot := Label.new()
        dot.text = "●"
        dot.add_theme_font_size_override("font_size", 10 if i > 0 else 12)
        dot.add_theme_color_override("font_color", ACCENT if i == 0 else ACCENT_2)
        level.add_child(dot)
        var label := Label.new()
        label.text = levels[i]
        label.add_theme_font_size_override("font_size", 11)
        label.add_theme_color_override("font_color", TEXT if i == 0 else MUTED)
        level.add_child(label)

    var bottom := Label.new()
    bottom.text = "✦  Mueve el tiempo. Cambia la luz. Observa antes de intervenir."
    bottom.position = Vector2(52, 658)
    bottom.add_theme_font_size_override("font_size", 12)
    bottom.add_theme_color_override("font_color", Color("#a5bda5"))
    menu_root.add_child(bottom)

    hint_label = Label.new()
    hint_label.text = "●  ECOSISTEMA ACTIVO"
    hint_label.position = Vector2(1030, 662)
    hint_label.add_theme_font_size_override("font_size", 11)
    hint_label.add_theme_color_override("font_color", ACCENT_2)
    menu_root.add_child(hint_label)

    info_panel = PanelContainer.new()
    info_panel.position = Vector2(700, 500)
    info_panel.size = Vector2(450, 130)
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
    row.custom_minimum_size = Vector2(315, 58)
    parent.add_child(row)

    var button := Button.new()
    button.text = title_text
    button.custom_minimum_size = Vector2(285 if primary else 245, 52)
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.add_theme_font_size_override("font_size", 19 if primary else 15)
    button.add_theme_color_override("font_color", TEXT if primary else Color("#c0d0c1"))
    button.add_theme_color_override("font_hover_color", ACCENT)
    button.add_theme_stylebox_override("normal", _box(Color(0.015, 0.05, 0.028, 0.58) if primary else Color(0.01, 0.035, 0.022, 0.28), 10, Color(0.35, 0.58, 0.40, 0.46), 1))
    button.add_theme_stylebox_override("hover", _box(Color(0.07, 0.15, 0.10, 0.72), 10, ACCENT, 1))
    button.add_theme_stylebox_override("pressed", _box(Color(0.10, 0.20, 0.13, 0.82), 10, ACCENT, 1))
    button.tooltip_text = hint
    button.pressed.connect(action)
    row.add_child(button)

    var arrow := Label.new()
    arrow.text = "  ›"
    arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    arrow.add_theme_font_size_override("font_size", 22)
    arrow.add_theme_color_override("font_color", ACCENT_2)
    row.add_child(arrow)

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
