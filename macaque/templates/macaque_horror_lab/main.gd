extends Node3D

const SAVE_PATH := "user://macaque_horror_save.json"

var player: CharacterBody3D
var zombie: CharacterBody3D
var camera: Camera3D
var hud: Label
var message: Label
var health := 100
var ammo := 12
var has_key := false
var zombie_health := 4
var zombie_alive := true
var door_open := false
var modern_controls := false
var attack_timer := 0.0
var message_timer := 0.0
var camera_zone := -1

var door_body: StaticBody3D
var key_body: Node3D
var zombie_mesh: MeshInstance3D

func _ready() -> void:
    _build_world()
    _build_player()
    _build_zombie()
    _build_items()
    _build_camera()
    _build_ui()
    _update_hud()
    _say("Find the key. Avoid the infected.", 5.0)

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    mat.roughness = 1.0
    return mat

func _box(
    name: String,
    pos: Vector3,
    size: Vector3,
    color: Color,
    collision_enabled: bool = true
) -> Node3D:
    var body: Node3D

    if collision_enabled:
        body = StaticBody3D.new()
    else:
        body = Node3D.new()

    body.name = name
    body.position = pos
    add_child(body)

    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = _material(color)
    body.add_child(mesh)

    if collision_enabled:
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collider.shape = shape
        body.add_child(collider)

    return body

func _build_world() -> void:
    _box("Floor", Vector3(0, -0.2, 0),
        Vector3(20, 0.4, 20), Color(0.22, 0.24, 0.25))

    _box("NorthWall", Vector3(0, 2, -10),
        Vector3(20, 4, 0.5), Color(0.29, 0.32, 0.32))

    _box("SouthWall", Vector3(0, 2, 10),
        Vector3(20, 4, 0.5), Color(0.29, 0.32, 0.32))

    _box("WestWall", Vector3(-10, 2, 0),
        Vector3(0.5, 4, 20), Color(0.29, 0.32, 0.32))

    _box("EastWall", Vector3(10, 2, 0),
        Vector3(0.5, 4, 20), Color(0.29, 0.32, 0.32))

    _box("HospitalBed", Vector3(-4, 0.45, -3),
        Vector3(2.0, 0.9, 3.0), Color(0.52, 0.52, 0.49))

    _box("Cabinet", Vector3(5, 1.0, -7),
        Vector3(2, 2, 0.8), Color(0.22, 0.31, 0.34))

    _box("Desk", Vector3(4, 0.6, 4),
        Vector3(3, 1.2, 1.5), Color(0.30, 0.19, 0.13))

    # Two openings in a dividing wall.
    _box("DividerLeft", Vector3(-6.5, 2, 0),
        Vector3(7, 4, 0.4), Color(0.33, 0.33, 0.34))

    _box("DividerRight", Vector3(6.5, 2, 0),
        Vector3(7, 4, 0.4), Color(0.33, 0.33, 0.34))

    door_body = _box("LockedExit", Vector3(0, 1.5, 0),
        Vector3(2.5, 3, 0.3), Color(0.36, 0.19, 0.12)) as StaticBody3D

    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.025, 0.035, 0.045)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.25, 0.31, 0.39)
    env.ambient_light_energy = 0.45
    env.fog_enabled = true
    env.fog_light_color = Color(0.10, 0.12, 0.14)
    env.fog_density = 0.025
    world.environment = env
    add_child(world)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-65, 30, 0)
    light.light_energy = 0.55
    light.shadow_enabled = true
    add_child(light)

    var lamp := OmniLight3D.new()
    lamp.position = Vector3(-4, 3.5, -4)
    lamp.light_color = Color(0.85, 0.76, 0.52)
    lamp.light_energy = 1.5
    lamp.omni_range = 9.0
    lamp.shadow_enabled = true
    add_child(lamp)

    var red_light := OmniLight3D.new()
    red_light.position = Vector3(5, 3, 5)
    red_light.light_color = Color(0.9, 0.12, 0.09)
    red_light.light_energy = 1.0
    red_light.omni_range = 7.0
    add_child(red_light)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(-4, 1, 5)
    add_child(player)

    var mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    mesh.mesh = capsule
    mesh.material_override = _material(Color(0.12, 0.36, 0.72))
    player.add_child(mesh)

    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.35
    shape.height = 1.8
    collider.shape = shape
    player.add_child(collider)

