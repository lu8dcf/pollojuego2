extends CharacterBody3D

@export var speed: float = 0

func _physics_process(delta: float) -> void:
	# Obtener dirección de entrada (WASD / flechas por defecto: ui_up, ui_down, ui_left, ui_right)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Convertir a dirección 3D en el plano XZ (sin rotación de cámara)
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)
	
	# Aplicar velocidad solo en X y Z, Y siempre 0
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0
	
	move_and_slide()
