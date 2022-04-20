extends AnimationPlayer


func _on_Unsupported_about_to_show() -> void:
	$"../../FabricUpdate".stop()
	play('PopUp')
