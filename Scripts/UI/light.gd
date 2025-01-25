extends TextureRect

class_name Light

func Toggle(t : bool, green : bool = false):
	if t :
		if green:
			if $AnimationPlayer.current_animation != "flickergreen" :
				$AnimationPlayer.play("flickergreen")
		else:
			if $AnimationPlayer.current_animation != "Flicket" :
				$AnimationPlayer.play("Flicket")
	else :
		$AnimationPlayer.stop()
