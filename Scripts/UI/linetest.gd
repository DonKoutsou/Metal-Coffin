extends PanelContainer

@export var WaveSize : float
@export var PointAmm : int
var t : float
@export var Speed : float
#var quifsa : float =  0
#var GoingUp : bool = false

var ContainerSize : Vector2

func _ready() -> void:
	ContainerSize = size

func _physics_process(delta: float) -> void:
	ContainerSize = size
	#if (GoingUp):
		#quifsa += delta * 100
		#if quifsa > 10:
			#GoingUp = false
	#else:
		#quifsa -= delta * 100
		#if quifsa < -10:
			#GoingUp = true
	
	
	t += delta * Speed
	queue_redraw()

func _draw() -> void:
	var point = []
	for g in PointAmm:
		#point.append(Vector2(ContainerSize.x / 2 + sin(g + t) * quifsa, (ContainerSize.y / PointAmm * (g + 0.5))))
		point.append(Vector2(ContainerSize.x / 2 + sin(g + t) * WaveSize, (ContainerSize.y / PointAmm * (g + 0.5))))
		
	draw_polyline(point, Color(0,1,0))