func _build_zombie() -> void:
    zombie = CharacterBody3D.new()
    zombie.name = "Infected"
    zombie.position = Vector3(5, 1, -5)
    add_child(zombie)

    zombie_mesh = MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.4
    capsule.height = 1.9
    zombie_mesh.mesh = capsule
    zombie_mesh.material_override = _material(Color(0.35, 0.47, 0.25))
    zombie.add_child(zombie_mesh)

    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.4
    shape.height = 1.9
    collider.shape = shape
    zombie.add_child(collider)

func _build_items() -> void:
    key_body = _box("Key", Vector3(-7, 0.6, -7),
        Vector3(0.45, 0.15, 0.9),
        Color(0.95, 0.75, 0.12), false)

func _build_camera() -> void:
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 55
    add_child(camera)
    _update_camera(true)

func _update_camera(force: bool = false) -> void:
    var zone := 0

    if player.global_position.z < 0:
        zone = 1

    if zone == camera_zone and not force:
        return

    camera_zone = zone

    if zone == 0:
        camera.position = Vector3(-8, 8, 13)
        camera.look_at(Vector3(0, 0.8, 3))
    else:
        camera.position = Vector3(8, 7, -13)
        camera.look_at(Vector3(0, 0.8, -3))

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    hud = Label.new()
    hud.position = Vector2(16, 12)
    hud.add_theme_color_override("font_color", Color(0.8, 0.95, 0.9))
    layer.add_child(hud)

    message = Label.new()
    message.position = Vector2(16, 72)
    message.add_theme_color_override("font_color", Color(1, 0.8, 0.45))
    layer.add_child(message)

    var controls := Label.new()
    controls.position = Vector2(16, 485)
    controls.text = "Arrows: Move | SPACE: Shoot | E: Interact | C: Controls | F5: Save | F9: Load"
    layer.add_child(controls)

func _update_hud() -> void:
    if hud == null:
        return

    hud.text = "MACAQUE HORROR LAB 0.6\nHEALTH: %d  |  AMMO: %d  |  KEY: %s" % [
        health, ammo, "YES" if has_key else "NO"
    ]

func _say(text: String, duration: float = 3.0) -> void:
    message.text = text
    message_timer = duration

func _physics_process(delta: float) -> void:
    if health <= 0:
        return

    _move_player(delta)
    _move_zombie(delta)
    _update_camera()

    if key_body.visible:
        key_body.rotate_y(delta)

    attack_timer = maxf(0.0, attack_timer - delta)

    if message_timer > 0:
        message_timer -= delta
        if message_timer <= 0:
            message.text = ""

func _move_player(delta: float) -> void:
    var forward := Input.get_axis("ui_down", "ui_up")
    var turning := Input.get_axis("ui_left", "ui_right")

    if modern_controls:
        var input_vector := Input.get_vector(
            "ui_left", "ui_right", "ui_up", "ui_down"
        )

        var direction := Vector3(
            input_vector.x, 0, input_vector.y
        ).normalized()

        player.velocity.x = direction.x * 3.5
        player.velocity.z = direction.z * 3.5

        if direction.length() > 0.1:
            player.rotation.y = atan2(-direction.x, -direction.z)
    else:
        player.rotate_y(-turning * 2.5 * delta)

        var direction := -player.global_transform.basis.z
        player.velocity.x = direction.x * forward * 3.0
        player.velocity.z = direction.z * forward * 3.0

    if not player.is_on_floor():
        player.velocity.y -= 18.0 * delta
    else:
        player.velocity.y = 0.0

    player.move_and_slide()

func _move_zombie(delta: float) -> void:
    if not zombie_alive:
        return

    var distance := zombie.global_position.distance_to(
        player.global_position
    )

    if distance < 8.0 and distance > 1.2:
        var direction := player.global_position - zombie.global_position
        direction.y = 0
        direction = direction.normalized()

        zombie.velocity.x = direction.x * 1.25
        zombie.velocity.z = direction.z * 1.25
        zombie.look_at(
            Vector3(
                player.global_position.x,
                zombie.global_position.y,
                player.global_position.z
            ),
            Vector3.UP
        )
    else:
        zombie.velocity.x = 0
        zombie.velocity.z = 0

    if not zombie.is_on_floor():
        zombie.velocity.y -= 18.0 * delta
    else:
        zombie.velocity.y = 0

    zombie.move_and_slide()

    if distance < 1.5 and attack_timer <= 0:
        health = maxi(0, health - 10)
        attack_timer = 1.5
        _say("The infected attacked you!")
        _update_hud()

        if health <= 0:
            _say("YOU DIED - Press F9 to load your save.", 9999)

