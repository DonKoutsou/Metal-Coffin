extends CanvasLayer

@export var RainMat : ShaderMaterial
@export var RainSound : AudioStreamPlayer

func _physics_process(_delta: float) -> void:
	var storm = 1 - ShipContoller.ControlledShipStormValue
	RainMat.set_shader_parameter("frequency" ,storm * 4.0)
	RainSound.volume_db = linear_to_db(storm)
