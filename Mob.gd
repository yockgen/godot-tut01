extends RigidBody2D
export var particleBooming : PackedScene


export var min_speed = 150  # Minimum speed range.
export var max_speed = 250  # Maximum speed range.
var soundPly 
var seDown 

var enemy = ""
var isGrounded
# Called when the node enters the scene tree for the first time.
func _ready():
	#$AnimatedSprite.animation = "walk"#mob_types[randi() % mob_types.size()]
	$AnimatedSprite.play()
	$Alerting.visible = false
	self.enemy = ""
	isGrounded = false
		
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()


func setEnemyDown (id):
	enemy = id	
	if $SoundDown.playing == false:
		$SoundDown.play()
		
	var _explosion = particleBooming.instance()
	_explosion.position = global_position
	_explosion.rotation = global_rotation
	_explosion.emitting = true
	get_tree().current_scene.add_child(_explosion)
	yield(get_tree().create_timer(0.3),"timeout")
	queue_free()
	
	#$AnimatedSprite.play("hitted")	
 
func _process(delta):
	if isGrounded == true:
	   rotation_degrees = 0
	
func setEnemyGrounded (_id):
	isGrounded = true 	
	$AnimatedSprite.play("grounded")
	$SndExplosion.play()	
	yield(get_tree().create_timer(2),"timeout")
	queue_free()
	
func _on_AnimatedSprite_animation_finished():
	if self.name == enemy:		
		$AnimatedSprite.visible = false
		$Alerting.visible = false
	

func _on_SoundDown_finished():	
	pass # Replace with function body.

func _on_AnimatedSprite_frame_changed():
	pass # Replace with function body.
