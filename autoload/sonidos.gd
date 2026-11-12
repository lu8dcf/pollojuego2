extends Node

# Global de sonidos

var musica_actual: AudioStreamPlayer = null

# Lista con los 4 temas musicales (sirven tanto para menú como combate)
var playlist_musica = [
	"res://assets/sonidos/mus_combate_1.mp3",
	"res://assets/sonidos/mus_combate_2.mp3",
	"res://assets/sonidos/mus_menu_1.mp3",
	"res://assets/sonidos/mus_menu_2.mp3"
]
var indices_reproducidos = []


func toggle_silenciar_audio(debe_silenciar: bool, nombre_bus: String = "Master"):
	var bus_idx = AudioServer.get_bus_index(nombre_bus)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, debe_silenciar)
		
func _ready() -> void:
	crear_buses_audio()
	reproducir_musica_aleatoria()

func crear_buses_audio():
	var music_idx = AudioServer.get_bus_index("Music")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	
	if music_idx == -1:
		AudioServer.add_bus()
		music_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_idx, "Music")
		AudioServer.set_bus_send(music_idx, "Master")
	
	if sfx_idx == -1:
		AudioServer.add_bus()
		sfx_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")

func crear_audio_player(tipo: String = "SFX") -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.bus = tipo 
	return player

func crear_audio_player_2d(tipo: String = "SFX") -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.bus = tipo
	return player

func crear_audio_player_3d(tipo: String = "SFX") -> AudioStreamPlayer3D:
	var player = AudioStreamPlayer3D.new()
	player.bus = tipo
	return player


# ==========================================
# MÚSICA (Reproducción aleatoria con Fade Out)
# ==========================================

func reproducir_musica_aleatoria():
	if playlist_musica.is_empty():
		return
	
	# Si ya reprodujimos todos, reiniciamos la lista para evitar repeticiones seguidas
	if indices_reproducidos.size() >= playlist_musica.size():
		indices_reproducidos.clear()
	
	var indice_aleatorio = randi() % playlist_musica.size()
	while indice_aleatorio in indices_reproducidos:
		indice_aleatorio = randi() % playlist_musica.size()
	
	indices_reproducidos.append(indice_aleatorio)
	
	var nuevo_player = crear_audio_player("Music")
	nuevo_player.stream = load(playlist_musica[indice_aleatorio])
	add_child(nuevo_player)
	nuevo_player.play()
	
	musica_actual = nuevo_player
	nuevo_player.finished.connect(_on_musica_terminada.bind(nuevo_player))

func _on_musica_terminada(player_terminado: AudioStreamPlayer):
	# Hacemos un fade out rápido y eliminamos el player anterior
	var tween = create_tween()
	tween.tween_property(player_terminado, "volume_db", -80.0, 1.5)
	await tween.finished
	player_terminado.queue_free()
	
	# Reproduce el siguiente tema aleatorio de inmediato
	reproducir_musica_aleatoria()


# ==========================================
# EFECTOS DE SONIDO (SFX)
# ==========================================

# Sonido genérico con pitch variable
func sonar_sfx(archivo):
	if archivo == "muerte" or archivo == "caida":
		var opcion = randi() % 4
		archivo = archivo + "/" + archivo + str(opcion)
	var sound = crear_audio_player_3d("SFX")
	var direccion = "res://assets/sound/sfx/" + archivo + ".mp3"
	sound.stream = load(direccion)
	
	# Variación aleatoria de pitch para que no suene igual siempre
	sound.pitch_scale = randf_range(0.85, 1.15)
	
	add_child(sound)
	sound.play()
	await sound.finished
	sound.queue_free()


# Sonido Pollo Temporal (en 2D con pitch variable)
func sonidoPollo():
	var pollo = crear_audio_player_2d("SFX")
	pollo.stream = preload("res://assets/sonidos/sonidoPolloTemporal.mp3")
	pollo.pitch_scale = randf_range(0.9, 1.1)
	add_child(pollo)
	pollo.play()
	await pollo.finished
	pollo.queue_free()


# Pistola: Elige al azar entre los 3 archivos con pitch variable
func sonidoPistola():
	var opcion = (randi() % 3) + 1 # Elige 1, 2 o 3
	var player = crear_audio_player("SFX")
	player.stream = load("res://assets/sound/sfx/sfx_pistola_" + str(opcion) + ".mp3")
	player.pitch_scale = randf_range(0.9, 1.15)
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()


# Click de interfaz
func sonidoClick():
	var player = crear_audio_player("SFX")
	player.stream = load("res://assets/sound/sfx/click.mp3")
	player.pitch_scale = randf_range(0.95, 1.05)
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()


# Sonido Ping
func sonidoPing():
	var player = crear_audio_player("SFX")
	player.stream = load("res://assets/sound/sfx/ping.mp3")
	player.pitch_scale = randf_range(0.9, 1.1)
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()


# Cohete (3D)
func sonidoCohete():
	var player = crear_audio_player_3d("SFX")
	player.stream = load("res://assets/sound/sfx/sfx_cohete_1.mp3")
	player.pitch_scale = randf_range(0.85, 1.1)
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()


# Compra
func sonidoCompra():
	var player = crear_audio_player("SFX")
	player.stream = load("res://assets/sound/sfx/sfx_compra.mp3")
	player.pitch_scale = randf_range(0.95, 1.05)
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()


# Escopeta (3D)
func sonidoEscopeta():
	var player = crear_audio_player_3d("SFX")
	player.stream = load("res://assets/sound/sfx/sfx_escopeta_1.mp3")
	player.pitch_scale = randf_range(0.8, 1.1)
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()


# Hover de interfaz
func sonidoHover():
	var player = crear_audio_player("SFX")
	player.stream = load("res://assets/sound/sfx/sfx_hover.mp3")
	player.pitch_scale = randf_range(0.95, 1.05)
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()


# Muerte de bicho (3D)
func sonidoMuerteBicho():
	var player = crear_audio_player_3d("SFX")
	player.stream = load("res://assets/sound/sfx/sfx_muerte_bicho.mp3")
	player.pitch_scale = randf_range(0.8, 1.2)
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()


# Recolección de monedas
func sonidoRecoleccionMonedas():
	var player = crear_audio_player("SFX")
	player.stream = load("res://assets/sound/sfx/sfx_recoleccion_monedas.mp3")
	player.pitch_scale = randf_range(0.9, 1.2)
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()


# Selección de menú
func sonidoSelect():
	var player = crear_audio_player("SFX")
	player.stream = load("res://assets/sound/sfx/sfx_select.mp3")
	player.pitch_scale = randf_range(0.95, 1.05)
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()
