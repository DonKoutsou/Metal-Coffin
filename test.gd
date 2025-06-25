extends Control

@export var start_eff = 6
@export var start_cap = 100
@export var points = 8   # how many "doublings" you want to look at

func _physics_process(delta: float) -> void:
	queue_redraw()

func _draw():
	var font = get_theme_default_font()
	var font_size = 16
	var g_width = 450
	var g_height = 250
	var origin_x = 40
	var origin_y = 310

	var max_range = 0.0
	var ranges = []
	var labels = []

	# Calculate range for each step where both stats increase
	for i in points:
		var FuelEf = start_eff * pow(2, float(i)/(points-1))  # doubles over range
		var FuelCap = start_cap * pow(6, float(i)/(points-1))
		var rng =  50 * pow(FuelCap * FuelEf, 0.55)
		rng = FuelCap * FuelEf
		#rng = 30 * log(1 + FuelCap * FuelEf)
		ranges.append(rng)
		max_range = max(max_range, rng)
		labels.append(str(roundi(FuelEf)) + " Ef, " + str(roundi(FuelCap)) + " Cap")

	# Plot
	for i in points - 1:
		var x1 = origin_x + (g_width * i / (points-1))
		var y1 = origin_y - (ranges[i] / max_range) * g_height
		var x2 = origin_x + (g_width * (i+1) / (points-1))
		var y2 = origin_y - (ranges[i+1] / max_range) * g_height
		draw_line(Vector2(x1, y1), Vector2(x2, y2), Color.GREEN, 2)
		draw_circle(Vector2(x1,y1),4,Color.GREEN)
		draw_string(font, Vector2(x1-10, y1-10), str(roundi(ranges[i])) + " km", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(x1-18, origin_y+22), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size-4)

	# Draw last label
	var x_last = origin_x + (g_width * (points-1) / (points-1))
	var y_last = origin_y - (ranges[points-1] / max_range) * g_height
	draw_string(font, Vector2(x_last-10, y_last-10), str(roundi(ranges[points-1])) + " km", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(x_last-18, origin_y+22), labels[points-1], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size-4)

	# Axes
	draw_line(Vector2(origin_x, origin_y-g_height), Vector2(origin_x, origin_y), Color.WHITE, 2)
	draw_line(Vector2(origin_x, origin_y), Vector2(origin_x+g_width, origin_y), Color.WHITE, 2)
	draw_string(font, Vector2(origin_x+g_width/2-40, origin_y+50), "Efficiency + Fuel Cap Scaling", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(origin_x-30, origin_y-g_height-10), "ShipRange", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
