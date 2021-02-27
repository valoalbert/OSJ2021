extends Node2D

var floor1_scene = load("res://FlatFloor1.tscn")
var floor2_scene = load("res://FlatFloor2.tscn")
var floor3_scene = load("res://IrregularFloor.tscn")
var floor4_scene = load("res://IrregularFloor2.tscn")

onready var bg_1 = $Backgrounds/Bg1
onready var bg_2 = $Backgrounds/Bg2
onready var floor1
onready var floor2
onready var player : KinematicBody2D = $Player
onready var player_anim_player = $Player/AnimPlayer
onready var player_state_machine = $Player/StateMachine
onready var bullet_spawner = $Player/BulletSpawner
onready var meters_counter_text = $CanvasLayer/Label

const MAX_SPEED : float = 300.0
const JUMP_H : float = -750.0
const GRAVITY : float = 30.0
const UP := Vector2(0, -1)

var motion := Vector2()
var is_death : bool
var is_shooting : bool
var state_machine

var bullet_scene := load("res://actors/Bullets/Bullet.tscn")

var rng = RandomNumberGenerator.new()
var floor_scenes
var meters_counter = 0

func _ready():
	meters_counter_text.text = str(meters_counter)
	state_machine = player_state_machine.get("parameters/playback")
	state_machine.start("run")
	floor_scenes = [floor1_scene, floor2_scene, floor3_scene, floor4_scene]
	floor1 = floor_scenes[0].instance()
	floor2 = floor_scenes[1].instance()
	floor2.global_position.x = 1007
	add_child(floor1)
	add_child(floor2)
	pass

func _process(_delta):
	meters_counter += 1
	meters_counter_text.text = "distance: " + str(meters_counter/100) 
	_move_background()
	_move_tilemap()
	_move_player()

	var projectiles_in_tree = get_tree().get_nodes_in_group("projectile")

	for projectile in projectiles_in_tree:
		projectile.global_position.x += 5
		pass

	pass


func _move_background():
	bg_1.global_position.x -= 1
	bg_2.global_position.x -= 1

	if bg_1.global_position.x < -1007:
		bg_1.global_position.x = 1007
		

	if bg_2.global_position.x < -1007:
		bg_2.global_position.x = 1007

	pass

func _move_tilemap():
	floor1.global_position.x -= 4
	floor2.global_position.x -= 4

	if floor1.global_position.x < -1007:
		floor1.queue_free()
		rng.randomize()
		var my_rng = rng.randi_range(0,3)
		floor1 = floor_scenes[my_rng].instance()
		floor1.global_position.x = 1007
		add_child(floor1)


	if floor2.global_position.x < -1007:
		floor2.queue_free()
		rng.randomize()
		var my_rng = rng.randi_range(0,3)
		floor2 = floor_scenes[my_rng].instance()
		floor2.global_position.x = 1007
		add_child(floor2)

	pass

func _move_player():
	motion.y += GRAVITY
	
	if is_shooting:
		state_machine.travel("shoot_n_run")
		_instance_bullet()
	else:
		state_machine.travel("run")
		
	if Input.is_action_pressed("ui_right"):
		motion.x = MAX_SPEED
	elif Input.is_action_pressed("ui_left"):
		motion.x = -MAX_SPEED * 1.2
	else:
		motion.x = 0
	pass
	
	if Input.is_action_just_pressed("shoot"):
		is_shooting = true
	pass
	
	if Input.is_action_just_released("shoot"):
		is_shooting = false
	pass

	if player.is_on_floor():
		if Input.is_action_just_pressed("player_jump"):
			motion.y = JUMP_H
		pass

	motion = player.move_and_slide(motion, UP)
	pass

func _instance_bullet():
	# Cambiar global transform por position
	var bullet_instance = bullet_scene.instance()
	get_parent().add_child(bullet_instance)
	bullet_instance.global_position = bullet_spawner.global_position
	bullet_instance.get_node("Hitbox").connect("body_entered", self, "_on_bullet_collide")

func _on_bullet_collide(body : Node):
	if body.is_in_group("enemy"):
		body.get_node("AnimatedSprite").animation = "hurt"
		body.get_node("AnimationPlayer").play("die")
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

	if event.is_action_pressed("reload"):
		get_tree().reload_current_scene()
