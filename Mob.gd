extends RigidBody2D

export var min_speed = 150  # Minimum speed range.
export var max_speed = 250  # Maximum speed range.
var soundPly 
var seDown 

var enemy = ""
# Called when the node enters the scene tree for the first time.
func _ready():
	#self.contact_monitor = true
	var mob_types = $AnimatedSprite.frames.get_animation_names()
	$AnimatedSprite.animation = "walk"#mob_types[randi() % mob_types.size()]
	$AnimatedSprite.play()
	self.enemy = ""
	
	#soundPly = AudioStreamPlayer.new()
	#seDown = load("res://assets/Sound/hitted.ogg")
	#add_child(soundPly)
	#soundPly.stream = seDown
		

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	pass

func setEnemyDown (id):
	enemy = id
	$AnimatedSprite.play("hitted")
	if $SoundDown.playing == false:
		$SoundDown.play()
	
func _on_AnimatedSprite_animation_finished():
	if self.name == enemy:		
		$AnimatedSprite.visible = false
	

func _on_SoundDown_finished():	
	pass # Replace with function body.

func _on_AnimatedSprite_frame_changed():
	pass # Replace with function body.
