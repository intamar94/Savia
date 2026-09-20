extends Node3D

var camera: Camera3D
var world_root: Node3D
var menu_layer: CanvasLayer
var content_panel: PanelContainer
var content_title: Label
var content_body: Label
var status_label: Label
var time := 0.0

const BG := Color("#0b1410")
const PANEL := Color("#101d17")
const PANEL_2 := Color("#16261d")
const TEXT := Color("#e2eee0")
const MUTED := Color("#9eb5a3")
const ACCENT := Color("#a9c99e")
const LINE := Color("#36513e")

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

    var shade := ColorRect.new()
    shade.color = Color(0.015, 0.025, 0.02, 0.48)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_layer.add_child(shade)

    # Top status bar
    var top := PanelContainer.new()
    top.position = Vector2(34, 24)
    top.size = Vector2(1210, 58)
    top.add_theme_stylebox_override("panel", _box(PANEL, 14, LINE, 1))
    menu_layer.add_child(top)

    var top_row := HBoxContainer.new()
    top_row.add_theme_constant_override("separation", 18)
    top.add_child(top_row)

    var mark := Label.new()
    mark.text = "SAVIA"
    mark.add_theme_font_size_override("font_size", 23)
    mark.add_theme_color_override("font_color", TEXT)
    top_row.add_child(mark)

    var divider := VSeparator.new()
    top_row.add_child(divider)

    var biome := Label.new()
    biome.text = "BOSQUE TEMPLADO  /  INVESTIGACIÓN ACTIVA"
    biome.add_theme_font_size_override("font_size", 14)
    biome.add_theme_color_override("font_color", MUTED)
    top_row.add_child(biome)

    var top_spacer := Control.new()
    top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_row.add_child(top_spacer)

    var season := Label.new()
    season.text = "DÍA 01  ·  PRIMAVERA"
    season.add_theme_font_size_override("font_size", 13)
    season.add_theme_color_override("font_color", ACCENT)
    top_row.add_child(season)

    # Main navigation
    var nav := PanelContainer.new()
    nav.position = Vector2(42, 112)
    nav.size = Vector2(370, 545)
    nav.add_theme_stylebox_override("panel", _box(PANEL, 18, LINE, 1))
    menu_layer.add_child(nav)

    var nav_box := VBoxContainer.new()
    nav_box.add_theme_constant_override("separation", 7)
    nav.add_child(nav_box)

    var title := Label.new()
    title.text = "SAVIA"
    title.add_theme_font_size_override("font_size", 62)
    title.add_theme_color_override("font_color", TEXT)
    nav_box.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "UN MUNDO VIVO"
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", MUTED)
    nav_box.add_child(subtitle)

    var intro := Label.new()
    intro.text = "Explora un ecosistema que cambia,
