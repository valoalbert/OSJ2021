extends Node2D

onready var bg_1 = $Bg1
onready var bg_2 = $Bg2
onready var flat_floor1 = $FlatFloor1
onready var flat_floor2 = $FlatFloor2
onready var irregular_floor = $IrregularFloor
onready var player : KinematicBody2D = $Player
onready var player_anim_player = $Player/AnimPlayer
onready var player_state_machine = $Player/StateMachine

const MAX_SPEED : float = 300.0
const JUMP_H : float = -700.0
const GRAVITY : float = 30.0
const UP := Vector2(0, -1)

var motion := Vector2()
var is_death : bool
var is_shooting : bool
var state_machine


func _ready():
	state_machine = player_state_machine.get("parameters/playback")
	state_machine.start("run")
	pass

func _process(_delta):
	_move_background()
	_move_tilemap()
	_move_player()

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
	flat_floor1.global_position.x -= 4
	flat_floor2.global_position.x -= 4

	if flat_floor1.global_position.x < -1007:
		flat_floor1.global_position.x = 1007

	if flat_floor2.global_position.x < -1007:
		flat_floor2.global_position.x = 1007

	pass

func _move_player():
	motion.y += GRAVITY
	
	if is_shooting:
		state_machine.travel("shoot_n_run")
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



func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
