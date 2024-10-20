extends Control
class_name MapSpot

signal MapPressed(Pos : MapSpot)
signal SpotSearched(Pos : MapSpot, Drops : Array[Item])

var SpotItems : Array[Item]
var SpotNameSt : String
var SpotMesh : Mesh
var Visited = false
var Seen = false

func _ready() -> void:
	$PanelContainer/VBoxContainer/VisitButton.visible = false
	$PanelContainer/VBoxContainer/LandButton.visible = false
	$PanelContainer/VBoxContainer/Label.visible = false

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
	var DropAmm = rng.randi_range(1, SpotDrop.RandomFindMaxCount)
	for g in DropAmm :
		SpotItems.insert(g, SpotDrop)

func ToggleVisitButton(tog : bool) -> void:
	$PanelContainer/VBoxContainer/VisitButton.visible = tog
func ToggleLandButton(tog : bool) -> void:
	$PanelContainer/VBoxContainer/LandButton.visible = tog
	
func OnSpotVisited() -> void:
	$Panel/Panel.visible = true
	Visited = true
func OnSpotSeen() -> void:
	$PanelContainer/VBoxContainer/Label.visible = true
	Seen = true

func _on_visit_button_pressed() -> void:
	MapPressed.emit(self)

func _on_land_button_pressed() -> void:
	SpotSearched.emit(self, SpotItems)
