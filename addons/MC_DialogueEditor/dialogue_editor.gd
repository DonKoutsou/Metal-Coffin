@tool
extends Control

class_name DialogueEditor

@export var graph : GraphEdit
@export var Menu : PopupMenu
@export var NodeMenu : PopupMenu

@export var NodeScenes : Dictionary[NodeType, PackedScene]

var selectedNode : BaseDialogueNode

var Happenings : Array[Happening]
var currentHappening : int = 0

var currentY : float = 0
var currentX : float = 0

enum NodeType{
	NORMAL,
	OPTION,
	REC_LOC,
	VIL_LOC
}

#--------------------------------------------------------
func _ready() -> void:
	UpdateDilogues()
	FixDialogues()
	SetHappening(0)

#--------------------------------------------------------
##Input
func _on_graph_edit_gui_input(event: InputEvent) -> void:
	
	if (event is InputEventMouseButton and !event.is_echo() and event.is_pressed()):
		if (event.button_index == 2):
			ProvedNodeSpawnOptions()
	if (event.is_action_pressed("ui_text_delete")):
		if (selectedNode == null):
			return
		selectedNode.queue_free()
		selectedNode = null

#--------------------------------------------------------
func _exit_tree() -> void:
	graph.clear_connections()
	for g in graph.get_children():
		if (g is GraphElement):
			g.queue_free()

#--------------------------------------------------------
##Checks happening directory and pulls all of them out
func UpdateDilogues() -> void:
	Menu.clear()
	var DirsToExplore :Array[String] = ["res://Resources/Happenings/"]
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
					print("Found file: " + file_name)
					var hap = load(g + "/" + file_name)
					if (hap is Happening):
						Happenings.append(hap)
						Menu.add_item(hap.HappeningName)
				
				file_name = dir.get_next()
	
	NodeMenu.clear()
	for g in NodeType.keys():
		NodeMenu.add_item(g)

#-----------------------------------------------
func SetHappening(id : int) -> void:
	currentX = 0
	currentY = 0
	
	graph.clear_connections()
	for g in graph.get_children():
		if (g is GraphElement):
			g.free()
	
	currentHappening = id
	var diag : Happening = Happenings[id]
	var LastNode : Array[BaseDialogueNode]
	for dialogueStageIndex : int in diag.Stages.size():
		var dialogueStage : HappeningStage = diag.Stages[dialogueStageIndex]
		
		currentX = 0
		var optionsSpace = 500 * dialogueStage.Options.size()
		currentY += optionsSpace / 2
		
		LastNode = HandleStage(dialogueStage, LastNode)
		
		currentY += LastNode[0].size.y + 100 + optionsSpace / 2
		
	graph.arrange_nodes()

#-----------------------------------------------
func HandleStage(stage : HappeningStage, connection : Array[BaseDialogueNode] = [], connectionIndex : int = 0) -> Array[BaseDialogueNode]:
	var optionsSpace = 500 * stage.Options.size()
	
	var lastNodes : Array[BaseDialogueNode] = connection
	for textIndex : int in stage.Texts.size():
		var newNode : StageDialogueNode = CreateDialogueNode()
		#newNode.title = "Stage {0}".format([stageIndex])
		newNode.ConfigureStage(stage, textIndex)
		for g in lastNodes:
			graph.connect_node(g.name, connectionIndex, newNode.name, 0)
			connectionIndex = 0
		lastNodes.clear()
		lastNodes.append(newNode)
		
		newNode.position_offset = Vector2(currentX, currentY)

		currentX += newNode.size.x + 100
	
	var lastOptions : Array[BaseDialogueNode]
	if (stage.Options.size() > 0):
		var optionsY = currentY - optionsSpace / 2 + 250
		
		for option : Happening_Option in stage.Options:
			var lastOption : BaseDialogueNode
			if (option is String_Happening_Option):
				var newNode : OptionDialogueNode = CreateDialogueNode(NodeType.OPTION)
				newNode.ConfigureOption(option)
				for g in lastNodes:
					graph.connect_node(g.name, 0, newNode.name, 0)
					
				newNode.position_offset = Vector2(currentX, optionsY)
				lastOption = newNode
			else: if (option is Recruit_Locator_Happening_Option):
				var newNode : RecruitLocatorOptionDialogueNode = CreateDialogueNode(NodeType.REC_LOC)
				newNode.ConfigureOption(option)
				for g in lastNodes:
					graph.connect_node(g.name, 0, newNode.name, 0)
				newNode.position_offset = Vector2(currentX, optionsY)
				
				lastOption = newNode
			else: if (option is Village_Locator_Happening_Option):
				var newNode : VillageLocatorOptionDialogueNode = CreateDialogueNode(NodeType.VIL_LOC)
				newNode.ConfigureOption(option)
				for g in lastNodes:
					graph.connect_node(g.name, 0, newNode.name, 0)
				newNode.position_offset = Vector2(currentX, optionsY)
				lastOption = newNode
			
			var branchSpace = 0
			if (option.WorldviewCheck != WorldView.WorldViews.NONE):
				branchSpace = 500
			
			var lastY = currentY
			var lastX = currentX
			
			currentX += lastOption.size.x + 100
			currentY = optionsY - branchSpace / 2
			
			var lastBranch : BaseDialogueNode = lastOption
			
			if (option.Branch != null):
				lastBranch = HandleStage(option.Branch, [lastBranch])[0]
			
			currentY = lastY
			currentX = lastX
				

			if (option.WorldviewCheck != WorldView.WorldViews.NONE):
				currentX += lastOption.size.x + 100
				currentY = optionsY + branchSpace / 2
				
				lastBranch = lastOption
				
				if (option.WorldViewFailBranch != null):
					lastBranch = HandleStage(option.WorldViewFailBranch, [lastBranch], 1)[0]
				
				currentY = lastY
				currentX = lastX
				
			if (!lastOption.option.FinishDiag):
				lastOptions.append(lastOption)
			optionsY += lastOption.size.y + 100
			
	if (lastOptions.size() > 0):
		return lastOptions
		
	return lastNodes

