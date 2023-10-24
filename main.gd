extends Node

export (PackedScene) var Mob
var score

func _ready():
	randomize()
	new_game()

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
	spawn(mob)	

func spawn (obj): 
	var direction = $MobPath/MobSpawnLocation.rotation + PI / 2
	obj.position = $MobPath/MobSpawnLocation.position
	direction += rand_range(-PI / 4, PI / 4)
	obj.rotation = direction
	obj.linear_velocity = Vector2(rand_range(150, 200), 0)
	obj.linear_velocity = obj.linear_velocity.rotated(direction)

