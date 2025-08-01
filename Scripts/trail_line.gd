@tool
extends Line2D

class_name TrailLine
# Parameters to adjust the trail behavior
@export var max_points: int = 50
@export var trail_fade_speed: float = 1.0
@export var min_distance: float = 5.0
@export var ManualInit : bool
# Internally used to track movement
var last_position: Vector2
var stationary_time: float = 0.0

var  PointPos : Array[Vector2] = []


func _exit_tree() -> void:
	clear_points()

func _enter_tree() -> void:
	if (ManualInit):
		return
	Init()

func Init() -> void:
	clear_points()
	#position = Vector2(0,0)
	PointPos.clear()
	last_position = global_position
	PointPos.append(Vector2(0,0))
	#print (PointPos)
	add_point(Vector2(0,0))

func Update(delta: float) -> void:

	#global_position - (CamPos - global_position) * Zoom * lerp(0.0, 0.03, Altitude / 10000.0)
	# Check if the position has changed
	if last_position.distance_squared_to(global_position) > min_distance * min_distance:
		PointPos.insert(1, last_position)
		#print(last_position)
		#print (PointPos)
		add_point(to_local(last_position))
		last_position = global_position
		#stationary_time = 0.0

	stationary_time += delta
	if stationary_time >= trail_fade_speed:
		if get_point_count() > 1:
			#print(PointPos)
			#print("remove")
			PointPos.remove_at(PointPos.size() - 1)
			remove_point(get_point_count() - 1)
			stationary_time = 0
			#print(PointPos)
			
	if (get_point_count() > 1):
		for g in range(1, get_point_count(), 1):

			set_point_position(g, to_local(PointPos[g]))
			#print(g, PointPos[g])
	# Keep the number of points under the max_points limit
	while points.size() > max_points:
		PointPos.remove_at(PointPos.size() - 1)
		remove_point(get_point_count() - 1)

func UpdateProjected(delta: float, paralax : float) -> void:
	
	#var base_uv = (global_position / lerp(0.0, 0.008, paralax)) / 2.0 + Vector2(0.5, 0.5)
	
	
	var Cam = ShipCamera.GetInstance()
	var CamPos = Cam.get_screen_center_position()
	#var screen_uv = (CamPos / get_viewport_rect().size) # Use your viewport's size to normalize
	#var offset = (screen_uv - Vector2(0.5, 0.5)) * paralax
	#var shadow_uv = base_uv - offset
	#var new_position = (shadow_uv - Vector2(0.5, 0.5)) * lerp(0.0, 0.008, paralax) # Scale back to world space
	var Zoom = Cam.zoom.x
	var Offset = (CamPos - global_position) * Zoom * 0.88 * paralax * 0.05
	Offset.x /= 1.65

	#global_position - (CamPos - global_position) * Zoom * lerp(0.0, 0.03, Altitude / 10000.0)
	# Check if the position has changed
	if last_position.distance_squared_to(global_position) > min_distance * min_distance:
		PointPos.insert(1, last_position)
		#print(last_position)
		#print (PointPos)
		add_point(to_local(last_position))
		last_position =  global_position
		#stationary_time = 0.0

	stationary_time += delta
	if stationary_time >= trail_fade_speed:
		if get_point_count() > 1:
			#print(PointPos)
			#print("remove")
			PointPos.remove_at(PointPos.size() - 1)
			remove_point(get_point_count() - 1)
			stationary_time = 0
			#print(PointPos)
	
	set_point_position(0, to_local(global_position - Offset))
	
	if (get_point_count() > 1):
		for g in range(1, get_point_count(), 1):
			#if (g == get_point_count()  - 1):
			#print(g)
			#print (PointPos)

			set_point_position(g, to_local(PointPos[g] - Offset))
			#print(g, PointPos[g])
	# Keep the number of points under the max_points limit
	while points.size() > max_points:
		PointPos.remove_at(PointPos.size() - 1)
		remove_point(get_point_count() - 1)
