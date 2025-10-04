extends Node3D

@export var shoot_speed: float = 15.0
@export var spread: float = 0.05
@export var lifetime: float = 2.0
@export var gravity: float = -9.8
@export var bullet_scene: PackedScene   # aquí arrastras tu "Gota.tscn"
var player

var particles = []  # cada partícula = {node, vel, time}




func _process(delta: float) -> void:
	for p in particles:
		# actualizar física
		p.vel.y += gravity * delta
		p.node.global_transform.origin += p.vel * delta
		p.time -= delta

	# limpiar las que ya murieron
	for p in particles.duplicate():
		if p.time <= 0:
			p.node.queue_free()
			particles.erase(p)
	

func shoot():
	var origin = $Marker.global_transform
	var dir = -$Marker.global_transform.basis.z
	
	# Monte Carlo: agregamos dispersión aleatoria
	dir.x += randf_range(-spread, spread)
	dir.y += randf_range(-spread, spread)
	dir = dir.normalized()
	
	var vel = dir * (shoot_speed + randf_range(-2, 2))
	
	# instanciar la gota
	var bullet = bullet_scene.instantiate()
	get_tree().get_first_node_in_group("Player").add_child(bullet)  # la ponemos en la escena principal
	bullet.global_transform = origin
	
	particles.append({
		"node": bullet,
		"vel": vel,
		"time": lifetime
	})
