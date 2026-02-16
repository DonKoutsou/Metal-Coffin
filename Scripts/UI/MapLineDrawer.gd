extends Node2D

class_name MapLineDrawer

var Lines : Array

@export var RoadLines : bool = false
@export var ResizeLinesWithZoom : bool = false
@export var PathTexture : Texture2D

var GenerationThread : Thread

signal PathsGenerated()

func _ready() -> void:
	if (ResizeLinesWithZoom):
		add_to_group("ZoomAffected")


func UpdateCameraZoom(NewZoom : float) -> void:
	for g in get_children():
		g.width =  1 / NewZoom
		g.visible = NewZoom < 1.5

func Generate(SpotLocs : PackedVector2Array) -> void:
	GenerationThread = Thread.new()
	GenerationThread.start(_DrawMapLines.bind(SpotLocs))

func _DrawMapLines(SpotLocs : PackedVector2Array) -> void:
	var time = Time.get_ticks_msec()
	if (OS.is_debug_build()):
		print("Started generating paths between cities")
		
	Lines = _prim_mst_optimized(SpotLocs)
	Lines = AddExtraLines(SpotLocs, Lines.duplicate())
	
	#If road randomise them a bit to look more organic
	if (RoadLines):
		for l in Lines:
			var Line = l as Array
			var point1 = Line[0]
			var point2 = Line[1]
			Line.remove_at(1)
			#l.remove_point(1)
			
			var dir = point1.direction_to(point2)
			
			var dist = point1.distance_to(point2)
			var pointamm = roundi(dist / 80)
			var offsetperpoint = dist/pointamm
			for g in pointamm:
				var offs = (dir * (offsetperpoint * g)) + Vector2(randf_range(-20, 20), randf_range(-20, 20))
				#Mut.lock()
				Line.append(point1 + offs)
				#Mut.unlock()
			Line.append(point2)
		
		
	call_deferred("GenerationFinished")
	
	if (OS.is_debug_build()):
		print("Generating paths finished in " + var_to_str(Time.get_ticks_msec() - time) + " ms")

func GenerationFinished() -> void:
	GenerationThread.wait_to_finish()
	
	if (RoadLines):
		pass
		#for g in Lines:
			#var l = g as Array[Vector2]
			#g[0] += (l[0].direction_to(l[l.size() - 1]) * 42)
			#g[l.size() - 1] += (l[l.size() - 1].direction_to(l[0]) * 42)
	else:
		PathsGenerated.emit(Lines)
		
	DrawLines()


func DrawLines() -> void:
	for g in get_children():
		g.queue_free()
	
	for points in Lines:
		
		if (points.size() == 0):
			continue
		
		
		var smoothedline
		if (RoadLines):
			smoothedline = Helper.SmoothLine2(points, 20)
		else:
			smoothedline = points
		var L = Line2D.new()
		
		L.joint_mode = Line2D.LINE_JOINT_ROUND
		L.begin_cap_mode = Line2D.LINE_CAP_ROUND
		L.end_cap_mode = Line2D.LINE_CAP_ROUND
		L.round_precision = 4
		
		L.use_parent_material = true
		L.width = 20
		
		if (!RoadLines):
			L.default_color = Color(1,1,1, 1)
		else:
			L.texture = PathTexture
			L.texture_mode = Line2D.LINE_TEXTURE_TILE
			L.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			#L.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			#L.texture = load("res://Assets/Sand/Tiles093_1K-PNG_Color.png")
			#L.default_color = Color(0,0,0, 1)
			L.width = 5
		add_child(L)
		L.global_position = points[0]
		#L.default_color = Color("0ca50a")
		#L.add_point(Vector2.ZERO, 0)
		for z in smoothedline.size():
			L.add_point(smoothedline[z] - L.global_position, z)