#---------------------------------------------------------
##Merges Stages into 1
func MergeStages(Stages : Array[HappeningStage]) -> void:
	for stageIndex in range(Stages.size() - 1 , -1, -1):
		var stage = Stages[stageIndex]
		
		if (stageIndex > 0):
			var prevStage = Stages[stageIndex - 1]
			##If prev stage has no options it means we can merge with current
			if prevStage.Options.size() == 0:
				Stages.remove_at(stageIndex)
				prevStage.Texts.append_array(stage.Texts)
				prevStage.Options.append_array(stage.Options)

#--------------------------------------------------------
func CreateDialogueAtMousePos(type : NodeType = NodeType.NORMAL) -> void:
	var pos = (graph.get_local_mouse_position() + graph.scroll_offset) / graph.zoom
	CreateDialogueNode(type, pos)

#--------------------------------------------------------
func CreateDialogueNode(type : NodeType = NodeType.NORMAL, posOverride : Vector2 = Vector2.INF) -> BaseDialogueNode:
	var node : BaseDialogueNode = NodeScenes[type].instantiate()
	graph.add_child(node)
	node.node_selected.connect(OnNodeSelected.bind(node))
	
	node.Changed.connect(ResaveHappening)
	
	if (node is StageDialogueNode):
		var newStage = HappeningStage.new()
		var t : Array[HappeningText] = []
		t.append(HappeningText.new())
		newStage.Texts = t
		node.ConfigureStage(newStage, 0)
	
	if (posOverride != Vector2.INF):
		node.position_offset = posOverride
	return node

#--------------------------------------------------------
func ResaveHappening() -> void:
	ResourceSaver.save(Happenings[currentHappening], Happenings[currentHappening].resource_path)
	#graph.arrange_nodes()

#--------------------------------------------------------
func OnNodeSelected(node : BaseDialogueNode) -> void:
	selectedNode = node

#-----------------------------------------------
func ProvedNodeSpawnOptions() -> void:
	var bar = MenuBar.new()
	add_child(bar)
	var nodeSpawnMenu = PopupMenu.new()
	nodeSpawnMenu.title = "Spawn Node"
	bar.add_child(nodeSpawnMenu)
	nodeSpawnMenu.mouse_exited.connect(nodeSpawnMenu.queue_free)
	for g in NodeType.keys():
		nodeSpawnMenu.add_item(g)
	nodeSpawnMenu.index_pressed.connect(CreateDialogueAtMousePos)
	nodeSpawnMenu.popup()
	bar.position = get_local_mouse_position()

