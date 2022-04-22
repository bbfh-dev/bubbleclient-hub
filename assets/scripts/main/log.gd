extends Panel


func _process(delta: float) -> void:
	if $Status/Sprite.get_animation() == 'loading':
		$Status/Sprite.rotation += PI * delta
	else:
		$Status/Sprite.rotation = 0

func set_log_data(label: String, sublabel: String = '', status: String = 'loading'):
	$Status/Sprite.set_animation(status)
	$Label.set_text(label)
	$Label/SubLabel.set_text(sublabel)
	$Label/SubLabel.rect_size.x = 520 - $Label.rect_size.x
