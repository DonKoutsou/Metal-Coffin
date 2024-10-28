extends Control
class_name MapSpot

@onready var visit_button: Button = $PanelContainer/VBoxContainer2/VBoxContainer/VisitButton
@onready var land_button: Button = $PanelContainer/VBoxContainer2/VBoxContainer/LandButton
@onready var analyze_button: Button = $PanelContainer/VBoxContainer2/VBoxContainer/AnalyzeButton
#@onready var label: Label = $PanelContainer/VBoxContainer2/Label

signal MapPressed(Pos : MapSpot)
signal SpotSearched(Pos : MapSpot)
signal SpotAnalazyed(Type : MapSpotType)

var SpotType : MapSpotType
var Pos : Vector2
var Visited = false
var Seen = false

func _ready() -> void:
	visit_button.visible = false
	land_button.visible = false
	analyze_button.visible = false
	if (Pos != Vector2.ZERO):
		position = Pos
		
func GetSaveData() -> Resource:
	var datas = MapSpotSaveData.new().duplicate()
	datas.SpotLoc = position
	datas.SpotType = SpotType
	datas.Seen = Seen
	datas.Visited = Visited
	return datas
#//////////////////////////////////////////////////////////////////
func SetSpotData(Data : MapSpotType) -> void:
	SpotType = Data
	if (!Data.CanLand):
		$PanelContainer/VBoxContainer2/VBoxContainer/LandButton.text = "Harvest"
	
	#SetSpotDrop(Data.PossibleDrops)

#func SetSpotDrop(ItList : Array[Item]) -> void:
#	if (ItList.size() == 0):
#		return
#	var it = ItList.pick_random()
##	var rng = RandomNumberGenerator.new()
#	var DropAmm = rng.randi_range(1, it.RandomFindMaxCount)
	#for g in DropAmm :
		#SpotItems.insert(g, it)
#//////////////////////////////////////////////////////////////////
func ToggleVisitButton(tog : bool) -> void:
	visit_button.visible = tog
func ToggleLandButton(tog : bool) -> void:
	land_button.visible = tog
func OnSpotVisited() -> void:
	$Panel/Panel.visible = true
	Visited = true
func OnSpotSeen() -> void:
	if (!Seen):
		$AnimationPlayer.play("SpotFound")
		$AudioStreamPlayer2D.play()
	$Panel.texture = SpotType.MapIcon
	Seen = true

func _on_visit_button_pressed() -> void:
	MapPressed.emit(self)
func _on_land_button_pressed() -> void:
	SpotSearched.emit(self)
func _on_analyze_button_pressed() -> void:
	SpotAnalazyed.emit(SpotType)


func _on_visibility_notif_area_entered(_area: Area2D) -> void:
	OnSpotSeen()


func _on_visibility_notif_area_exited(_area: Area2D) -> void:
	pass # Replace with function body.


func _on_fuel_notif_area_entered(_area: Area2D) -> void:
	visit_button.visible = true
	#pass # Replace with function body.


func _on_fuel_notif_area_exited(_area: Area2D) -> void:
	visit_button.visible = false


func _on_alanyze_notif_area_entered(_area: Area2D) -> void:
	analyze_button.visible = true


func _on_alanyze_notif_area_exited(_area: Area2D) -> void:
	analyze_button.visible = false
