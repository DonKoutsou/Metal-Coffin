extends PanelContainer

class_name Exploration

@onready var items_found_notif: ItemNotif = $"VBoxContainer/PanelContainer/VBoxContainer/Items Found Notif"
@onready var planet_surface: PlanetSurface = $SubViewportContainer/SubViewport/PlanetSurface
var SpotT : MapSpotType
var PlayerHp = 100
var PlayerOxy = 100
var Findings : Array[Item] = []

signal OnExplorationEnded(RemainingHP : int, RemainingOxygen : int, Supplies : Array[Item])

func StartExploration(Spot : MapSpotType, Playership : BaseShip) -> void:
	SpotT = Spot
	var sc = Spot.Scene.instantiate() as MeshInstance3D
	var mat = sc.get_active_material(0) as ShaderMaterial
	var Col1 = mat.get_shader_parameter("color_2")
	var Col2 = mat.get_shader_parameter("color_3")
	planet_surface.ApplySurfaceColors(Col1, Col2)
	$VBoxContainer/Stat_Panel.StatsUpCust("HP", PlayerHp)
	$VBoxContainer/Stat_Panel.StatsUpCust("OXYGEN", PlayerOxy)
	planet_surface.SetShipVisuals(Playership.ShipScene)
	
func Explore() -> void:
	if (planet_surface.Exploring):
		return
	if (PlayerHp <= 10):
		DoPopUp("Not enough HP to complete action.")
		return
	if (PlayerOxy <= 5):
		DoPopUp("Not enough oxygen to complete action.")
		return
		
	PlayerHp -= 10
	if (!SpotT.HasAtmoshere):
		PlayerOxy -= 5
	$VBoxContainer/Stat_Panel.StatsUpCust("HP", PlayerHp)
	$VBoxContainer/Stat_Panel.StatsUpCust("OXYGEN", PlayerOxy)
	var itms = SpotT.GetSpotDrop()
	Findings.append_array(itms)
	items_found_notif.AddItems(itms)
	planet_surface.MoveLocs()
func DoPopUp(Text : String):
	var dig = AcceptDialog.new()
	add_child(dig)
	dig.dialog_text = Text
	dig.popup_centered()
	
func _on_leave_pressed() -> void:
	planet_surface.Takeoff()
	
	$VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Explore.disabled = true
	$VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/Leave.disabled = true
func _on_explore_pressed() -> void:
	Explore()
	
func _on_planet_surface_takeoff_finished() -> void:
	OnExplorationEnded.emit(PlayerHp, PlayerOxy, Findings)
	queue_free()
