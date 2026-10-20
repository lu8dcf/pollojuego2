extends Node

var material_res = preload("res://assets/modelos/power_ups/tipo_mejora.tres")
var material_copia: ShaderMaterial # Variable para guardar la copia única
@export var tipo: int
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D # Ajusta a tu nodo

func _ready() -> void:
	# 1. Duplicamos el material para que sea único para este objeto
	material_copia = material_res.duplicate()
	
	# 2. Asignamos la copia al objeto 3D
	if mesh_instance:
		mesh_instance.material_override = material_copia
		
	cambiar_color()
	
func cambiar_color() -> void:
	match tipo:
		1:
			material_res.set_shader_parameter("color", Color.RED)
		2:
			material_res.set_shader_parameter("color", Color.GREEN)
		3:
			material_res.set_shader_parameter("color", Color.BLUE)
		4:
			material_res.set_shader_parameter("color", Color.YELLOW)
