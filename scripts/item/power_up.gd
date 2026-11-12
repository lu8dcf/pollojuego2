extends Node

var libre = true  # bandera para que solo lo capture uno
@export var tipo: int = 1 # tipo d item
@onready var power_up_generico = $PowerUpGenerico

func _ready() -> void:
	# 1. Al inicializar (o cuando definas la opción), le pasas el dato al hijo
	configurar_power_up()

func configurar_power_up() -> void:
	#  función del hijo y SE pasa el tipo
	if power_up_generico.has_method("color"):
		power_up_generico.color(tipo)

# Si un jugador lo captura
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugadores") and libre:
		# recolectar item
		libre = false
		
			
		#print ("item capturado")
		eliminar()


func _on_tiempo_vida_timeout() -> void:
	#print ("tiempo elimidado")
	eliminar()
	
func eliminar():
	queue_free()
