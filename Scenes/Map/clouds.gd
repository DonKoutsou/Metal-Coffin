extends ColorRect

class_name Clouds

@export var CloudGradient : Gradient
var CloudMad : ShaderMaterial

func _physics_process(_delta: float) -> void:
	var pos = global_position + size/2
	AdjustCloudCoverage(WeatherManage.GetInstance().StormValueInPosition(pos))

#coverage is normalised float from 0 to 1
func AdjustCloudCoverage(Coverage : float) -> void:
	var cov = Helper.mapvalue(Coverage, CloudGradient.get_offset(2), CloudGradient.get_offset(0))
	CloudGradient.set_offset(1 ,cov)
	#CloudMad.set_shader_parameter("density", Coverage * 3)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CloudMad = material
