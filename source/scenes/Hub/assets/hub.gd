extends Control


var full_minecraft_path := ''
var fabric_dir := ''
var http_request := 'none'
var ram_size = 4

func _ready() -> void:
	$Contents.hide()


func _on_BootUp() -> void:
	update_fabricmc_status()
	var mod_list = File.new()
	mod_list.open('user://modlist.txt', File.READ)
	$Contents/Window/Info/Panel/RichTextLabel.set_bbcode(
		$Contents/Window/Info/Panel/RichTextLabel.get_bbcode().replace('<ML>', str(mod_list.get_as_text().split('\n').size() - 1))
	)
	mod_list.close()
	$Contents.show()


func hide_all() -> void:
	$Contents/Window/Controls/Panel/Features.set_disabled(false)
	$Contents/Window/Controls/Panel/Fabric.set_disabled(false)
	$Contents/Window/Controls/Panel/Mods.set_disabled(false)
	$Contents/Window/Controls/Panel/Configs.set_disabled(false)
	$Contents/Window/Controls/Panel/About.set_disabled(false)
	
	$Contents/Window/Page/Panel/Features.hide()
	$Contents/Window/Page/Panel/Fabric.hide()
	$Contents/Window/Page/Panel/Mods.hide()
	$Contents/Window/Page/Panel/Configs.hide()
	$Contents/Window/Page/Panel/About.hide()

func _on_Fabric_pressed() -> void:
	hide_all()
	$Contents/Window/Controls/Panel/Fabric.set_disabled(true)
	$Contents/Window/Page/Panel/Fabric.show()


func _on_Features_pressed() -> void:
	hide_all()
	$Contents/Window/Controls/Panel/Features.set_disabled(true)
	$Contents/Window/Page/Panel/Features.show()


func _on_Mods_pressed() -> void:
	hide_all()
	$Contents/Window/Controls/Panel/Mods.set_disabled(true)
	$Contents/Window/Page/Panel/Mods.show()


func _on_Configs_pressed() -> void:
	hide_all()
	$Contents/Window/Controls/Panel/Configs.set_disabled(true)
	$Contents/Window/Page/Panel/Configs.show()


func _on_About_pressed() -> void:
	hide_all()
	$Contents/Window/Controls/Panel/About.set_disabled(true)
	$Contents/Window/Page/Panel/About.show()


func _on_DownloadButton_pressed() -> void:
	OS.shell_open('https://fabricmc.net/use/installer/')


func _on_FabricUpdate_timeout() -> void:
	update_fabricmc_status()


func update_fabricmc_status() -> void:
	if OS.get_environment('APPDATA'):
		open_minecraft_dir(OS.get_environment('APPDATA') + '/.minecraft')
	elif OS.get_environment('HOME'):
		open_minecraft_dir(OS.get_environment('HOME') + '/.minecraft')
	else:
		$Unsupported.popup()
	if fabric_dir != '':
		$Contents/Buttons/DownloadButton.set_disabled(true)
		$Contents/Buttons/InstallButton.set_disabled(false)
		$Contents/Buttons/ConfigureButton.set_disabled(false)
		$FabricUpdate.stop()


func open_minecraft_dir(environment: String) -> void:
	var minecraft_dir = Directory.new()
	if not minecraft_dir.open(environment + '/versions') == OK:
		return
	
	minecraft_dir.open(environment + '/versions')
	minecraft_dir.list_dir_begin()
	var file_name = minecraft_dir.get_next()
	while file_name != "":
		if minecraft_dir.current_is_dir():
			if 'fabric-loader' in file_name and '1.17.1' in file_name:
				fabric_dir = environment + '/versions' + '/' + file_name
				full_minecraft_path = environment
		file_name = minecraft_dir.get_next()


func _on_InstallButton_pressed() -> void:
	$InstallModsWarning.popup()


func log_message(message: String, icon: String = '') -> void:
	$InstallMods/Panel/Control/Message8.move_from($InstallMods/Panel/Control/Message7)
	$InstallMods/Panel/Control/Message7.move_from($InstallMods/Panel/Control/Message6)
	$InstallMods/Panel/Control/Message6.move_from($InstallMods/Panel/Control/Message5)
	$InstallMods/Panel/Control/Message5.move_from($InstallMods/Panel/Control/Message4)
	$InstallMods/Panel/Control/Message4.move_from($InstallMods/Panel/Control/Message3)
	$InstallMods/Panel/Control/Message3.move_from($InstallMods/Panel/Control/Message2)
	$InstallMods/Panel/Control/Message2.move_from($InstallMods/Panel/Control/Message)
	$InstallMods/Panel/Control/Message.popup(message, icon)


