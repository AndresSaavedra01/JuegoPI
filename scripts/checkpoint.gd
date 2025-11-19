extends Area3D

var jugador: player
var checkpoints
var altura_de_respawn_de_caida := -10


func _ready() -> void:
	checkpoints = get_tree().get_nodes_in_group("checkpoints")

var conection := false

func _physics_process(delta: float) -> void:
	if jugador != null:
		if !conection:
			jugador.connect("dead", Callable(self, "reset"))
			conection = true
		
		if jugador.global_position.y < altura_de_respawn_de_caida :
			jugador.global_position = global_position
		

func reset():
	if jugador == null :  return
	await  get_tree().create_timer(2).timeout
	jugador.global_position = global_position
	jugador.reset()

func desCheckPoint():
	jugador = null

func _on_body_entered(body: Node3D) -> void:
	if body is player:
		print("checkpoint")
		for i in checkpoints:
			if self != i:
				i.desCheckPoint()
		jugador = body
