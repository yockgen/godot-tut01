extends Node

export (PackedScene) var Mob
export (int) var Score

func _ready():
	$Player.connect("EnemyDefeated", self, "on_PlayerDefeated")
	$Player.connect("GotHit", self, "on_PlayerGotHit")	
	$PauseCtrl.connect("Restart", self, "on_Restart")
	randomize()
	new_game()
	
func emptyEnemies():
	for child in get_children():
		if "enemy" in child.name:
			child.queue_free()
			
func on_Restart():
	emptyEnemies()
	$MobTimer.start()
	$ScoreTimer.start()	
	new_game()
	
func on_PlayerDefeated():
	setscore(150)

func on_PlayerGotHit():
	setscore(-100)
	$AnimInfo.play("AnimScore")

func _on_Ground_body_entered(body):	
	if "enemy" in body.name:
		setscore(-150)
		$AnimInfo.play("AnimScore")
		body.linear_velocity = Vector2(0,0)
		body.get_node("CollisionShape2D").set_deferred("disabled",true)
		body.setEnemyGrounded(body.name)
	
func game_over():
	$MobTimer.stop()
	$ScoreTimer.stop()	
	$PauseCtrl.gameover()
	 
func new_game():
	$Player.start($StartPosition.position)
	$StartTimer.start()
	Score = 150
	setscore(Score)
	
func _on_ScoreTimer_timeout():	
	pass
	
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
	spawn(mob)	

func spawn (obj): 
	var direction = $MobPath/MobSpawnLocation.rotation + PI / 2
	obj.position = $MobPath/MobSpawnLocation.position
	direction += rand_range(-PI / 4, PI / 4)
	obj.rotation = direction
	obj.linear_velocity = Vector2(rand_range(150, 200), 0)
	obj.linear_velocity = obj.linear_velocity.rotated(direction)

func setscore(val):
	Score += val
	if Score <=0: 
		Score = 0
		game_over()		
	$UserInterface/Score.text = "Confidence " + str(Score).pad_zeros(9)

