extends Control

class_name RadioSpeaker
@export var SoundList: Dictionary[RadioSound, Array]
@export var frequency: float = 1.0  # Wiggle speed
@export var phase_offset: float = 0.0  # Phase offset for randomness
@export var max_rotation: float = 0.1  # Maximum angle in radians for rotation

static var Instance : RadioSpeaker

func _ready() -> void:
	Instance = self
	phase_offset = randf_range(0.0, TAU)

static func GetInstance() -> RadioSpeaker:
	return Instance

var PlayingSounds : int = 0
func PlaySound(Sound : RadioSound) -> void:
	var List = SoundList[Sound]
	var SoundStream = List.pick_random()
	var DelSound = DeletableSound.new()
	DelSound.stream = SoundStream
	DelSound.bus = "MapSounds"
	DelSound.autoplay = true
	add_child(DelSound)
	PlayingSounds += 1
	$Light.Toggle(true, true)
	await DelSound.finished
	PlayingSounds -= 1
	if (PlayingSounds == 0):
		$Light.Toggle(false)

func ApplyShake(amm : float = 1) -> void:
	max_rotation = max(max_rotation, 0.04 * amm)

func _physics_process(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0

	var rotation_angle = max_rotation * sin(frequency * 1.2 * time + phase_offset)  # Slightly different frequency

	max_rotation = max(max_rotation - delta / 60, 0.003)

	rotation = rotation_angle


enum RadioSound{
	LANDING_START,
	LANDING_END,
	DAMAGED,
	LIFTOFF,
	RADAR_DETECTED,
	ELINT_DETECTED,
	VISUAL_CONTACT,
	TARGET_DEST,
	APROACHING
}
