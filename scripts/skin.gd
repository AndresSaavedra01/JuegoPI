extends Node3D

@onready var animation_tree = $AnimationTree2
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@export var proyectil: PackedScene
@onready var cañonMelee := $"robotV3/rig/Skeleton3D/cañon-melee"
@onready var spawn_cañon := $robotV3/rig/Skeleton3D/Marker3D
@onready var cañon := $"robotV3/rig/Skeleton3D/cañon"
@onready var waterGun := $WaterGun


func idle():
	state_machine.travel("idle")

func run():
	state_machine.travel("run")

func fall():
	state_machine.travel("fall")

func jump():
	state_machine.travel("Jump")
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector3(0.9, 1.1, 0.9), 0.1)
	tween.tween_property(self, "scale", Vector3(1,1,1), 0.1)


func jump2():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation", Vector3(0, rotation.y + deg_to_rad(720) ,0),0.5)
	



func bubble_attack():
	#state_machine.travel("attack")
	animation_tree.set("parameters/attackpochito/request",true )


func water_attack(active: bool = false) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(animation_tree,"parameters/Blend2/blend_amount",int (active), 0.2)
	if active : waterGun.shoot()


func attackMelee():
	#state_machine.travel("attack")
	animation_tree.set("parameters/attack-melee/request",true )
	


func ataquar():
	var p = proyectil.instantiate()
	get_parent().get_parent().add_child(p)
	p.global_transform = spawn_cañon.global_transform
	p.apply_central_impulse(-spawn_cañon.global_transform.basis.z * -20)
	


func _on_animation_tree_2_animation_started(anim_name: StringName) -> void:
	print(anim_name)
	if anim_name == "attack":
		await get_tree().create_timer(0.3).timeout
		ataquar()
