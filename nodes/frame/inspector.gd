# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Frame Sub-Inspector
extends Control

@onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = {
	"label": "",
	"color": null,
	"rect": [128, 128],
}

var _OPEN_NODE_ID
var _OPEN_NODE

var This = self

@onready var ColorInput = $ColorPicker
@onready var LabelEdit = $TextEdit
@onready var SizeXEdit = $Width/Value
@onready var SizeYEdit = $Height/Value

#func _ready() -> void:
#	register_connections()
#	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then update parameters
	LabelEdit.set_text("")
	if node.has("data") && node.data is Dictionary:
		if node.data.has("label") && node.data.label is String:
			LabelEdit.set_text(node.data.label)
		if node.data.has("color") && node.data.color is String:
			var the_color = Helpers.Utils.rgba_hex_to_color(node.data.color)
			ColorInput.set_pick_color(the_color)
		else:
			ColorInput.set_pick_color( Helpers.Generators.create_random_color() )
		if node.data.has("rect") && node.data.rect is Array && node.data.rect.size() >= 2:
			SizeXEdit.set_value(node.data.rect[0])
			SizeYEdit.set_value(node.data.rect[1])
	pass

func _read_parameters() -> Dictionary:
	var parameters = {
		"label": LabelEdit.get_text(),
		"color": Helpers.Utils.color_to_rgba_hex(ColorInput.color),
		"rect": [
			SizeXEdit.get_value(),
			SizeYEdit.get_value(),
		]
	}
	return parameters

func _create_new(_new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	data.color = Helpers.Utils.color_to_rgba_hex(Helpers.Generators.create_random_color(0.5))
	return data
