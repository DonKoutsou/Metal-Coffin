@tool
extends Container

class_name FanCardHandContainer

@export var max_rotation_degrees: float = 45.0  # Maximum rotation in degrees
@export var max_cards: int = 10  # Maximum number of cards in the container

func _sort_children():
	# Gather only visible Control children
	var visible_children = []
	for child in get_children():
		if child is Control and child.visible:
			visible_children.append(child)

	var child_count: int = visible_children.size()
	if child_count == 0:
		return
	
	var card_width: float = visible_children[0].size.x  # Use rect_size for correct width
	var max_width: float = size.x

	# Determine total required width for all cards
	var total_width: float = card_width * child_count
	
	# Calculate overlap if cards don't fit
	var overlap: float = 0.0
	if total_width > max_width:
		overlap = (total_width - max_width) / (max(1, child_count - 1))

	var step: float = card_width - overlap
	var start_x: float = (max_width - (card_width * child_count - (overlap * (max(1, child_count - 1))))) / 2.0

	# Calculate effective rotation
	var scale_factor: float = total_width / max_width
	var effective_rotation: float = max_rotation_degrees * (scale_factor - 1) # Increase rotation as the container gets smaller
	effective_rotation = clamp(effective_rotation, 0, max_rotation_degrees)

	# Assign positions and rotations to visible children
	for i in range(child_count):
		var g = visible_children[i]
		var new_pos: Vector2 = Vector2(start_x + i * step, 0)
		g.pivot_offset = Vector2(g.size.x / 2, g.size.y)
		
		 # Calculate rotation - handle single card special case
		var rotation_amount: float
		if child_count == 1:
			rotation_amount = 0.0  # No rotation for single card
		else:
			rotation_amount = -effective_rotation + (i / float(child_count - 1)) * (2 * effective_rotation)
			
		if (g.position != new_pos):
			if Engine.is_editor_hint():
				g.position = new_pos
			else:
				pass
				var tween = get_tree().create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_BACK)
				tween.tween_property(g, "position", new_pos, 0.25)
				
		if (g.rotation_degrees != rotation_amount):
			if Engine.is_editor_hint():
				g.rotation_degrees = rotation_amount
			else:
				var tween = get_tree().create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_BACK)
				tween.tween_property(g, "rotation_degrees", rotation_amount, 0.25)


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()
