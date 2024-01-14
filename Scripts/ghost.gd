extends CharacterBody2D

class_name Ghost


@onready var sprite_2d = $Sprite2D
@onready var panel = $Panel
@onready var energy_bar = %EnergyBar
@onready var hurt_box = $HurtBox

@export var immobile: bool = false
@export var SPEED = 20.0
@export var team: Globals.Teams

var player_to_attack:CharacterBody2D = null
var taking_damage:bool = false

var sprite2d_shader: ShaderMaterial

func _ready():
	player_to_attack = Globals.currentPlayer
	energy_bar.value = 0
	sprite2d_shader = sprite_2d.get("material")
	hurt_box.initialize_team(team)
	
func _physics_process(_delta):
	
	if energy_bar.value <= 0:
		energy_bar.visible = false
	else:
		energy_bar.visible = true
		
	if taking_damage:
		pass
	else:
		adjust_energy(-1)

	
	if player_to_attack != null:

		var direction = global_position.direction_to(player_to_attack.global_position)
		if direction.x > 0:
			sprite_2d.flip_h = true
		elif direction.x < 0:
			sprite_2d.flip_h = false	
		
		if !immobile:
			velocity = direction * SPEED
		
	elif Globals.currentPlayer != null:
		player_to_attack = Globals.currentPlayer

	move_and_slide()

func take_damage(damage_power):
	taking_damage = true
	panel.visible = false
	adjust_energy(damage_power)
	if energy_bar.value >= 100:
		queue_free()

func stop_damaging():
	taking_damage = false

func targetted():
	panel.visible = true
	Globals.currentTargetedGhost = self
	
func untargetted():
	panel.visible = false
	Globals.currentTargetedGhost = null
	taking_damage = false

func adjust_energy(adjustment):
	energy_bar.value += adjustment
	sprite_2d.scale = Vector2(1,1) * (1 + energy_bar.value / 400.0)
	sprite2d_shader.set_shader_parameter("intensity", energy_bar.value / 250.0)
	if energy_bar.value >=80:
		sprite_2d.region_rect.position.x = 320
	else:
		sprite_2d.region_rect.position.x = 288

