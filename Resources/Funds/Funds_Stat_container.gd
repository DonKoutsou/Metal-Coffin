extends Control
class_name FundsStat

@export var FundsThing : String
@export var PlayerWallet : Wallet
@export var Sound : AudioStreamPlayer2D
@export var Text : Label

var CurrentAmm :int = 0
var tw : Tween
func _ready() -> void:
	Text.text = "{0} {1}".format([PlayerWallet.Funds, FundsThing])
	CurrentAmm = PlayerWallet.Funds
	UpDateFunds(CurrentAmm)
	PlayerWallet.connect("OnFundsUpdated", UpDateFunds)

func UpDateFunds(NewAmm : int) -> void:
	if (tw != null):
		tw.kill()
	tw = create_tween()
	tw.tween_method(UpdateLabel, CurrentAmm, NewAmm, 2 + min(abs(CurrentAmm - NewAmm) / 10000, 2))
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

func UpdateLabel(Amm : int) -> void:
	var AmmStr = var_to_str(Amm).replace(".0", "")
	Text.text = "{0} {1}".format([AmmStr, FundsThing])
	CurrentAmm = Amm
	Sound.play()
