extends String_Happening_Option
class_name LieHappening_Option

func OptionOutCome(Instigator : MapShip) -> bool:
	super(Instigator)
	WorldView.GetInstance().Lied = true
	return CheckResault
