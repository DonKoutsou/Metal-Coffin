extends Control

class_name CageFight_TeamComp

@export var CharButton : PackedScene
@export var PossibleCharacters : Array[Captain]

@export var CharacterButtonPlacement : Control
@export var PlayerTeamPlacement : Control
@export var EnemyTeamPlacement : Control

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
	var CharB = CharButton.instantiate() as CaptainButton
	CharB.SetCpt(Cpt)
	CharB.OnShipSelected.connect(RemoveFromTeam.bind(CharB))
	if (OverPlayerTeam):
		PlayerTeamPlacement.add_child(CharB)
		PlayerTeam.append(Cpt)
	else : if (OverEnemyTeam):
		EnemyTeamPlacement.add_child(CharB)
		EnemyTeam.append(Cpt)
	else:
		CharB.queue_free()

func RemoveFromTeam(B : CaptainButton) -> void:
	B.queue_free()
	PlayerTeam.erase(B.ContainedCaptain)
	EnemyTeam.erase(B.ContainedCaptain)

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
	TeamReady.emit(PlayerTeam, EnemyTeam)


func _on_random_pressed() -> void:
	PlayerTeam.clear()
	EnemyTeam.clear()
	TeamReady.emit(PlayerTeam, EnemyTeam)
