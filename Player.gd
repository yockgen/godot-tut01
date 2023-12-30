extends Area2D

export (ShaderMaterial) var whiten_material
onready var collision_shape = $CollisionShape2D

export var speed = 400  # How fast the player will move (pixels/sec).
var screen_size  # Size of the game window

var action = "walk"
var state = "normal"
var isFaceRight = false
var isAttack = false
var isBulletTimeChance = false
var iMoveUnit = 1
var iDashCnt = 0
var iDashing = false

signal EnemyDefeated
signal BossGetHit
signal GotHit

onready var fin01 = $Finisher01
onready var fin02 = $Finisher02

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size	
	$Attack.visible = false
	isBulletTimeChance = false
	iMoveUnit = 1
#	timer.connect("timeout", self, "unfreeze")
	iDashCnt = 0
	iDashing = false
	$Info.visible = false
	
	fin01.visible = false
	fin01.get_node("CollisionShape2D").set_deferred("disabled",true)	
	fin02.visible = false
	fin02.get_node("CollisionShape2D").set_deferred("disabled",true)
 

func freeze(time: float) -> void: 
	$CollisionShape2D.disabled = true
	
	whiten_material.set_shader_param("whiten", true)
	yield(get_tree().create_timer(time/2), "timeout")
	whiten_material.set_shader_param("whiten", false)
		
		
	yield(get_tree().create_timer(time/2), "timeout")
	state = "normal"
	$CollisionShape2D.disabled = false	
	$AnimatedSprite.animation = "stand"
	
	#timer.start(time)

func enteredBulletTime(time: float) -> void: 
	state = "bullettime"
	$CollisionShape2D.disabled = true   
	Engine.time_scale = time
	$TimerBulletTime.start(time)

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false

func playStandingPose():		
	$AnimatedSprite.play("stand")
	
func fin01Trigger(trigger):	
	
	if trigger:
		$AnimatedSprite.play("open_arm")
		fin01.play()
		fin01.visible = trigger
		fin01.get_node("CollisionShape2D").set_deferred("disabled",!trigger)	
	else:
		fin01.stop()
		fin01.visible = trigger
		fin01.get_node("CollisionShape2D").set_deferred("disabled",!trigger)
		
func fin02Trigger(trigger):	
	
	if trigger:
		$AnimatedSprite.play("swing")
		
		fin02.play($AnimatedSprite.flip_h)
		fin02.visible = trigger
		fin02.get_node("CollisionShape2D").set_deferred("disabled",!trigger)	
	else:
		#fin02.stop()
		fin02.visible = trigger
		fin02.get_node("CollisionShape2D").set_deferred("disabled",!trigger)
	#fin01.set		

func playFinisher():
	
	var roulette = get_parent().get_node("FinisherRoulette")
	var idx = roulette.get_node("AnimatedSprite").get_frame()	
	#var idx = randi() % 2 + 1		
	if idx == 3:
		fin01Trigger(true)
	else:
		fin02Trigger(true)
		
		$AnimatedSprite.play("swing")
		 
