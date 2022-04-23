extends Control

export (NodePath) var main_path
const LOG = preload('res://src/main/Log.tscn')
const PROMPT = preload('res://src/main/Prompt.tscn')
const MIGRATION_PROMPT = preload('res://src/main/MigrationPrompt.tscn')
onready var ROOT = get_node('/root/ProjectVariables')
onready var MAIN = get_node_or_null(main_path)
var downloader_arg = ''


func _ready() -> void:
	add_new_log('Ready to be installed', ROOT.BUBBLECLIENT_DIR.replace('AppData', '...').replace('Roaming', '...'), 'done')

func add_new_log(label: String, sublabel: String = '', status: String = 'loading') -> void:
	var new_child = LOG.instance()
	$FabricFound/Logs/Container.add_child(new_child)
	$FabricFound/Logs/Container.move_child(new_child, 0)
	update_last_log(label, sublabel, status)

func update_last_log(label: String, sublabel: String = '', status: String = 'loading'):
	$FabricFound/Logs/Container.get_child(0).set_log_data(label, sublabel, status)

func update_last_log_progress(value, max_value = -1) -> void:
	$FabricFound/Logs/Container.get_child(0).set_progress(value, max_value)

func _on_InstallUpdateButton_pressed() -> void:
	for child in $FabricFound/Logs/Container.get_children():
		$FabricFound/Logs/Container.remove_child(child)
	"""
	MODS:
	"""
	$FabricFound/Panel/InstallUpdateButton.set_disabled(true)
	$FabricFound/Panel/MigrateButton.set_disabled(true)
	MAIN.set_is_loading(true)
	add_new_log('Preparing to install', str(ROOT.CLIENT_STATUS['mods'].size()) + ' Mods', 'loading')
	yield(get_tree().create_timer(0.5), 'timeout')
	var dir = Directory.new()
	var file = File.new()
	var counter = 0
	for mod in ROOT.CLIENT_STATUS['mods']:
		counter += 1
		if mod['action'] == 'download':
			add_new_log('Searching for mod', mod['file'], 'check')
			yield(get_tree().create_timer(0.05), 'timeout')
			if file.file_exists(ROOT.BUBBLECLIENT_DIR + '/mods/' + mod['file']):
				update_last_log('Already installed', mod['file'], 'done')
			else:
				update_last_log('Downloading', mod['file'], 'downloading')
				dir.make_dir_recursive(ROOT.BUBBLECLIENT_DIR + '/mods/')
				$Downloader.set_download_file(ROOT.BUBBLECLIENT_DIR + '/mods/' + mod['file'])
				downloader_arg = mod['file']
				$Downloader.request(ROOT.get_absolute_server_url('mods/' + mod['file']))
				$Downloader.is_downloading = true
				update_last_log_progress(0, float(mod['size']))
				var file_size := File.new()
				yield(get_tree().create_timer(0.5), 'timeout')
				while ($Downloader.is_downloading):
					file_size.open(ROOT.BUBBLECLIENT_DIR + '/mods/' + mod['file'], File.READ)
					update_last_log_progress(file_size.get_len())
					file_size.close()
					yield(get_tree().create_timer(0.1), 'timeout')
		elif mod['action'] == 'remove':
			add_new_log('Searching for mod', mod['file'], 'check')
			if file.file_exists(ROOT.BUBBLECLIENT_DIR + '/mods/' + mod['file']):
				dir.remove(ROOT.BUBBLECLIENT_DIR + '/mods/' + mod['file'])
				update_last_log('Removed', mod['file'], 'done')
			else:
				update_last_log('Already removed', mod['file'], 'done')
		file.close()
		yield(get_tree().create_timer(0.05), 'timeout')
	add_new_log('Done!', 'Operations in total: ' + str(counter), 'done')
	yield(get_tree().create_timer(0.5), 'timeout')


	"""
	CONFIGS:
	"""
	add_new_log('Reading configuration data', ROOT.BUBBLECLIENT_DIR + '/config', 'loading')
	yield(get_tree().create_timer(1), 'timeout')
	var config_file = File.new()
	var regex = RegEx.new()
	regex.compile('\\S+\\/(\\S+\\/)?(\\S+\\/)?(\\S+\\/)?(\\S+\\/)?')
	for config in ROOT.CLIENT_STATUS['configs']:
		var re_match = ''
		if regex.search(config['filename']):
			re_match = regex.search(config['filename']).get_string()
		dir.make_dir_recursive(ROOT.BUBBLECLIENT_DIR + '/' + re_match)
		if not config_file.file_exists(ROOT.BUBBLECLIENT_DIR + '/' + config['filename']):
			config_file.open(ROOT.BUBBLECLIENT_DIR + '/' + config['filename'], File.WRITE)
			if config['contents'] is String:
				config_file.store_string(config['contents'])
			else:
				config_file.store_string(JSON.print(config['contents'], '\t'))
			config_file.close()
	update_last_log('Configured', ROOT.BUBBLECLIENT_DIR + '/config', 'done')

	"""
	LAUNCHER PROFILE:
	"""
	add_new_log('Creating profile', ROOT.MINECRAFT_DIR + '/launcher_profiles.json', 'loading')
	file.open(ROOT.MINECRAFT_DIR + '/launcher_profiles.json', File.READ_WRITE)
	var launcher = JSON.parse(file.get_as_text()).get_result()
	if 'fabric-loader-1.17.1' in launcher['profiles']:
		launcher['profiles']['fabric-loader-1.17.1']
		launcher['profiles']['fabric-loader-1.17.1']['name'] = 'BubbleClient 1.17.1'
		launcher['profiles']['fabric-loader-1.17.1']['icon'] = ROOT.ICON
		launcher['profiles']['fabric-loader-1.17.1']['gameDir'] = ROOT.BUBBLECLIENT_DIR
		
		var new_child = PROMPT.instance()
		$FabricFound/Logs/Container.add_child(new_child)
		$FabricFound/Logs/Container.move_child(new_child, 0)
		$FabricFound/Logs/Container.get_child(0).get_node('Label').set_text('Enter RAM Amount:')
		$FabricFound/Logs/Container.get_child(0).get_node('Description').set_text('The more RAM you allocate the smoother minecraft will be.\nBut be careful, do not allocate more\nthan 75% of your computer RAM!')
		yield($FabricFound/Logs/Container.get_child(0), 'next')
		var ram_size = $FabricFound/Logs/Container.get_child(0).get_node('Input').value
		launcher['profiles']['fabric-loader-1.17.1']['javaArgs'] = '-Xmx' + str(ram_size) + 'G -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M'
		file.store_string(JSON.print(launcher, '\t'))
		add_new_log('Created profile', 'BubbleClient 1.17.1', 'done')
		MAIN.set_is_loading(false)
		$FabricFound/Panel/InstallUpdateButton.set_disabled(false)
		$FabricFound/Panel/MigrateButton.set_disabled(false)
	else:
		update_last_log('Failed to add profile', '"fabric-loader-1.17.1" not found! Please, reinstall fabric', 'error')
	file.close()


