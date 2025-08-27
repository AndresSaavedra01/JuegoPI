extends Node3D

@onready var animation_tree = $AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

func idle():
	state_machine.travel("idle")

func run():
	state_machine.travel("run")

func fall():
	state_machine.travel("fall")

func jump():
	state_machine.travel("Jump")

func attack():
	animation_tree.set("parameters/attackpochito/request",true )
	
