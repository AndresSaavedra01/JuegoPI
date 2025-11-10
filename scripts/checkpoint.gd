extends Area3D

var jugador: player
var checkpoints
var altura_de_respawn_de_caida := -10

func _ready() -> void:
	checkpoints = get_tree().get_nodes_in_group("checkpoints")

func _process(delta: float) -> void:
	if jugador != null:
		if jugador.global_position.y < altura_de_respawn_de_caida or jugador.dead:
			jugador.global_position = global_position
	


func desCheckPoint():
	jugador = null

func _on_body_entered(body: Node3D) -> void:
	if body is player:
		print("checkpoint")
		for i in checkpoints:
			i.desCheckPoint()
		jugador = body
