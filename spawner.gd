extends StaticBody3D

@export var entityScene : PackedScene
@export var spawnRadio : float = 5.0
@export var detectAreaRadio : float = 10.0
@export var maxEntityCount : int = 5
@export var entityGroup : String

@onready var detectArea : Area3D = $DetectArea
@onready var spanwTimeout : Timer = $SpawnTimeout
@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var rng : RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	var collision : CollisionShape3D = detectArea.get_node("CollisionShape3D")
	collision.shape.set("radius", detectAreaRadio)
	
func _process(delta: float) -> void:
	var overlaps : Array[Node3D] = detectArea.get_overlapping_bodies()
	if overlaps.filter(inGroup).size() < maxEntityCount and overlaps.any(is_player):
		if spanwTimeout.is_stopped():
			spanwTimeout.start()
	
func inGroup(nodo : Node3D) -> bool:
	return nodo.is_in_group(entityGroup)

func is_player(nodo : Node3D) -> bool:
	return nodo.is_in_group("Player")

func _on_spawn_timeout_timeout() -> void:
	var entity = entityScene.instantiate()
	if entity:
		get_tree().get_first_node_in_group("World").add_child(entity)
		var x : float = rng.randf_range(0.0,spawnRadio)
		if(rng.randf() > 0.5):
			x *= -1
		var z : float = rng.randf_range(0.0, spawnRadio)
		if(rng.randf() > 0.5):
			z *= -1
		var pos : Vector3 = Vector3(x, 0.0, z) + global_position
		var map : RID = navAgent.get_navigation_map()
		pos = NavigationServer3D.map_get_closest_point(map, pos)
		entity.global_position = pos
		entity.scale *= 0.4
