extends RigidBody3D


func empujar(dir: Vector3, fuerza:float)-> void:
	apply_central_force(dir*fuerza)

func impulsar(dir: Vector3, fuerza:float)-> void:
	apply_impulse(dir*fuerza)
