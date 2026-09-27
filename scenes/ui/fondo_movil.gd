extends TextureRect

@export var velocidad: float = 0.15

func _ready() -> void:
	# Creamos el shader que fuerza el movimiento continuo horizontal
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;

	uniform float velocidad_x = 0.15;

	void fragment() {
		// Mantiene la coordenada Y fija y solo desplaza la coordenada X
		vec2 uv = vec2(fract(UV.x + TIME * velocidad_x), UV.y);
		COLOR = texture(TEXTURE, uv);
	}
	"""
	
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("velocidad_x", velocidad)
	material = mat

func _process(_delta: float) -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("velocidad_x", velocidad)
