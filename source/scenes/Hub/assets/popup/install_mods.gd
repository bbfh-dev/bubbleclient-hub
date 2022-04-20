extends AnimationPlayer


func _on_PopupDialog_about_to_show() -> void:
	play('PopUp')


func _on_PopupDialog_popup_hide() -> void:
	play('Hide')
