extends Control
class_name FundsStat

@export var FundsThing : String
@export var PlayerWallet : Wallet
var CurrentAmm :int = 0
var tw : Tween
func _ready() -> void:
	UpDateFunds(PlayerWallet.Funds)
	PlayerWallet.connect("OnFundsUpdated", UpDateFunds)

func UpDateFunds(NewAmm : int) -> void:
	if (tw != null):
		tw.kill()
	tw = create_tween()
	tw.tween_method(UpdateLabel, CurrentAmm, NewAmm, 2 + min(abs(CurrentAmm - NewAmm) / 10000, 2))
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

func UpdateLabel(Amm : int) -> void:
	$Label.text = "Funds\n{0} {1}".format([Amm, FundsThing])
	CurrentAmm = Amm
	$AudioStreamPlayer2D.play()
