extends Control


const hub := preload('res://source/scenes/Hub/Hub.tscn')


func _ready() -> void:
	$Contents.hide()


func _on_BootUp() -> void:
	$Contents.show()


func _on_update_clicked(meta) -> void:
	OS.shell_open(meta)


func _on_Continue_meta_clicked(meta) -> void:
	get_tree().change_scene_to(hub)
