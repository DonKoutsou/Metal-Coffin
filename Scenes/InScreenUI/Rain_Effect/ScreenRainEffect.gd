extends CanvasLayer

class_name RainEffect

@export var RainMat : ShaderMaterial
@export var RainSound : AudioStreamPlayer

static var Instance : RainEffect

var working : bool = true

func _ready() -> void:
	Instance = self
	ToggleEffects(SettingsPanel.GetRain())

func _physics_process(_delta: float) -> void:
	if (!working):
		return
	var storm = ShipContoller.ControlledShipStormValue
	RainMat.set_shader_parameter("frequency" ,(1 - storm) * 4.0)
	RainSound.volume_db = linear_to_db(storm) - 6

func _exit_tree() -> void:
	RainMat.set_shader_parameter("frequency" , 4.0)

func ToggleEffects(t : bool) -> void:
	working = t
	
	RainSound.playing = t
	visible = t
