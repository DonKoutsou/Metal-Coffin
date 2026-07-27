class_name ViewportSizer
extends TextureRect


@export var target_viewport: SubViewport

var _base_render_size: Vector2 = Vector2()
var _window: Window


func _ready():
	_window = get_tree().root as Window
	_window.size_changed.connect(update_size)
	_base_render_size = target_viewport.size


## Calculates a scale for width and height, and applies the lower of the two.
##
## This assumes the following display settings:
## - display/window/stretch/mode: canvas_items
## - display/window/stretch/aspect: expand
func update_size():
	# Cast from Vector2i (integer) to Vector2 (float) for smooth results
	var current_viewport_size: Vector2 = _window.size
	var reference_viewport_size: Vector2 = _window.content_scale_size
	
	var viewport_scale: Vector2 = current_viewport_size / reference_viewport_size
	var size_scale: float = minf(viewport_scale.x, viewport_scale.y)
	
	# Round back to integer size to prevent truncation
	var scaled_size: Vector2i = (_base_render_size * size_scale).round()
	target_viewport.size = scaled_size
