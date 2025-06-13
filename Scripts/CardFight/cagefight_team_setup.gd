extends Control

class_name CageFight_TeamComp

@export var CharButton : PackedScene
@export var PossibleCharacters : Array[Captain]

@export var CharacterButtonPlacement : Control
@export var PlayerTeamPlacement : Control
@export var EnemyTeamPlacement : Control
@export var TeamComp : Control
@export var EquipmentComp : TeamEquipmentSetup

var FloatingButton : CaptainButton

var OverPlayerTeam : bool
var OverEnemyTeam : bool

var PlayerTeam : Array[Captain]
var EnemyTeam : Array[Captain]

signal TeamReady(PlTeam : Array[Captain], EnTeam : Array[Captain])

func _ready() -> void:
	for g in PossibleCharacters:
		var CharB = CharButton.instantiate() as CaptainButton
		CharB.SetCpt(g)
		CharacterButtonPlacement.add_child(CharB)
		CharB.OnShipSelected.connect(OnCptButtonPressed.bind(g))

func OnCptButtonPressed(Cpt : Captain) -> void:
	FloatingButton = CharButton.instantiate() as CaptainButton
	FloatingButton.SetCpt(Cpt)
	add_child(FloatingButton)
	FloatingButton.Dissable()

func OnCptReleased(Cpt : Captain) -> void:
	FloatingButton.queue_free()
	FloatingButton = null
	
	var NewCpt = Cpt.duplicate()
	
	var CharB = CharButton.instantiate() as CaptainButton
	CharB.SetCpt(NewCpt)
	CharB.OnShipSelected.connect(RemoveFromTeam.bind(CharB))
	if (OverPlayerTeam):
		#PopupManager.GetInstance().DoFadeNotif("{0} added to Player's team".format([Cpt.CaptainName]))
		PlayerTeamPlacement.add_child(CharB)
		PlayerTeam.append(NewCpt)
	else : if (OverEnemyTeam):
		#PopupManager.GetInstance().DoFadeNotif("{0} added to Enemy's team".format([Cpt.CaptainName]))
		EnemyTeamPlacement.add_child(CharB)
		EnemyTeam.append(NewCpt)
	else:
		CharB.queue_free()

func RemoveFromTeam(B : CaptainButton) -> void:
	B.queue_free()
	if (PlayerTeam.has(B.ContainedCaptain)):
		#PopupManager.GetInstance().DoFadeNotif("{0} removed from Player's team".format([B.ContainedCaptain.CaptainName]))
		PlayerTeam.erase(B.ContainedCaptain)
	else:
		#PopupManager.GetInstance().DoFadeNotif("{0} removed from Enemy's team".format([B.ContainedCaptain.CaptainName]))
		EnemyTeam.erase(B.ContainedCaptain)
		
	FloatingButton = CharButton.instantiate() as CaptainButton
	FloatingButton.SetCpt(B.ContainedCaptain)
	add_child(FloatingButton)
	FloatingButton.Dissable()

func _physics_process(delta: float) -> void:
	if (FloatingButton != null):
		FloatingButton.global_position = get_global_mouse_position() - FloatingButton.size / 2
		if (Input.is_action_just_released("Click")):
			OnCptReleased(FloatingButton.ContainedCaptain)

func _on_player_team_mouse_entered() -> void:
	OverPlayerTeam = true


func _on_player_team_mouse_exited() -> void:
	OverPlayerTeam = false


func _on_enemy_team_mouse_entered() -> void:
	OverEnemyTeam = true


func _on_enemy_team_mouse_exited() -> void:
	OverEnemyTeam = false

func _on_ready_pressed() -> void:
	if (PlayerTeam.size() == 0):
		PopUpManager.GetInstance().DoFadeNotif("Can't start fight\n Player Team is empty")
		return
	if (EnemyTeam.size() == 0):
		PopUpManager.GetInstance().DoFadeNotif("Can't start fight\n Enemy Team is empty")
		return
	TeamReady.emit(PlayerTeam, EnemyTeam)


func _on_random_pressed() -> void:
	PlayerTeam.clear()
	EnemyTeam.clear()
	TeamReady.emit(PlayerTeam, EnemyTeam)


func _on_pick_items_pressed() -> void:
	if (EquipmentComp.visible):
		return
	TeamComp.visible = false
	EquipmentComp.visible = true
	EquipmentComp.Init(PlayerTeam, EnemyTeam)


func _on_team_comp_pressed() -> void:
	if (TeamComp.visible):
		return
	TeamComp.visible = true
	EquipmentComp.visible = false
	EquipmentComp.Clear()
