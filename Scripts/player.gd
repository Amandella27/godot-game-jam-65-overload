extends CharacterBody2D

class_name Player

signal player_health_changed(new_health)
signal player_max_health_changed(new_max_health)
signal player_death

enum PlayerMoveStates{IDLE, WALKING, DODGE_ROLLING, STUNNED, PAUSED}
enum PlayerAttackStates{FIRING, NOT_FIRING}

@onready var sprite_2d = $Sprite2D
@onready var dps_timer = $DPSTimer
@onready var animation_player = $AnimationPlayer
@onready var weapon_1 = $Weapon1
@onready var weapon_muzzle = $WeaponMuzzle
@onready var hitbox_component = $HitboxComponent
@onready var beam_container = $BeamContainer

@onready var health_component:HealthComponent = $HealthComponent

@export var team: Globals.Teams
@export var weapon_inv: WpnInv
@export var item_inv: ItemInv
@export var upg_inv: UpgInv


const SPEED = 100.0
const JUMP_VELOCITY = -400.0

var maxFireDistance = 100.0
var damagePower = 5.0
var speedIncrease = 1
var healthIncrease: int
var damagingGhost: Ghost = null
var currentMoveState: PlayerMoveStates
var currentAttackState: PlayerAttackStates
var tractorBeam: Line2D

var paused: bool = false

func _ready():
	currentMoveState = PlayerMoveStates.IDLE
	hitbox_component.initialize_team(team)
	emit_signal("player_health_changed",health_component.get_health())

func _physics_process(_delta):
	
	match currentMoveState:
		
		PlayerMoveStates.IDLE:
			
			var direction:Vector2 = Input.get_vector("left", "right", "up", "down")
			if direction:
				currentMoveState = PlayerMoveStates.WALKING
				return
			
			velocity.x = move_toward(velocity.x, 0, SPEED * speedIncrease)
			velocity.y = move_toward(velocity.y, 0, SPEED * speedIncrease)
			
			animation_player.play("idle")
			
			select_target()
			check_damaging_ghost()
			move_tractor_beam()
			
			move_and_slide()
			
		PlayerMoveStates.WALKING:
			
			var direction:Vector2 = Input.get_vector("left", "right", "up", "down")
			if direction == Vector2.ZERO:
				currentMoveState = PlayerMoveStates.IDLE
				return
			
			else:
				direction = direction.normalized()
				if direction.x > 0 and damagingGhost == null:
					sprite_2d.flip_h = true
					weapon_1.scale.x = -1
					weapon_muzzle.position.x = 16
				elif direction.x < 0 and damagingGhost == null:
					sprite_2d.flip_h = false
					weapon_1.scale.x = 1
					weapon_muzzle.position.x = -16
				velocity.x = direction.x * SPEED * speedIncrease
				velocity.y = direction.y * SPEED * speedIncrease
				animation_player.play("walking")
			
			select_target()
			check_damaging_ghost()
			move_tractor_beam()
			
			move_and_slide()
			
		PlayerMoveStates.DODGE_ROLLING:
			pass

		PlayerMoveStates.PAUSED:
			animation_player.play("idle")
		
	if health_component.current_health <= 0:
		player_death.emit()
		
func select_target():
	if Input.is_action_just_pressed("fire_beam") and Globals.currentTargetedGhost != null:
		damagingGhost = Globals.currentTargetedGhost
		
		var start_point = weapon_muzzle.position
		var end_point = damagingGhost.global_position - global_position
		
		tractorBeam = Line2D.new()
		tractorBeam.add_point(start_point)
		tractorBeam.add_point(end_point/2)
		tractorBeam.add_point(end_point)
		tractorBeam.default_color = Color.AQUAMARINE
		tractorBeam.width = 5
		tractorBeam.begin_cap_mode = Line2D.LINE_CAP_ROUND
		tractorBeam.end_cap_mode = Line2D.LINE_CAP_ROUND
		beam_container.add_child(tractorBeam)
		
	
func check_damaging_ghost():
	
	if damagingGhost != null:
		if Input.is_action_just_released("fire_beam") or global_position.distance_to(damagingGhost.global_position) > maxFireDistance:
			damagingGhost.stop_damaging()
			damagingGhost = null
			#tractorBeam.queue_free()
			for i in beam_container.get_children():
				i.queue_free()
			
		elif dps_timer.is_stopped():
			damagingGhost.take_damage(damagePower)
			dps_timer.start()
	else:
		if tractorBeam != null:
			tractorBeam.queue_free()

func move_tractor_beam():
	if tractorBeam != null and damagingGhost != null:
		var start_point = weapon_muzzle.position
		var end_point = damagingGhost.global_position - global_position
		var points_size = tractorBeam.points.size()
		tractorBeam.points[points_size - 3] = start_point
		tractorBeam.points[points_size - 2] = Vector2((end_point.x + randi_range(-5, 5)) / 2, (end_point.y + randi_range(-5,5)) / 2)
		tractorBeam.points[points_size - 1] = end_point


func collect_item(item, amount):
	item_inv.insert(item, amount)

func collect_upgrade(upgrade, amount):
	upg_inv.insert(upgrade, amount)
	if upgrade.name == "Arc Extender":
		maxFireDistance += 5
	if upgrade.name == "Beam Battery+":
		damagePower += 1
	if upgrade.name == "Wraith Boots":
		speedIncrease += .1
	if upgrade.name == "Spectre Coat":
		healthIncrease = 25
		health_component.adjust_max_health(healthIncrease)
		health_component.adjust_health(healthIncrease)
		
		sprite_2d.texture = preload("res://Assets/bungus-spectrecoat.png")
		
func _on_health_component_health_changed(new_health):
	emit_signal("player_health_changed", new_health)
	
func _on_health_component_max_health_changed(new_max_health):
	player_max_health_changed.emit(new_max_health)
	
func pause():
	currentMoveState = PlayerMoveStates.PAUSED

func unpause():
	currentMoveState = PlayerMoveStates.IDLE