func _shoot() -> void:
    if ammo <= 0:
        _say("No ammunition!")
        return

    ammo -= 1
    _update_hud()

    if not zombie_alive:
        _say("Nothing to shoot.")
        return

    var to_zombie := zombie.global_position - player.global_position
    var distance := to_zombie.length()
    var facing := -player.global_transform.basis.z

    if distance < 12.0 and facing.dot(to_zombie.normalized()) > 0.75:
        var space := get_world_3d().direct_space_state
        var query := PhysicsRayQueryParameters3D.create(
            player.global_position + Vector3.UP * 0.4,
            zombie.global_position + Vector3.UP * 0.4
        )
        query.exclude = [player.get_rid()]

        var result := space.intersect_ray(query)

        if result.get("collider") == zombie:
            zombie_health -= 1
            _say("Hit! Infected health: %d" % maxi(0, zombie_health))

            if zombie_health <= 0:
                zombie_alive = false
                zombie.visible = false
                zombie.collision_layer = 0
                zombie.collision_mask = 0
                _say("Infected eliminated!")
            return

    _say("Missed!")

func _interact() -> void:
    if key_body.visible:
        if player.global_position.distance_to(key_body.global_position) < 2.0:
            has_key = true
            key_body.visible = false
            _say("Picked up the rusty key.")
            _update_hud()
            return

    if player.global_position.distance_to(door_body.global_position) < 2.5:
        if has_key:
            door_open = true
            door_body.visible = false
            door_body.collision_layer = 0
            door_body.collision_mask = 0
            _say("Door unlocked! You escaped!", 9999)
        else:
            _say("The door is locked. Find the key.")
        return

    _say("Nothing to interact with.")

func _save_game() -> void:
    var data := {
        "position": [
            player.position.x,
            player.position.y,
            player.position.z
        ],
        "rotation": player.rotation.y,
        "health": health,
        "ammo": ammo,
        "has_key": has_key,
        "zombie_health": zombie_health,
        "zombie_alive": zombie_alive,
        "door_open": door_open,
        "modern_controls": modern_controls
    }

    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

    if file == null:
        _say("Save failed.")
        return

    file.store_string(JSON.stringify(data))
    file.close()
    _say("Game saved!")

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        _say("No save file found.")
        return

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        _say("Load failed.")
        return

    var data = JSON.parse_string(file.get_as_text())

    if not data is Dictionary:
        _say("Invalid save file.")
        return

    var pos = data.get("position", [-4, 1, 5])

    if not pos is Array or pos.size() != 3:
        _say("Invalid save position.")
        return

    player.position = Vector3(
        float(pos[0]), float(pos[1]), float(pos[2])
    )
    player.rotation.y = float(data.get("rotation", 0))
    player.velocity = Vector3.ZERO

    health = int(data.get("health", 100))
    ammo = int(data.get("ammo", 12))
    has_key = bool(data.get("has_key", false))
    zombie_health = int(data.get("zombie_health", 4))
    zombie_alive = bool(data.get("zombie_alive", true))
    door_open = bool(data.get("door_open", false))
    modern_controls = bool(data.get("modern_controls", false))

    key_body.visible = not has_key
    zombie.visible = zombie_alive
    zombie.collision_layer = 1 if zombie_alive else 0
    zombie.collision_mask = 1 if zombie_alive else 0
    door_body.visible = not door_open
    door_body.collision_layer = 1 if not door_open else 0
    door_body.collision_mask = 1 if not door_open else 0

    _update_hud()
    _update_camera(true)
    _say("Game loaded!")

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return

    if not event.pressed or event.echo:
        return

    match event.keycode:
        KEY_SPACE:
            if health > 0:
                _shoot()

        KEY_E:
            if health > 0:
                _interact()

        KEY_C:
            modern_controls = not modern_controls
            _say(
                "Modern controls" if modern_controls
                else "Classic tank controls"
            )

        KEY_F5:
            _save_game()

        KEY_F9:
            _load_game()

        KEY_ESCAPE:
            get_tree().quit()
