extends PanelContainer

class_name CurrentShipPanel

func SetText(Text : Array[String]) -> void:
	if ($VBoxContainer.get_child_count() != Text.size()):
		for g in $VBoxContainer.get_children():
			g.free()
			
		for g in Text.size():
			var Hb = HBoxContainer.new()
			var Sep = Control.new()
			#Hb.alignment = BoxContainer.ALIGNMENT_END
			var L = Label.new()
			
			L.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			L.text = Text[g]
			
			$VBoxContainer.add_child(Hb)
			Hb.add_child(L)
			Hb.add_child(Sep)
			
			Sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			Hb.alignment = BoxContainer.ALIGNMENT_END
			Hb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			L.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			L.add_theme_font_size_override("", 14)
	else:
		for g in Text.size():
			$VBoxContainer.get_child(g).get_child(0).text = Text[g]

func SetSelected(S : int = -1) -> void:
	for g in $VBoxContainer.get_child_count():
		var c = $VBoxContainer.get_child(g).get_child(1) as Control
		if (S == g):
			if (c.custom_minimum_size.x != 50):
				var tw = create_tween()
				tw.set_ease(Tween.EASE_OUT)
				tw.set_trans(Tween.TRANS_QUAD)
				tw.tween_property(c, "custom_minimum_size", Vector2(20, 0), 0.5)
		else:
			if (c.custom_minimum_size.x != 0):
				var tw = create_tween()
				tw.set_ease(Tween.EASE_OUT)
				tw.set_trans(Tween.TRANS_QUAD)
				tw.tween_property(c, "custom_minimum_size", Vector2(0, 0), 0.5)
