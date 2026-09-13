# globalSignal.gd
extends Node

@warning_ignore("unused_signal")
var seleccionPollo

# ===== SEÑALES DE LOBBY =====
@warning_ignore("unused_signal")
signal jugador_conectado(peer_id: int)
@warning_ignore("unused_signal")
signal jugador_desconectado(peer_id: int)
@warning_ignore("unused_signal")
signal seleccion_pollo_cambiada(nuevo_pollo: String)
@warning_ignore("unused_signal")
signal seleccion_pollo_confirmada(pollo_id: String)
@warning_ignore("unused_signal")
signal sesion_actualizada(info_sesion: Dictionary)


# ===== SEÑALES DE INVENTARIO =====
@warning_ignore("unused_signal")
signal inventario_actualizado(nuevo_inventario: Array)
@warning_ignore("unused_signal")
signal objeto_agregado(slot: int, objeto: Resource)
@warning_ignore("unused_signal")
signal objeto_eliminado(slot: int)

# ===== SEÑALES DE SALUD =====
@warning_ignore("unused_signal")
signal salud_jugador_cambiada(nueva_salud: int)
@warning_ignore("unused_signal")
signal jugador_recibio_daño(peer_id: int, cantidad: int)
@warning_ignore("unused_signal")
signal jugador_muerto()

# ===== SEÑALES DE EXPERIENCIA =====
@warning_ignore("unused_signal")
signal experiencia_jugador_cambiada(nueva_experiencia: int)

# ===== SEÑALES DE JUEGO =====
@warning_ignore("unused_signal")
signal ronda_iniciada()
@warning_ignore("unused_signal")
signal ronda_terminada()
@warning_ignore("unused_signal")
signal juego_pausado()
@warning_ignore("unused_signal")
signal juego_reanudado()

# ===== SEÑALES DE PUNTAJE =====
@warning_ignore("unused_signal")
signal puntaje_actualizado(peer_id: int, nuevo_puntaje: int)
