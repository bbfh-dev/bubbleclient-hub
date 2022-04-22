extends Control

onready var ROOT = get_node('/root/ProjectVariables')


func _ready() -> void:
	OS.set_borderless_window(false)
	$AnimationPlayer.play('boot_up')
	var file = File.new()
	file.open('user://server_status.json', File.READ)
	var server_version = JSON.parse(file.get_as_text()).get_result()['version']
	file.close()

	$Status/Control/Label.set_text('v' + ROOT.CLIENT_VERSION)
	set_is_loading(true)
	$Window/Features.set_bbcode(ROOT.get_client_status('features'))
	$Window/Mods.set_bbcode(ROOT.get_client_status('mod_docs'))
	$Window/About.set_bbcode(ROOT.get_client_status('about'))
	if ROOT.CLIENT_VERSION != server_version:
		$Status/Control/Label/VersionControl.modulate = Color(0.99, 0.71, 0.125)
		$Status/Control/Label/VersionControl/Label.set_text('Outdated')
		$Status/Control/Label.set_text('v' + ROOT.CLIENT_VERSION + ' -> ' + 'v' + server_version)
	set_is_loading(false)


func set_is_loading(boolean: bool = true) -> void:
	if boolean:
		$Status/Control/LogoFade.play('fade_in')
	else:
		$Status/Control/LogoFade.play('fade_out')


func _on_text_meta_clicked(meta) -> void:
	OS.shell_open(meta)
