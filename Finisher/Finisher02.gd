extends Area2D

signal EnemyDefeated
signal BossGetHit

var isPlay
var speed = -18
onready var g0 = $AnimatedSprite
onready var g1 = $Ghost1
onready var g2 = $Ghost2
onready var g3 = $Ghost3

func _ready(): 
	isPlay = false
	$AnimatedSprite.stop()  
	
func _process(delta):
	if !isPlay:		
		return
	
	if get_parent():
		var iActSpd = 0	
		if !$AnimatedSprite.flip_h:
			iActSpd = speed
		else:
			iActSpd = -speed	 
		var offset = Vector2(iActSpd, 0)  # Adjust the values as needed
		var new_position = position + offset
		set_position(new_position)
		
		var ghostOffset = 200
		if g0.flip_h:
			ghostOffset = -200			
		var ghostPos = Vector2 (g0.position.x+ghostOffset,g0.position.y)
		g1.position = ghostPos
		ghostPos = Vector2 (g1.position.x+ghostOffset,g1.position.y)
		g2.position = ghostPos
		ghostPos = Vector2 (g2.position.x+ghostOffset,g2.position.y)
		g3.position = ghostPos
		
		#g1.global_position = g1.global_position.linear_interpolate(g0.global_position,.3)
		#g2.global_position = g2.global_position.linear_interpolate(g1.global_position,.3)
		#g3.global_position = g3.global_position.linear_interpolate(g2.global_position,.3)
	

func _on_Finisher01_body_entered(body):
	body.linear_velocity = Vector2(0,0)
	body.get_node("CollisionShape2D").set_deferred("disabled",true)
	body.setEnemyDown(body.name)
	emit_signal("EnemyDefeated")	

func play (isFlipH):	
	$AnimatedSprite.flip_h = isFlipH
	set_position(Vector2(0, -100))
	isPlay = true
	$AnimatedSprite.frame = 0
	$AnimatedSprite.visible = true
	$AnimatedSprite.play()
	
	g1.flip_h = isFlipH
	g1.frame = 0
	g1.visible = true
	g1.play()
	
	g2.flip_h = isFlipH	
	g2.frame = 0
	g2.visible = true
	g2.play()
	
	g3.flip_h = isFlipH	
	g3.frame = 0
	g3.visible = true
	g3.play()
	
func stop ():	
	isPlay = false
	
func _on_Finisher02_area_entered(area):
	if area.name == "Boss01":
		emit_signal("BossGetHit")

func _on_AnimatedSprite_animation_finished():
	isPlay = false
	$AnimatedSprite.frame = 0
	$AnimatedSprite.visible = false
	
	g1.frame = 0
	g1.visible = false
	g2.frame = 0
	g2.visible = false
	g3.frame = 0
	g3.visible = false




func _on_Finisher02_body_entered(body):
	body.linear_velocity = Vector2(0,0)
	body.get_node("CollisionShape2D").set_deferred("disabled",true)
	body.setEnemyDown(body.name)
	emit_signal("EnemyDefeated")
