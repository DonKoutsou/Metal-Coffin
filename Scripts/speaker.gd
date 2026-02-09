extends Control

class_name RadioSpeaker
@export var SoundList: Dictionary[RadioSound, Array]
@export var frequency: float = 1.0  # Wiggle speed
@export var phase_offset: float = 0.0  # Phase offset for randomness
@export var max_rotation: float = 0.1  # Maximum angle in radians for rotation
@export var L : Light

static var SoundsOnCooldown : Dictionary[RadioSound, float]
static var CurrentlyPlayed : Dictionary[RadioSound, DeletableSound]

static var Instance : RadioSpeaker

signal Clicked

func _ready() -> void:
	Instance = self
	phase_offset = randf_range(0.0, TAU)

static func GetInstance() -> RadioSpeaker:
	return Instance

static func AddSoundToQueue(Sound : RadioSound) -> void:
	if (CurrentlyPlayed.size() == 0 and Instance != null):
		Instance.PlaySound(Sound)
	else:
		SoundsOnCooldown[Sound] = 1

var PlayingSounds : int = 0
func PlaySound(Sound : RadioSound, Volume : float = 0) -> void:
	if (CurrentlyPlayed.has(Sound)):
		CurrentlyPlayed[Sound].volume_db = Volume
	if (SoundsOnCooldown.has(Sound)):
		return

	var List = SoundList[Sound]
	var SoundStream = List.pick_random() as AudioStream
	var DelSound = DeletableSound.new()
	CurrentlyPlayed[Sound] = DelSound
	DelSound.stream = SoundStream
	SoundsOnCooldown[Sound] = SoundStream.get_length() + 0.1
	DelSound.bus = "MapSounds"
	DelSound.volume_db = Volume
	DelSound.autoplay = true
	DelSound.finished.connect(Finished)
	add_child(DelSound)
	PlayingSounds += 1
	L.Toggle(true, true)
	
	await DelSound.finished
	PlayingSounds -= 1
	if (PlayingSounds == 0):
		L.Toggle(false)
	#CurrentlyPlayed.erase(Sound)

func Finished(Sound : DeletableSound) -> void:
	CurrentlyPlayed.erase(Sound)

func ApplyShake(amm : float = 1) -> void:
	max_rotation = min(0.1, max_rotation + (0.004 * amm))

func _physics_process(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0

	var rotation_angle = max_rotation * sin(frequency * 1.2 * time + phase_offset)  # Slightly different frequency

	max_rotation = max(max_rotation - delta / 10, 0.003)

	rotation = rotation_angle
	
	for g in range(SoundsOnCooldown.size() - 1, -1, -1):
		SoundsOnCooldown[SoundsOnCooldown.keys()[g]] -= delta
		if (SoundsOnCooldown[SoundsOnCooldown.keys()[g]] <= 0):
			SoundsOnCooldown.erase(SoundsOnCooldown.keys()[g])


enum RadioSound{
	LANDING_START,
	LANDING_END,
	DAMAGED,
	LIFTOFF,
	RADAR_DETECTED,
	ELINT_DETECTED,
	VISUAL_CONTACT,
	TARGET_DEST,
	APROACHING,
	STATIC,
	BEEP,
}


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("Click")):
		ApplyShake(10)
		Clicked.emit()