#func DrawLines() -> void:
	#for g in get_children():
		#g.queue_free()
	#
	#for points in Lines:
		#
		#if (points.size() == 0):
			#continue
		#
		#
		#var smoothedline
		#if (RoadLines):
			#smoothedline = Helper.SmoothLine2(points, 5)
		#else:
			#smoothedline = points
		#var L
		#
		#if RoadLines:
			#L = LinePath2D.new()
			#add_child(L)
			#L.global_position = points[0]
			##L.cap_joint_mode = Line2D.LINE_JOINT_ROUND
			##L.cap_begin_cap = Line2D.LINE_CAP_ROUND
			##L.cap_end_cap = Line2D.LINE_CAP_ROUND
			##L.border_round_precision = 4
			#L.fill_texture = PathTexture
			#L.fill_texture_mode = Line2D.LINE_TEXTURE_TILE
			#L.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			#L.width = 5
			#
			#var LocalPoints : Array
			#for g in smoothedline.size():
				#LocalPoints.append(smoothedline[g] - L.global_position)
				#
			#var c = Helper.array_to_curve(LocalPoints, 10)
				#
			#L._curve = c
			#L.width_profile = null
		#else:
			#L = Line2D.new()
			#add_child(L)
			#L.global_position = points[0]
			#L.joint_mode = Line2D.LINE_JOINT_ROUND
			#L.begin_cap_mode = Line2D.LINE_CAP_ROUND
			#L.end_cap_mode = Line2D.LINE_CAP_ROUND
			#L.round_precision = 4
			#L.default_color = Color(1,1,1, 1)
			#L.width = 20
		#
			#for z in smoothedline.size():
				#L.add_point(smoothedline[z] - L.global_position, z)
		#
		#
		#L.use_parent_material = true

#NEW MUCH SIMPLER ALGORITH FOR LINES
func AddExtraLines(cities : Array, Lines : Array) -> Array:
	for g in cities:
		var ConnectionAmmount : int = 0
		for z in cities:
			if (Lines.has([g, z])):
				ConnectionAmmount += 1
		var Dist = 2000
		while (ConnectionAmmount < 3):
			Dist += 500
			if (Dist >= 4000):
				break
			for z in cities:
				if (ConnectionAmmount > 2):
					break
				if (Lines.has([g, z]) or Lines.has([z, g])):
					continue
				if (z.distance_to(g) < Dist):
					Lines.append([g, z])
					ConnectionAmmount += 1
	return Lines
	
#OLD ALGORITH FOR LINES
# Helper function: Push an element to the heap
func _heap_push(heap: Array, element: Array):
	heap.append(element)
	var i = heap.size() - 1
	while i > 0:
		var parent = (i - 1)
		if heap[i][0] >= heap[parent][0]:
			break
		_swap(heap, i, parent)
		i = parent
		
		
func _swap(arr: Array, i: int, j: int):
	var tmp = arr[i]
	arr[i] = arr[j]
	arr[j] = tmp
	
	
# Helper function: Pop an element from the heap
func _heap_pop(heap: Array) -> Array:
	_swap(heap, 0, heap.size() - 1)
	var result = heap.pop_back()
	var i = 0
	while i < heap.size():
		var left_child = 2 * i + 1
		var right_child = 2 * i + 2

		var smallest = i
		if left_child < heap.size() and heap[left_child][0] < heap[smallest][0]:
			smallest = left_child
		if right_child < heap.size() and heap[right_child][0] < heap[smallest][0]:
			smallest = right_child
		
		if smallest == i:
			break
		_swap(heap, i, smallest)
		i = smallest
	
	return result
	

func _prim_mst_optimized(cities: Array) -> Array:
	var num_cities = cities.size()
	if num_cities <= 1:
		return []
	
	var connected = PackedInt32Array()
	connected.append(0)  # Start with the first city connected
	
	var edge_min_heap = []
	var mst_edges = []

	# Add all edges from city 0 to the heap
	for i in range(1, num_cities):
		var distance = cities[0].distance_to(cities[i])
		_heap_push(edge_min_heap, [distance, 0, i])

	while connected.size() < num_cities:
		# Pop the smallest edge from the heap
		var min_edge = _heap_pop(edge_min_heap)
		#var dist = min_edge[0]
		var u = min_edge[1]
		var v = min_edge[2]

		if not connected.has(v):
			connected.append(v)
			mst_edges.append([cities[u], cities[v]])

			# Add all edges from this newly connected city to the heap
			for j in range(num_cities):
				if not connected.has(j):
					var new_distance = cities[v].distance_to(cities[j])
					_heap_push(edge_min_heap, [new_distance, v, j])

	return mst_edges
