extends Node

var material_res = preload("res://assets/modelos/power_ups/tipo_mejora.tres")

func color(opcion: int) -> void:
	var color_elegido = Color.WHITE
	
	match opcion:
		1: color_elegido = Color.RED
		2: color_elegido = Color.GREEN
		3: color_elegido = Color.BLUE
		4: color_elegido = Color.YELLOW
	
	# 1. Duplicamos el material para que este item tenga su propio color
	var material_unico = material_res.duplicate()
	
	# 2. Le asignamos el color (usando la propiedad de StandardMaterial3D)
	material_unico.albedo_color = color_elegido
	
	# 3. Buscamos el nodo del modelo visual (el hijo "jeringa_generica")
	var modelo = get_node_or_null("jeringa_generica")
	
	if modelo:
		# Si el modelo es un MeshInstance3D directamente
		if modelo is MeshInstance3D:
			modelo.material_override = material_unico
		# Si el modelo tiene mallas internas (por si acaso)
		else:
			# Busca la primera MeshInstance3D en sus hijos
			var meshes = modelo.find_children("*", "MeshInstance3D", true, false)
			if meshes.size() > 0:
				meshes[0].material_override = material_unico
