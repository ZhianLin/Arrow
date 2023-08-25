# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Randomizer Node Type Inspector
extends ScrollContainer

onready var Main = get_tree().get_root().get_child(0)

const DEFAULT_NODE_DATA = {
	"slots": RandomizerSharedClass.RANDOMIZER_MINIMUM_ACCEPTABLE_OUT_SLOTS
}

var _OPEN_NODE_ID
var _OPEN_NODE

var This = self

onready var Slots = get_node("./Randomizer/Slots")

func _ready() -> void:
	Slots.set_max(RandomizerSharedClass.RANDOMIZER_MAXIMUM_ACCEPTABLE_OUT_SLOTS)
	Slots.set_min(RandomizerSharedClass.RANDOMIZER_MINIMUM_ACCEPTABLE_OUT_SLOTS)
	# register_connections()
	pass

#func register_connections() -> void:
#	# e.g. SOME_CHILD.connect("the_signal", self, "the_handler_on_self", [], CONNECT_DEFERRED)
#	pass

func _update_parameters(node_id:int, node:Dictionary) -> void:
	# first cache the node
	_OPEN_NODE_ID = node_id
	_OPEN_NODE = node
	# ... then update parameters
	if node.has("data") && node.data is Dictionary:
		if node.data.has("slots") && node.data.slots is int:
			Slots.set_value(node.data.slots)
		else:
			Slots.set_value(DEFAULT_NODE_DATA.slots)
	pass

func cut_off_dropped_connections() -> void:
	if _OPEN_NODE.has("data") && _OPEN_NODE.data.has("slots") && ( _OPEN_NODE.data.slots is int ):
		if _OPEN_NODE.data.slots > Slots.get_value():
			Main.Grid.cut_off_connections(_OPEN_NODE_ID, "out", Slots.get_value() - 1)
	pass

func _read_parameters() -> Dictionary:
	cut_off_dropped_connections()
	var parameters = {
		"slots": int( Slots.get_value() )
	}
	return parameters

func _create_new(new_node_id:int = -1) -> Dictionary:
	var data = DEFAULT_NODE_DATA.duplicate(true)
	return data

