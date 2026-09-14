# fondo_infinito.gd
extends TextureRect

@export var velocidad: float = 0.15  # Cambia la velocidad aquí (valores sugeridos: 0.05 a 0.5)

func _ready() -> void:
	# Forzar el modo de estiramiento TILE desde código
	stretch_mode = TextureRect.STRETCH_TILE
	
	# Crear el shader que obliga a la textura a repetirse y desplazarse
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;

	uniform float velocidad_x = 0.15;

	void fragment() {
		// fract() fuerza a que las coordenadas vuelvan a 0 al pasar de 1 (loop infinito)
		vec2 uv_desplazada = vec2(fract(UV.x + TIME * velocidad_x), UV.y);
		COLOR = texture(TEXTURE, uv_desplazada);
	}
	"""
	
	# Asignar el shader al material del TextureRect
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("velocidad_x", velocidad)
	material = mat

func _process(_delta: float) -> void:
	# Permite cambiar la velocidad en tiempo real desde el Inspector
	if material is ShaderMaterial:
		material.set_shader_parameter("velocidad_x", velocidad)
