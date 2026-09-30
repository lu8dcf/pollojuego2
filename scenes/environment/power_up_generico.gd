extends Node

var material_res = preload("res://assets/modelos/power_ups/tipo_mejora.tres")

func cambiar_color(opcion: int) -> void:
	match opcion:
		1:
			material_res.set_shader_parameter("color", Color.RED)
		2:
			material_res.set_shader_parameter("color", Color.GREEN)
		3:
			material_res.set_shader_parameter("color", Color.BLUE)
		4:
			material_res.set_shader_parameter("color", Color.YELLOW)
