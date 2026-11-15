extends AudioStreamPlayer

func _process(_delta: float):
	if Input.is_action_just_pressed("mute"):
		if self.playing:
			self.stop()
		else:
			self.play()
