extends StaticBody3D

@export var entityScene : PackedScene
@export var spawnRadio : float = 5.0
@export var detectAreaRadio : float = 10.0
@export var maxEntityCount : int = 10
@export var fallSpeed : float = 3.0
@export var throwing_time : float = 1.2
@export var throwing_force : float = 2.0
@export var min_wait_time : float = 1.5
@export var max_wait_time : float = 3.0
@export var debug_radios : bool = false

@onready var detectArea : Area3D = $DetectArea
@onready var spawnTimeout : Timer = $SpawnTimeout
@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var rng : RandomNumberGenerator = RandomNumberGenerator.new()
@onready var collision : CollisionShape3D = $CollisionShape3D
@onready var radioDebug : MeshInstance3D = $RadioDebug

var is_spawning : bool = false
var current_entity : CharacterBody3D
var final_pos : Vector3

func _ready() -> void:
	var collision : CollisionShape3D = detectArea.get_node("CollisionShape3D")
	collision.shape.set("radius", detectAreaRadio)
	radioDebug.mesh.top_radius = spawnRadio
	radioDebug.mesh.bottom_radius = spawnRadio
	radioDebug.visible = debug_radios
	
func _physics_process(delta: float) -> void:
	var overlaps : Array[Node3D] = detectArea.get_overlapping_bodies()
	if is_spawning:
		throw_entity(delta)
	elif spawnTimeout.is_stopped() and overlaps.any(is_player) and overlaps.filter(is_enemy).size() < maxEntityCount:
			is_spawning = true
			spawnTimeout.wait_time = rng.randf_range(min_wait_time, max_wait_time)
			spawnTimeout.start()
	
	
func is_enemy(nodo : Node3D) -> bool:
	return nodo.is_in_group("Enemies")

func is_player(nodo : Node3D) -> bool:
	return nodo.is_in_group("Player")

func _on_spawn_timeout_timeout() -> void:
	var overlaps : Array[Node3D] = detectArea.get_overlapping_bodies()
	current_entity = entityScene.instantiate()
	if current_entity:
		get_tree().get_first_node_in_group("World").add_child(current_entity)
		var x : float = rng.randf_range(0.0 ,spawnRadio)
		if(rng.randf() > 0.5):
			x *= -1
		var z : float = rng.randf_range(0.0, spawnRadio)
		if(rng.randf() > 0.5):
			z *= -1
		var pos : Vector3 = Vector3(x, 0.0, z) + global_position
		var map : RID = navAgent.get_navigation_map()
		final_pos = NavigationServer3D.map_get_closest_point(map, pos)
		print(final_pos)
		current_entity.global_position = global_position + Vector3.UP * collision.shape.size.y
		current_entity.velocity.y = throwing_force
		current_entity.scale *= 0.4
		var dir : Vector3 = (final_pos - global_position).normalized()
		var rotacion : float = atan2(dir.x, dir.z)
		current_entity.body.rotate_y(rotacion)
		
		

func throw_entity(delta : float) -> void:
	if current_entity:
		if not current_entity.is_on_floor():
			var dir : Vector3 = (final_pos - global_position).normalized()
			var speed : float = global_position.distance_to(final_pos) / throwing_time
			current_entity.velocity.y -= delta * fallSpeed
			current_entity.velocity.x = dir.x * speed
			current_entity.velocity.z = dir.z * speed
			current_entity.move_and_slide()
		else:
			print(current_entity.global_position)
			is_spawning = false
			current_entity = null
