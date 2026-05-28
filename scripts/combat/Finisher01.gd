extends Attack
# Finisher01: Spinning Attack
# Rotate and damage enemies in the spinning area

class_name Finisher01

# ============ PROPERTIES ============
export var spin_speed = 4.0  # Rotation speed per second
export var spin_duration = 0.5  # How long to spin

var is_spinning = false
var spin_timer = 0.0
var spin_node = null  # Reference to the spinning node (Area2D)

# ============ CONFIGURATION ============

func _ready():
	attack_name = "Finisher 01 - Spin Attack"
	damage = 20
	cooldown = 1.0
	animation_name = "dance"  # Using dance as animation reference

# ============ ATTACK EXECUTION ============

func _perform_attack(target_position: Vector2):
	"""Execute spinning attack"""
	if player_ref == null:
		return
	
	is_spinning = true
	spin_timer = spin_duration
	
	# Get or create spinning node
	if spin_node == null:
		spin_node = Area2D.new()
		spin_node.name = "Finisher01_Hitbox"
		player_ref.add_child(spin_node)
		
		# Add collision shape
		var collision = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 100
		collision.shape = circle_shape
		spin_node.add_child(collision)
		
		# Connect signals
		spin_node.connect("body_entered", self, "_on_hitbox_body_entered")
		spin_node.connect("area_entered", self, "_on_hitbox_area_entered")
	
	spin_node.rotation = 0

func _process(delta):
	.._process(delta)
	
	if not is_spinning:
		return
	
	# Rotate the spin node
	if spin_node:
		spin_node.rotation += spin_speed * delta
	
	spin_timer -= delta
	
	if spin_timer <= 0:
		_finish_spin()

func _finish_spin():
	"""End spinning attack"""
	is_spinning = false
	if spin_node:
		spin_node.rotation = 0
	finish_execution()

# ============ HITBOX DETECTION ============

func _on_hitbox_body_entered(body):
	"""Hit rigid body (enemy)"""
	if body.has_method("take_damage"):
		body.take_damage(damage)
		# Disable collision temporarily
		if body.has_node("CollisionShape2D"):
			body.get_node("CollisionShape2D").set_deferred("disabled", true)

func _on_hitbox_area_entered(area):
	"""Hit area (boss)"""
	if area.name == "Boss01":
		if area.has_method("take_damage"):
			area.take_damage(damage)
