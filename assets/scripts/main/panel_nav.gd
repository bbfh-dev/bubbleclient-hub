extends Panel

export (NodePath) var window_path
onready var window := get_node_or_null(window_path)
onready var ROOT = get_node('/root/ProjectVariables')


func _ready() -> void:
	open_page('Features')
	check_fabric_installed()


func _on_Features_pressed() -> void:
	open_page('Features')


func _on_Installation_pressed() -> void:
	open_page('Installation')


func _on_Mods_pressed() -> void:
	open_page('Mods')


func _on_About_pressed() -> void:
	open_page('About')


func open_page(page: String) -> void:
	if window:
		for child in window.get_children():
			if child.get_name() == page:
				child.show()
			else:
				child.hide()
		for child in get_children():
			if child.get_name() == page:
				child.set_disabled(true)
			else:
				child.set_disabled(false)
		if $'../PanelHelp/About'.get_name() == page:
			$'../PanelHelp/About'.set_disabled(true)
		else:
			$'../PanelHelp/About'.set_disabled(false)


func _on_FabricChecker_timeout() -> void:
	check_fabric_installed()


func check_fabric_installed() -> void:
	var file = File.new()
	file.open(ROOT.MINECRAFT_DIR + '/launcher_profiles.json', File.READ)
	if 'fabric-loader-1.17.1' in JSON.parse(file.get_as_text()).get_result()['profiles']:
		$'../Window/Installation/FabricNotFound'.hide()
		$'../Window/Installation/FabricFound'.show()
		$'../Window/Installation/FabricChecker'.stop()
	else:
		$'../Window/Installation/FabricNotFound'.show()
		$'../Window/Installation/FabricFound'.hide()
