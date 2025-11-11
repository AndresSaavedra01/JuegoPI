class_name TrashEnemySkin
extends Node3D

var material : Material
var arms_material : Material
@onready var meshes : Array[MeshInstance3D] = [$Armature/Skeleton3D/body, $Armature/Skeleton3D/knot/knot, $Armature/Skeleton3D/arms_001, $Armature/Skeleton3D/arms_002, $Armature/Skeleton3D/arms_003, $Armature/Skeleton3D/arms_004, $Armature/Skeleton3D/bag_ear, $Armature/Skeleton3D/bottle]
@onready var arms : MeshInstance3D = $Armature/Skeleton3D/arms

func _ready() -> void:
	material = meshes[0].mesh.surface_get_material(0).duplicate()
	arms_material = arms.mesh.surface_get_material(0).duplicate()
	for mesh in meshes:
		print(mesh.name)
		mesh.set_surface_override_material(0, material)
	arms.set_surface_override_material(0, arms_material)
			
func emission_red():
	material.set("emission", Color.RED)
	
func emission_black():
	material.set("emission", Color.BLACK)
	
func emission_arms_green():
	arms_material.set("emission", Color(69, 255,0))
	
func emission_arms_red():
	arms_material.set("emission", Color.RED)
	
func set_emission(value : bool) -> void:
	material.set("emission_enabled", value)
	arms_material.set("emission_enabled", value)
