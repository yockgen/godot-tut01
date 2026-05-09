extends Area2D

const whiten_duration = 0.3
export (ShaderMaterial) var whiten_material
onready var collision_shape = $CollisionShape2D

func setGetHit ():
	$SndHitBy.play()
	whiten_material.set_shader_param("whiten", true)
	yield(get_tree().create_timer(whiten_duration), "timeout")
	whiten_material.set_shader_param("whiten", false)

# Dead code removed - collision and damage handling is done through signals
