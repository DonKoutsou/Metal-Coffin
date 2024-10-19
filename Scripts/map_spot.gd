extends Control
class_name MapSpot

signal MapPressed(Pos : MapSpot)
signal SpotSearched(Pos : MapSpot, Drops : Array[Item])

var SpotItems : Array[Item]
var SpotNameSt : String
var SpotMesh : Mesh

func ToggleVisited(t : bool) -> void:
	$Panel/Panel.visible = t

func SetSpotData(Data : MapSpotType) -> void:
	SetSpotName(Data.Name)
	SetSpotMesh(Data.Model)
	SetSpotDrop(Data.PossibleDrops.pick_random())

func SetSpotName(SpotName : String) -> void:
	var b = get_node("PanelContainer/VBoxContainer/Label") as Label
	b.text = SpotName
	SpotNameSt = SpotName

func SetSpotMesh(SpetMesh : Mesh) -> void:
	SpotMesh = SpetMesh

func SetSpotDrop(SpotDrop : Item) -> void:
	var rng = RandomNumberGenerator.new()
	var DropAmm = rng.randi_range(0, 10)
	for g in DropAmm :
		SpotItems.insert(g, SpotDrop)

func ToggleButton(tog : bool) -> void:
	var b = get_node("PanelContainer/VBoxContainer/Button") as Button
	b.visible = tog
	
func OnSpotVisited() -> void:
	var but = get_node("PanelContainer/VBoxContainer/Button") as Button
	but.text = "Land"
	ToggleVisited(true)

func _on_button_pressed() -> void:
	var but = get_node("PanelContainer/VBoxContainer/Button") as Button
	if (but.text == "Visit"):
		MapPressed.emit(self)
	else:
		SpotSearched.emit(self, SpotItems)