#-----------------------------------------------
func OnNodeConnected(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from : BaseDialogueNode = graph.get_node(NodePath(from_node))
	var to : BaseDialogueNode = graph.get_node(NodePath(to_node))
	
	if (from is StageDialogueNode):
		#var stageSize = from.stage.HappeningTexts.size()
		#if (stageSize - 1 > from.textIndex):
			#printerr("Can only add text to end of stage")
			#return
			
		if (to is StageDialogueNode):
			if (to.stage == null):
				to.stage = from.stage
				to.textIndex = from.textIndex + 1
				to.stage.Texts.append(to.text)
				var next = GetNextStage(from)
		
		if (to is OptionDialogueNode):
			if (to.option == null):
				printerr("Missing a configured option")
				return
				
			if (from.stage.Options.size() == 0):
				var newArr : Array[Happening_Option] = [to.option]
				from.stage.Options = newArr

			else:
				from.stage.Options.append(to.option)
			
	else: if (from is OptionDialogueNode):
		if (to is OptionDialogueNode):
			printerr("Cant connect option to option")
			return
			
		if (to is StageDialogueNode):
			if (from.option.Branch != null):
				printerr("Option already has a branch going out")
				return
				
			var stage : HappeningStage
			if (to.stage == null):
				stage = HappeningStage.new()
				stage.Texts.append(to.text)
				to.ConfigureStage(stage, 0)
			else:
				stage = to.stage

			from.option.Branch = stage
			

	graph.connect_node(from_node, from_port, to_node, to_port)
	ResaveHappening()


func OnNodeConectToEmpty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	pass # Replace with function body.


func OnNodeDisconnected(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	pass
	#var from : BaseDialogueNode = graph.get_node(NodePath(from_node))
	#var to : BaseDialogueNode = graph.get_node(NodePath(to_node))
	#
	#if (from is StageDialogueNode):
		#var textIndex = from.stage.Texts.find(from.text)
		#while from.stage.Texts.size() - 1 > textIndex:
			#from.stage.Texts.pop_back()		
		#
		#var newStage = 
	
	graph.disconnect_node(from_node, from_port, to_node, to_port)

func _on_popup_menu_index_pressed(index: int) -> void:
	SetHappening(index)


func _on_popup_menu_2_index_pressed(index: int) -> void:
	CreateDialogueNode(index)

#func GetStageOwner(stage : StageDialogueNode) -> Array[HappeningStage]:
	#var prev = GetPrevStage(stage)
	#while prev != null:
		#var newPrev = GetPrevStage(prev)
		#if (newPrev is OptionDialogueNode):
			#if (newPrev.option.BranchContinuation.has(stage)):
				#return newPrev.option.BranchContinuation
			#else: if(newPrev.option.WorldViewCheckFailBranch.has(stage)):
				#return newPrev.option.WorldViewCheckFailBranch
			#else:
				#return []
		#prev = newPrev
		#
	#return Happenings[currentHappening].Stages

func GetPrevStage(stage : StageDialogueNode) -> StageDialogueNode:
	var connections = graph.get_connection_list_from_node(stage.name) 
	for connectionInfo in connections:
		var from : StringName = connectionInfo["from_node"]
		var from_port : int = connectionInfo["from_port"]
		var to : StringName = connectionInfo["to_node"]
		var to_port : int = connectionInfo["to_port"]
		
		var toNode : BaseDialogueNode = graph.get_node(NodePath(to))
		if (toNode != stage):
			continue
			
		var fromNode : BaseDialogueNode = graph.get_node(NodePath(from))
		if (fromNode is StageDialogueNode):
			if (toNode.stage == stage.stage and toNode.textIndex > stage.textIndex):
				return fromNode
		
	return null

func GetNextStage(stage : StageDialogueNode) -> StageDialogueNode:
	var connections = graph.get_connection_list_from_node(stage.name) 
	for connectionInfo in connections:
		var from : StringName = connectionInfo["from_node"]
		var from_port : int = connectionInfo["from_port"]
		var to : StringName = connectionInfo["to_node"]
		var to_port : int = connectionInfo["to_port"]
		
		var fromNode : BaseDialogueNode = graph.get_node(NodePath(from))
		if (fromNode != stage):
			continue
			
		var toNode : BaseDialogueNode = graph.get_node(NodePath(to))
		if (toNode is StageDialogueNode):
			if (toNode.stage == stage.stage and toNode.textIndex > stage.textIndex):
				return toNode
		
	return null

func OnNodeDeleted(nodes: Array[StringName]) -> void:
	for n in nodes:
		var node : BaseDialogueNode = graph.get_node(NodePath(n))
		var connections = graph.get_connection_list_from_node(n)
		
		var frList : Dictionary[StringName, int]
		var toList : Dictionary[StringName, int]
		
		if (node is StageDialogueNode):
			node.stage.Texts.remove_at(node.textIndex)
			RecursevlyAdjustTextIndex(node, -1)
		
		for connectionInfo in connections:
			var from : StringName = connectionInfo["from_node"]
			var from_port : int = connectionInfo["from_port"]
			var to : StringName = connectionInfo["to_node"]
			var to_port : int = connectionInfo["to_port"]
			
			
			var fromNode : BaseDialogueNode = graph.get_node(NodePath(from))
			var toNode : BaseDialogueNode = graph.get_node(NodePath(to))
			
			if (fromNode is StageDialogueNode):
				if (toNode is OptionDialogueNode):
					fromNode.stage.Options.erase(toNode.option)
			
			if (fromNode is OptionDialogueNode):
				if (toNode is StageDialogueNode):
					fromNode.option.Branch = null
					fromNode.option.WorldViewFailBranch = null
					
			graph.disconnect_node(from, from_port, to, to_port)

			#From is not the one being deleted
			if (from != n):
				for g in toList:
					OnNodeConnected(from, from_port, g, toList[g])

			#To is not the one being deleted		
			if (to != n):
				for g in frList:
					OnNodeConnected(g, frList[g], to, to_port)
			
			frList[from] = from_port
			toList[to] = to_port
	
	ResaveHappening()
	#SetHappening(currentHappening)

##When removing a text from a stage or adding a text in the middle we need to go down the line and fix the indexes
func RecursevlyAdjustTextIndex(node : StageDialogueNode, adjustment : int) -> void:
	var connections = graph.get_connection_list_from_node(node.name)
	for connectionInfo in connections:
		var from : StringName = connectionInfo["from_node"]
		var from_port : int = connectionInfo["from_port"]
		var to : StringName = connectionInfo["to_node"]
		var to_port : int = connectionInfo["to_port"]
		
		var fromNode : BaseDialogueNode = graph.get_node(NodePath(from))
		var toNode : BaseDialogueNode = graph.get_node(NodePath(to))
		
		if (fromNode != node):
			continue
		
		if (toNode is StageDialogueNode):
			toNode.textIndex += adjustment
			RecursevlyAdjustTextIndex(toNode, adjustment)

##Applied the new stage recursevly down
func RecursevlyUpdateStage(node : StageDialogueNode, newStage : HappeningStage, index : int) -> void:
	var connections = graph.get_connection_list_from_node(node.name)
	for connectionInfo in connections:
		var from : StringName = connectionInfo["from_node"]
		var from_port : int = connectionInfo["from_port"]
		var to : StringName = connectionInfo["to_node"]
		var to_port : int = connectionInfo["to_port"]
		
		var fromNode : BaseDialogueNode = graph.get_node(NodePath(from))
		var toNode : BaseDialogueNode = graph.get_node(NodePath(to))
		
		if (fromNode != node):
			continue
		
		if (toNode is StageDialogueNode):
			if (toNode.textIndex == 0):
				return
			var oldStage = toNode.stage
			oldStage.Texts.erase(toNode.text)
			
			toNode.ConfigureStage(newStage, index)
			
			RecursevlyUpdateStage(toNode, newStage, index + 1)





func FixDialogues() -> void:
	
	for hap : Happening in Happenings:
		
		FixStage(hap.Stages)
		#
		#ResourceSaver.save(hap, hap.resource_path)

func FixStage(Stages : Array[HappeningStage]) -> void:
	
	for stage : HappeningStage in Stages:
		for opt in stage.Options:
			if (opt.BranchContinuation.size() > 0):
				opt.Branch = opt.BranchContinuation[0]
			if (opt.WorldViewCheckFailBranch.size() > 0):
				opt.WorldViewFailBranch = opt.WorldViewCheckFailBranch[0]
				
			FixStage(opt.BranchContinuation)
			FixStage(opt.WorldViewCheckFailBranch)
		#if (stage.HappeningTexts.size() > 0):
			#for t : String in stage.HappeningTexts:
				#var text = HappeningText.new()
				#text.Text = t
				#text.Pic = stage.StagePic
				#stage.Texts.append(text)
			#stage.HappeningTexts.clear()
		#for opt in stage.Options:
			#FixStage(opt.BranchContinuation)
			#FixStage(opt.WorldViewCheckFailBranch)
				#
	#for stageIndex in range(Stages.size() - 1 , -1, -1):
		#var stage = Stages[stageIndex]
		#
		#if (stageIndex > 0):
			#var prevStage = Stages[stageIndex - 1]
			###If prev stage has no options it means we can merge with current
			#if prevStage.Options.size() == 0:
				#Stages.remove_at(stageIndex)
				#prevStage.Texts.append_array(stage.Texts)
				#prevStage.Options.append_array(stage.Options)



###
