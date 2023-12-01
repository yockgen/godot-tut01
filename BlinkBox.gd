extends Area2D

const whiten_duration = 0.3
export (ShaderMaterial) var whiten_material
onready var collision_shape = $CollisionShape2D

var is_invincible = false


func start_invincibility(invincibility_duration):
	is_invincible = true
	collision_shape.set_deferred("disabled", true)
	yield(get_tree().create_timer(invincibility_duration), "timeout")
	collision_shape.set_deferred("disabled", false)
	is_invincible = false


func _on_BlinkBox_body_entered(body):		
	whiten_material.set_shader_param("whiten", true)
	yield(get_tree().create_timer(whiten_duration), "timeout")
	whiten_material.set_shader_param("whiten", false)
	pass

