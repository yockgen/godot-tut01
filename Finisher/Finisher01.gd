extends Node2D

signal EnemyDefeated
signal BossGetHit

# Called every frame. 'delta' is the elapsed time since the previous frame.
var isPlay
func _ready(): 
	isPlay = false

func _process(delta):
	
	if !isPlay:
		return
			
	if rotation >=3.5:
		rotation = 0		
	else:	
		rotation += 4 * delta

func _on_Finisher01_body_entered(body):
	body.linear_velocity = Vector2(0,0)
	body.get_node("CollisionShape2D").set_deferred("disabled",true)
	body.setEnemyDown(body.name)
	emit_signal("EnemyDefeated")	

func play ():	
	isPlay = true
	rotation = 0
	
func stop ():	
	isPlay = false
	rotation = 0


func _on_Finisher01_area_entered(area):
	if area.name == "Boss01":
		emit_signal("BossGetHit")
