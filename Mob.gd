extends RigidBody2D

export var min_speed = 150  # Minimum speed range.
export var max_speed = 250  # Maximum speed range.

var enemy = "00"
# Called when the node enters the scene tree for the first time.
func _ready():
	#self.contact_monitor = true
	var mob_types = $AnimatedSprite.frames.get_animation_names()
	$AnimatedSprite.animation = "walk"#mob_types[randi() % mob_types.size()]
	$AnimatedSprite.play()
	self.enemy = "0"
	

func _on_VisibilityNotifier2D_screen_exited():
	#print("yockgen123")
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func setEnemyDownId (id):
	enemy = id
	
func _on_AnimatedSprite_animation_finished():
	#print ("call yockgen ", self.name)
	if self.name == enemy:
		$AnimatedSprite.visible = false
	pass # Replace with function body.
