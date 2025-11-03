extends Node2D

@onready var level_holder = $LevelHolder
@onready var player = $SubViewportContainer/SubViewport/Player

var levels = []
@onready var curr_level = $LevelHolder/Level1

var lerp_speed = 2.0
var lerp_progress = 0.0
var completed_movement = true
var lerp_threshold = 0.1

func _ready():
	levels = level_holder.get_children()
	update_levels()

func update_levels():
	for level in levels:
		if level.name in LevelData.level_dic:
			if LevelData.level_dic[level.name]["unlocked"]:
				level.get_node("Sprite2D").texture = load("res://assets/Menu/unlocked.png")
				if LevelData.level_dic[level.name]["beaten"]:
					level.get_node("Sprite2D").texture = load("res://assets/Menu/beaten.png")
			else:
				level.get_node("Sprite2D").texture = load("res://assets/Menu/locked.png")

func _process(delta):
	var target_level : Node2D
	
	if Input.is_action_just_pressed("adelante") and curr_level.up:
		target_level = curr_level.up
	elif Input.is_action_just_pressed("atras") and curr_level.down:
		target_level = curr_level.down
	elif Input.is_action_just_pressed("izquierda") and curr_level.left:
		target_level = curr_level.left
	elif Input.is_action_just_pressed("derecha") and curr_level.right:
		target_level = curr_level.right

	if Input.is_action_just_pressed("saltar"):
		await get_tree().create_timer(0.4).timeout
		get_tree().change_scene_to_file("res://esenas/" + curr_level.name + ".tscn")

	if target_level and target_level.name in LevelData.level_dic and LevelData.level_dic[target_level.name]["unlocked"] and completed_movement:
		completed_movement = false
		lerp_progress = 0.0

		while lerp_progress < 1.0:
			lerp_progress += lerp_speed * delta
			lerp_progress = clamp(lerp_progress, 0.0, 1.0)
			player.position = player.position.lerp(target_level.global_position, lerp_progress)
			
			if player.position.distance_to(target_level.global_position) < lerp_threshold:
				break

			await get_tree().process_frame

		player.position = target_level.global_position
		curr_level = target_level
		completed_movement = true
