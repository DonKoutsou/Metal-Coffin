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

	if (Command.substr(Command.length() - 1, Command.length()) == "\n"):
		Command = Command.replace("\n", "")
		var response = HandleCommand(Command)
		if (StartingMen):
			PopUpManager.GetInstance().DoFadeNotif(response, get_parent())
		else:
			PopUpManager.GetInstance().DoFadeNotif(response, null)
		
		Text.text = ""
	UpdateRecomendations()
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
				args.append(str_to_var(CommandList[g]))
			if (get_method_argument_count(commandToExecute) != args.size()):
				return "Missing arguments.\nFailed to call command"
			if (!DoArgumentMatch(commandToExecute, args)):
				return "Error matching arguments"
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

func DoArgumentMatch(methodName : String, methodArgs : Array[Variant]) -> bool:
	var m = get_method_list()
	var matchingArguments : int = 0
	for method in m:
		var n = method["name"]
		var args = method["args"]
		if (n != methodName):
			continue
		for argumentIndex in args.size():
			var methodArgument = args[argumentIndex]
			var incommingArgument = methodArgs[argumentIndex]
			var methodArgumentType = methodArgument["type"]
			var incommingArgumentType = typeof(incommingArgument)
			if (methodArgumentType == incommingArgumentType):
				matchingArguments += 1
		break
	return matchingArguments == methodArgs.size()

func HandlePrologueCommand(Command) -> String:
	if (Command.size() == 1):
		StartPrologue.emit(false)
		return "Starting Prologue"
	
	match (Command[1].to_lower()):
		"skip":
			StartPrologue.emit(true)
			return "Starting Prologue\nSkipping Story"
	
	return "Error Handling Location Command"

func Prologue(skip : bool) -> String:
	if (World.Instance != null):
		return "Can only apply while in main menu"

	StartPrologue.emit(skip)
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

func Teleport(CharName : String, Locx : int, Locy : int) -> String:
	if (World.Instance == null or World.WORLDST != World.WORLDSTATE.NORMAL):
		return "Can only apply while in map"

	for g in get_tree().get_nodes_in_group("PlayerShips"):
		var ship = g as MapShip
		if ship.Cpt.GetCaptainName().to_lower() == CharName.to_lower():
			ship.global_position = Vector2(Locx, Locy) * 10
			return "Successfully teleported\n{0} to pos\n|{1}|".format([CharName, ship.global_position])
	
	return "Teleport failed"

func EnemyDebug(t : bool) -> String:
	Commander.GetInstance().ToggleEnemyDebug(t)
	return "Enemy debug toggled"

func PrintLocations(CharName : String) -> String:
	for g in get_tree().get_nodes_in_group("PlayerShips"):
		var ship = g as MapShip
		if ship.Cpt.GetCaptainName().to_lower() == CharName.to_lower():
			return "{0}'s position is |x: {1}, y : {2}|".format([CharName, ship.global_position.x, ship.global_position.y])
	
	return "Location Print Failed"

func InventoryAdd(CapName : String, ItemName : String, ItemAmmount : int = 1) -> String:
	if (World.Instance == null or World.WORLDST != World.WORLDSTATE.NORMAL):
		return "Can only apply while in map"
	var Inv = InventoryManager.GetInstance()
	var inv = Inv.GetCharacterInventoryByName(CapName)
	if (inv == null):
		return "Couldn't find captain name"

	return HandleInventoryItemAddCommand(inv, CapName, ItemName, ItemAmmount)

func StatRefill(CapName : String, StatName : String) -> String:
	if (World.Instance == null or World.WORLDST != World.WORLDSTATE.NORMAL):
		return "Can only apply while in map"
	for g in get_tree().get_nodes_in_group("PlayerShips"):
		var ship = g as MapShip
		if ship.Cpt.GetCaptainName().to_lower() == CapName.to_lower():
			return HandleStatCommand(ship.Cpt, StatName)

	return "Couldn't find captain name"

func InventoryUpgrade(CapName : String, ItemName : String) -> String:
	if (World.Instance == null or World.WORLDST != World.WORLDSTATE.NORMAL):
		return "Can only apply while in map"
	var Inv = InventoryManager.GetInstance()
	var inv = Inv.GetCharacterInventoryByName(CapName)
	if (inv == null):
		return "Couldn't find captain name"
	return HandleItemUpgrade(inv, ItemName)

