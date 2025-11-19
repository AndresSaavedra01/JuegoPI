extends Node3D

@onready var boss : Boss = $MrSteven



func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is player:
		boss.start_mrSteven()
	$Area3D.queue_free()
	
