extends Node3D

@onready var animation_tree = $AnimationTree2
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@export var proyectil: PackedScene
@onready var spawn_cañon = $rig/Skeleton3D/Marker3D

func idle():
	state_machine.travel("idle")

func run():
	state_machine.travel("run")

func fall():
	state_machine.travel("fall")

func jump():
	state_machine.travel("Jump")

func attack():
	#state_machine.travel("attack")
	animation_tree.set("parameters/attackpochito/request",true )
	


func ataquar():
	var p = proyectil.instantiate()
	get_parent().add_child(p)
	p.global_transform = spawn_cañon.global_transform
	p.apply_central_impulse(-spawn_cañon.global_transform.basis.z * -20)	


func _on_animation_tree_2_animation_started(anim_name: StringName) -> void:
	if anim_name == "attack":
		await get_tree().create_timer(0.3).timeout
		ataquar()