responde y conserva memoria."
    intro.add_theme_font_size_override("font_size", 14)
    intro.add_theme_color_override("font_color", Color("#7f9b87"))
    nav_box.add_child(intro)

    var gap := Control.new()
    gap.custom_minimum_size = Vector2(1, 24)
    nav_box.add_child(gap)

    _add_nav_button(nav_box, "NUEVA INVESTIGACIÓN", "Comenzar una investigación", _new_investigation, true)
    _add_nav_button(nav_box, "CONTINUAR", "Retomar el último bioma", _continue_game, false)
    _add_nav_button(nav_box, "MIS BIOMAS", "Explorar tus mundos", _my_biomes, false)
    _add_nav_button(nav_box, "ATLAS VIVO", "Fenómenos y conocimiento", _atlas, false)

    var nav_gap := Control.new()
    nav_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
    nav_box.add_child(nav_gap)

    _add_nav_button(nav_box, "PERFIL", "Investigador", _profile, false)
    _add_nav_button(nav_box, "OPCIONES", "Configuración", _options, false)

    # Research dashboard
    content_panel = PanelContainer.new()
    content_panel.position = Vector2(445, 112)
    content_panel.size = Vector2(795, 545)
    content_panel.add_theme_stylebox_override("panel", _box(Color(0.055, 0.105, 0.08, 0.92), 18, LINE, 1))
    menu_layer.add_child(content_panel)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    content_panel.add_child(content)

    var header := HBoxContainer.new()
    content.add_child(header)

    var header_box := VBoxContainer.new()
    header_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(header_box)

    content_title = Label.new()
    content_title.text = "ESTADO DEL BIOMA"
    content_title.add_theme_font_size_override("font_size", 28)
    content_title.add_theme_color_override("font_color", TEXT)
    header_box.add_child(content_title)

    content_body = Label.new()
    content_body.text = "Tu investigación acaba de comenzar."
    content_body.add_theme_font_size_override("font_size", 14)
    content_body.add_theme_color_override("font_color", MUTED)
    header_box.add_child(content_body)

    var live := Label.new()
    live.text = "●  VIVO"
    live.add_theme_font_size_override("font_size", 13)
    live.add_theme_color_override("font_color", ACCENT)
    header.add_child(live)

    _add_section_label(content, "INVESTIGACIÓN")

    var stats := GridContainer.new()
    stats.columns = 3
    stats.add_theme_constant_override("h_separation", 10)
    stats.add_theme_constant_override("v_separation", 10)
    stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_child(stats)

    _add_stat(stats, "EXPLORACIÓN", "0 %", "Territorio observado")
    _add_stat(stats, "CONOCIMIENTO", "0", "Fenómenos documentados")
    _add_stat(stats, "PREGUNTAS", "3", "Preguntas abiertas")
    _add_stat(stats, "HIPÓTESIS", "0", "En investigación")
    _add_stat(stats, "ANOMALÍAS", "0", "Sin explicar")
    _add_stat(stats, "REPRODUCCIONES", "0", "Resultados confirmados")

    _add_section_label(content, "NORA")

    var nora_panel := PanelContainer.new()
    nora_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    nora_panel.custom_minimum_size = Vector2(1, 82)
    nora_panel.add_theme_stylebox_override("panel", _box(PANEL_2, 12, LINE, 1))
    content.add_child(nora_panel)

    var nora_text := Label.new()
    nora_text.text = "NORA  ·  "No hay suficiente evidencia todavía.\nPodemos comenzar observando el suelo, el agua y la vegetación.""
    nora_text.add_theme_font_size_override("font_size", 15)
    nora_text.add_theme_color_override("font_color", Color("#c6d8c8"))
    nora_panel.add_child(nora_text)

    _add_section_label(content, "ÚLTIMA ACTIVIDAD")

    status_label = Label.new()
    status_label.text = "Sin observaciones registradas. El ecosistema está esperando."
    status_label.add_theme_font_size_override("font_size", 14)
    status_label.add_theme_color_override("font_color", MUTED)
    content.add_child(status_label)

    var footer := Label.new()
    footer.text = "SAVIA 0.2  ·  SIMULACIÓN CIENTÍFICA EN DESARROLLO"
    footer.position = Vector2(42, 680)
    footer.add_theme_font_size_override("font_size", 11)
    footer.add_theme_color_override("font_color", Color("#718a78"))
    menu_layer.add_child(footer)

func _add_nav_button(parent: VBoxContainer, title_text: String, hint: String, action: Callable, primary: bool) -> void:
    var button := Button.new()
    button.text = title_text + "    ›"
    button.custom_minimum_size = Vector2(1, 52)
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.add_theme_font_size_override("font_size", 17 if primary else 15)
    button.add_theme_color_override("font_color", TEXT if primary else MUTED)
    button.add_theme_color_override("font_hover_color", TEXT)
    button.add_theme_stylebox_override("normal", _box(Color("#17251c") if primary else Color("#111e17"), 10, LINE, 1))
    button.add_theme_stylebox_override("hover", _box(Color("#213328"), 10, ACCENT, 1))
    button.add_theme_stylebox_override("pressed", _box(Color("#2a4030"), 10, ACCENT, 1))
    button.tooltip_text = hint
    button.pressed.connect(action)
    parent.add_child(button)

