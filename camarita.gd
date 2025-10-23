extends Node3D
class_name camera

var camera_rotation := Vector2.ZERO
var sensivility := 0.009
var max_rotation := 1.0
var change_camera_speed := 0.2
@export var player: player
@onready var edge_spring_arm := $EdgeSpringArm3D
@onready var rear_spring_arm := $EdgeSpringArm3D/RearSpringArm3D
var apuntando := false


# ===============================================================
# PROCESO PRINCIPAL
# ===============================================================
func _process(delta: float) -> void:
	if apuntando:
		camera_look(delta)
		align_player_to_camera(delta)
	else:
		reset_camera_position()

# ===============================================================
# ENTRADA DE RATÓN Y CAMBIOS DE MODO
# ===============================================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("apuntar"):
		apuntar()
	elif event.is_action_released("apuntar"):
		apuntando = false
	elif not apuntando:
		camera_free(event)


# ===============================================================
# CÁMARA DE APUNTADO (mira con el ratón)
# ===============================================================
func camera_look(delta):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	var motion_event = Input.get_last_mouse_velocity() * sensivility * 0.01
	camera_rotation += motion_event
	camera_rotation.y = clamp(camera_rotation.y, -max_rotation, max_rotation)

	# Rotación de cámara
	rotation.y -= motion_event.x
	rotation.x = clamp(rotation.x - motion_event.y, -1.2, 1.2)


# ===============================================================
# ALINEAR PLAYER CON LA CÁMARA (SOLO EN MODO APUNTADO)
# ===============================================================
func align_player_to_camera(delta: float) -> void:
	var cuerpo = player.cuerpo
	# Dirección hacia donde mira la cámara
	var forward = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	# Calcular el ángulo hacia esa dirección
	var target_angle = atan2(forward.x, forward.z)
	
	# Girar suavemente el cuerpo hacia ese ángulo
	cuerpo.rotation.y = lerp_angle(cuerpo.rotation.y, target_angle, delta * 10.0)



# ===============================================================
# CÁMARA LIBRE
# ===============================================================
func camera_free(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * player.mouse_sens_x))
		camera_rotation.y = clamp(camera_rotation.y - event.relative.y * player.mouse_sens_y, -1.0, 1.0)
		rotation.x = camera_rotation.y


# ===============================================================
# CAMBIO ENTRE MODOS
# ===============================================================
func apuntar():
	apuntando = true

	rotation.y = player.camera_pivot.rotation.y
	rotation.x = player.camera_pivot.rotation.x

	var new_pos_edge := 2.0
	var new_pos_rear := 1.5
	set_rear_spring_arm_position(new_pos_rear, change_camera_speed)
	set_edge_spring_arm_position(new_pos_edge, change_camera_speed)


func reset_camera_position():
	apuntando = false

	# 🔹 sincroniza el pivot con la rotación actual de la cámara
	player.camera_pivot.rotation.y = rotation.y
	player.camera_pitch = rotation.x

	var pos_edge = 0
	var pos_rear = 3
	set_rear_spring_arm_position(pos_rear, change_camera_speed)
	set_edge_spring_arm_position(pos_edge, change_camera_speed)



# ===============================================================
# TWEENS DE TRANSICIÓN DE CÁMARA
# ===============================================================
func set_edge_spring_arm_position(pos: float, speed: float):
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_property(edge_spring_arm, "spring_length", pos, speed)

func set_rear_spring_arm_position(pos: float, speed: float):
	var camera_tween = get_tree().create_tween()
	camera_tween.tween_property(rear_spring_arm, "spring_length", pos, speed)
