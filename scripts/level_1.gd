extends Node3D

@onready var boss : Boss = $MrSteven


func _ready() -> void:
	AudioController.play_music("res://audio/Sketchbook 2024-08-21.ogg")


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is player:
		boss.start_mrSteven()
	$Area3D.queue_free()
	
	AudioController.play_music("res://audio/Tester 2.0 boss.mp3")
