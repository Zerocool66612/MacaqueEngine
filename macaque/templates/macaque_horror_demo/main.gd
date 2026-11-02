extends Node3D

var player: CharacterBody3D
var camera: Camera3D

func _ready() -> void:
    _create_room()
    _create_player()
    _create_camera()
    _create_lighting()
    _create_hud()

func _create_box(
    name: String,
    position: Vector3,
    size: Vector3,
    color: Color
) -> void:
    var body := StaticBody3D.new()
    body.name = name
    body.position = position
    add_child(body)

    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box

    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    mesh.material_override = material
    body.add_child(mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

func _create_room() -> void:
    _create_box(
        "Floor",
        Vector3(0, -0.15, 0),
        Vector3(14, 0.3, 14),
        Color(0.28, 0.29, 0.31)
    )

    _create_box(
        "BackWall",
        Vector3(0, 2, -7),
        Vector3(14, 4, 0.4),
        Color(0.36, 0.34, 0.32)
    )

    _create_box(
        "FrontWall",
        Vector3(0, 2, 7),
        Vector3(14, 4, 0.4),
        Color(0.36, 0.34, 0.32)
    )

    _create_box(
        "LeftWall",
        Vector3(-7, 2, 0),
        Vector3(0.4, 4, 14),
        Color(0.32, 0.33, 0.36)
    )

    _create_box(
        "RightWall",
        Vector3(7, 2, 0),
        Vector3(0.4, 4, 14),
        Color(0.32, 0.33, 0.36)
    )

    _create_box(
        "Table",
        Vector3(2, 0.6, -2),
        Vector3(2, 1.2, 1),
        Color(0.35, 0.22, 0.15)
    )

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 1, 2)
    add_child(player)

    var mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.35
    capsule.height = 1.7
    mesh.mesh = capsule

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.2, 0.4, 0.8)
    mesh.material_override = material
    player.add_child(mesh)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.35
    shape.height = 1.7
    collision.shape = shape
    player.add_child(collision)

func _create_camera() -> void:
    camera = Camera3D.new()
    camera.name = "FixedCamera"
    camera.position = Vector3(8, 7, 12)
    camera.current = true
    add_child(camera)
    camera.look_at(Vector3.ZERO)

func _create_lighting() -> void:
    var light := DirectionalLight3D.new()
    light.name = "Moonlight"
    light.rotation_degrees = Vector3(-55, 25, 0)
    light.light_energy = 1.2
    light.shadow_enabled = true
    add_child(light)

    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.05, 0.06, 0.09)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.25, 0.28, 0.35)
    env.ambient_light_energy = 0.5
    environment.environment = env
    add_child(environment)

func _create_hud() -> void:
    var hud := CanvasLayer.new()
    add_child(hud)

    var label := Label.new()
    label.text = "MACAQUE ENGINE 0.5 | Arrows: Move/Turn | ESC: Quit"
    label.position = Vector2(15, 15)
    hud.add_child(label)

func _physics_process(delta: float) -> void:
    if player == null:
        return

    var turn := Input.get_axis("ui_left", "ui_right")
    var forward := Input.get_axis("ui_down", "ui_up")

    player.rotate_y(-turn * 2.5 * delta)

    var direction := -player.global_transform.basis.z

    player.velocity.x = direction.x * forward * 3.0
    player.velocity.z = direction.z * forward * 3.0

    if not player.is_on_floor():
        player.velocity.y -= 18.0 * delta
    else:
        player.velocity.y = 0.0

    player.move_and_slide()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.pressed and event.keycode == KEY_ESCAPE:
            get_tree().quit()
