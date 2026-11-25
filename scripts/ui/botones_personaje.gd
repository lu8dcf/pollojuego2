extends TextureButton




func _on_pressed() -> void:
	if Sonidos.has_method("sonidoHover"):
		Sonidos.sonidoHover()
	if Sonidos.has_method("sonidoSelect"):
		Sonidos.sonidoSelect()
