extends VBoxContainer

@export var option_resolution: OptionButton
@export var option_fullscreen: CheckBox
@export var option_borderless: CheckBox
@export var option_vsync: CheckBox
@export var back_button: Button

func _ready():
	#var animator = ButtonAnimator.new()
	#add_child(animator)
	#
	#var buttons: Array = animator.get_all_buttons(self)
	#await get_tree().process_frame
	#buttons.sort_custom(animator.buttons_array_sorting)
	#await animator.animate_buttons(buttons.duplicate(),true,0.16, Vector2(-20,0), Vector2.ZERO, 0.5)


	var resolutions = [
		Vector2i(1920,1080),
		Vector2i(1600,900),
		Vector2i(1280,720),
		Vector2i(640,360),
		Vector2i(320,180),
	]
	for res in resolutions:
		option_resolution.add_item("%dx%d" % [res.x, res.y])
		
	load_current_settings()
	
	option_resolution.item_selected.connect(_on_resolution_selected)
	option_fullscreen.toggled.connect(_on_fullscreen_toggled)
	option_borderless.toggled.connect(_on_borderless_toggled)
	option_vsync.toggled.connect(_on_vsync_toggled)
	back_button.pressed.connect(_on_back_pressed)

	
func load_current_settings():
	var mode = DisplayServer.window_get_mode()
	option_fullscreen.button_pressed = mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	option_borderless.button_pressed = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
	option_vsync.button_pressed = DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED
	
	var window_size = DisplayServer.window_get_size()
	for i in range(option_resolution.item_count):
		var res_text = option_resolution.get_item_text(i)
		var parts = res_text.split("x")
		if parts.size() == 2 and int(parts[0]) == window_size.x and int(parts[1]) == window_size.y:
			option_resolution.select(i)
			break
	
func _on_resolution_selected(index: int):
	var text = option_resolution.get_item_text(index)
	var parts = text.split("x")
	if parts.size() == 2:
		DisplayServer.window_set_size(Vector2i(int(parts[0]), int(parts[1])))
		
func _on_fullscreen_toggled(enabled: bool):
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
func _on_borderless_toggled(enabled: bool):
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, enabled)
	
func _on_vsync_toggled(enabled: bool):
	var mode = DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://esenas/MenuGUI/MenuPrincipal.tscn")