func _on_MigrateButton_pressed() -> void:
	for child in $FabricFound/Logs/Container.get_children():
		$FabricFound/Logs/Container.remove_child(child)
	add_new_log('This is going to migrate your settings/server list from other client!')
	var child = MIGRATION_PROMPT.instance()
	var file = File.new()
	file.open(ROOT.MINECRAFT_DIR + '/launcher_profiles.json', File.READ)
	var launcher = JSON.parse(file.get_as_text()).get_result()
	var options = []
	for profile in launcher['profiles']:
		if 'name' in launcher['profiles'][profile] and launcher['profiles'][profile]['name'] != '':
			child.get_node('OptionButton').add_item(launcher['profiles'][profile]['name'])
		else:
			child.get_node('OptionButton').add_item(launcher['profiles'][profile]['lastVersionId'])
		options.append(profile)
	$FabricFound/Logs/Container.add_child(child)
	$FabricFound/Logs/Container.move_child(child, 0)
	yield(child.get_node('ContinueButton'), 'pressed')
	var selected_profile = launcher['profiles'][options[child.get_node('OptionButton').get_selected_id()]]
	var selected_profile_dir = ROOT.MINECRAFT_DIR
	if 'gameDir' in launcher['profiles'][options[child.get_node('OptionButton').get_selected_id()]]:
		selected_profile_dir = launcher['profiles'][options[child.get_node('OptionButton').get_selected_id()]]['gameDir']
	file.close()

	"""
	MIGRATE
	"""
	
	store_from_to(selected_profile_dir + '/options.txt', ROOT.BUBBLECLIENT_DIR + '/options.txt')
	store_from_to(selected_profile_dir + '/servers.dat', ROOT.BUBBLECLIENT_DIR + '/servers.dat')
	var dir = Directory.new()
	if dir.open(selected_profile_dir + '/resourcepacks') == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			else:
				dir.make_dir_recursive(ROOT.BUBBLECLIENT_DIR + '/resourcepacks')
				store_from_to(selected_profile_dir + '/resourcepacks/' + file_name, ROOT.BUBBLECLIENT_DIR + '/resourcepacks/' + file_name)
			file_name = dir.get_next()
	add_new_log('Settings migrated', 'from ' + selected_profile_dir, 'done')


func store_from_to(source: String, target: String) -> void:
	var file = File.new()
	var file_source = File.new()
	file_source.open(source, File.READ)
	file.open(target, File.WRITE)
	file.store_buffer(file_source.get_buffer(file_source.get_len()))
	file_source.close()
	file.close()
