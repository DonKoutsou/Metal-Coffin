extends Control
class_name MapSpot

@onready var visit_button: Button = $PanelContainer/VBoxContainer2/VBoxContainer/VisitButton
@onready var land_button: Button = $PanelContainer/VBoxContainer2/VBoxContainer/LandButton
@onready var analyze_button: Button = $PanelContainer/VBoxContainer2/VBoxContainer/AnalyzeButton
@onready var label: Label = $PanelContainer/VBoxContainer2/Label


signal MapPressed(Pos : MapSpot)
signal SpotSearched(Pos : MapSpot, Drops : Array[Item])
signal SpotAnalazyed(Type : MapSpotType)

var SpotType : MapSpotType
var SpotItems : Array[Item]
var Visited = false
var Seen = false

func _ready() -> void:
	visit_button.visible = false
	land_button.visible = false
	label.visible = false
	analyze_button.visible = false
#//////////////////////////////////////////////////////////////////
func SetSpotData(Data : MapSpotType) -> void:
	SpotType = Data
	SetSpotName(Data.Name)
	SetSpotDrop(Data.PossibleDrops)
func SetSpotName(SpotName : String) -> void:
	label.text = SpotName

func SetSpotDrop(ItList : Array[Item]) -> void:
	if (ItList.size() == 0):
		return
	var it = ItList.pick_random()
	var rng = RandomNumberGenerator.new()
	var DropAmm = rng.randi_range(1, it.RandomFindMaxCount)
	for g in DropAmm :
		SpotItems.insert(g, it)
#//////////////////////////////////////////////////////////////////
func ToggleVisitButton(tog : bool) -> void:
	visit_button.visible = tog
func ToggleAnalyzeButton(tog : bool) -> void:
	analyze_button.visible = tog
func ToggleLandButton(tog : bool) -> void:
	land_button.visible = tog
func OnSpotVisited() -> void:
	$Panel/Panel.visible = true
	Visited = true
func OnSpotSeen() -> void:
	label.visible = true
	Seen = true

func _on_visit_button_pressed() -> void:
	MapPressed.emit(self)
func _on_land_button_pressed() -> void:
	SpotSearched.emit(self, SpotItems)
func _on_analyze_button_pressed() -> void:
	SpotAnalazyed.emit(SpotType)
