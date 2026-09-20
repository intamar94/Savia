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
    environment.background_color = BG
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#9ab8a2")
    environment.ambient_light_energy = 0.62
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.glow_enabled = true
    environment.glow_intensity = 0.7
    environment.glow_bloom = 0.12
    environment.fog_enabled = true
    environment.fog_light_color = Color("#789789")
    environment.fog_density = 0.012
    env.environment = environment
    world_root.add_child(env)

    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-38, -28, 0)
    moon.light_energy = 1.0
    moon.light_color = Color("#c9dfcf")
    moon.shadow_enabled = true
    world_root.add_child(moon)

    camera = Camera3D.new()
    camera.position = Vector3(8.2, 5.2, 13.8)
    camera.fov = 45.0
    world_root.add_child(camera)
    camera.look_at(Vector3(0, 1.7, -10), Vector3.UP)

    _create_ground()
    _create_water()
    _create_distant_forest()
    _create_foreground_forest()
    _create_research_station()
    _create_fireflies()
    _create_mushroom_cluster()
    _create_fern_beds()

func _create_ground() -> void:
    var ground := MeshInstance3D.new()
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(70, 70)
    ground.mesh = mesh
    ground.position = Vector3(0, -0.42, -10)
    ground.material_override = _mat(Color("#1c3025"), 0.95)
    world_root.add_child(ground)

    for i in range(18):
        var rock := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 0.25 + float(i % 4) * 0.12
        sphere.height = sphere.radius * 1.35
        rock.mesh = sphere
        rock.position = Vector3(-18 + float((i * 11) % 36), -0.1, -3 - float((i * 17) % 30))
        rock.scale = Vector3(1.5, 0.65, 1.0)
        rock.material_override = _mat(Color("#405044"), 0.98)
        world_root.add_child(rock)

func _create_water() -> void:
    var river := MeshInstance3D.new()
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(9, 70)
    river.mesh = mesh
    river.position = Vector3(5.3, -0.12, -11)
    river.rotation_degrees.y = -5
    river.material_override = _mat(Color("#224c52"), 0.22)
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
    for i in range(34):
        var x := -20.0 + float((i * 13) % 40)
        var z := -18.0 - float((i * 7) % 25)
        _create_tree(Vector3(x, 0, z), 0.65 + float(i % 5) * 0.08, true)

func _create_foreground_forest() -> void:
    for i in range(15):
        var x := -17.0 + float((i * 19) % 32)
        var z := -1.0 - float((i * 29) % 23)
        if abs(x - 4.5) < 4.0:
            x -= 6.0
        _create_tree(Vector3(x, 0, z), 0.82 + float(i % 4) * 0.12, false)

func _create_tree(pos: Vector3, scale_factor: float, distant: bool) -> void:
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
    for i in range(18):
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

func _animate_world() -> void:
    if camera:
        var target := Vector3(0.0 + sin(time * 0.045) * 1.4, 1.7 + sin(time * 0.17) * 0.08, -10.0)
        camera.position.x = 8.2 + sin(time * 0.035) * 1.5
        camera.position.y = 5.2 + sin(time * 0.12) * 0.1
        camera.look_at(target, Vector3.UP)

    for i in range(fireflies.size()):
        var f := fireflies[i]
        var base := f.position
        f.position = base + Vector3(sin(time * (0.5 + i * 0.01) + i) * 0.012, sin(time * 1.3 + i) * 0.018, cos(time * 0.6 + i) * 0.012)
        var glow := 0.35 + 0.35 * sin(time * 1.8 + i)
        f.scale = Vector3.ONE * (0.8 + glow)

    for i in range(grass_blades.size()):
        grass_blades[i].rotation_degrees.z += sin(time * 0.6 + i) * 0.002

func _build_interface() -> void:
    menu_layer = CanvasLayer.new()
    add_child(menu_layer)

    var vignette := ColorRect.new()
    vignette.color = Color(0.0, 0.015, 0.01, 0.20)
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(vignette)

    menu_root = Control.new()
    menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(menu_root)

    # Title: part of the world, not a dashboard.
    var brand := VBoxContainer.new()
    brand.position = Vector2(54, 42)
    brand.custom_minimum_size = Vector2(300, 110)
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

    # Main actions, deliberately sparse.
    var nav := VBoxContainer.new()
    nav.position = Vector2(54, 280)
    nav.custom_minimum_size = Vector2(310, 300)
    nav.add_theme_constant_override("separation", 9)
    menu_root.add_child(nav)

    _add_main_action(nav, "ENTRAR EN EL BOSQUE", "continuar la investigación", _enter_world, true)
    _add_main_action(nav, "MIS MUNDOS", "ecosistemas que siguen vivos", _my_biomes, false)
    _add_main_action(nav, "ATLAS VIVO", "lo que has descubierto", _atlas, false)
    _add_main_action(nav, "EXPEDICIONES", "otros biomas y regiones", _expeditions, false)

    var bottom := Label.new()
    bottom.text = "Mueve el tiempo. Cambia la luz. Observa antes de intervenir."
    bottom.position = Vector2(54, 650)
    bottom.add_theme_font_size_override("font_size", 12)
    bottom.add_theme_color_override("font_color", Color("#8fa493"))
    menu_root.add_child(bottom)

    # NORA is a presence, not a chat box.
    var nora := PanelContainer.new()
    nora.position = Vector2(905, 48)
    nora.size = Vector2(315, 86)
    nora.add_theme_stylebox_override("panel", _box(GLASS, 16, Color(0.32, 0.47, 0.36, 0.45), 1))
    menu_root.add_child(nora)

    var nora_box := VBoxContainer.new()
    nora_box.add_theme_constant_override("separation", 4)
    nora.add_child(nora_box)

    var nora_name := Label.new()
    nora_name.text = "NORA  ·  PRESENCIA DE CAMPO"
    nora_name.add_theme_font_size_override("font_size", 11)
    nora_name.add_theme_color_override("font_color", ACCENT)
    nora_box.add_child(nora_name)

    var nora_msg := Label.new()
    nora_msg.text = "Hay actividad bajo la hojarasca.\nTodavía no sé qué significa."
    nora_msg.add_theme_font_size_override("font_size", 13)
    nora_msg.add_theme_color_override("font_color", TEXT)
    nora_box.add_child(nora_msg)

    hint_label = Label.new()
    hint_label.text = "●  ECOSISTEMA ACTIVO"
    hint_label.position = Vector2(1060, 660)
    hint_label.add_theme_font_size_override("font_size", 11)
    hint_label.add_theme_color_override("font_color", ACCENT_2)
    menu_root.add_child(hint_label)

    # Subtle in-world note panel for secondary menu actions.
    info_panel = PanelContainer.new()
    info_panel.position = Vector2(760, 510)
    info_panel.size = Vector2(455, 125)
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
    button.custom_minimum_size = Vector2(245 if primary else 215, 52)
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.add_theme_font_size_override("font_size", 19 if primary else 15)
    button.add_theme_color_override("font_color", TEXT if primary else Color("#c0d0c1"))
    button.add_theme_color_override("font_hover_color", ACCENT)
    button.add_theme_stylebox_override("normal", _box(Color(0.02, 0.06, 0.04, 0.48) if primary else Color(0.02, 0.05, 0.035, 0.22), 10, Color(0.3, 0.45, 0.34, 0.38), 1))
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
