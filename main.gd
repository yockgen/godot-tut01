extends Node

@export var Mob: PackedScene
@export var Score: int

func _ready():
	var _discard = $Player.connect("EnemyDefeated", Callable(self, "on_MinionGetHit"))
	_discard = $Player.connect("GotHit", Callable(self, "on_PlayerGotHit"))
	_discard = $Player.connect("BossGetHit", Callable(self, "on_BossGetHit"))	
	_discard = $Player.get_node("Finisher01").connect("EnemyDefeated", Callable(self, "on_MinionGetHit"))
	_discard = $Player.get_node("Finisher01").connect("BossGetHit", Callable(self, "on_BossGetHit"))
	_discard = $Player.get_node("Finisher02").connect("EnemyDefeated", Callable(self, "on_MinionGetHit"))
	_discard = $Player.get_node("Finisher02").connect("BossGetHit", Callable(self, "on_BossGetFinisher2Hit"))
	
	
	_discard = $PauseCtrl.connect("Restart", Callable(self, "on_Restart"))
	randomize()
	new_game()

func on_BossGetFinisher2Hit():
	setscore(300)
	$Boss01.setGetHit()
	
func on_BossGetHit():
	setscore(1)
	$Boss01.setGetHit()
	
func emptyEnemies():
	for child in get_children():
		if "enemy" in child.name:
			child.queue_free()
			
func on_Restart():
	emptyEnemies()
	$MobTimer.start()
	$ScoreTimer.start()	
	new_game()
	
func on_MinionGetHit():
	setscore(150)

func on_PlayerGotHit():
	setscore(-100)
	$AnimInfo.play("AnimScore")

func _on_Ground_body_entered(body):	
	print("Ground body entered: ", body.name, " class: ", body.get_class())
	if "enemy" in body.name:
		print("enemy detected, calling setEnemyGrounded")
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
	$MobPath/MobSpawnLocation.progress_ratio = randf()
	# Create a Mob instance and add it to the scene.
	var mob = Mob.instantiate()
	mob.name="enemy"
	
	add_child(mob)
	spawn(mob)	

func spawn (obj): 
	var direction = $MobPath/MobSpawnLocation.rotation + PI / 2
	obj.position = $MobPath/MobSpawnLocation.position
	direction += randf_range(-PI / 4, PI / 4)
	obj.rotation = 0
	obj.angular_velocity = 0
	obj.linear_velocity = Vector2(randf_range(150, 200), 0).rotated(direction)
	if obj.has_node("AnimatedSprite2D"):
		var sprite = obj.get_node("AnimatedSprite2D")
		sprite.flip_h = obj.linear_velocity.x < 0

func setscore(val):
	Score += val
	if Score <=0: 
		Score = 0
		game_over()		
	$UserInterface/Score.text = "Confidence " + str(Score).pad_zeros(9)
