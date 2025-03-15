extends Node2D

# Customize these variables
@export var max_radius = 200.0 # Max expansion radius
@export var expansion_rate = 100.0 # Pixels per second
@export var line_width = 2.0
@export var num_circles = 5
@export var circle_spacing = 20.0
@export var TimesPlayed : int = 2
var timer : Timer

# Create multiple circles over time
func _ready():
	timer = Timer.new()
	timer.wait_time = 4
	timer.connect("timeout", TimerFin)
	add_child(timer)
	timer.start()

func TimerFin() -> void:
	TimesPlayed -= 1
	if (TimesPlayed == 0):
		queue_free()

# Called every frame
func _process(delta):
	queue_redraw()

func _draw():
	print(timer.wait_time - timer.time_left)
	for i in range(num_circles):
		var radius = i * circle_spacing + expansion_rate * ((timer.wait_time - timer.time_left) - (timer.wait_time / 2))
		if radius <= max_radius and radius > 0:
			draw_circle(Vector2.ZERO, radius, Color(1, 0, 0, 1), false, line_width)
	
