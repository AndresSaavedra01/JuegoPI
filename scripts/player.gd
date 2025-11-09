extends CharacterBody3D
class_name player
# ==========================================================
# CONFIGURACIÓN GENERAL
# ==========================================================
@export var move_speed := 8.0
@export var rotation_speed := 10.0
@export var jump_force := 10.0
@export var double_jump_force := 12.0
@export var gravity_force := 20.0
@export var COYOTE_TIME := 0.2
@export var totalHearts : int = 5
@export var heartScene : = preload("res://esenas/heart.tscn")
@export var bubbleKnockbackForce : float = 40.0
@export var bubbleKnockbackUpForce : float = 5.0
@export var waterKnockbackForce : float = 10.0
@export var waterKnockbackUpForce : float = 1.0
@export var bubbleDamage : float = 5.0
@export var waterDamage : float = 0.5

# Sensibilidad de cámara
@export var mouse_sens_x := 0.5
@export var mouse_sens_y := 0.5
@export var camera_pitch_min := -60.0
@export var camera_pitch_max := 40.0

# Ataques
@export var bubble_rate := 0.3
@export var soap_rate := 0.3
@export var water_rate := 0.2
@export var melee_rate := 0.5
@export var melee_push := 5.0

# ==========================================================
# VARIABLES DE ESTADO
# ==========================================================
var camera_pitch := 0.0
var has_double_jumped := false
var can_attack := true
var is_attacking := false
var current_attack_mode := "Bubble"
var attack_modes := ["Bubble", "Soap", "Water", "Melee"]
var attack_mode_index := 0
var dead:= false
var combo_step := 0
var combo_window := 1
var combo_timer := 0.0
var in_combo := false
var coyote_timer := 0.0
var currentHeartIndex : int
var health : int
# ==========================================================
# REFERENCIAS A NODOS
# ==========================================================
@onready var camera_pivot := $camaraPivot
@onready var robot : skin = $robotV3
@onready var particles := $GPUParticles3D
@onready var hitbox := $robotV3/robotV3/rig/Skeleton3D/BoneAttachment3D/Hitbox
@onready var cooldown_timer := $Timer
@onready var heartsContiner : HBoxContainer = $Control/hearts
@onready var mira_sprite := $camaraPivot/EdgeSpringArm3D/RearSpringArm3D/Camera3D/Sprite3D
