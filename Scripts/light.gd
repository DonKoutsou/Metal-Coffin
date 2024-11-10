extends TextureRect

class_name Light

func Toggle(t : bool, green : bool = false):
	if t :
		if green:
			if !$AnimationPlayer.is_playing() :
				$AnimationPlayer.play("flickergreen")
		else:
			if !$AnimationPlayer.is_playing() :
				$AnimationPlayer.play("Flicket")
	else :
		$AnimationPlayer.stop()
