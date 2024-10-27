@tool
extends EditorPlugin

const editorDock = preload("res://PlanetRandomiser/PlanetRandomiserDock.tscn")
var dockedScene
# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	pass
func _enter_tree() -> void:
	dockedScene = editorDock.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, dockedScene)
	dockedScene.get_node("VBoxContainer/Button").connect("pressed", NewPlanetScene)
func _exit_tree() -> void:
	remove_control_from_docks(dockedScene)
	dockedScene.free()

	
func NewPlanetScene() -> void:
	var index = (dockedScene.get_node("VBoxContainer/OptionButton") as OptionButton).selected
	var Baseplanet
	var BaseRes
	var Name
	var ScenePath
	var ResPath
	if (index == 0):
		Baseplanet = (load("res://Scenes/MapSpotScenes/Terrestrial/T1.tscn") as PackedScene).duplicate()
		BaseRes = (load("res://Resources/MapSpots/Terrestrial/T1.tres") as Resource).duplicate()
		Name = "T"
		ScenePath = "res://Scenes/MapSpotScenes/Terrestrial/"
		ResPath = "res://Resources/MapSpots/Terrestrial/"
	if (index == 1):
		Baseplanet = (load("res://Scenes/MapSpotScenes/Gas/G1.tscn") as PackedScene).duplicate()
		BaseRes = (load("res://Resources/MapSpots/Gas/G1.tres") as Resource).duplicate()
		Name = "G"
		ScenePath = "res://Scenes/MapSpotScenes/Gas/"
		ResPath = "res://Resources/MapSpots/Gas/"
	if (index == 2):
		Baseplanet = (load("res://Scenes/MapSpotScenes/Star/S1.tscn") as PackedScene).duplicate()
		BaseRes = (load("res://Resources/MapSpots/Star/S1.tres") as Resource).duplicate()
		Name = "S"
		ScenePath = "res://Scenes/MapSpotScenes/Star/"
		ResPath = "res://Resources/MapSpots/Star/"
	if (index == 3):
		Baseplanet = (load("res://Scenes/MapSpotScenes/Sand/S1.tscn") as PackedScene).duplicate()
		BaseRes = (load("res://Resources/MapSpots/Sand/S1.tres") as Resource).duplicate()
		Name = "S"
		ScenePath = "res://Scenes/MapSpotScenes/Sand/"
		ResPath = "res://Resources/MapSpots/Sand/"
	if (index == 4):
		Baseplanet = (load("res://Scenes/MapSpotScenes/Lava/L1.tscn") as PackedScene).duplicate()
		BaseRes = (load("res://Resources/MapSpots/Lava/L1.tres") as Resource).duplicate()
		Name = "L"
		ScenePath = "res://Scenes/MapSpotScenes/Lava/"
		ResPath = "res://Resources/MapSpots/Lava/"
	if (index == 5):
		Baseplanet = (load("res://Scenes/MapSpotScenes/Ice/I1.tscn") as PackedScene).duplicate()
		BaseRes = (load("res://Resources/MapSpots/Ice/I1.tres") as Resource).duplicate()
		Name = "I"
		ScenePath = "res://Scenes/MapSpotScenes/Ice/"
		ResPath = "res://Resources/MapSpots/Ice/"
	if (index == 6):
		Baseplanet = (load("res://Scenes/MapSpotScenes/Ringed/R1.tscn") as PackedScene).duplicate()
		BaseRes = (load("res://Resources/MapSpots/Ringed/R1.tres") as Resource).duplicate()
		Name = "R"
		ScenePath = "res://Scenes/MapSpotScenes/Ringed/"
		ResPath = "res://Resources/MapSpots/Ringed/"
	var amm = AmmountOfFilesInDir(ScenePath)
	var scpath = ScenePath + Name + var_to_str(amm) + ".tscn"
	ResourceSaver.save(Baseplanet, scpath) 
	EditorInterface.open_scene_from_path(scpath)
	
	var respath = ResPath + Name + var_to_str(amm) + ".tres"
	BaseRes.Scene = load(scpath) as PackedScene
	ResourceSaver.save(BaseRes, respath)
	
func AmmountOfFilesInDir(path : String) -> int:
	var amm = 0
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		amm += 1
		while file_name != "":
			amm += 1
			file_name = dir.get_next()
	return amm
