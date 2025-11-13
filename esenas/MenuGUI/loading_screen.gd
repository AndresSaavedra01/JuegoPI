extends Control

func _ready():
	ResourceLoader.load_threaded_request(LoadingController.next_scene)
	
func _process(delta):
	var progress = []
	ResourceLoader.load_threaded_get_status(LoadingController.next_scene, progress)
	$Panel/VBoxContainer/progress_bar.value = progress[0]*100
	#$progress_number.text = str(progress[0]*100)+"%"
	
	if progress[0] == 1:
		var packed_Scene = ResourceLoader.load_threaded_get(LoadingController.next_scene)
		get_tree().change_scene_to_packed(packed_Scene)
