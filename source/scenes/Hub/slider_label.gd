extends Label



func _on_HSlider_value_changed(value: float) -> void:
	set_text(str(value) + 'GB')
