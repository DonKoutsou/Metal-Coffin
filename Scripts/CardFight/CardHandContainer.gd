@tool
extends Container

class_name CardHandContainer

@export var Vertical : bool = false

var Tweens : Array[Tween]

func _sort_children():
	# Gather only visible Control children
	var visible_children := []
	for child in get_children():
		if child is Control and child.visible:
			visible_children.append(child)
	
	for g in Tweens:
		g.kill()
	Tweens.clear()
	
	var child_count: int = visible_children.size()
	if child_count == 0:
		return
	
	var card_width: float
	var max_width: float
	if (Vertical):
		max_width = size.y
		card_width = visible_children[0].size.y
	else:
		max_width = size.x
		card_width = visible_children[0].size.x
	var overlap: float = 0.0
	
	# If cards can't all fit, compute overlap
	if child_count > 1:
		var needed_width: float = card_width * child_count
		if needed_width > max_width:
			overlap = (needed_width - max_width) / (child_count - 1)
			
	var step
	if (Vertical):
		step = (max_width / child_count) - overlap
	else:
		step = card_width - overlap
		
	
	var total_width = step * (child_count - 1) + card_width
	var start_x = (max_width - total_width) / 2.0

	# Assign positions only to visible children, as before
	for i in visible_children.size():
		var g = visible_children[i]
		var new_pos : Vector2
		if (Vertical):
			new_pos = Vector2(size.x/2 - g.size.x / 2, start_x + i * step)
		else:
			new_pos = Vector2(start_x + i * step, size.y/2 - g.size.y / 2,)
		if Engine.is_editor_hint():
			g.position = new_pos
		else:
			if g.position != new_pos:
				var tween = get_tree().create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_BACK)
				tween.tween_property(g, "position", new_pos, 0.25)\
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				Tweens.append(tween)
	
func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()
