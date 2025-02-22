extends Area2D

# Exported variables
export (ShaderMaterial) var whiten_material
export var speed = 400  # Pixels/sec

# Node references
onready var collision_shape = $CollisionShape2D
onready var animated_sprite = $AnimatedSprite
onready var attack_node = $Attack
onready var fin01 = $Finisher01
onready var fin02 = $Finisher02

# Screen and movement variables
var screen_size: Vector2
var velocity: Vector2 = Vector2.ZERO

# State and action variables
enum State { NORMAL, FREEZE, BULLET_TIME }
var current_state = State.NORMAL
var action = "walk"
var is_face_right = false
var is_attack = false
var is_bullet_time_chance = false
var move_unit = 1
var dash_count = 0
var is_dashing = false

# Signals
signal EnemyDefeated
signal BossGetHit
signal GotHit

# Called when the node enters the scene tree
func _ready():
	screen_size = get_viewport_rect().size
	attack_node.visible = false
	is_bullet_time_chance = false
	move_unit = 1
	dash_count = 0
	is_dashing = false
	$Info.visible = false
	
	fin01.visible = false
	fin01.get_node("CollisionShape2D").set_deferred("disabled", true)
	fin02.visible = false
	fin02.get_node("CollisionShape2D").set_deferred("disabled", true)

# Main process loop
func _process(delta):
	if current_state == State.FREEZE or is_animation_locked():
		return
	
	velocity = Vector2.ZERO
	handle_input()
	handle_dodging()
	update_movement(delta)
	update_animation()

# Handle all player input
func handle_input():
	# Movement
	if Input.is_action_pressed("ui_right"):
		action = "walk"
		velocity.x += move_unit
		is_face_right = true
		animated_sprite.flip_h = true  # Face right (assuming default sprite faces right)
		update_attack_position(true)
	elif Input.is_action_pressed("ui_left"):
		action = "walk"
		velocity.x -= move_unit
		is_face_right = false
		animated_sprite.flip_h = false  # Face left
		update_attack_position(false)
	
	# Attack 1
	if Input.is_action_pressed("attack1"):
		is_attack = true
		attack_node.visible = true
		animated_sprite.play("fire_stand")
		play_attack_animation(true)
		return
	
	# Attack 2 (Finisher)
	if Input.is_action_pressed("attack2"):
		play_finisher()
		return
	
	# Dance
	if Input.is_action_pressed("dance"):
		animated_sprite.play("dance")
		return
	
	# Release actions
	if Input.is_action_just_released("attack1") or Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right"):
		stop_attack()

# Handle dodging mechanics
func handle_dodging():
	if Input.is_action_just_pressed("dodge") and action != "dash" and not is_dashing:
		collision_shape.set_deferred("disabled", true)
		dash_count = 15
		action = "dash"
		is_dashing = true
		$SndDash.play()
		if is_bullet_time_chance:
			entered_bullet_time(0.3)
			speed = speed * 16
		else:
			speed = speed * 4
	
	if dash_count > 0:
		dash_count = max(0, dash_count - 1)
		var dash_speed = speed * (12 if is_bullet_time_chance else 4)
		velocity.x = (move_unit if !is_face_right else -move_unit) * dash_speed
	else:
		is_dashing = false
		collision_shape.set_deferred("disabled", false)
		speed = 400  # Reset speed after dash

# Update player movement
func update_movement(delta):
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		position += velocity * delta
		position.x = clamp(position.x, 0, screen_size.x)
		position.y = clamp(position.y, 0, screen_size.y)

# Update animations based on state
func update_animation():
	if velocity.length() > 0 and action == "walk":
		animated_sprite.play(action)
	elif action == "walk":
		play_standing_pose()

# Utility functions
func play_standing_pose():
	animated_sprite.play("stand")

func freeze(time: float) -> void:
	current_state = State.FREEZE
	collision_shape.disabled = true
	whiten_material.set_shader_param("whiten", true)
	yield(get_tree().create_timer(time / 2), "timeout")
	whiten_material.set_shader_param("whiten", false)
	yield(get_tree().create_timer(time / 2), "timeout")
	current_state = State.NORMAL
	collision_shape.disabled = false
	play_standing_pose()

