extends Attack
# Finisher02: Ghost Trail Dash Attack
# Rush forward with ghost trail effect

class_name Finisher02

# ============ PROPERTIES ============
export var dash_speed = 400  # Movement speed during dash
export var dash_duration = 1.0  # Duration of dash
export var ghost_count = 3  # Number of ghost images
export var ghost_offset = 200  # Distance between ghosts

var is_dashing = false
var dash_timer = 0.0
var dash_node = null  # Area2D for movement
var ghost_nodes = []  # Array of ghost sprites

# ============ CONFIGURATION ============

func _ready():
	attack_name = "Finisher 02 - Ghost Dash"
	damage = 25
	cooldown = 1.2
	animation_name = "walk"

# ============ ATTACK EXECUTION ============

func _perform_attack(target_position: Vector2):
	"""Execute ghost trail dash attack"""
	if player_ref == null:
		return
	
		# Hide player during finisher
		player_ref.visible = false
		
	if player_ref.has_node("AnimatedSprite"):
		var sprite = player_ref.get_node("AnimatedSprite")
		if sprite.flip_h:
			direction = -1
	
	# Create dash node if needed
	if dash_node == null:
		_setup_dash_node()
	
	# Reset position to player offset
	dash_node.position = Vector2(0, -100)
	dash_node.direction = direction
	
	# Create/show ghosts
	_create_ghosts()

func _setup_dash_node():
	"""Set up the moving dash node"""
	dash_node = Area2D.new()
	dash_node.name = "Finisher02_Dash"
	player_ref.add_child(dash_node)
	
	# Add collision for hit detection
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.extents = Vector2(50, 50)
	collision.shape = rect_shape
	dash_node.add_child(collision)
	
	# Connect signals
	dash_node.connect("body_entered", self, "_on_dash_body_entered")
	dash_node.connect("area_entered", self, "_on_dash_area_entered")
	dash_node.direction = 1

func _create_ghosts():
	"""Create ghost trail sprites"""
	# Clear old ghosts
	for ghost in ghost_nodes:
		ghost.queue_free()
	ghost_nodes.clear()
	
	# Create new ghosts
	for i in range(ghost_count):
		var ghost = Sprite.new()
		ghost.name = "Ghost_%d" % i
		dash_node.add_child(ghost)
		ghost_nodes.append(ghost)
		
		# Show ghost at offset position (will update during dash)
		if player_ref.has_node("AnimatedSprite"):
			var sprite = player_ref.get_node("AnimatedSprite")
			ghost.texture = sprite.frames.get_frame(sprite.animation, 0)
			ghost.flip_h = sprite.flip_h

func _process(delta):
	.._process(delta)
	
	if not is_dashing:
		return
	
	# Move dash node forward
	if dash_node:
		var movement = dash_speed * dash_node.direction * delta
		dash_node.position.x += movement
		
		# Update ghost positions
		_update_ghosts()
	
	dash_timer -= delta
	
	if dash_timer <= 0:
		_finish_dash()

func _update_ghosts():
	"""Update ghost trail positions"""
	if dash_node == null or ghost_nodes.empty():
		return
	
	# Position ghosts in a trail behind the main dash position
	for i in range(ghost_nodes.size()):
		var ghost = ghost_nodes[i]
		var ghost_pos_x = dash_node.position.x - (ghost_offset * (i + 1) * dash_node.direction)
		ghost.position = Vector2(ghost_pos_x, dash_node.position.y)

func _finish_dash():
	"""End dash attack"""
	is_dashing = false
	if dash_node:
		dash_node.position = Vector2.ZERO
	
	# Hide ghosts
	for ghost in ghost_nodes:
		ghost.visible = false
	
		# Show player again
		if player_ref:
			player_ref.visible = true
		
			body.get_node("CollisionShape2D").set_deferred("disabled", true)

func _on_dash_area_entered(area):
	"""Hit area (boss)"""
	if area.name == "Boss01":
		if area.has_method("take_damage"):
			area.take_damage(damage)
