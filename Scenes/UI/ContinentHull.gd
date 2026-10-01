class_name ContinentGenerator
extends RefCounted


const EPSILON := 0.001
const MAX_MERGE_PASSES := 100


# ================================================================
# PUBLIC
#
# Returns:
#
# Array[
#     Array[PackedVector2Array]
# ]
#
# Each continent can have one or more polygon pieces.
# ================================================================

static func generate(
	continents: Array[PackedVector2Array],
	map_bounds: Rect2
) -> Array:

	var all_points := PackedVector2Array()
	var point_owner := PackedInt32Array()


	# ------------------------------------------------------------
	# Collect all points.
	# ------------------------------------------------------------

	for continent_id in continents.size():

		for point in continents[continent_id]:

			all_points.append(point)
			point_owner.append(continent_id)


	# ------------------------------------------------------------
	# Not enough points.
	# ------------------------------------------------------------

	if all_points.size() < 3:

		var fallback_result: Array = []

		for continent in continents:

			if continent.size() >= 3:

				fallback_result.append([
					Geometry2D.convex_hull(continent)
				])

			else:

				fallback_result.append([
					continent
				])

		return fallback_result


	# ------------------------------------------------------------
	# Build bounded Voronoi cells.
	# ------------------------------------------------------------

	var cells: Array[PackedVector2Array] = []

	for point_id in all_points.size():

		var cell := _build_cell(
			point_id,
			all_points,
			map_bounds
		)

		cells.append(cell)


	# ------------------------------------------------------------
	# Group cells by continent.
	# ------------------------------------------------------------

	var result: Array = []

	for continent_id in continents.size():

		var continent_cells: Array[PackedVector2Array] = []

		for point_id in all_points.size():

			if point_owner[point_id] != continent_id:
				continue

			if cells[point_id].size() >= 3:

				continent_cells.append(
					cells[point_id]
				)


		var merged := _merge_cells_safe(
			continent_cells
		)

		result.append(merged)


	return result


# ================================================================
# BOUNDED VORONOI CELL
# ================================================================

static func _build_cell(
	point_id: int,
	points: PackedVector2Array,
	bounds: Rect2
) -> PackedVector2Array:

	var site := points[point_id]

	var cell := _rect_polygon(bounds)


	for other_id in points.size():

		if other_id == point_id:
			continue


		var other := points[other_id]


		if site.distance_squared_to(other) <= (
			EPSILON * EPSILON
		):
			continue


		cell = _clip_to_half_plane(
			cell,
			site,
			other
		)


		if cell.size() < 3:

			return PackedVector2Array()


	return _clean_polygon(cell)


# ================================================================
# VORONOI HALF-PLANE CLIPPING
# ================================================================

static func _clip_to_half_plane(
	polygon: PackedVector2Array,
	site: Vector2,
	other: Vector2
) -> PackedVector2Array:

	if polygon.size() < 3:
		return PackedVector2Array()


	var normal := other - site

	var limit := (
		other.length_squared()
		-
		site.length_squared()
	) * 0.5


	var result := PackedVector2Array()


	var previous := polygon[
		polygon.size() - 1
	]

	var previous_value := (
		normal.dot(previous) - limit
	)

	var previous_inside := (
		previous_value <= EPSILON
	)


	for current in polygon:

		var current_value := (
			normal.dot(current) - limit
		)

		var current_inside := (
			current_value <= EPSILON
		)


		# Outside -> Inside
		if current_inside and not previous_inside:

			result.append(
				_line_intersection(
					previous,
					current,
					previous_value,
					current_value
				)
			)


		# Inside -> Inside
		if current_inside:

			result.append(current)


		# Inside -> Outside
		elif previous_inside:

			result.append(
				_line_intersection(
					previous,
					current,
					previous_value,
					current_value
				)
			)


		previous = current
		previous_value = current_value
		previous_inside = current_inside


	return _remove_duplicate_points(result)


# ================================================================
# LINE INTERSECTION
# ================================================================

static func _line_intersection(
	a: Vector2,
	b: Vector2,
	a_value: float,
	b_value: float
) -> Vector2:

	var denominator := a_value - b_value

	if abs(denominator) < EPSILON:

		return a


	var t := a_value / denominator

	t = clamp(t, 0.0, 1.0)

	return a.lerp(b, t)


# ================================================================
# SAFE CELL MERGING
#
# IMPORTANT:
#
# This function has a HARD upper bound on work.
#
# No while(true).
# No potentially endless geometry cycle.
# ================================================================

static func _merge_cells_safe(
	cells: Array[PackedVector2Array]
) -> Array[PackedVector2Array]:

	if cells.is_empty():

		return []


	var polygons: Array[PackedVector2Array] = []


	for cell in cells:

		if cell.size() >= 3:

			polygons.append(cell)


	if polygons.size() <= 1:

		return polygons


	# ------------------------------------------------------------
	# At most N-1 successful merges are necessary to combine N
	# connected pieces.
	#
	# We perform at most N passes, each examining pairs once.
	# ------------------------------------------------------------

	var max_passes = min(
		MAX_MERGE_PASSES,
		polygons.size()
	)


	for p in max_passes:

		var did_merge = false


		for i in range(polygons.size()):

			if i >= polygons.size():
				break


			for j in range(i + 1, polygons.size()):

				if j >= polygons.size():
					break


				var a := polygons[i]
				var b := polygons[j]


				if not _polygons_touch(a, b):
					continue


				var merged := Geometry2D.merge_polygons(
					a,
					b
				)


				if merged.is_empty():
					continue


				# ------------------------------------------------
				# Remove old polygons.
				# ------------------------------------------------

				polygons.remove_at(j)
				polygons.remove_at(i)


				# ------------------------------------------------
				# Add merged result.
				# ------------------------------------------------

				for polygon in merged:

					if polygon.size() >= 3:

						polygons.append(
							_clean_polygon(polygon)
						)


				did_merge = true

				break


			if did_merge:
				break


		# --------------------------------------------------------
		# No more merges possible.
		# --------------------------------------------------------

		if not did_merge:

			break


		# --------------------------------------------------------
		# Usually we're done after N-1 merges.
		# --------------------------------------------------------

		if polygons.size() <= 1:

			break


	return polygons


