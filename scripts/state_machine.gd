extends Node

var current_state: states = states.IDLE

enum states{
	IDLE,
	RUN,
	JUMP,
	JUMP_2,
	FALL,
	ATTACK_BUBBLE,
	ATTACK_WATER,
	ATTACK_MELEE,
	ATTACK_SOAP
} 


func _physics_process(delta: float) -> void:
	
	match  current_state:
		states.IDLE : idle()
		states.RUN : run()
		states.JUMP : jump()
		states.JUMP_2 : jump_2()
		states.ATTACK_BUBBLE : bubble()
		states.ATTACK_WATER : water()
		states.ATTACK_MELEE : melee()
		states.ATTACK_SOAP : soap()

func idle():
	pass

func run():
	pass

func jump():
	pass

func jump_2():
	pass

func bubble():
	pass

func water():
	pass

func melee():
	pass

func soap():
	pass
