extends Control

@export var back_button: Button

func _ready():
	#var animator = ButtonAnimator.new()
	#add_child(animator)
	#
	#var buttons: Array = animator.get_all_buttons(self)
	#await get_tree().process_frame
	#buttons.sort_custom(animator.buttons_array_sorting)
	#await animator.animate_buttons(buttons.duplicate(),true,0.16, Vector2(-20,0), Vector2.ZERO, 0.5)

	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://esenas/MenuGUI/MenuPrincipal.tscn")
