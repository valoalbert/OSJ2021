extends Node2D

signal remove_bullet

var floor1_scene = load("res://FlatFloor1.tscn")
var floor2_scene = load("res://FlatFloor2.tscn")
var floor3_scene = load("res://IrregularFloor.tscn")
var floor4_scene = load("res://IrregularFloor2.tscn")
var enemy_scene = load("res://actors/enemies/Tomato.tscn")

onready var bg_1 = $Backgrounds/Bg1
onready var bg_2 = $Backgrounds/Bg2
onready var floor1
onready var floor2
onready var player : KinematicBody2D = $Player
onready var player_anim_player = $Player/AnimPlayer
onready var player_state_machine = $Player/StateMachine
onready var player_notifier = $Player/notifier
onready var bullet_spawner = $Player/BulletSpawner
onready var meters_counter_text = $CanvasLayer/Label
onready var game_over_label = $GameOver/Control/Label
onready var start_label = $GameOver/Control/Label2
onready var shoot_Sfx = $ShotSfx
onready var explosion_sfx = $Explosion
onready var menu_music = $Menu
onready var gameplay_music = $Gameplay
onready var lose_music = $Gameoversfx
onready var volume = $GameOver/Control/Volume/HSlider.value
onready var volume_slider = $GameOver/Control/Volume/HSlider

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
var velocity_counter = 0
var map_velocity = 4
var game_started := false

func _init():
	floor_scenes = [floor1_scene, floor2_scene, floor3_scene, floor4_scene]
	floor1 = floor_scenes[0].instance()
	floor2 = floor_scenes[1].instance()
	floor2.global_position.x = 1007


func _ready():
	player.get_node("Hurtbox").connect("body_entered", self, "_on_player_die")
	volume_slider.connect("value_changed", self, "_on_volume_changed")
	game_over_label.visible = false
	meters_counter_text.text = str(meters_counter)
	state_machine = player_state_machine.get("parameters/playback")
	state_machine.start("idle")
	
	add_child(floor1)
	add_child(floor2)
	floor1.show_behind_parent = true
	floor2.show_behind_parent = true
	menu_music.playing = true

	shoot_Sfx.volume_db = volume
	gameplay_music.volume_db = volume
	lose_music.volume_db = volume
	menu_music.volume_db = volume
	pass

func _process(_delta):
	if !game_started:
		if Input.is_action_just_pressed("ui_accept"):
			meters_counter_text.visible = true
			$GameOver/Control/Volume.visible = false
			start_label.visible = false
			game_started = true
			state_machine.travel("run")
			menu_music.playing = false
			gameplay_music.playing = true
	else:
		if !player_notifier.is_on_screen():
			game_over()

		meters_counter += 1
		velocity_counter += 1

		meters_counter_text.text = "score: " + str(meters_counter/100)

		if velocity_counter > 2000:
			map_velocity = map_velocity*1.3
			velocity_counter = 0

		_move_background()
		_move_tilemap(map_velocity)
		_move_player()

		var projectiles_in_tree = get_tree().get_nodes_in_group("projectile")

		for projectile in projectiles_in_tree:
			projectile.global_position.x += 5
			if projectile.global_position.x > 1009:
				projectile.queue_free()
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

func _move_tilemap(velocity):
	floor1.global_position.x -= velocity
	floor2.global_position.x -= velocity

	if floor1.global_position.x < -1007:
		floor1.queue_free()
		rng.randomize()
		var my_rng = rng.randi_range(0,3)
		floor1 = floor_scenes[my_rng].instance()
		floor1.global_position.x = 1007
		add_child(floor1)
		floor1.show_behind_parent = true
		var enemy_instance = enemy_scene.instance()
		enemy_instance.global_position = Vector2(0,0)
		my_rng = rng.randi_range(1,3)
		print(my_rng)
		floor1.get_node("spot"+str(my_rng)).add_child(enemy_instance)


	if floor2.global_position.x < -1007:
		floor2.queue_free()
		rng.randomize()
		var my_rng = rng.randi_range(0,3)
		floor2 = floor_scenes[my_rng].instance()
		floor2.global_position.x = 1007
		add_child(floor2)
		floor2.show_behind_parent = true
		var enemy_instance = enemy_scene.instance()
		enemy_instance.global_position = Vector2(0,0)
		my_rng = rng.randi_range(1,3)
		print(my_rng)
		floor2.get_node("spot"+str(my_rng)).add_child(enemy_instance)

	pass

func _move_player():
	motion.y += GRAVITY
	if is_death:
		state_machine.travel("die")
	else:
		if is_shooting:
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
			shoot_Sfx.playing = true
			state_machine.travel("shoot_n_run")
		else:
			is_shooting = false


		if player.is_on_floor():
			if Input.is_action_just_pressed("player_jump"):
				motion.y = JUMP_H
			pass

	motion = player.move_and_slide(motion, UP)
	pass

func _instance_bullet():
	var bullet_instance = bullet_scene.instance()
	get_parent().add_child(bullet_instance)
	bullet_instance.global_position = bullet_spawner.global_position
	bullet_instance.get_node("Hitbox").connect("body_entered", self, "_on_bullet_collide")
	print(bullet_instance.global_position.x)



func _on_bullet_collide(body : Node):
	if body.is_in_group("enemy"):
		explosion_sfx.playing = true
		body.get_node("AnimatedSprite").animation = "hurt"
		body.get_node("AnimationPlayer").play("die")

	pass

func _input(event):
	#if event.is_action_pressed("ui_cancel"):
		#get_tree().quit()

	if event.is_action_pressed("reload"):
		get_tree().paused = false
		get_tree().reload_current_scene()


func game_over():
	game_over_label.visible = true
	meters_counter_text.visible = false
	gameplay_music.playing = false
	map_velocity = 0
	lose_music.playing = true
	
func _on_player_die(body):
	if body.is_in_group("enemy"):
		is_death = true
		game_over()

func _on_volume_changed(volume):
	shoot_Sfx.volume_db = volume
	gameplay_music.volume_db = volume
	lose_music.volume_db = volume
	menu_music.volume_db = volume
