extends PanelContainer

class_name CommandLine

@export var Text : TextEdit
@export var StartingMen : bool

@export var CommandListConfiguration : Dictionary[PackedStringArray, String]

var Items : Array[Item]

signal StartPrologue(SkipStory : bool)
signal StartCampaign(SkipStory : bool)

static var Typing : bool = false

func _ready() -> void:
	#if (!OS.is_debug_build() or OS.get_name() != "Windows"):
		#queue_free()
		#return
	Typing = false
	visible = false
	set_physics_process(false)
	RefrshExistingItems()

func OnCommandEntered() -> void:
	var Command = Text.text
	
	#UpdateRecomendations()
	
	if (Command.substr(Command.length() - 1, Command.length()) == "\n"):
		Command = Command.replace("\n", "")
		var response = HandleCommand(Command)
		if (StartingMen):
			PopUpManager.GetInstance().DoFadeNotif(response, get_parent())
		else:
			PopUpManager.GetInstance().DoFadeNotif(response, null)
		
		Text.text = ""
	Text.set_caret_column(Text.text.length())

func Focus() -> void:
	Text.grab_focus()
	Text.text = ""
	
func HandleCommand(Command : String) -> String:
	
	var CommandList = Command.split(" ")
	
	if (CommandList.size() == 0):
		return "Error"
	
	for command in CommandListConfiguration:
		var Match : bool = false
		var commandToExecute : String = ""
		var currentCheckedWord = 0
		while currentCheckedWord < command.size():
			var typedWord = CommandList[currentCheckedWord]
			var currentCommandWord = command[currentCheckedWord]
			if (typedWord.to_lower() == currentCommandWord.to_lower()):
				currentCheckedWord += 1
				if (currentCheckedWord == command.size()):
					Match = true
			else:
				break
		
		if (!Match):
			continue
		
		commandToExecute = CommandListConfiguration[command]
		
		
		if (commandToExecute != ""):
			if (!has_method(commandToExecute)):
				continue
			
			var args : Array = []
			for g in range(currentCheckedWord, CommandList.size()):
				args.append(CommandList[g])
			if (get_method_argument_count(commandToExecute) != args.size()):
				return "Missing arguments.\nFailed to call command"
			
			return callv(commandToExecute, args)
			#call(commandToExecute, args)
	
	#match firstword:
		#"prologue":
			#return HandlePrologueCommand(CommandList)
		#"inv":
			#return HandleInventoryCommand(CommandList)
		#"stat":
			#return HandleStatCommand(CommandList)
		#"loc":
			#return HandleLocationCommand(CommandList)
	
	return "Couldnt match command"

func HandlePrologueCommand(Command) -> String:
	if (Command.size() == 1):
		StartPrologue.emit(false)
		return "Starting Prologue"
	
	match (Command[1].to_lower()):
		"skip":
			StartPrologue.emit(true)
			return "Starting Prologue\nSkipping Story"
	
	return "Error Handling Location Command"

func Prologue(skip : String) -> String:
	var sk : bool = str_to_var(skip)
	if (sk == null):
		return "Wrong argument"
	StartPrologue.emit(sk)
	return "Starting Prologue"

#func HandleCampaignCommand(Command) -> String:
	#if (Command.size() == 1):
		#return "Prologue What?"
	#
	#match (Command[1].to_lower()):
		#"print":
			#return PrintLocations(Command[1])
		#"tp":
			#return HandleTeleport(Command[1], str_to_var(Command[3]) , str_to_var(Command[4]))
	#
	#return "Error Handling Location Command"

#func HandleLocationCommand(Command) -> String:
	#
	#if (Command.size() == 1):
		#return "forgot to add captain name"
	#
	#if (Command.size() == 2):
		#return "Missing Command After Captain Name"
	#
	#match (Command[2].to_lower()):
		#"print":
			#return PrintLocations(Command[1])
		#"tp":
			#return HandleTeleport(Command[1], str_to_var(Command[3]) , str_to_var(Command[4]))
	#
	#return "Error Handling Location Command"

func Teleport(CharName : String, Locx : String, Locy : String) -> String:
	var xpos : int = str_to_var(Locx)
	var ypos : int = str_to_var(Locy)
	if (xpos == null or ypos == null):
		return "Misstyped location"
	for g in get_tree().get_nodes_in_group("PlayerShips"):
		var ship = g as MapShip
		if ship.Cpt.GetCaptainName().to_lower() == CharName.to_lower():
			ship.global_position = Vector2(xpos, ypos) * 10
			return "Successfully teleported\n{0} to pos\n|{1}|".format([CharName, ship.global_position])
	
	return "Teleport failed"

func EnemyDebug(t : String) -> String:
	var toggle : bool = str_to_var(t)
	if (toggle == null):
		return "Wrong Argument"
	Commander.GetInstance().ToggleEnemyDebug(toggle)
	return "Enemy debug toggled"

