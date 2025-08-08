extends Node3D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.y += event.relative.x * 0.005
