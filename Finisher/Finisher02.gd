extends Area2D

signal EnemyDefeated
signal BossGetHit

# Called every frame. 'delta' is the elapsed time since the previous frame.
var isPlay
var speed = -18
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
	
	
func stop ():	
	isPlay = false
	
func _on_Finisher01_area_entered(area):
	if area.name == "Boss01":
		emit_signal("BossGetHit")


func _on_AnimatedSprite_animation_finished():
	isPlay = false
	$AnimatedSprite.frame = 0
	$AnimatedSprite.visible = false
