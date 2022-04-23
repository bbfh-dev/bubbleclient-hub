extends HTTPRequest

export (NodePath) var installation_path
onready var installation = get_node(installation_path)
var is_downloading := true

signal next


func _on_Downloader_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray) -> void:
	if response_code != 200:
		installation.update_last_log('Could not download', installation.downloader_arg, 'error')
	else:
		installation.update_last_log('Download', installation.downloader_arg, 'done')
	emit_signal('next')
	is_downloading = false
