extends Node

#Global de sonidos

var musica_menu_global: AudioStreamPlayer = null

func _ready() -> void:
	crear_buses_audio()

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
	player.bus = tipo  # "Master", "Music" o "SFX"
	return player

func crear_audio_player_2d(tipo: String = "SFX") -> AudioStreamPlayer2D:
	var player = AudioStreamPlayer2D.new()
	player.bus = tipo
	return player

func crear_audio_player_3d(tipo: String = "SFX") -> AudioStreamPlayer3D:
	var player = AudioStreamPlayer3D.new()
	player.bus = tipo
	return player

func sonar_sfx(archivo):
	if archivo=="muerte" or archivo=="caida":
		var opcion=randi() % 4
		archivo = archivo+"/"+archivo + str(opcion)
	var sound = crear_audio_player_3d("SFX")
	var direccion = "res://assets/sound/sfx/" + archivo + ".mp3"
	sound.stream = load(direccion)
	add_child(sound)
	sound.play()
	await sound.finished
	sound.queue_free()

####SONIDO POLLO
func sonidoPollo():
	var sonidoPollo = crear_audio_player_2d("SFX")
	sonidoPollo.stream = preload("res://assets/sonidos/sonidoPolloTemporal.mp3")
	add_child(sonidoPollo)
	sonidoPollo.play()
	await sonidoPollo.finished
	sonidoPollo.queue_free()
