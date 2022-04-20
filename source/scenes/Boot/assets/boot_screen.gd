extends Control
class_name Boot

const hub := preload('res://source/scenes/Hub/Hub.tscn')
const updater := preload('res://source/scenes/Updater/Updater.tscn')
var http_request_task := 'status'
var promise := ''


func _ready() -> void:
	var version_file = File.new()
	version_file.open('user://version.txt', File.WRITE)
	version_file.store_string('0.1b')
	version_file.close()
	
	http_request_task = 'status'
	$HTTPRequest.request('https://raw.githubusercontent.com/bubblefish-dev/bubbleclient-server/main/status.txt')


func load_hub() -> void:
	promise = 'hub'
	$ConnectingToServer.set_text('Getting latest configs')
	http_request_task = 'configlist'
	$HTTPRequest.request('https://raw.githubusercontent.com/bubblefish-dev/bubbleclient-server/main/configs.json')

func execute_promise() -> void:
	if promise == 'hub':
		OS.set_borderless_window(false)
		get_tree().change_scene_to(hub)
	elif promise == 'updater':
		OS.set_borderless_window(false)
		OS.set_window_resizable(true)
		get_tree().change_scene_to(updater)


func load_updater() -> void:
	promise = 'updater'
	$ConnectingToServer.set_text('Getting latest modlist')
	http_request_task = 'modlist'
	$HTTPRequest.request('https://raw.githubusercontent.com/bubblefish-dev/bubbleclient-server/main/mods/list.txt')

func _on_HTTPRequest_request_completed(result: int, response_code: int, headers: PoolStringArray, body) -> void:
	if not response_code == 200:
		$ConnectingToServer.text = "Connected failed with code " + String(response_code) + "\nPlease restart!"
		yield(get_tree().create_timer(2), 'timeout')
		get_tree().quit()
	
	if http_request_task == 'status':
		var version = body.get_string_from_utf8()
		var file = File.new()
		
		if file.file_exists('user://version.txt'):
			file.open('user://version.txt', File.READ)
			var content = file.get_as_text()
			file.close()
			if content in version:
				yield(get_tree().create_timer(0.5), 'timeout')
				load_hub()
			else:
				yield(get_tree().create_timer(0.5), 'timeout')
				load_updater()
		else:
			file.open('user://version.txt', File.WRITE)
			file.store_string(version)
			file.close()
			yield(get_tree().create_timer(0.5), 'timeout')
			load_hub()
	elif http_request_task == 'modlist':
		var modlist = body.get_string_from_utf8()
		var file = File.new()
		file.open('user://modlist.txt', File.WRITE)
		file.store_string(modlist)
		file.close()
		execute_promise()
	elif http_request_task == 'configlist':
		var configlist = body.get_string_from_utf8()
		var file = File.new()
		file.open('user://configs.json', File.WRITE)
		var json_config = JSON.parse(configlist).get_result()
		file.store_string(JSON.print(json_config, '\t'))
		file.close()
		$ConnectingToServer.set_text('Getting latest modlist')
		http_request_task = 'modlist'
		$HTTPRequest.request('https://raw.githubusercontent.com/bubblefish-dev/bubbleclient-server/main/mods/list.txt')
