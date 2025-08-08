extends Node3D

@export var sensivilidad: float = 0.01

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		get_parent().get_parent().rotate_y(deg_to_rad(- event.relative.x *sensivilidad))
		rotate_x(deg_to_rad(- event.relative.y*sensivilidad))
	pass