func PrintLocations(CharName : String) -> String:
	for g in get_tree().get_nodes_in_group("PlayerShips"):
		var ship = g as MapShip
		if ship.Cpt.GetCaptainName().to_lower() == CharName.to_lower():
			return "{0}'s position is |x: {1}, y : {2}|".format([CharName, ship.global_position.x, ship.global_position.y])
	
	return "Location Print Failed"

func InventoryAdd(CapName : String, ItemName : String, ItemAmmount : String = "1") -> String:
	var Inv = InventoryManager.GetInstance()
	var inv = Inv.GetCharacterInventoryByName(CapName)
	if (inv == null):
		return "Couldn't find captain name"
	var Amm = str_to_var(ItemAmmount)
	if (Amm == null):
		return "Ammount typed wrong"
	return HandleInventoryItemAddCommand(inv, CapName, ItemName, Amm)

func InventoryUpgrade(CapName : String, ItemName : String) -> String:
	var Inv = InventoryManager.GetInstance()
	var inv = Inv.GetCharacterInventoryByName(CapName)
	if (inv == null):
		return "Couldn't find captain name"
	return HandleItemUpgrade(inv, ItemName)

func HandleInventoryItemAddCommand(Inv : CharacterInventory, InventoryOwnerName : String, ItemName : String, ItAmm : int) -> String:

	for g in Items:
		if (g.ItemName.to_lower() == ItemName.replace("_", " ").to_lower()):
			for a in ItAmm:
				Inv.AddItem(g)
			return "Added {0}X of {1} to {2}'s inventory".format([ItAmm, g.ItemName, InventoryOwnerName])
	
	return "Error Adding Item"
	
func HandleItemUpgrade(Inv : CharacterInventory, ItemName : String) -> String:
	for It in Inv._GetInventoryBoxes():
		if It.IsEmpty():
			continue
		if It._ContainedItem.ItemName.to_lower() == ItemName.to_lower():
			var success = Inv.ForceUpgradeItem(It)
			if (success):
				return "{0} upgraded succesfully".format([ItemName])
			else:
				return "Couldnt upgrade Item"
			
	return "Error Upgrading Item"
	
func HandleStatCommand(Command) -> String:
	var Inv = InventoryManager.GetInstance()
	if (Command.size() == 1):
		return "forgot to add captain name"
		
	var Char = Inv.GetCharacterByName(Command[1])
	if (Char == null):
		return "Could Not Find Character"
	
	if (Command.size() == 2):
		return "No Stat Found"
	
	var statName = STAT_CONST.StringToEnum(Command[2])
	
	if (statName == -1):
		return "Wrong stat name"

	Char.FullyRefilStat(statName)
	
	return "{0} was refilled".format([Command[2]])

func RefrshExistingItems() -> void:
	var DirsToExplore :Array[String] = ["res://Resources/Items"]
	for g in DirsToExplore:
		var dir = DirAccess.open(g)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					print("Found directory: " + file_name)
					DirsToExplore.append(g + "/" + file_name)
				else:
					printraw("Found file: " + file_name)
					var It = load(g + "/" + file_name)
					Items.append(It)
				
				file_name = dir.get_next()

var offset : Vector2

func OnMoveButtonDown() -> void:
	offset = get_global_mouse_position() - global_position
	set_physics_process(true)

func OnMoveButtonUp() -> void:
	set_physics_process(false)
	Focus()
	
func _physics_process(_delta: float) -> void:
	global_position = get_global_mouse_position() - offset

func OnCloseButtonPressed() -> void:
	Typing = false
	visible = false

#func UpdateRecomendations() -> void:
	#ClearRecomendations()
	#if (Text.text.length() == 0):
		#AddRecomendation("inv")
		#AddRecomendation("loc")
		#AddRecomendation("stat")
	#else:
		#var text = Text.text.split(" ")
		#if (text[0] == "inv"):
			#AddRecomendation("add")
			#AddRecomendation("upgrade")
		#if (text[0] == "stat"):
			#AddRecomendation("add")
			#AddRecomendation("upgrade")
		#if (text[0] == "loc"):
			#AddRecomendation("add")
			#AddRecomendation("upgrade")
		
#func RecomendationPressed(text : String) -> void:
	#Text.text += text + " "
	#UpdateRecomendations()
	
#func OnCommandLineFocused() -> void:
	#UpdateRecomendations()
		
#func AddRecomendation(RecText : String) -> void:
	#var butn = Button.new()
	#butn.connect("pressed", RecomendationPressed.bind(RecText))
	#$VBoxContainer/TextEdit/VBoxContainer.add_child(butn)
	#butn.text = RecText

func ClearRecomendations() -> void:
	for g in $VBoxContainer/TextEdit/VBoxContainer.get_children():
		g.queue_free()
	
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("CommandLine")):
		visible = !visible
		Typing = visible
		call_deferred("Focus")
