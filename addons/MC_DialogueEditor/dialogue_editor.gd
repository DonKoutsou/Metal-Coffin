@tool
extends Control

class_name DialogueEditor

@export var graph : GraphEdit

@export var NodeScene : PackedScene

var selectedNode : BaseDialogueNode

func _ready() -> void:
	OpenDialigue()

func OpenDialigue() -> void:
	var diag : Happening = load("res://Resources/Happenings/CardiPrince.tres")
	
	var yPos = 0
	for dialogueStage : HappeningStage in diag.Stages:
		var xPos = 0
		
		var lastNode : BaseDialogueNode
		for text : String in dialogueStage.HappeningTexts:
			var newNode : BaseDialogueNode = CreateDialogueNode()
			newNode.AddText(text)
			if (lastNode != null):
				graph.connect_node(lastNode.name, 0, newNode.name, 0)
			lastNode = newNode
			newNode.position_offset = Vector2(xPos, yPos)

			xPos += 500
		
		var optionsY = yPos - 500 * (dialogueStage.Options.size() / 2)
		for option : Happening_Option in dialogueStage.Options:
			if (option is String_Happening_Option):
				var newNode : BaseDialogueNode = CreateDialogueNode()
				newNode.title = option.OptionName
				newNode.AddText(option.StringReply)
				graph.connect_node(lastNode.name, 0, newNode.name, 0)
				newNode.position_offset = Vector2(xPos, optionsY)
				optionsY += 250
				
			
		yPos += 1000

func CreateDialogueNode() -> BaseDialogueNode:
	var node : BaseDialogueNode = NodeScene.instantiate()
	graph.add_child(node)
	node.node_selected.connect(OnNodeSelected.bind(node))
	return node

func _on_button_pressed() -> void:
	var node : BaseDialogueNode = NodeScene.instantiate()
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
	print(from_node)
	graph.connect_node(from_node, from_port, to_node, to_port)
