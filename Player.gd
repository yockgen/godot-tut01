extends Area2D

# Exported variables
#export (ShaderMaterial) var whiten_material
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
var is_finisher_active = false  # Track finisher state

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
	is_finisher_active = false
	$Info.visible = false
	
	fin01.visible = false
	fin01.get_node("CollisionShape2D").set_deferred("disabled", true)
	fin02.visible = false
	fin02.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	if not animated_sprite.is_connected("animation_finished", self, "_on_AnimatedSprite_animation_finished"):
		animated_sprite.connect("animation_finished", self, "_on_AnimatedSprite_animation_finished")

# Main process loop
func _process(delta):
	if current_state == State.FREEZE or is_animation_locked() or is_finisher_active:
		return  # Block processing during finisher
	
	velocity = Vector2.ZERO
	handle_input()
	handle_dodging()
	update_movement(delta)
	update_animation()

# Handle all player input
func handle_input():
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
	
	if Input.is_action_pressed("attack1"):
		is_attack = true
		attack_node.visible = true
		animated_sprite.play("fire_stand")
		play_attack_animation(true)
		return
	
	if Input.is_action_pressed("attack2"):
		play_finisher()
		return
	
	if Input.is_action_pressed("dance"):
		animated_sprite.play("dance")
		return
	
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
		speed = 400

# Update player movement
func update_movement(delta):
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		position += velocity * delta
		position.x = clamp(position.x, 0, screen_size.x)
		position.y = clamp(position.y, 0, screen_size.y)

# Update animations based on state
func update_animation():
	if action == "walk":
		if velocity.length() > 0:
			animated_sprite.play("walk")
		else:
			play_standing_pose()
	# Don’t override if action is "finisher" or "dance"

# Utility functions
func play_standing_pose():
	animated_sprite.play("stand")

func freeze(time: float) -> void:
	current_state = State.FREEZE
	collision_shape.disabled = true  # Invincibility by disabling collision
	Engine.time_scale = 1.0  # Reset time scale
	
	# Blink 10 times
	for i in range(10):
		#whiten_material.set_shader_param("whiten", true)
		self.visible = false
		yield(get_tree().create_timer(0.3), "timeout")
		
		#whiten_material.set_shader_param("whiten", false)
		self.visible = true
		yield(get_tree().create_timer(0.05), "timeout")
	
	yield(get_tree().create_timer(time / 2), "timeout")
	current_state = State.NORMAL
	collision_shape.disabled = false  # End invincibility
	animated_sprite.play("stand")  # Resume normal animation
	is_finisher_active = false  # Ensure reset in case of overlap

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
	play_attack_animation(false)
	action = "walk"
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
		is_finisher_active = false  # Reset explicitly
		action = "walk"
		current_state = State.NORMAL  # Ensure state reset

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
		is_finisher_active = false  # Reset explicitly
		action = "walk"
		current_state = State.NORMAL  # Ensure state reset

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
		return true
	return false

# Collision and signal handlers
func _on_Player_body_entered(_body):
	if is_finisher_active:
		return  # Ignore hits during finisher (optional, remove if you want hits to interrupt)
	$SndHitBy.play()
	stop_attack()
	emit_signal("GotHit")
	$AnimInfo.play()
	$Info.visible = true
	
	# Reset any lingering BULLET_TIME effects
	Engine.time_scale = 1.0
	$TimerBulletTime.stop()
	
	# Force stop and reset animation state
	animated_sprite.stop()
	animated_sprite.animation = "down"  # Set animation directly
	animated_sprite.frame = animated_sprite.frames.get_frame_count("down") - 1
	
	# Freeze and become invincible
	freeze(2.0)

func _on_AnimatedSprite_animation_finished():
	if animated_sprite.animation == "open_arm":
		fin01_trigger(false)
	elif animated_sprite.animation == "swing":
		fin02_trigger(false)
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
	animated_sprite.stop()  # Ensure animation resets
	play_standing_pose()    # Reset to standing pose
	is_finisher_active = false  # Ensure reset in case of overlap

func _on_AnimInfo_animation_finished(_anim_name):
	$Info.visible = false
