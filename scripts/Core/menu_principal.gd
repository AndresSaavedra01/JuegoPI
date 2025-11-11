extends Control

@export var play_button: Button
@export var settings_button: Button
@export var exit_button: Button
@export var tween_intensity: float
@export var tween_duration: float


func _ready():
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	for button in [play_button, settings_button, exit_button]:
		button.mouse_entered.connect(_on_button_hovered.bind(button, true))
		button.mouse_exited.connect(_on_button_hovered.bind(button, false))

	var buttons: Array = get_all_buttons(self)
	await get_tree().process_frame
	buttons.sort_custom(buttons_array_sorting)
	animate_buttons(buttons.duplicate(), true, 0.16, Vector2(-20,0), Vector2.ZERO, 0.5)
	
	
func start_tween(object: Object, property: String, final_val: Variant, duration: float):
	var tween = create_tween()
	tween.tween_property(object, property, final_val, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_button_hovered(button: Button, hovered: bool):
	button.pivot_offset = button.size / 2
	if hovered:
		start_tween(button, "scale", Vector2.ONE * tween_intensity, tween_duration)
	else:
		start_tween(button, "scale", Vector2.ONE, tween_duration)

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://esenas/MenuGUI/WorldMap.tscn")
	
func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://esenas/MenuGUI/MenuOpciones.tscn")
	
func _on_exit_pressed():
	get_tree().quit()
	
func get_all_buttons(node: Node) -> Array:
	var buttons: Array = []
	for child in node.get_children():
		if child is Button:
			buttons.append(child)
		if child.get_child_count() > 0:
			buttons += get_all_buttons(child)
	return buttons

func buttons_array_sorting(a: Button, b: Button) -> bool:
	if a.global_position.y == b.global_position.y:
		return a.global_position.x < b.global_position.x
	return a.global_position.y < b.global_position.y
	
func animate_buttons(buttons:Array, forward := true, delay_between_buttons := 0.16, move_offset := Vector2(-20,0), scale_offset := Vector2.ZERO, animation_length := 0.5):
	if !forward:
		buttons.reverse()
		
	for btn:Button in buttons:
		btn.modulate.a = 0.0 if forward else 1.0
		
		btn.pivot_offset.y = btn.size.y/2.0
		btn.scale = scale_offset if forward else Vector2.ONE
			
	for i:Button in buttons:
		var tween_ease: int = Tween.EASE_OUT if forward else Tween.EASE_IN
		var pos_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(tween_ease)
		var modulate_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(tween_ease)
		var scale_tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(tween_ease)
		
		var target_pos: Vector2 = i.position - move_offset if forward else i.position + move_offset
		var target_modulate: float = 1.0 if forward else 0.0
		var target_scale: Vector2 = Vector2.ONE if forward else scale_offset
		
		pos_tween.tween_property(i,"position", target_pos, animation_length)
		modulate_tween.tween_property(i,"modulate:a",target_modulate, animation_length)
		scale_tween.tween_property(i,"scale", target_scale, animation_length)
			
		await get_tree().create_timer(delay_between_buttons).timeout
		