func HandleInventoryItemAddCommand(Inv : CharacterInventory, InventoryOwnerName : String, ItemName : String, ItAmm : int) -> String:

	for g in Items:
		if (g.GetItemName().to_lower() == ItemName.replace("_", " ").to_lower()):
			for a in ItAmm:
				Inv.AddItem(g)
			return "Added {0}X of {1} to {2}'s inventory".format([ItAmm, g.GetItemName(), InventoryOwnerName])
	
	return "Error Adding Item"
	
func HandleItemUpgrade(Inv : CharacterInventory, ItemName : String) -> String:
	for It in Inv._GetInventoryBoxes():
		if It.IsEmpty():
			continue
		if It._ContainedItem.GetItemName().to_lower() == ItemName.to_lower():
			var success = Inv.ForceUpgradeItem(It)
			if (success):
				return "{0} upgraded succesfully".format([ItemName])
			else:
				return "Couldnt upgrade Item"
			
	return "Error Upgrading Item"
	
func HandleStatCommand(Char : Captain, statName : String) -> String:
	var key = STAT_CONST.STATS.keys().find(statName.to_upper())
	if (key == -1):
		return "Invalid stat name"
	Char.FullyRefilStat(key)
	
	return "{0}'s {1} was refilled".format([Char.CaptainName, statName])

func RefrshExistingItems() -> void:
	var DirsToExplore :Array[String] = ["res://Resources/Items"]
	for g in DirsToExplore:
		var dir = DirAccess.open(g)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					#print("Found directory: " + file_name)
					DirsToExplore.append(g + "/" + file_name)
				else:
					#printraw("Found file: " + file_name)
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

func UpdateRecomendations() -> void:
	ClearRecomendations()
	if (Text.text.length() == 0):
		for g in CommandListConfiguration:
			var commandText = ListToString(g)
			var args = GetMethodArguments(CommandListConfiguration[g])
			AddRecomendation(commandText + ListToString(args))
	else:
		var text = Text.text.to_lower().split(" ")
		var matchingCommandIndexes : Array[int] = []
		for textIndex in text.size():
			if (text[textIndex] == ""):
				continue
			var length = text[textIndex].length()
			for wordListIndex : int in CommandListConfiguration.size():
				var wordList = CommandListConfiguration.keys()[wordListIndex]
				if (wordList.size() - 1 < textIndex):
					continue
				var word = wordList[textIndex].to_lower().substr(0, length)
				if (word == text[textIndex]):
					if (!matchingCommandIndexes.has(wordListIndex)):
						matchingCommandIndexes.append(wordListIndex)
				else:
					matchingCommandIndexes.erase(wordListIndex)
		for command in matchingCommandIndexes:
			var list = CommandListConfiguration.keys()[command]
			var commandText = ListToString(list)
			var args = GetMethodArguments(CommandListConfiguration[list])
			AddRecomendation(commandText + ListToString(args))
				
					

func GetMethodArguments(methodName : String) -> PackedStringArray:
	var methods = get_method_list()
	var argList : PackedStringArray = []
	
	for g in methods:
		if (g["name"] == methodName):
			var args = g["args"]
			for argumentIndex in args.size():
				var ArgumentName : String = args[argumentIndex]["name"]
				var ArgumentType = args[argumentIndex]["type"]
				argList.append("({0}:{1})".format([ArgumentName, type_string(ArgumentType)]))
	return argList

func ListToString(list : PackedStringArray) -> String:
	var finalString : String = ""
	for g in list:
		finalString += g + " "
	return finalString

func RecomendationPressed(text : String) -> void:
	Text.text = text + " "
	UpdateRecomendations()
	
func OnCommandLineFocused() -> void:
	UpdateRecomendations()
		
func AddRecomendation(RecText : String) -> void:
	var butn = Button.new()
	butn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	butn.autowrap_mode = TextServer.AUTOWRAP_WORD
	butn.custom_minimum_size.x = size.x - 20
	butn.connect("pressed", RecomendationPressed.bind(RecText))
	$VBoxContainer/TextEdit/VBoxContainer.add_child(butn)
	butn.text = RecText

func ClearRecomendations() -> void:
	for g in $VBoxContainer/TextEdit/VBoxContainer.get_children():
		g.queue_free()
	
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("CommandLine")):
		visible = !visible
		Typing = visible
		call_deferred("Focus")
