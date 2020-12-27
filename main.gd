extends Node


export (PackedScene) var Mob
var score
var enemy_id

func _ready():
	randomize()
	new_game()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func game_over():
 $MobTimer.stop()
 $ScoreTimer.stop()
 
func new_game():
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	
func _on_ScoreTimer_timeout():
	score += 1




func _on_StartTimer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()



func _on_MobTimer_timeout():
 # Choose a random location on Path2D.
	$MobPath/MobSpawnLocation.offset = randi()
	# Create a Mob instance and add it to the scene.
	var mob = Mob.instance()
	mob.name="enemy"
	
	add_child(mob)
	

	# Set the mob's direction perpendicular to the path direction.
	var direction = $MobPath/MobSpawnLocation.rotation + PI / 2
	# Set the mob's position to a random location.
	mob.position = $MobPath/MobSpawnLocation.position
	# Add some randomness to the direction.
	direction += rand_range(-PI / 4, PI / 4)
	mob.rotation = direction
	# Set the velocity (speed & direction).
	#print(mob.max_speed)
	#mob.linear_velocity = Vector2(rand_range(mob.min_speed, mob.max_speed), 0)
	mob.linear_velocity = Vector2(rand_range(150, 200), 0)
	mob.linear_velocity = mob.linear_velocity.rotated(direction)

func set_enemy_id(body):
	enemy_id = body
	print (body)
	

func _on_Player_hit():
	#no need for this
	print("player hitted")
	for itx in self.get_children():
		if ( enemy_id == itx.name):
			#print(itx.name)
			var mobTmp = itx
			mobTmp.get_node("AnimatedSprite").play("hitted")
			mobTmp.linear_velocity = Vector2(0,0) #stop
			mobTmp.get_node("CollisionShape2D").set_deferred("disabled",true)
			
			

func _on_Player_attack():
	#no need for this
	print("player attack")
	for itx in self.get_children():
		if ( enemy_id == itx.name):
			#print(itx.name)
			var mobTmp = itx
			mobTmp.get_node("AnimatedSprite").play("hitted")
			mobTmp.linear_velocity = Vector2(0,0) #stop
			mobTmp.get_node("CollisionShape2D").set_deferred("disabled",true)
