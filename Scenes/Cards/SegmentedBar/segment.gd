extends TextureRect

class_name Segment
 
func Toggle(t : bool) -> void:
	if (t):
		modulate.a = 1
	else:
		modulate.a = 0
