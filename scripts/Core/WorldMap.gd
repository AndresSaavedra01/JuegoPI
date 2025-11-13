extends Node2D

@onready var level_holder = $LevelHolder
@onready var player_viewport_container = $PlayerViewportContainer
@onready var player_viewport = $PlayerViewportContainer/PlayerViewport
@onready var player_3d = $PlayerViewportContainer/PlayerViewport/robotV3
@export var back_button: Button

var levels = []
@onready var curr_level = $LevelHolder/Level1
var data = LevelData.new()
var lerp_speed = 2.0
var lerp_progress = 0.0
var completed_movement = true
var lerp_threshold = 5.0  # Aumentado para 2D


func _ready():
	player_3d.get_node("AnimationPlayer").play("idle")
	levels = level_holder.get_children()
	update_levels()
	
	# Posicionar el viewport container en la posición inicial del playe
	back_button.pressed.connect(_on_back_pressed)
	
func _on_back_pressed():
	get_tree().change_scene_to_file("res://esenas/MenuGUI/MenuPrincipal.tscn")

func update_levels():
	for level in levels:
		if level.name in data.level_dic:
			if data.level_dic[level.name]["unlocked"]:
				level.get_node("Sprite2D").texture = load("res://assets/Menu/unlocked.png")
				if data.level_dic[level.name]["beaten"]:
					level.get_node("Sprite2D").texture = load("res://assets/Menu/beaten.png")
			else:
				level.get_node("Sprite2D").texture = load("res://assets/Menu/locked.png")

func _process(delta):
	var target_level : Node2D
	
	if Input.is_action_just_pressed("adelante") and curr_level.up:
		target_level = curr_level.up
		player_viewport_container.rotation_degrees = 180
	if Input.is_action_just_pressed("atras") and curr_level.down:
		target_level = curr_level.down
		player_viewport_container.rotation_degrees = 0
	if Input.is_action_just_pressed("izquierda") and curr_level.left:
		target_level = curr_level.left
		player_viewport_container.rotation_degrees = 90
	if Input.is_action_just_pressed("derecha") and curr_level.right:
		target_level = curr_level.right
		player_viewport_container.rotation_degrees = -90

	if Input.is_action_just_pressed("ui_accept"):
		player_3d.get_node("AnimationPlayer").play("Jump")
		await get_tree().create_timer(0.4).timeout
		LoadingController.next_scene = "res://esenas/" + curr_level.name + ".tscn"
		get_tree().change_scene_to_packed(LoadingController.loading_screen)

	if target_level and target_level.name in data.level_dic and data.level_dic[target_level.name]["unlocked"] and completed_movement:
		start_movement(target_level)

func start_movement(target_level: Node2D):
	completed_movement = false
	player_3d.get_node("AnimationPlayer").play("run_001")

	lerp_progress = 0.0
	
	var start_position = player_viewport_container.position
	var end_position = target_level.position - (player_viewport_container.size / 2)	
	
	while lerp_progress < 1.0:
		lerp_progress += lerp_speed * get_process_delta_time()
		lerp_progress = clampf(lerp_progress, 0.0, 1.0)
		
		player_viewport_container.position = start_position.lerp(end_position, lerp_progress)
		
		if player_viewport_container.position.distance_to(end_position) < lerp_threshold:
			break
			
		await get_tree().create_timer(get_process_delta_time()).timeout
	
	player_viewport_container.position = end_position
	curr_level = target_level
	player_3d.get_node("AnimationPlayer").play("idle")
	completed_movement = true
