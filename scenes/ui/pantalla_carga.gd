extends CanvasLayer


signal cancelado
@onready var label_cargando: Label = $Centro/LabelCargando
@onready var boton_cancelar: AnimatedButton = $Centro/BotonCancelar

func _ready() -> void:
	boton_cancelar.pressed.connect(_on_cancelar_pressed)
	visible = true

func set_mensaje(texto: String) -> void:
	if label_cargando:
		label_cargando.text = texto

func _on_cancelar_pressed() -> void:
	cancelado.emit()
