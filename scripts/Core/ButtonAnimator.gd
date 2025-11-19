extends Node
class_name ButtonAnimator

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
		
