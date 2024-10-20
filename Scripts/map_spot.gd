extends Control
class_name MapSpot

signal MapPressed(Pos : MapSpot)
signal SpotSearched(Pos : MapSpot, Drops : Array[Item])

var SpotItems : Array[Item]
var SpotNameSt : String
var SpotMesh : Mesh
var Visited = false
func _ready() -> void:
	$PanelContainer/VBoxContainer/VisitButton.visible = false
	$PanelContainer/VBoxContainer/LandButton.visible = false

func ToggleVisited(t : bool) -> void:
	$Panel/Panel.visible = t
	Visited = true

func SetSpotData(Data : MapSpotType) -> void:
	SetSpotName(Data.Name)
	SetSpotMesh(Data.Model)
	SetSpotDrop(Data.PossibleDrops.pick_random())

func SetSpotName(SpotName : String) -> void:
	$PanelContainer/VBoxContainer/Label.text = SpotName
	SpotNameSt = SpotName

func SetSpotMesh(SpetMesh : Mesh) -> void:
	SpotMesh = SpetMesh

func SetSpotDrop(SpotDrop : Item) -> void:
	var rng = RandomNumberGenerator.new()
	var DropAmm = rng.randi_range(0, 10)
	for g in DropAmm :
		SpotItems.insert(g, SpotDrop)

func ToggleVisitButton(tog : bool) -> void:
	$PanelContainer/VBoxContainer/VisitButton.visible = tog
func ToggleLandButton(tog : bool) -> void:
	$PanelContainer/VBoxContainer/LandButton.visible = tog
	
func OnSpotVisited() -> void:
	ToggleVisited(true)

func _on_visit_button_pressed() -> void:
	MapPressed.emit(self)

func _on_land_button_pressed() -> void:
	SpotSearched.emit(self, SpotItems)
