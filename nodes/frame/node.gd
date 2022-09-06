# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Frame Node Type
extends GraphNode

onready var Main = get_tree().get_root().get_child(0)
onready var Grid = Main.Grid
onready var Mind = Main.Mind
onready var TheTree = Main.TheTree

var Utils = Helpers.Utils

const NO_LABEL_MESSAGE = "No Label!"
const HIDE_EMPTY_LABLE = true

var _node_id
var _node_resource

var This = self

onready var CollapseToggle = get_node("./MarginContainer/VBoxContainer/Header/CollapseToggle")
onready var FrameLabel = get_node("./MarginContainer/VBoxContainer/FrameLabel")

func _ready() -> void:
	register_connections()
	pass

func register_connections() -> void:
	self.connect("resize_request", self, "_on_resize_request", [], CONNECT_DEFERRED)
	CollapseToggle.connect("toggled", self, "_handle_collapse_and_size", [], CONNECT_DEFERRED)
	pass

func _on_resize_request(new_min_size) -> void:
	if new_min_size.x < 128 :
		new_min_size.x = 128
	if new_min_size.y < 128 :
		new_min_size.y = 128
	Mind.update_resource(
		_node_id, 
		{ "data": { "rect": Utils.vector2_to_array(new_min_size) } },
		"nodes",
		true
	)
	# Because we are updating resource out of signal hierarchy,
	# we need to manually toggle the save status as well:
	Mind.reset_project_save_status(false)
	pass

func _handle_collapse_and_size(do_collapse: bool = CollapseToggle.is_pressed()) -> void:
	var size_vector = Utils.array_to_vector2(_node_resource.data.rect)
	if do_collapse:
		self.set_deferred("resizable", false)
		var shrink_fill = Vector2(size_vector.x, 0)
		self.set_deferred("rect_min_size", shrink_fill)
		self.set_deferred("rect_size", shrink_fill)
	else:
		self.set_deferred("resizable", true)
		self.set_deferred("rect_min_size", size_vector)
		self.set_deferred("rect_size", size_vector)
	pass

func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_doubleclick():
			# (We use alt modifier in order not to interfere with double-click to inspect)
			if event.get_alt(): # Alt + Double-click:
				event.set_pressed(false)
				var nodes_there = Grid.get_nodes_under_cursor()
				# Select singular one under the cursor:
				if nodes_there.size() > 1:
					self.set_deferred("selected", false)
					Grid.call_deferred("_on_node_unselection", self)
					for each in nodes_there:
						if each.id != self._node_id:
							each.node.set_deferred("selected", true)
							Grid.call_deferred("_on_node_selection", each.node)
				# Select all framed nodes:
				else:
					Grid.call_deferred("sellect_all_in", self.get_global_rect())
	pass

func _update_node(data:Dictionary) -> void:
	if data.has("label") && (data.label is String) && data.label.length() > 0:
		FrameLabel.set_deferred("text", data.label)
		FrameLabel.set_deferred("visible", true)
	else:
		FrameLabel.set_deferred("text", NO_LABEL_MESSAGE)
		FrameLabel.set_deferred("visible", (!HIDE_EMPTY_LABLE))
	if data.has("color") && (data.color is String):
		This.set("self_modulate", Utils.rgba_hex_to_color(data.color) )
	if data.has("rect") && data.rect is Array && data.rect.size() >= 2:
		_handle_collapse_and_size()
	pass
