extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
		
	if Input.is_action_just_pressed("Exit"):
		get_tree().quit()
