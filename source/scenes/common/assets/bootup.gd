extends Control


signal is_ready

func _ready() -> void:
	show()
	$AnimationPlayer.play('BootUp')
	yield($AnimationPlayer, 'animation_finished')
	emit_signal('is_ready')
