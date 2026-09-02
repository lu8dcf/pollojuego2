# animated_button.gd
extends Button
class_name AnimatedButton

@export var hover_scale: float = 1.15
@export var hover_offset: Vector2 = Vector2(5, 0)
@export var animation_duration: float = 0.2
@export var idle_float_amplitude: float = 2.0
@export var idle_float_speed: float = 0.5

var original_position: Vector2
var original_scale: Vector2
var is_hovering: bool = false
var time_offset: float = 0.0

func _ready() -> void:
	original_position = position
	original_scale = scale
	pivot_offset = size / 2
	time_offset = randf_range(0, TAU)  # Fase aleatoria para movimiento independiente
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Iniciar animación idle
	_start_idle_animation()

func _process(delta: float) -> void:
	if not is_hovering:
		_update_idle_movement(delta)

func _start_idle_animation() -> void:
	var tween = create_tween().set_loops()
	tween.tween_callback(_update_idle_position)
	tween.tween_interval(0.05)

func _update_idle_position() -> void:
	if not is_hovering:
		var offset = Vector2(
			sin(Time.get_ticks_msec() * 0.001 * idle_float_speed + time_offset) * idle_float_amplitude,
			cos(Time.get_ticks_msec() * 0.001 * idle_float_speed * 0.7 + time_offset) * idle_float_amplitude * 0.5
		)
		position = original_position + offset

func _update_idle_movement(delta: float) -> void:
	# Movimiento flotante suave (reemplaza a _update_idle_position)
	var offset = Vector2(
		sin(Time.get_ticks_msec() * 0.001 * idle_float_speed + time_offset) * idle_float_amplitude,
		cos(Time.get_ticks_msec() * 0.001 * idle_float_speed * 0.7 + time_offset) * idle_float_amplitude * 0.5
	)
	position = position.lerp(original_position + offset, delta * 5)

func _on_mouse_entered() -> void:
	is_hovering = true
	_animate_hover(true)

func _on_mouse_exited() -> void:
	is_hovering = false
	_animate_hover(false)

func _animate_hover(hovering: bool) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	if hovering:
		# Escalar y mover
		tween.tween_property(self, "scale", original_scale * hover_scale, animation_duration)
		tween.tween_property(self, "position", original_position + hover_offset, animation_duration)
		
		# Añadir brillo/glow
		modulate = Color(1.2, 1.2, 1.2)
	else:
		# Volver al estado original
		tween.tween_property(self, "scale", original_scale, animation_duration * 0.8)
		tween.tween_property(self, "position", original_position, animation_duration * 0.8)
		tween.tween_property(self, "modulate", Color.WHITE, animation_duration * 0.8)
