extends TextureRect

class_name Light

@export var OffText : Texture
@export var Red : Texture
@export var Green : Texture

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

func ToggleNoAnim(t : bool, green : bool = false):
	if t :
		if green:
			texture = Green
		else:
			texture = Red
	else :
		texture = OffText
