extends TextureRect

class_name WeatherManage

@export var N : FastNoiseLite
@export var LighAmm : Curve
@export var Debug : bool = false

static var WorldBounds : Vector2

static var Instance : WeatherManage

var tx : Image

static func GetInstance() -> WeatherManage:
	return Instance

func _ready() -> void:
	Instance = self
	tx = texture.get_image()

func SetWorldBounds(WB : Vector2) -> void:
	WorldBounds = WB
	position = Vector2(-WorldBounds.x, WorldBounds.y * 2)
	size = Vector2(WorldBounds.x * 2, -WorldBounds.y * 3)

var d = 0.2
func _physics_process(delta: float) -> void:
	d -= delta
	if (d <= 0):
		var t = Clock.GetInstance().TimePassedInMinutes()
		N.offset.y = -t / 10
		d = 0.2
		tx = texture.get_image()
		#queue_redraw()

#func _draw() -> void:
	#if (!Debug):
		#return
	#
	#for g : float in range(-10, 11):
		#var locx = (WorldBounds.x / 2) * (g / 10.0) - position.x
		#for z in range(-10, 10):
			#var loc = Vector2(locx, WorldBounds.y * (z / 10.0))
			#
			#var Col = Color(1,1,1)
			#Col *= get_color_at_global_position(loc)
			#Col.a = 1
			#draw_circle(loc, 50, Col)

func GetVisibilityInPosition(pos : Vector2) -> float:
	#N.offset.y = -Clock.GetInstance().TimePassedInMinutes()
	var t = Clock.GetInstance().GetHours()
	var Maxv = LighAmm.sample(t)
	#if (t < 20 and t > 6):
		#Maxv = 1
	var value = Helper.mapvalue(1 - get_color_at_global_position(pos).r, 0.5, Maxv)
	return value

func GetLightAmm() -> float:
	var t = Clock.GetInstance().GetHours()
	return LighAmm.sample(t)

func get_color_at_global_position(pos: Vector2) -> Color:
	# Step 1: Get the global transform
	var global_transform = get_global_transform()
	
	# Step 2: Invert the transformation matrix
	var inverse_transform = global_transform.affine_inverse()

	# Step 3: Use the inverse transform to get the local position
	var local_position = (inverse_transform * Vector2(pos.x, pos.y))
	
	var rect_size = get_rect().size
	
	# Step 3: Ensure the position is within the bounds of the TextureRect
	if local_position.x < 0 or local_position.x > rect_size.x or local_position.y < 0 or local_position.y > rect_size.y:
		return Color(0, 0, 0, 0)  # Return transparent color if out of bounds

	 # Step 5: Calculate UV coordinates based on Keep Aspect Covered
	var texture_size = texture.get_size()
	var rect_aspect_ratio = rect_size.x / rect_size.y
	var texture_aspect_ratio = texture_size.x / texture_size.y

	var scale = 1.0
	if texture_aspect_ratio > rect_aspect_ratio:
		scale = rect_size.x / texture_size.x  # Scale by the width
	else:
		scale = rect_size.y / texture_size.y  # Scale by the height

	# Scaled dimensions
	var scaled_width = texture_size.x * scale
	var scaled_height = texture_size.y * scale

	# Offsets to center the texture based on the clipping
	var offset_x = (rect_size.x - scaled_width) / 2.0
	var offset_y = (rect_size.y - scaled_height) / 2.0

	# Map local position to UV coordinates
	var uv = Vector2((local_position.x - offset_x) / scaled_width, 
					 (local_position.y - offset_y) / scaled_height)

	#tx.lock()  # Lock the image for pixel access
	var color = tx.get_pixel(uv.x * texture_size.x, clamp(uv.y * texture_size.y, 0, 511))
	#tx.unlock()  # Unlock after accessing

	return color