func entered_bullet_time(time: float) -> void:
	current_state = State.BULLET_TIME
	collision_shape.disabled = true
	Engine.time_scale = time
	$TimerBulletTime.start(time)

func start(pos):
	position = pos
	show()
	collision_shape.disabled = false

func update_attack_position(facing_right: bool):
	var attack_sprite = attack_node.get_node("AnimatedSpriteAttack")
	var attack_collision = attack_node.get_node("CollisionShape2D")
	attack_sprite.flip_h = facing_right
	attack_sprite.position.x = animated_sprite.position.x + (200 if facing_right else -200)
	attack_collision.position.x = animated_sprite.position.x + (200 if facing_right else -200)

func play_attack_animation(play: bool):
	var attack_sprite = attack_node.get_node("AnimatedSpriteAttack")
	var attack_sound = attack_node.get_node("AttackSound")
	var attack_collision = attack_node.get_node("CollisionShape2D")
	if play:
		attack_sprite.play()
		attack_collision.disabled = false
		if not attack_sound.playing:
			attack_sound.play()
	else:
		attack_sprite.stop()
		attack_sound.stop()
		attack_collision.disabled = true

func stop_attack():
	is_attack = false
	attack_node.visible = false
	play_standing_pose()
	play_attack_animation(false)

func fin01_trigger(enable: bool):
	if enable:
		animated_sprite.play("open_arm")
		fin01.play()
		fin01.visible = true
		fin01.get_node("CollisionShape2D").set_deferred("disabled", false)
	else:
		fin01.stop()
		fin01.visible = false
		fin01.get_node("CollisionShape2D").set_deferred("disabled", true)

func fin02_trigger(enable: bool):
	if enable:
		animated_sprite.play("swing")
		fin02.play(animated_sprite.flip_h)
		fin02.visible = true
		fin02.get_node("CollisionShape2D").set_deferred("disabled", false)
	else:
		fin02.visible = false
		fin02.get_node("CollisionShape2D").set_deferred("disabled", true)

func play_finisher():
	var roulette = get_parent().get_node("FinisherRoulette")
	var idx = roulette.get_node("AnimatedSprite").get_frame()
	if idx == 3:
		fin01_trigger(true)
	else:
		fin02_trigger(true)

func is_animation_locked() -> bool:
	var anim = animated_sprite.animation
	var is_playing = animated_sprite.is_playing()
	var frame = animated_sprite.frame
	var frame_count = animated_sprite.frames.get_frame_count(anim)
	
	if anim == "swing" and is_playing and frame < frame_count - 1:
		return true
	if anim == "dance" and is_playing and frame < frame_count - 1:
		return true
	if anim == "open_arm" and is_playing and frame < frame_count - 1:
		if frame == frame_count - 2:
			fin01_trigger(false)
		return true
	return false

# Collision and signal handlers
func _on_Player_body_entered(_body):
	$SndHitBy.play()
	stop_attack()
	emit_signal("GotHit")
	$AnimInfo.play()
	$Info.visible = true
	animated_sprite.play("down")
	freeze(1.0)

func _on_AnimatedSprite_animation_finished():
	action = "walk"
	current_state = State.NORMAL

func _on_Attack_body_entered(body):
	body.linear_velocity = Vector2.ZERO
	body.get_node("CollisionShape2D").set_deferred("disabled", true)
	attack_node.get_node("CollisionShape2D").set_deferred("disabled", true)
	body.setEnemyDown(body.name)
	emit_signal("EnemyDefeated")

func _on_Attack_area_entered(area):
	if attack_node.visible and area.name == "Boss01":
		emit_signal("BossGetHit")

func _on_Area2DEnemyCloser_body_entered(body):
	is_bullet_time_chance = true
	body.get_node("Alerting").set_deferred("visible", true)

func _on_Area2DEnemyCloser_body_exited(_body):
	is_bullet_time_chance = false

func _on_TimerBulletTime_timeout():
	collision_shape.disabled = false
	Engine.time_scale = 1.0
	current_state = State.NORMAL

func _on_AnimInfo_animation_finished(_anim_name):
	$Info.visible = false
