extends Area2D

const whiten_duration = 0.3
export (ShaderMaterial) var whiten_material
onready var collision_shape = $CollisionShape2D

func setGetHit ():
	$SndHitBy.play()
	whiten_material.set_shader_param("whiten", true)
	yield(get_tree().create_timer(whiten_duration), "timeout")
	whiten_material.set_shader_param("whiten", false)

func _on_Boss01_area_entered(area):
	#whiten_material.set_shader_param("whiten", true)
	#yield(get_tree().create_timer(whiten_duration), "timeout")
	#whiten_material.set_shader_param("whiten", false)
	pass

func _on_Boss01_body_entered(body):
	
	#print (body)
	#whiten_material.set_shader_param("whiten", true)
	#yield(get_tree().create_timer(whiten_duration), "timeout")
	#whiten_material.set_shader_param("whiten", false)
	pass


func _on_Boss01_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	
	#print ("body2")
	#whiten_material.set_shader_param("whiten", true)
	#yield(get_tree().create_timer(whiten_duration), "timeout")
	#whiten_material.set_shader_param("whiten", false)
	pass # Replace with function body.
