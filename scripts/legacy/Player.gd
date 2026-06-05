extends Area2D

# Exported variables
#export (ShaderMaterial) var whiten_material
@export var speed = 400  # Pixels/sec (overridden by GameConfig at runtime)

# Node references
@onready var collision_shape = $CollisionShape2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_node = $Attack
@onready var fin01 = $Finisher01
@onready var fin02 = $Finisher02

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
var is_finisher_active = false

# Signals
signal EnemyDefeated
signal BossGetHit
signal GotHit

func _ready():
	screen_size = get_viewport_rect().size
	speed = GameConfig.PLAYER_SPEED
	attack_node.visible = false
	is_bullet_time_chance = false
	move_unit = 1
	dash_count = 0
	is_dashing = false
	is_finisher_active = false
	$Info.visible = false
	fin01.visible = false
	fin01.get_node("CollisionShape2D").set_deferred("disabled", true)
	fin02.visible = false
	fin02.get_node("CollisionShape2D").set_deferred("disabled", true)
	if not animated_sprite.is_connected("animation_finished", Callable(self, "_on_AnimatedSprite_animation_finished")):
		animated_sprite.connect("animation_finished", Callable(self, "_on_AnimatedSprite_animation_finished"))

func _process(delta):
	if current_state == State.FREEZE or is_animation_locked() or is_finisher_active:
		return
	velocity = Vector2.ZERO
	handle_input()
	handle_dodging()
	update_movement(delta)
	update_animation()

func handle_input():
	if action == "dance":
		return
	if Input.is_action_just_pressed("attack1"):
		if action != "attack":
			is_attack = true
			action = "attack"
			attack_node.visible = true
			if animated_sprite.frames.has_animation("fire_stand"):
				animated_sprite.play("fire_stand")
			play_attack_animation(true)
		return
	if Input.is_action_just_released("attack1"):
		stop_attack()
	if action == "attack":
		return
	if Input.is_action_pressed("ui_right"):
		action = "walk"
		velocity.x += move_unit
		is_face_right = true
		animated_sprite.flip_h = true
		update_attack_position(true)
	elif Input.is_action_pressed("ui_left"):
		action = "walk"
		velocity.x -= move_unit
		is_face_right = false
		animated_sprite.flip_h = false
		update_attack_position(false)
	if Input.is_action_just_pressed("attack2"):
		play_finisher()
		return
	if Input.is_action_just_pressed("dance"):
		action = "dance"
		if animated_sprite.frames.has_animation("dance"):
			animated_sprite.play("dance")
		return

func handle_dodging():
	if Input.is_action_just_pressed("dodge") and not is_dashing:
		collision_shape.set_deferred("disabled", true)
		dash_count = int(GameConfig.PLAYER_DASH_DURATION * 100)
		action = "dash"
		is_dashing = true
		if animated_sprite.frames.has_animation("dash"):
			animated_sprite.play("dash")
		$SndDash.play()
		if is_bullet_time_chance:
			entered_bullet_time(0.3)
			speed = GameConfig.PLAYER_SPEED * GameConfig.PLAYER_BULLET_TIME_DASH_MULTIPLIER
		else:
			speed = GameConfig.PLAYER_SPEED * GameConfig.PLAYER_NORMAL_DASH_MULTIPLIER
	if dash_count > 0:
		dash_count -= 1
		velocity.x = (move_unit if !is_face_right else -move_unit) * speed
	else:
		if is_dashing:
			is_dashing = false
			action = "walk"
			collision_shape.set_deferred("disabled", false)
			speed = GameConfig.PLAYER_SPEED

func update_movement(delta):
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		position += velocity * delta
		position.x = clamp(position.x, 0, screen_size.x)
		position.y = clamp(position.y, 0, screen_size.y)

func update_animation():
	if action == "attack" or action == "finisher" or action == "dance":
		return
	if action == "dash":
		if animated_sprite.animation != "dash":
			if animated_sprite.frames.has_animation("dash"):
				animated_sprite.play("dash")
		return
	if velocity.length() > 0:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "stand":
			play_standing_pose()

func play_standing_pose():
	animated_sprite.play("stand")

func freeze(time: float) -> void:
	current_state = State.FREEZE
	collision_shape.disabled = true
	Engine.time_scale = 1.0
	for _i in range(10):
		self.visible = false
		await get_tree().create_timer(0.3).timeout
		self.visible = true
		await get_tree().create_timer(0.05).timeout
	await get_tree().create_timer(time / 2).timeout
	current_state = State.NORMAL
	collision_shape.disabled = false
	animated_sprite.play("stand")
	is_finisher_active = false

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
	action = "walk"
	attack_node.visible = false
	play_attack_animation(false)
	play_standing_pose()

func fin01_trigger(enable: bool):
	if enable:
		action = "finisher"
		is_finisher_active = true
		if animated_sprite.frames.has_animation("open_arm"):
			animated_sprite.play("open_arm")
		else:
			print("ERROR: open_arm animation not found in SpriteFrames")
		fin01.play()
		fin01.visible = true
		fin01.get_node("CollisionShape2D").set_deferred("disabled", false)
	else:
		fin01.stop()
		fin01.visible = false
		fin01.get_node("CollisionShape2D").set_deferred("disabled", true)
		animated_sprite.play("stand")
		is_finisher_active = false
		action = "walk"
		current_state = State.NORMAL

func fin02_trigger(enable: bool):
	if enable:
		action = "finisher"
		is_finisher_active = true
		if animated_sprite.frames.has_animation("swing"):
			animated_sprite.play("swing")
		else:
			print("ERROR: swing animation not found in SpriteFrames")
		fin02.play(animated_sprite.flip_h)
		fin02.visible = true
		fin02.get_node("CollisionShape2D").set_deferred("disabled", false)
	else:
		fin02.visible = false
		fin02.get_node("CollisionShape2D").set_deferred("disabled", true)
		animated_sprite.play("stand")
		is_finisher_active = false
		action = "walk"
		current_state = State.NORMAL

func play_finisher():
	var roulette = get_parent().get_node("FinisherRoulette")
	var idx = roulette.get_selected_finisher()
	if idx == 3:
		fin01_trigger(true)
	else:
		fin02_trigger(true)

func is_animation_locked() -> bool:
	var anim = animated_sprite.animation
	if animated_sprite.is_playing() and anim in ["swing", "dance", "open_arm"]:
		var frame = animated_sprite.frame
		var frame_count = animated_sprite.frames.get_frame_count(anim)
		return frame < frame_count - 1
	return false

func _on_Player_body_entered(_body):
	if is_finisher_active:
		return
	$SndHitBy.play()
	stop_attack()
	emit_signal("GotHit")
	$AnimInfo.play()
	$Info.visible = true
	Engine.time_scale = 1.0
	$TimerBulletTime.stop()
	animated_sprite.stop()
	animated_sprite.animation = "down"
	animated_sprite.frame = animated_sprite.frames.get_frame_count("down") - 1
	freeze(2.0)

func _on_AnimatedSprite_animation_finished():
	if animated_sprite.animation == "open_arm":
		fin01_trigger(false)
	elif animated_sprite.animation == "swing":
		fin02_trigger(false)
	elif animated_sprite.animation == "dash":
		return
	elif animated_sprite.animation == "dance":
		action = "walk"
		play_standing_pose()
	else:
		action = "walk"
		current_state = State.NORMAL
		play_standing_pose()

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
	animated_sprite.stop()
	play_standing_pose()
	is_finisher_active = false

func _on_AnimInfo_animation_finished(_anim_name):
	$Info.visible = false
