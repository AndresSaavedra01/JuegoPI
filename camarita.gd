extends Node3D

var camera_rotation := Vector2.ZERO
var sensivility := 0.001
var max_rotation :=1.0
@export var player: CharacterBody3D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion_event : Vector2 = event.screen_relative * sensivility
		camera_look(motion_event)
	

func camera_look(mouse_movement):
	camera_rotation += mouse_movement
	
	transform.basis = Basis()
	player.transform.basis = Basis()
	
	player.rotate_object_local(Vector3(0,1,0), -camera_rotation.x)
	rotate_object_local(Vector3(1,0,0), -camera_rotation.y)
	
	camera_rotation.y = clamp(camera_rotation.y, -max_rotation, max_rotation)
