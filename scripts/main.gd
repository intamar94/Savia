extends Node3D

var camera: Camera3D
var world_root: Node3D
var menu_layer: CanvasLayer
var status_label: Label
var time := 0.0

func _ready() -> void:
    _build_world()
    _build_interface()

func _process(delta: float) -> void:
    time += delta
    if camera:
        camera.position.y = 5.8 + sin(time * 0.18) * 0.12
        camera.look_at(Vector3(0, 1.2, -10), Vector3.UP)
    if world_root:
        world_root.rotation.y = sin(time * 0.025) * 0.025

func _build_world() -> void:
    world_root = Node3D.new()
    world_root.name = "LivingBiome"
    add_child(world_root)

    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#101a16")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#9bbca6")
    environment.ambient_light_energy = 0.55
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.fog_enabled = true
    environment.fog_light_color = Color("#789487")
    environment.fog_density = 0.008
    env.environment = environment
    world_root.add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    world_root.add_child(sun)

    camera = Camera3D.new()
    camera.position = Vector3(0, 5.8, 12)
    camera.fov = 48.0
    world_root.add_child(camera)
    camera.look_at(Vector3(0, 1.2, -10), Vector3.UP)

    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(70, 70)
    ground.mesh = plane
    ground.position = Vector3(0, -0.35, -10)
    ground.material_override = _mat(Color("#263c2d"))
    world_root.add_child(ground)

    var river := MeshInstance3D.new()
    var river_mesh := PlaneMesh.new()
    river_mesh.size = Vector2(10, 70)
    river.mesh = river_mesh
    river.position = Vector3(4.0, -0.05, -10)
    river.rotation_degrees.y = -4
    river.material_override = _mat(Color("#294f57"), 0.05)
    world_root.add_child(river)

    for i in range(7):
        var hill := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 5.0 + i * 0.45
        sphere.height = 7.0 + i * 0.6
        hill.mesh = sphere
        hill.position = Vector3(-18 + i * 6.0, 1.8 + (i % 2) * 0.8, -24 - (i % 3) * 2)
        hill.scale = Vector3(1.8, 0.65, 1.2)
        hill.material_override = _mat(Color("#20362b"))
        world_root.add_child(hill)

    for i in range(24):
        var x := -17.0 + float((i * 17) % 34)
        var z := -2.0 - float((i * 23) % 35)
        if abs(x - 4.0) < 4.5:
            x -= 7.0
        _create_tree(Vector3(x, 0, z), 0.8 + float(i % 4) * 0.12)

func _create_tree(pos: Vector3, scale_factor: float) -> void:
    var tree := Node3D.new()
    tree.position = pos
    tree.scale = Vector3.ONE * scale_factor
    world_root.add_child(tree)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.18
    trunk_mesh.bottom_radius = 0.28
    trunk_mesh.height = 2.6
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.3
    trunk.material_override = _mat(Color("#4b3627"))
    tree.add_child(trunk)

    var crown := MeshInstance3D.new()
    var crown_mesh := SphereMesh.new()
    crown_mesh.radius = 1.35
    crown_mesh.height = 2.6
    crown.mesh = crown_mesh
    crown.position.y = 3.0
    crown.material_override = _mat(Color("#31573b"))
    tree.add_child(crown)

func _mat(color: Color, roughness := 0.8) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    return material

func _build_interface() -> void:
    menu_layer = CanvasLayer.new()
    add_child(menu_layer)

    var backdrop := ColorRect.new()
    backdrop.color = Color(0.015, 0.025, 0.02, 0.38)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(backdrop)

    var left := VBoxContainer.new()
    left.position = Vector2(70, 80)
    left.size = Vector2(470, 560)
    left.add_theme_constant_override("separation", 12)
    menu_layer.add_child(left)

    var title := Label.new()
    title.text = "SAVIA"
    title.add_theme_font_size_override("font_size", 72)
    title.add_theme_color_override("font_color", Color("#dcebd8"))
    left.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "UN MUNDO VIVO"
    subtitle.add_theme_font_size_override("font_size", 20)
    subtitle.add_theme_color_override("font_color", Color("#9fbea5"))
    left.add_child(subtitle)

    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(1, 70)
    left.add_child(spacer)

    _add_button(left, "NUEVA INVESTIGACIÓN", _new_investigation)
    _add_button(left, "CONTINUAR", _continue_game)
    _add_button(left, "MIS BIOMAS", _my_biomes)
    _add_button(left, "PERFIL", _profile)
    _add_button(left, "OPCIONES", _options)

    status_label = Label.new()
    status_label.text = "INVESTIGACIÓN ACTIVA  •  BOSQUE TEMPLADO"
    status_label.position = Vector2(70, 665)
    status_label.add_theme_font_size_override("font_size", 14)
    status_label.add_theme_color_override("font_color", Color("#91ad98"))
    menu_layer.add_child(status_label)

    var nora := Label.new()
    nora.text = "NORA  ·  El ecosistema está esperando ser observado."
    nora.position = Vector2(760, 650)
    nora.add_theme_font_size_override("font_size", 15)
    nora.add_theme_color_override("font_color", Color("#c5d7c7"))
    menu_layer.add_child(nora)

func _add_button(parent: VBoxContainer, label_text: String, action: Callable) -> void:
    var button := Button.new()
    button.text = label_text
    button.custom_minimum_size = Vector2(380, 58)
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.add_theme_font_size_override("font_size", 20)
    button.pressed.connect(action)
    parent.add_child(button)

func _new_investigation() -> void:
    status_label.text = "NUEVA INVESTIGACIÓN  •  BOSQUE TEMPLADO"
    _show_message("El bioma está activo.\nExplora. Observa. Formula una hipótesis.")

func _continue_game() -> void:
    _show_message("El sistema de guardado se conectará al estado persistente del bioma.")

func _my_biomes() -> void:
    _show_message("MIS BIOMAS\n\nBosque templado — investigación activa\nPreguntas abiertas: 0\nFenómenos documentados: 0")

func _profile() -> void:
    _show_message("PERFIL DEL INVESTIGADOR\n\nConocimiento: inicial\nDescubrimientos: 0")

func _options() -> void:
    _show_message("OPCIONES\n\nGráficos · Audio · Controles · Idioma")

func _show_message(message: String) -> void:
    var popup := AcceptDialog.new()
    popup.title = "SAVIA"
    popup.dialog_text = message
    popup.ok_button_text = "CONTINUAR"
    menu_layer.add_child(popup)
    popup.popup_centered(Vector2(520, 300))
    popup.confirmed.connect(popup.queue_free)