func _add_section_label(parent: VBoxContainer, text_value: String) -> void:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", 11)
    label.add_theme_color_override("font_color", Color("#6f8b76"))
    parent.add_child(label)

func _add_stat(parent: GridContainer, title_text: String, value_text: String, detail: String) -> void:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(0, 82)
    card.add_theme_stylebox_override("panel", _box(PANEL_2, 11, LINE, 1))
    parent.add_child(card)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 2)
    card.add_child(box)

    var value := Label.new()
    value.text = value_text
    value.add_theme_font_size_override("font_size", 25)
    value.add_theme_color_override("font_color", ACCENT)
    box.add_child(value)

    var title := Label.new()
    title.text = title_text
    title.add_theme_font_size_override("font_size", 11)
    title.add_theme_color_override("font_color", TEXT)
    box.add_child(title)

    var detail_label := Label.new()
    detail_label.text = detail
    detail_label.add_theme_font_size_override("font_size", 10)
    detail_label.add_theme_color_override("font_color", MUTED)
    box.add_child(detail_label)

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
    box.content_margin_left = 18
    box.content_margin_right = 18
    box.content_margin_top = 14
    box.content_margin_bottom = 14
    return box

func _new_investigation() -> void:
    status_label.text = "Investigación iniciada. Observa antes de intervenir."
    content_title.text = "NUEVA INVESTIGACIÓN"
    content_body.text = "Bosque templado · Punto de partida seleccionado"
    _show_message("INVESTIGACIÓN INICIADA\n\nEl mundo ya está activo.\nTu primera tarea es observar, no intervenir.")

func _continue_game() -> void:
    status_label.text = "Continuación preparada para el sistema de guardado persistente."
    content_title.text = "CONTINUAR"
    content_body.text = "Último estado conocido del ecosistema"
    _show_message("CONTINUAR\n\nEl sistema de guardado persistente se conectará al estado completo del bioma.")

func _my_biomes() -> void:
    content_title.text = "MIS BIOMAS"
    content_body.text = "Cada mundo conserva su propia historia."
    status_label.text = "Bosque templado · Investigación activa"
    _show_message("MIS BIOMAS\n\nBOSQUE TEMPLADO\nInvestigación activa\nPreguntas abiertas: 3\nFenómenos documentados: 0")

func _atlas() -> void:
    content_title.text = "ATLAS VIVO"
    content_body.text = "Conocimiento, fenómenos y anomalías."
    status_label.text = "El Atlas todavía no contiene descubrimientos."
    _show_message("ATLAS VIVO\n\nFenómenos conocidos\nHipótesis\nAnomalías\nPreguntas abiertas\n\nEl catálogo crecerá con tus investigaciones.")

func _profile() -> void:
    content_title.text = "PERFIL DEL INVESTIGADOR"
    content_body.text = "Tu conocimiento se construye con evidencia."
    status_label.text = "Investigador · Nivel inicial"
    _show_message("PERFIL\n\nConocimiento: inicial\nDescubrimientos: 0\nReproducciones: 0")

func _options() -> void:
    content_title.text = "OPCIONES"
    content_body.text = "Configuración de la experiencia."
    status_label.text = "Opciones disponibles próximamente."
    _show_message("OPCIONES\n\nGráficos\nAudio\nControles\nIdioma\nAccesibilidad")

func _show_message(message: String) -> void:
    var popup := AcceptDialog.new()
    popup.title = "SAVIA"
    popup.dialog_text = message
    popup.ok_button_text = "CONTINUAR"
    menu_layer.add_child(popup)
    popup.popup_centered(Vector2(540, 310))
    popup.confirmed.connect(popup.queue_free)
