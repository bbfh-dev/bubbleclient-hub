extends Panel


export var label := ''
export var icon := 'checking'


func popup(new_label: String = '', new_icon: String = '') -> void:
	if new_label:
		label = new_label
	if new_icon:
		icon = new_icon
	
	$Text/Label.set_text(label)
	$Icon/AnimatedSprite.set_animation(icon)
	show()

func move_from(message: Panel):
	self.popup(message.get_node('Text/Label').get_text(), message.get_node('Icon/AnimatedSprite').animation)
