extends Area2D
signal hit
signal attack

export var speed = 400  # How fast the player will move (pixels/sec).
var screen_size  # Size of the game window

var action = "walk"
var state = "normal"
var isFaceRight = false
var isAttack = false


onready var timer = $Timer
func freeze(time: float) -> void: 
	$CollisionShape2D.disabled = true   
	timer.start(time)

func unfreeze() -> void:
	state = "normal"
	$CollisionShape2D.disabled = false	
	$AnimatedSprite.animation = "stand"
		
# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size	
	$Attack.visible = false
	timer.connect("timeout", self, "unfreeze")

	hide()

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var velocity = Vector2()  # The player's movement vector.
	var objAttackSprite =$Attack.get_node("AnimatedSpriteAttack")
	var objAttackSound = $Attack.get_node("AttackSound")
	var objAttackColli = $Attack.get_node("CollisionShape2D")
	
	if $AnimatedSprite.animation == "down":		
		return	
		
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
		$AnimatedSprite.flip_h = true 
		objAttackSprite.flip_h = true
		objAttackSprite.position.x = $AnimatedSprite.position.x+200 
		objAttackColli.position.x = $AnimatedSprite.position.x+200
			
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
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
	
	if Input.is_action_just_released("attack1") || Input.is_action_just_released("ui_left"):		
		isAttack = false
		$Attack.visible = false
		$AnimatedSprite.play("stand")
		objAttackSprite.stop()
		objAttackSound.stop()
		objAttackColli.disabled = true
		return
	
		
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite.play(action)
	else:
		$AnimatedSprite.stop()
	
	position += velocity * delta
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)	
	
	if velocity.x != 0:
		#$AnimatedSprite.animation = "walk"
		#$AnimatedSprite.flip_v = false
		# See the note below about boolean assignment
		#$AnimatedSprite.flip_h = velocity.x < 0
		pass
	elif velocity.y != 0:
		#$AnimatedSprite.animation = "walk"
		#$AnimatedSprite.flip_v = velocity.y > 0
		pass


func _on_Player_body_entered(body):
	#return
	var objAttackSprite =$Attack.get_node("AnimatedSpriteAttack")
	var objAttackSound =$Attack.get_node("AttackSound")
	
	if $HitSound.playing == false:
	   $HitSound.play()
	
	objAttackSprite.stop()
	$Attack.visible = false
	objAttackSound.stop()
	$AnimatedSprite.play("down")
	state = "freeze"
	freeze(2.0)		
	
	
func _on_AnimatedSprite_animation_finished():
	$HitSound.stop()	
	

func _on_AnimatedSprite_frame_changed():
	pass

func _on_Attack_body_entered(body):
	var objAttackSound =$Attack.get_node("AttackSound")
	var objAttackSprite =$Attack.get_node("AnimatedSpriteAttack")
	
	if $HitSound.playing == false:
		$HitSound.play()		
	
	body.linear_velocity = Vector2(0,0)
	body.get_node("CollisionShape2D").set_deferred("disabled",true)
	$Attack.get_node("CollisionShape2D").set_deferred("disabled",true)
	body.get_node("AnimatedSprite").play("hitted")


func _on_AnimatedSpriteAttack_animation_finished():
	$HitSound.stop()
