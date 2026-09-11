@tool
extends Control

class_name DialogueEditor

@export var graph : GraphEdit
@export var Menu : PopupMenu

@export var NodeScenes : Dictionary[NodeType, PackedScene]

var selectedNode : BaseDialogueNode

var Happenings : Array[Happening]
var currentHappening : int = 0

var currentY : float = 0
var currentX : float = 0

enum NodeType{
	NORMAL,
	OPTION,
}

func _ready() -> void:
	UpdateDilogues()
	SetHappening(0)
	
func _exit_tree() -> void:
	graph.clear_connections()
	for g in graph.get_children():
		if (g is GraphElement):
			g.queue_free()

func UpdateDilogues() -> void:
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

func SetHappening(id : int) -> void:
	currentX = 0
	currentY = 0
	
	graph.clear_connections()
	for g in graph.get_children():
		if (g is GraphElement):
			g.queue_free()
	
	currentHappening = id
	var diag : Happening = Happenings[id]
	var LastNode : Array[BaseDialogueNode]
	for dialogueStage : HappeningStage in diag.Stages:
		currentX = 0
		var optionsSpace = 500 * dialogueStage.Options.size()
		currentY += optionsSpace / 2
		LastNode = HandleStage(dialogueStage, LastNode)
		currentY += LastNode[0].size.y + 100 + optionsSpace / 2
		

func HandleStage(stage : HappeningStage, connection : Array[BaseDialogueNode] = [], connectionIndex : int = 0) -> Array[BaseDialogueNode]:
	var optionsSpace = 500 * stage.Options.size()
	
	var lastNodes : Array[BaseDialogueNode] = connection
	for textIndex : int in stage.HappeningTexts.size():
		var newNode : StageDialogueNode = CreateDialogueNode()
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
			
			var branchSpace = 0
			if (option.WorldviewCheck != WorldView.WorldViews.NONE):
				branchSpace = 500
				
			var lastY = currentY
			var lastX = currentX
			
			currentX += lastOption.size.x + 100
			currentY = optionsY - branchSpace / 2
			var lastBranch : BaseDialogueNode = lastOption
			for branch in option.BranchContinuation:
				lastBranch = HandleStage(branch, [lastBranch])[0]
			currentY = lastY
			currentX = lastX
			
			if (option.WorldviewCheck != WorldView.WorldViews.NONE):
				currentX += lastOption.size.x + 100
				currentY = optionsY + branchSpace / 2
				lastBranch = lastOption
				for branch in option.WorldViewCheckFailBranch:
					lastBranch = HandleStage(branch, [lastBranch], 1)[0]
				currentY = lastY
				currentX = lastX
			
			
			lastOptions.append(lastOption)
			
			optionsY += lastOption.size.y + 100
	if (lastOptions.size() > 0):
		return lastOptions
		
	return lastNodes

func CreateDialogueNode(type : NodeType = NodeType.NORMAL) -> BaseDialogueNode:
	var node : BaseDialogueNode = NodeScenes[type].instantiate()
	graph.add_child(node)
	node.node_selected.connect(OnNodeSelected.bind(node))
	
	node.Changed.connect(ResaveHappening)
	
	return node

func ResaveHappening() -> void:
	ResourceSaver.save(Happenings[currentHappening], Happenings[currentHappening].resource_path)

func _on_button_pressed() -> void:
	var node : BaseDialogueNode = CreateDialogueNode()
	graph.add_child(node)
	node.node_selected.connect(OnNodeSelected.bind(node))

func OnNodeSelected(node : BaseDialogueNode) -> void:
	selectedNode = node

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_text_delete")):
		if (selectedNode == null):
			return
		selectedNode.queue_free()
		selectedNode = null


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from : BaseDialogueNode = graph.get_node(NodePath(from_node))
	var to : BaseDialogueNode = graph.get_node(NodePath(to_node))
	
	print(from)
	print(to)
	
	print(from_node)
	graph.connect_node(from_node, from_port, to_node, to_port)

func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.disconnect_node(from_node, from_port, to_node, to_port)

func _on_popup_menu_index_pressed(index: int) -> void:
	SetHappening(index)