func _on_ContinueButton_pressed() -> void:
	$InstallModsWarning.hide()
	$InstallMods.popup()
	$InstallMods/Panel/Control/Message.popup('Reading the mod list', 'checking')
	yield(get_tree().create_timer(1), 'timeout')
	var file = File.new()
	file.open('user://modlist.txt', File.READ)
	var content = file.get_as_text()
	if not content:
		$InstallMods/Panel/Control/Message.popup('The mod list is empty :(', 'error')
	else:
		$InstallMods/Panel/Control/Message.popup('Found the modlist!', 'found')
		yield(get_tree().create_timer(0.5), 'timeout')
		var dir = Directory.new()
		for line in content.split('\n'):
			if not line == '':
				if line.begins_with('<DOWNLOAD>'):
					line = line.trim_prefix('<DOWNLOAD> ')
					log_message('Searching for ' + line, 'checking')
					var mod_file = File.new()
					if mod_file.file_exists(full_minecraft_path + '/BubbleClientHub/mods/' + line):
						$InstallMods/Panel/Control/Message.popup('Already installed! ' + line, 'found')
					else:
						$InstallMods/Panel/Control/Message.popup('Downloading ' + line, 'downloading')
						http_request = line
						dir.make_dir_recursive(full_minecraft_path + '/BubbleClientHub/mods/')
						$HTTPRequest.download_file = full_minecraft_path + '/BubbleClientHub/mods/' + line
						$HTTPRequest.request('https://github.com/bubblefish-dev/bubbleclient-server/raw/main/mods/' + line)
						yield($HTTPRequest, 'request_completed')
				if line.begins_with('<REMOVE> '):
					line = line.trim_prefix('<REMOVE> ')
					var remove_file = Directory.new()
					remove_file.remove(full_minecraft_path + '/BubbleClientHub/mods/' + line)
			yield(get_tree().create_timer(0.1), 'timeout')
		log_message('Mods were installed! Now use "Configure mods"', 'found')
		yield(get_tree().create_timer(2), 'timeout')
		$InstallMods.hide()
	file.close()
	$HowMuchRam.popup()
	yield($HowMuchRam/Panel/Button, 'pressed')
	ram_size = $HowMuchRam/Panel/HSlider.get_value()
	$HowMuchRam.hide()
	set_launcher_profiles()


func set_launcher_profiles() -> void:
	var file = File.new()
	file.open(full_minecraft_path + '/launcher_profiles.json', File.READ_WRITE)
	var json = JSON.parse(file.get_as_text()).get_result()
	json['profiles']['fabric-loader-1.17.1']['name'] = 'BubbleClient 1.17.1'
	json['profiles']['fabric-loader-1.17.1']['icon'] = 'data:image/png;base64,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'
	var dir = Directory.new()
	dir.open(full_minecraft_path + '/BubbleClientHub')
	json['profiles']['fabric-loader-1.17.1']['gameDir'] = dir.get_current_dir()
	json['profiles']['fabric-loader-1.17.1']['javaArgs'] = '-Xmx' + str(ram_size) + 'G -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M'
	
	file.store_string(JSON.print(json, '\t'))
	file.close()


func _on_HTTPRequest_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
	if not response_code == 200:
		$InstallMods/Panel/Control/Message.popup('Could not download ' + http_request, 'error')
	else:
		$InstallMods/Panel/Control/Message.popup('Downloded ' + http_request, 'found')


func _on_ConfigureButton_pressed() -> void:
	$ConfigureMods/Panel/Control/Message.popup('Reading config list', 'checking')
	$ConfigureMods.popup()
	var file = File.new()
	file.open('user://configs.json', File.READ)
	var json = JSON.parse(file.get_as_text()).get_result()
	file.close()
	
	$ConfigureMods/Panel/Control/Message.popup('Loading configs', 'found')
	var output_config = File.new()
	var config_dir = Directory.new()
	for config in json['configs']:
		var contents = config['contents']
		if config['optional'] == true:
			$ConfigureMods/Panel/Control/Panel/RichTextLabel.set_bbcode('[center]' + config['optional_prompt'] + '[/center]')
			$ConfigureMods/Panel/Control/Panel.show()
			yield($ConfigureMods/Panel/Control/Panel/Button, 'pressed')
			$ConfigureMods/Panel/Control/Panel.hide()
			if not $ConfigureMods/Panel/Control/Panel/CheckButton.pressed:
				contents = config['declined']

		var config_path = config['file'].split('/')
		if config_path.size() > 1:
			config_path = config_path[0]
		else:
			config_path = ''
		config_dir.make_dir_recursive(full_minecraft_path + '/BubbleClientHub/config/' + config_path)
		output_config.open(full_minecraft_path + '/BubbleClientHub/config/' + config['file'], File.WRITE)
		var output_string = ""
		for content in contents:
			if content is String:
				output_string += content + '\n'
			else:
				output_string = content
		
		output_config.store_string(JSON.print(output_string, '\t'))
		output_config.close()
	$ConfigureMods.hide()


func _on_InfoLink_meta_clicked(meta) -> void:
	OS.shell_open(meta)


func _on_Features_meta_clicked(meta) -> void:
	OS.shell_open(meta)


func _on_About_meta_clicked(meta) -> void:
	OS.shell_open(meta)
