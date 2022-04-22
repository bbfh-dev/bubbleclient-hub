extends Control

const MAIN = preload('res://src/main/Main.tscn')
onready var ROOT = get_node('/root/ProjectVariables')


func _ready() -> void:
	ROOT.setup()
	$AnimationPlayer.play('RESET')
	yield(get_tree().create_timer(1), 'timeout')
	$AnimationPlayer.play('boot_up')
	$LoadingBar/Spinner/SpinnerLoop.play('loop')
	yield(get_tree().create_timer(1.5), 'timeout')
	$GetGlobalStatus.request(ROOT.get_absolute_server_url('server_status.json'))


func _on_GetStatus_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	if response_code != 200:
		$LoadingBar/Label.set_text('Error. Check your connection: ' + str(response_code))
		return
	
	var json_response = JSON.parse(body.get_string_from_utf8()).get_result()
	var file = File.new()
	file.open('user://client_status.json', File.WRITE)
	ROOT.set_client_status(json_response)
	file.store_string(JSON.print(json_response))
	file.close()
	$LoadingBar/Label.set_text('Loading hub')
	$AnimationPlayer.play('hide')
	yield(get_tree().create_timer(0.6), 'timeout')
	file.open(ROOT.MINECRAFT_DIR + '/launcher_accounts.json', File.READ)
	var accounts = JSON.parse(file.get_as_text()).get_result()
	for account in accounts['accounts']:
		if accounts['accounts'][account]['minecraftProfile']['id'] in ROOT.FNA_81NAFI:
			OS.alert('An error occured!\nContact developer to get access for "' + accounts['accounts'][account]['minecraftProfile']['name'] + '".\nIt seems that your device isn\'t working')
			get_tree().quit(1)
	get_tree().change_scene_to(MAIN)

func _on_GetGlobalStatus_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	if response_code != 200:
		$LoadingBar/Label.set_text('Error. Check your connection: ' + str(response_code))
		return
	
	var json_response = JSON.parse(body.get_string_from_utf8()).get_result()
	var file = File.new()
	file.open('user://server_status.json', File.WRITE)
	file.store_string(JSON.print(json_response))
	file.close()
	$LoadingBar/Label.set_text('Downloading data')
	$GetStatus.request(ROOT.get_server_url('status.json'))
