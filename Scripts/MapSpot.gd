extends Node2D
class_name MapSpot

@onready var land_button_container: PanelContainer = $LandButtonContainer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var HostileShipScene : PackedScene

#signal MapPressed(Pos : MapSpot)
signal SpotSearched(Pos : MapSpot)
signal SpotAnalazyed(Type : MapSpotType)
signal SpotAproached(Type :MapSpotType)

var SpotType : MapSpotType
var Pos : Vector2
var Visited = false
var Seen = false
var Analyzed = false
#bool to avoid sent drones colliding with current visited spot
var CurrentlyVisiting = false
var Evnt : Happening
var SpotName : String

func _ready() -> void:
	$VBoxContainer.visible = Analyzed
	visible = Seen
	global_rotation = 0
	land_button_container.visible = false
	if (Pos != Vector2.ZERO):
		position = Pos
	set_physics_process(false)
	if (SpotType.EnemyCity):
		add_to_group("EnemyDestinations")
	
		
		
func SpawnEnemyShip():
	var host = HostileShipScene.instantiate() as HostileShip
	host.DestinationCity = self
	get_parent().get_parent().get_parent().get_parent().add_child(host)
	host.global_position = global_position
func _physics_process(_delta: float) -> void:
	var cam = ShipCamera.GetInstance()
	$LandButtonContainer.scale = Vector2(1,1) /  cam.zoom

#//////////////////////////////////////////////////////////////////
func GetSaveData() -> Resource:
	var datas = MapSpotSaveData.new().duplicate()
	datas.SpotLoc = position
	datas.SpotType = SpotType
	datas.Seen = Seen
	datas.Visited = Visited
	datas.Analyzed = Analyzed
	datas.SpotName = SpotName
	datas.Evnt = Evnt
	return datas

func SetSpotData(Data : MapSpotType) -> void:
	SpotType = Data
	#if (Data.GetEnumString() == "SUB_STATION"):
		#$LandButtonContainer/LandButton.text = "Search"
	#else :if (Data.GetEnumString() == "STATION"):
		#$LandButtonContainer/LandButton.text = "Dock"
	#else :if (!Data.CanLand):
	
	$LandButtonContainer/LandButton.text = "Search"
	
	for g in Data.PossibleDrops:
		var text = TextureRect.new()
		text.texture = g.ItemIconSmol
		if (g is UsableItem):
			text.self_modulate = g.ItecColor
		text.use_parent_material = true
		$VBoxContainer/HBoxContainer.add_child(text)
	if (Data.CustomData.size() > 0):
		for g in Data.CustomData:
			if (g is MapSpotCustomData_CompleteInfo):
				var IDs = g as MapSpotCustomData_CompleteInfo
				if (IDs.PossibleIds.size() == 0):
					continue

				for z in IDs.PossibleIds:
					if (z.PickedBy != null):
						continue
					#if (ID.PickedBy != null):
					#continue
					SpotName = z.SpotName
					Evnt = z.Event
					#IDs.PossibleIds.erase(ID)
					z.PickedBy = self
					break
				
		
	if (SpotType.VisibleOnStart):
		OnSpotSeen(false)
		OnSpotAnalyzed(false)

	add_to_group(Data.FullName)
func GetSpotName() -> String:
	return SpotName if Analyzed else "?"
func GetSpotDescriptio() -> String:
	return SpotType.Description if Analyzed else "?"
func CanLand() -> bool:
	return SpotType.CanLand if Visited or Analyzed else false
func HasAtmosphere() -> bool:
	return SpotType.HasAtmoshere if Visited or Analyzed else false
func GetPossibleDrops() -> Array:
	return SpotType.PossibleDrops if Analyzed else []
