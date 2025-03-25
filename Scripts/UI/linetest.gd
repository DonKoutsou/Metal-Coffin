@tool
extends PanelContainer

@export var OrientationUpDown : bool = true

var ti : float
@export var Speed : float
@export var Col : Color
#var quifsa : float =  0
#var GoingUp : bool = false

var stream = AudioStreamGenerator
var playback : AudioStreamGeneratorPlayback
@export var AudiostreamPlayer : AudioStreamPlayer
@export var frequency := 440.0
@export var amplitude := 50.0
@export var waveform_points := 360 # Number of points for one cycle
@export var sample_rate := 44100
@export var buffer_size := 2048
@export var phase := 0.0
@export var volume := 0.5
@export var LineWidth : float = 2
var ContainerSize : Vector2

#func _ready() -> void:
	##ContainerSize = size
	##stream.buffer_length = buffer_size / sample_rate
	##stream.mix_rate = sample_rate
	##
	##AudiostreamPlayer.stream = stream
	#
	#AudiostreamPlayer.play()
	#
	#playback = AudiostreamPlayer.get_stream_playback() as AudioStreamGeneratorPlayback
	#
	#start_audio()
	#AudiostreamPlayer.connect("audio_frame", _on_audio_frame)


func _physics_process(delta: float) -> void:
	ContainerSize = size

	ti += delta * Speed
	
	queue_redraw()
	
	#_on_audio_frame(AudiostreamPlayer.get_stream_playback())

#func _on_audio_frame(buffer: AudioStreamGeneratorPlayback):
	#for i in range(buffer_size):
		## Simulate speech with sine waves
		#var value = noise_wave(frequency) * volume
		#buffer.push_frame(Vector2(value, value))
#
#func start_audio():
	#while playback.get_frames_available() >= buffer_size:
		#var buffer = PackedVector2Array()
		#for i in range(buffer_size):
			## Generate sound sample
			#var value = noise_wave(frequency) * volume
			#buffer.append(Vector2(value, value)) # Stereo sound
		#playback.push_buffer(buffer)
#
#func noise_wave(freq: float) -> float:
	## Create a wave with a combination of noise and a sine wave
	#var noise = randf() * 2.0 - 1.0
	#var sine_wave = sin(phase * TAU)
	#phase += freq / amplitude / 3000
	#if phase > 1.0:
		#phase -= 1.0
	## Mix sine and noise to simulate speech-like sound
	#return 0.2 + sine_wave * 0.8

func _draw() -> void:
	#var point = []
	#for g in PointAmm:
		#var XOffset = ContainerSize.x / 2 + sin(g + t) * WaveSize
		#XOffset += sin(g + t + 3) * WaveSize
		##point.append(Vector2(ContainerSize.x / 2 + sin(g + t) * quifsa, (ContainerSize.y / PointAmm * (g + 0.5))))
		#point.append(Vector2(XOffset, (ContainerSize.y / PointAmm * (g + 0.5))))
		#
	#draw_polyline(point, Color(0,1,0))
	
	var height 
	if (OrientationUpDown):
		height = ContainerSize.y
	else:
		height = ContainerSize.x
	
	# Adjust the frequency and noise
	var phase_offset = 0.0
	var step = 1.0 / waveform_points
	var prev_point = Vector2(0, 0)
	
	for y in range(height):
		var t = y / height
		var sine_value_1 = sin(t * TAU * frequency + phase_offset + ti)
		var sine_value_2 = 0.5 * sin(t * TAU * frequency * 2 + phase_offset * 0.5)
		var noise = (randf() * 2 - 1) * 0.1
		var x = amplitude * (sine_value_1 + sine_value_2 + noise)
		
		var point 
		if (OrientationUpDown):
			point = Vector2(ContainerSize.x / 2 + x, y)
		else:
			point = Vector2(y, ContainerSize.y / 2 + x)
		if y > 0:
			draw_line(prev_point, point, Col, LineWidth, true)
		
		prev_point = point
	
		phase_offset += step