# ================================================================
# POLYGON TOUCH TEST
# ================================================================

static func _polygons_touch(
	a: PackedVector2Array,
	b: PackedVector2Array
) -> bool:

	var tolerance := EPSILON * 10.0
	var tolerance_squared := tolerance * tolerance


	# ------------------------------------------------------------
	# Vertex tests.
	# ------------------------------------------------------------

	for point in a:

		if Geometry2D.is_point_in_polygon(
			point,
			b
		):

			return true


		if _point_near_polygon(
			point,
			b,
			tolerance_squared
		):

			return true


	for point in b:

		if Geometry2D.is_point_in_polygon(
			point,
			a
		):

			return true


		if _point_near_polygon(
			point,
			a,
			tolerance_squared
		):

			return true


	# ------------------------------------------------------------
	# Edge tests.
	# ------------------------------------------------------------

	for i in a.size():

		var a1 := a[i]
		var a2 := a[(i + 1) % a.size()]


		for j in b.size():

			var b1 := b[j]
			var b2 := b[(j + 1) % b.size()]


			if _segments_close(
				a1,
				a2,
				b1,
				b2,
				tolerance_squared
			):

				return true


	return false


# ================================================================
# POINT NEAR POLYGON
# ================================================================

static func _point_near_polygon(
	point: Vector2,
	polygon: PackedVector2Array,
	tolerance_squared: float
) -> bool:

	for i in polygon.size():

		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]


		var closest := (
			Geometry2D.get_closest_point_to_segment(
				point,
				a,
				b
			)
		)


		if point.distance_squared_to(
			closest
		) <= tolerance_squared:

			return true


	return false


# ================================================================
# SEGMENTS CLOSE
# ================================================================

static func _segments_close(
	a1: Vector2,
	a2: Vector2,
	b1: Vector2,
	b2: Vector2,
	tolerance_squared: float
) -> bool:

	if a1.distance_squared_to(b1) <= tolerance_squared:
		return true

	if a1.distance_squared_to(b2) <= tolerance_squared:
		return true

	if a2.distance_squared_to(b1) <= tolerance_squared:
		return true

	if a2.distance_squared_to(b2) <= tolerance_squared:
		return true


	var p := Geometry2D.get_closest_point_to_segment(
		a1,
		b1,
		b2
	)

	if a1.distance_squared_to(p) <= tolerance_squared:
		return true


	p = Geometry2D.get_closest_point_to_segment(
		a2,
		b1,
		b2
	)

	if a2.distance_squared_to(p) <= tolerance_squared:
		return true


	p = Geometry2D.get_closest_point_to_segment(
		b1,
		a1,
		a2
	)

	if b1.distance_squared_to(p) <= tolerance_squared:
		return true


	p = Geometry2D.get_closest_point_to_segment(
		b2,
		a1,
		a2
	)

	if b2.distance_squared_to(p) <= tolerance_squared:
		return true


	return false


# ================================================================
# RECTANGLE
# ================================================================

static func _rect_polygon(
	rect: Rect2
) -> PackedVector2Array:

	return PackedVector2Array([
		rect.position,
		Vector2(
			rect.end.x,
			rect.position.y
		),
		rect.end,
		Vector2(
			rect.position.x,
			rect.end.y
		)
	])


# ================================================================
# CLEAN POLYGON
# ================================================================

static func _clean_polygon(
	polygon: PackedVector2Array
) -> PackedVector2Array:

	var result := _remove_duplicate_points(
		polygon
	)


	if result.size() < 3:

		return PackedVector2Array()


	var cleaned := PackedVector2Array()


	for i in result.size():

		var previous := result[
			(i - 1 + result.size())
			% result.size()
		]

		var current := result[i]

		var next := result[
			(i + 1)
			% result.size()
		]


		var ab := current - previous
		var bc := next - current


		if ab.length_squared() <= (
			EPSILON * EPSILON
		):

			continue


		if bc.length_squared() <= (
			EPSILON * EPSILON
		):

			continue


		if abs(ab.cross(bc)) <= EPSILON:

			continue


		cleaned.append(current)


	return cleaned


# ================================================================
# REMOVE DUPLICATE POINTS
# ================================================================

static func _remove_duplicate_points(
	polygon: PackedVector2Array
) -> PackedVector2Array:

	if polygon.is_empty():

		return PackedVector2Array()


	var result := PackedVector2Array()

	var epsilon_squared := (
		EPSILON * EPSILON
	)


	for point in polygon:

		if result.is_empty():

			result.append(point)
			continue


		if point.distance_squared_to(
			result[result.size() - 1]
		) > epsilon_squared:

			result.append(point)


	if result.size() >= 2:

		if result[0].distance_squared_to(
			result[result.size() - 1]
		) <= epsilon_squared:

			result.remove_at(
				result.size() - 1
			)


	return result
