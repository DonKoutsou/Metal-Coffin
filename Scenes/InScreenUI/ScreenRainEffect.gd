extends CanvasLayer

@export var RainMat : ShaderMaterial
@export var RainSound : AudioStreamPlayer

func _physics_process(_delta: float) -> void:
	var storm = max(0, ShipContoller.ControlledShipStormValue - 0.9) * 10.0
	RainMat.set_shader_parameter("frequency" ,(1 - storm) * 4.0)
	RainSound.volume_db = linear_to_db(storm)