func _process(delta):
	var velocity = Vector2()  # The player's movement vector.
	var objAttackSprite =$Attack.get_node("AnimatedSpriteAttack")
	var objAttackSound = $Attack.get_node("AttackSound")
	var objAttackColli = $Attack.get_node("CollisionShape2D")
	var iActualSpeed = speed
	var iDashSpeed = 0
	
	#print ($AnimatedSprite.animation,$AnimatedSprite.is_playing(), $AnimatedSprite.frame)
		
	if $AnimatedSprite.animation == "down":		
		return	
	
	if $AnimatedSprite.is_playing() and $AnimatedSprite.animation == "swing" and $AnimatedSprite.frame <= 4:	
		#if 	$AnimatedSprite.frame == 4:
		#	fin02Trigger(false)	
		return		
	elif $AnimatedSprite.is_playing() and $AnimatedSprite.animation == "dance" and $AnimatedSprite.frame < 8:		
		return
	elif $AnimatedSprite.animation == "open_arm" and $AnimatedSprite.is_playing() and $AnimatedSprite.frame <= 4:
		if 	$AnimatedSprite.frame == 4:
			fin01Trigger(false)	
		return
	#elif $AnimatedSprite.animation == "swing":
		#$AnimatedSprite.play("stand")	
	#	self.playStandingPose()
	#	return
	
		
	if Input.is_action_pressed("ui_right"):
		action = "walk"
		velocity.x += iMoveUnit
		$AnimatedSprite.flip_h = true 
		objAttackSprite.flip_h = true
		objAttackSprite.position.x = $AnimatedSprite.position.x+200 
		objAttackColli.position.x = $AnimatedSprite.position.x+200
			
	if Input.is_action_pressed("ui_left"):
		action = "walk"
		velocity.x -= iMoveUnit
		$AnimatedSprite.flip_h = false 
		objAttackSprite.flip_h = false
		objAttackSprite.position.x = $AnimatedSprite.position.x - 200
		objAttackColli.position.x = $AnimatedSprite.position.x-200
	
	if Input.is_action_pressed("attack1"):
		isAttack = true
		$Attack.visible = true	
		
		$AnimatedSprite.play("fire_stand")		
		objAttackSprite.play()
		objAttackColli.disabled = false
		
		if objAttackSound.playing == false:
			objAttackSound.play()			
		return
		
	if Input.is_action_pressed("attack2"):
		#isAttack = true
		self.playFinisher()
		return
		
	if Input.is_action_pressed("dance"):
		#isAttack = true
		$AnimatedSprite.play("dance")				
		return
		
	if Input.is_action_just_released("attack1") || Input.is_action_just_released("ui_left")  || Input.is_action_just_released("ui_right"):		
		isAttack = false
		$Attack.visible = false
		#$AnimatedSprite.play("stand")
		self.playStandingPose()
		objAttackSprite.stop()
		objAttackSound.stop()
		objAttackColli.disabled = true
		return
		
	#start: dodge related
	if Input.is_action_pressed("dodge"):
	#if Input.is_action_just_released("dodge"):
		if action != "dash" and iDashing == false:
			self.get_node("CollisionShape2D").set_deferred("disabled",true)
			iDashCnt = 15
			action = "dash"				
			iDashing = true			
			if isBulletTimeChance == true:
				enteredBulletTime (0.3)		
				iActualSpeed =  speed * 16			
			else:
				iActualSpeed =  speed * 4
			
			if $AnimatedSprite.flip_h == true:
				velocity.x -= iMoveUnit
			else:		
				velocity.x += iMoveUnit
			$SndDash.play()
	
	if Input.is_action_just_released("dodge"):
		if iDashCnt>0:	
			action = "dash"
		iDashing = false
						
	iDashCnt = iDashCnt -1
	if iDashCnt >=1:
		self.get_node("CollisionShape2D").set_deferred("disabled",true)
		iDashSpeed = speed * 4
		if isBulletTimeChance == true:
			iDashSpeed = speed * 12
		iActualSpeed =  iDashSpeed
		if $AnimatedSprite.flip_h == true:
				velocity.x -= iMoveUnit
		else:		
				velocity.x += iMoveUnit
	else:
		iDashing = false
		self.get_node("CollisionShape2D").set_deferred("disabled",false)
			
		
		
	#end: dodge related	
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * iActualSpeed
		$AnimatedSprite.play(action)		
	else:
		if action == "walk":
			$AnimatedSprite.stop()
	
	position += velocity * delta
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)	
	
	#if not Input.is_action_just_pressed("ui_up") and  not Input.is_action_just_pressed("ui_down") and not Input.is_action_just_pressed("ui_left") and  not Input.is_action_just_pressed("ui_right"):
	#	self.playStandingPose()
	
	

func _on_Player_body_entered(_body):
	
	var objAttackSprite =$Attack.get_node("AnimatedSpriteAttack")
	var objAttackSound =$Attack.get_node("AttackSound")
	
	#if $SndHitBy.playing == false:
	$SndHitBy.play()
	
	objAttackSprite.stop()
	$Attack.visible = false
	objAttackSound.stop()
	
	emit_signal("GotHit")
	$AnimInfo.play()
	$Info.visible = true
	$AnimatedSprite.play("down")
	state = "freeze"
	freeze(1.0)		
	
	
func _on_AnimatedSprite_animation_finished():
	action = "walk"
	state = "normal"	

func _on_AnimatedSpriteAttack_animation_finished():
	pass

func _on_Attack_body_entered(body):			
	body.linear_velocity = Vector2(0,0)
	body.get_node("CollisionShape2D").set_deferred("disabled",true)
	$Attack.get_node("CollisionShape2D").set_deferred("disabled",true)
	body.setEnemyDown(body.name)
	emit_signal("EnemyDefeated")

func _on_Attack_area_entered(area):
	if $Attack.visible and area.name == "Boss01":		
		emit_signal("BossGetHit")

func _on_Area2DEnemyCloser_body_entered(body):
	self.isBulletTimeChance = true
	body.get_node("Alerting").set_deferred("visible",true)
	pass # Replace with function body.


func _on_Area2DEnemyCloser_body_exited(_body):
	self.isBulletTimeChance = false
	

func _on_TimerBulletTime_timeout():
	$CollisionShape2D.disabled = false   
	Engine.time_scale = 1.0


func _on_AnimInfo_animation_finished(_anim_name):
	$Info.visible = false

