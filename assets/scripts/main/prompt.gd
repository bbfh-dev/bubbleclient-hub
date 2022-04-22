extends Panel


signal next

func _on_ContinueButton_pressed() -> void:
	emit_signal('next')