#//////////////////////////////////////////////////////////////////
#todo find better way for dialogue from station
func OnSpotVisited(PlayAnim : bool = true) -> void:
	#if (SpotType.GetEnumString() == "SUB_STATION"):
		#var diags = SpotType.GetCustomData("StationInfo")
		#var diag : MapSpotCustomDataStringArray = diags.pick_random()
		#while (DialogueProgressHolder.GetInstance().IsDialogueSpoken(diag.Value[0])):
			#if (diags.size() == 0):
				#diag = null
				#break
			#diag = diags.pick_random()
			#diags.erase(diag)
		#var Dialogue : Array[String] = ["Operator, it seems like the station was under collapse.", "Our visit has destabilised the station even more and it's been completely destroyed."]
		#if (diag == null):
			#Ingame_UIManager.GetInstance().PlayDiag(Dialogue)
		#else:
			#Dialogue.append("I managed to find some of the crew logs. This entry seems to be just before the collapse. Take a listen operator.")
			#Dialogue.append_array(diag.Value)
			#Dialogue.append("Entry ended.")
			#DialogueProgressHolder.GetInstance().OnDialogueSpoken(diag.Value[0])
			#Ingame_UIManager.GetInstance().PlayDiag(Dialogue)
		##SpotType.ClearCustomData(diag)
		#queue_free()
	if (!Analyzed):
		OnSpotAnalyzed(PlayAnim)
	Visited = true
#Called when radar sees a mapspot
func OnSpotSeen(PlayAnim : bool = true) -> void:
	visible = true
	if (PlayAnim):
		if (SpotType.GetEnumString() == "SUB_STATION"):
			Ingame_UIManager.GetInstance().PlayDiag(["Operator, we are aproaching a sub-station.","I'd recomend visiting it to look for supplies or any clues regarding the collapse."])
		if (!Seen):
			animation_player.play("SpotFound")
			PlaySound()
	$VBoxContainer/TextureRect.texture = SpotType.MapIcon
	Seen = true
#Called when drone visits a mapspot
func OnSpotSeenByDrone(PlayAnim : bool = true) -> void:
	visible = true
	if (PlayAnim):
		if (SpotType.GetEnumString() == "SUB_STATION"):
			Ingame_UIManager.GetInstance().PlayDiag(["Operator, one of the drones found a sub-station.","I'd recomend visiting it to look for supplies or any clues regarding the collapse."])
		if (!Seen):
			animation_player.play("SpotFound")
			PlaySound()
	$VBoxContainer/TextureRect.texture = SpotType.MapIcon
	Seen = true
func OnSpotVisitedByDrone() -> void:
	if (!Analyzed):
		OnSpotAnalyzed()
	visible = true
	
func _on_land_button_pressed() -> void:
	SpotSearched.emit(self)
	
func _on_analyze_button_pressed() -> void:
	SpotAnalazyed.emit(self)

func OnSpotAnalyzed(PlayAnim : bool = true) ->void:
	if (PlayAnim):
		var notif = (load("res://Scenes/AnalyzedNotif.tscn") as PackedScene).instantiate() as AnalyzeNotif
		add_child(notif)
		notif.EntityToFollow = self
		animation_player.play("SpotAnalyzed")
		PlaySound()
	$VBoxContainer.visible = true
	$VBoxContainer/TextureRect2.text = SpotName
	Analyzed = true

func PlaySound():
	var sound = AudioStreamPlayer2D.new()
	sound.bus = "MapSounds"
	sound.volume_db = 10
	sound.stream = load("res://Assets/Sounds/radar-beeping-sound-effect-192404.mp3")
	add_child(sound)
	sound.play()
	
func AreaEntered(area: Area2D):
	if (area.get_parent() is PlayerShip or area.get_parent()  is Drone):
		if (area.get_collision_layer_value(1)):
			if (!Seen):
				OnSpotSeen()
		else: if (area.get_collision_layer_value(2)):
			if (!Analyzed):
				OnSpotAnalyzed()
		else: if (area.get_collision_layer_value(3)):
			#if (SpotType.GetEnumString() != "ASTEROID_BELT" or SpotType.FullName != "Black Whole"):
			land_button_container.visible = true
			set_physics_process(true)
			SpotAproached.emit(self)
			OnSpotVisited()
			CurrentlyVisiting = true
func AreaExited(area: Area2D):
	if (area.get_collision_layer_value(3)):
		land_button_container.visible = false
		set_physics_process(false)
		CurrentlyVisiting = false
