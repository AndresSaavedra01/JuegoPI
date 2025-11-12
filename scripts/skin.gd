extends Node3D
class_name skin
@onready var animation_tree = $AnimationTree2
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var cañon = $"Cañon"
@onready var cañonMelee := $"robotV3/rig/Skeleton3D/cañon-melee"
@onready var waterGun := $WaterGun
@onready var bubble := preload("res://esenas/burbuja.tscn")
@onready var soap := preload("res://esenas/soap.tscn")
@onready var water := preload("res://esenas/water_proyectil.tscn")
signal animation_finished


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

func die():
	state_machine.travel("Die")

func jump2():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation", Vector3(0, rotation.y + deg_to_rad(720) ,0),0.4)
	

func bubble_attack():
	animation_tree.set("parameters/one_shoot/request",true )


func soap_attack():
	cañon.speed = 30.0
	animation_tree.set("parameters/one_shoot/request",true )


func water_attack(damage : float, knockbackForce : float, knockbackUpForce : float, active: bool = false) -> void:
	var tween = get_tree().create_tween()
	cañon.speed = 20.0
	cañon.proyectil = water
	waterGun.proyectil = water
	if active : 
		#cañon.ataquar(damage,knockbackForce,knockbackUpForce)
		waterGun.ataquar(damage, knockbackForce, knockbackUpForce)
	tween.tween_property(animation_tree,"parameters/hold_shoot/blend_amount",int (active), 0.2)


func attackMelee():
	#state_machine.travel("attack")
	cañonMelee.visible = true
	animation_tree.set("parameters/attack-melee/request", true )
	

func attackMelee_2():
	#state_machine.travel("attack")
	animation_tree.set("parameters/attack-melee-2/request",true )
	

func attackMelee_3():
	animation_tree.set("parameters/attack-melee-3/request",true )



func _on_animation_tree_2_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("meele"):
		emit_signal("animation_finished")
	
	if anim_name == "Die":
		emit_signal("animation_finished")
	
