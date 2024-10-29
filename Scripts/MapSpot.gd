extends Control
class_name MapSpot

@onready var land_button_container: PanelContainer = $LandButtonContainer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


#signal MapPressed(Pos : MapSpot)
signal SpotSearched(Pos : MapSpot)
signal SpotAnalazyed(Type : MapSpotType)
signal SpotAproached(Type :MapSpotType)

var SpotType : MapSpotType
var Pos : Vector2
var Visited = false
var Seen = false
var Analyzed = false

func _ready() -> void:
	visible = Seen
	land_button_container.visible = false
	if (Pos != Vector2.ZERO):
		position = Pos

#//////////////////////////////////////////////////////////////////
func GetSaveData() -> Resource:
	var datas = MapSpotSaveData.new().duplicate()
	datas.SpotLoc = position
	datas.SpotType = SpotType
	datas.Seen = Seen
	datas.Visited = Visited
	datas.Analyzed = Analyzed
	return datas

func SetSpotData(Data : MapSpotType) -> void:
	SpotType = Data
	if (!Data.CanLand):
		$LandButtonContainer/LandButton.text = "Harvest"
	if (Data.FullName == "Black Whole"):
		$LandButtonContainer/LandButton.text = "Enter"
#//////////////////////////////////////////////////////////////////

func OnSpotVisited() -> void:
	Visited = true
	
func OnSpotSeen(PlayAnim : bool = true) -> void:
	visible = true
	if (!Seen and PlayAnim):
		animation_player.play("SpotFound")
		audio_stream_player_2d.play()
	$AnalyzeButton.icon = SpotType.MapIcon
	Seen = true

func _on_land_button_pressed() -> void:
	SpotSearched.emit(self)
	
func _on_analyze_button_pressed() -> void:
	SpotAnalazyed.emit(self)

func _on_visibility_notif_area_entered(_area: Area2D) -> void:
	OnSpotSeen()

func _on_alanyze_notif_area_entered(_area: Area2D) -> void:
	if (!Analyzed):
		animation_player.play("SpotAnalyzed")
		audio_stream_player_2d.play()
	OnSpotAnalyzed()
	
func OnSpotAnalyzed() ->void:
	Analyzed = true

func _on_land_notif_area_entered(_area: Area2D) -> void:
	if (SpotType.GetEnumString() != "ASTEROID_BELT" or SpotType.FullName != "Black Whole"):
		land_button_container.visible = true
	SpotAproached.emit(self)

func _on_land_notif_area_exited(_area: Area2D) -> void:
	land_button_container.visible = false
