extends PanelContainer


@onready var nombre_usuario: LineEdit = %nombre_usuario
@onready var empezar_solo: TextureButtonAnimado = %empezar_solo
#@onready var boton_volver: Button = %BotonVolver

func _ready() -> void:
	empezar_solo.pressed.connect(_on_empezar_pressed)
	#boton_volver.pressed.connect(func(): solicitar_volver.emit())
	# Restaurar nombre previo
	if GlobalJuego.nombre_jugador != "":
		nombre_usuario.text = GlobalJuego.nombre_jugador
	nombre_usuario.text_changed.connect(_on_nombre_changed)

func _on_nombre_changed(txt: String) -> void:
	GlobalJuego.nombre_jugador = txt

func _on_empezar_pressed() -> void:
	if nombre_usuario.text.strip_edges() == "":
		GlobalJuego.nombre_jugador = "Jugador"
	else:
		GlobalJuego.nombre_jugador = nombre_usuario.text.strip_edges()
	GlobalSignal.solicitar_empezar.emit()
