# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Inspector :: Variables Tab
extends Tabs

signal relay_request_mind

onready var Main = get_tree().get_root().get_child(0)
onready var Grid = get_node(Addressbook.GRID)

var Utils = Helpers.Utils

var _LISTED_VARIABLES_BY_ID = {}
var _LISTED_VARIABLES_BY_NAME = {}

var _SELECTED_VARIABLE_BEING_EDITED_ID = -1

var _SELECTED_VARIABLE_USERS_IN_THE_SCENE = {} # id: {id, resource, map}
var _SELECTED_VARIABLE_USER_IDS_IN_THE_SCENE = []

var _CURRENT_LOCATED_REF_ID = -1

onready var Filter = get_node(Addressbook.INSPECTOR.VARIABLES.LISTING_INSTRUCTION.FILTER)
onready var FilterReverse = get_node(Addressbook.INSPECTOR.VARIABLES.LISTING_INSTRUCTION.FILTER_REVERSE)
onready var FilterInType = get_node(Addressbook.INSPECTOR.VARIABLES.LISTING_INSTRUCTION.FILTER_IN_TYPE)
onready var FilterForScene = get_node(Addressbook.INSPECTOR.VARIABLES.LISTING_INSTRUCTION.FILTER_FOR_SCENE)
onready var SortAlphabetical = get_node(Addressbook.INSPECTOR.VARIABLES.LISTING_INSTRUCTION.SORT_ALPHABETICAL)
onready var VariablesList = get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLES_LIST)

onready var VariableEditorPanel = get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.itself)
onready var VariableRawUid = get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.RAW_UID)
onready var VariableEditorName = get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.NAME_EDIT)
onready var VariableEditorInitialValue = {
	"str": get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.INITIAL_VALUE_EDITS["str"]),
	"num": get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.INITIAL_VALUE_EDITS["num"]),
	"bool": get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.INITIAL_VALUE_EDITS["bool"])
}
onready var VariableEditorSaveButton = get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.SAVE_BUTTON)
onready var VariableEditorRemoveButton = get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.REMOVE_BUTTON)

onready var VariablesTypeSelect = get_node(Addressbook.INSPECTOR.VARIABLES.TYPE_SELECT)
onready var VariablesNewButton = get_node(Addressbook.INSPECTOR.VARIABLES.NEW_BUTTON)

const VARIABLE_TYPE_IN_SELECTION_TEXT_TEMPLATE = "{name} ({type})"
const VARIABLE_IN_LIST_TEXT_TEMPLATE = "{name} ({type}, {init})"

onready var VariableAppearanceGoToButton = get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.VARIABLE_USAGES.GO_TO_MENU_BUTTON)
onready var VariableAppearanceGoToButtonPopup = VariableAppearanceGoToButton.get_popup()
onready var VariableAppearanceGoToPrevious = get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.VARIABLE_USAGES.GO_TO_PREVIOUS)
onready var VariableAppearanceGoToNext = get_node(Addressbook.INSPECTOR.VARIABLES.VARIABLE_EDITOR.VARIABLE_USAGES.GO_TO_NEXT)

const VARIABLE_APPEARANCE_INDICATION_TEMPLATE = "{here} : {total}"
const RAW_UID_TIP_TEMPLATE = "Raw UID: %s \n[press button to copy]"

func _ready() -> void:
	register_connections()
	VariableAppearanceGoToButtonPopup.set_allow_search(true)
	pass

func register_connections() -> void:
	VariablesNewButton.connect("pressed", self, "request_new_variable_creation", [], CONNECT_DEFERRED)
	VariablesList.connect("item_selected", self, "_on_variables_list_item_selected", [], CONNECT_DEFERRED)
	VariablesList.connect("nothing_selected", self, "_on_variables_list_nothing_selected", [], CONNECT_DEFERRED)
	VariablesList.connect("gui_input", self, "_on_list_gui_input", [], CONNECT_DEFERRED)
	VariableRawUid.connect("pressed", self, "os_clipboard_push_raw_uid", [], CONNECT_DEFERRED)
	VariableEditorSaveButton.connect("pressed", self, "submit_variable_modification", [], CONNECT_DEFERRED)
	VariableEditorRemoveButton.connect("pressed", self, "request_remove_variable", [], CONNECT_DEFERRED)
	VariableAppearanceGoToButtonPopup.connect("index_pressed", self, "_on_go_to_menu_button_popup_index_pressed", [], CONNECT_DEFERRED)
	VariableAppearanceGoToPrevious.connect("pressed", self, "_rotate_go_to", [-1], CONNECT_DEFERRED)
	VariableAppearanceGoToNext.connect("pressed", self, "_rotate_go_to", [1], CONNECT_DEFERRED)
	Filter.connect("text_changed", self, "_on_listing_instruction_change", [], CONNECT_DEFERRED)
	FilterReverse.connect("toggled", self, "_on_listing_instruction_change", [], CONNECT_DEFERRED)
	FilterInType.connect("toggled", self, "_on_listing_instruction_change", [], CONNECT_DEFERRED)
	FilterForScene.connect("toggled", self, "_on_listing_instruction_change", [], CONNECT_DEFERRED)
	SortAlphabetical.connect("toggled", self, "_on_listing_instruction_change", [], CONNECT_DEFERRED)
	pass

func initialize_tab() -> void:
	refresh_variable_type_selection()
	refresh_variables_list()
	pass

func refresh_tab() -> void:
	refresh_variables_list()
	pass

func refresh_variable_type_selection() -> void:
	VariablesTypeSelect.clear()
	for type_id in Settings.VARIABLE_TYPES_ENUM:
		var type = Settings.VARIABLE_TYPES_ENUM[type_id]
		var the_type = Settings.VARIABLE_TYPES[type]
		VariablesTypeSelect.add_item(
			VARIABLE_TYPE_IN_SELECTION_TEXT_TEMPLATE.format({
				"name": the_type.name,
				"type": type
			}),
			type_id
		)
	pass
	
func refresh_variables_list(list:Dictionary = {}) -> void:
	VariablesList.clear()
	_LISTED_VARIABLES_BY_ID.clear()
	_LISTED_VARIABLES_BY_NAME.clear()
	if list.size() == 0 :
		# fetch the variables dataset if it's not provided as parameter
		list = Main.Mind.clone_dataset_of("variables")
	list_variables(list)
	VariablesList.unselect_all()
	smartly_toggle_editor()
	pass

func _on_listing_instruction_change(_x = null) -> void:
	refresh_variables_list()
	pass

func read_listing_instruction() -> Dictionary:
	return {
		"FILTER": Filter.get_text(),
		"FILTER_REVERSE": FilterReverse.is_pressed(),
		"FILTER_IN_TYPE": [null, "num", "str", "bool"][ FilterInType.get_selected_id() ],
		"FILTER_FOR_SCENE": FilterForScene.is_pressed(),
		"SORT_ALPHABETICAL": SortAlphabetical.is_pressed(),
	}

# appends a list of variables to the existing ones
# CAUTION! this won't refresh the current list,
# if a variable exists (by id) it'll be updated, otherwise added
func list_variables(list_to_append:Dictionary) -> void :
	var _LISTING = read_listing_instruction()
	for variable_id in list_to_append:
		var the_variable = list_to_append[variable_id]
		if Utils.filter_pass(the_variable.name, _LISTING.FILTER, _LISTING.FILTER_REVERSE):
			if _LISTING.FILTER_IN_TYPE == null || the_variable.type == _LISTING.FILTER_IN_TYPE:
				if _LISTING.FILTER_FOR_SCENE == false || Main.Mind.resource_is_used_in_scene(variable_id, "variables"):
					if _LISTED_VARIABLES_BY_ID.has(variable_id):
						update_variable_list_item(variable_id, the_variable)
					else:
						insert_variable_list_item(variable_id, the_variable)
	VariablesList.ensure_current_is_visible()
	if _LISTING.SORT_ALPHABETICAL:
		VariablesList.call_deferred("sort_items_by_text")
	pass

func unlist_variables(id_list:Array) -> void :
	VariablesList.unselect_all()
	smartly_toggle_editor()
	# remove items from the list
	# Note: to avoid conflicts, we remove from end, because the indices may change otherwise and disturb the job.
	var idx = ( VariablesList.get_item_count() - 1 )
	while idx >= 0:
		if id_list.has( VariablesList.get_item_metadata(idx) ):
			VariablesList.remove_item(idx)
		idx = (idx - 1)
	# also clean from the references
	for variable_id in id_list:
		dereference_listed_variables(variable_id)
	pass
	
func reference_listed_variables(variable_id:int, the_variable:Dictionary) -> void:
	# is it previously referenced ?
	if _LISTED_VARIABLES_BY_ID.has(variable_id): # if so, attempt some cleanup
		var previously_referenced = _LISTED_VARIABLES_BY_ID[variable_id]
		# the id never changes but names change, so we need to remove previously kept reference by name
		if previously_referenced.name != the_variable.name: # if the name is changed
			# ... to avoid the false notion that the old name is still in use
			_LISTED_VARIABLES_BY_NAME.erase(previously_referenced.name)
	# now we can update or create the references
	_LISTED_VARIABLES_BY_ID[variable_id] = the_variable
	_LISTED_VARIABLES_BY_NAME[the_variable.name] = _LISTED_VARIABLES_BY_ID[variable_id]
	# we can refresh variable editor because change in reference means an update
	if _SELECTED_VARIABLE_BEING_EDITED_ID == variable_id:
		load_variable_in_editor(_SELECTED_VARIABLE_BEING_EDITED_ID)
	pass

func dereference_listed_variables(variable_id:int) -> void:
	if _LISTED_VARIABLES_BY_ID.has(variable_id):
		_LISTED_VARIABLES_BY_NAME.erase( _LISTED_VARIABLES_BY_ID[variable_id].name )
		_LISTED_VARIABLES_BY_ID.erase(variable_id)
	pass
	
func insert_variable_list_item(variable_id:int, the_variable:Dictionary) -> void:
	reference_listed_variables(variable_id, the_variable)
	var item_text = VARIABLE_IN_LIST_TEXT_TEMPLATE.format(the_variable)
	# insert the variable as list item
	VariablesList.add_item( item_text )
	# we need to keep track of ids in metadata
	# the item is added last, so:
	var item_index = (VariablesList.get_item_count() - 1)
	VariablesList.set_item_metadata(item_index, variable_id)
	# then select and load it in the variable editor
	VariablesList.select(item_index)
	load_variable_in_editor(variable_id)
	pass

func update_variable_list_item(variable_id:int, the_variable:Dictionary) -> void:
	reference_listed_variables(variable_id, the_variable)
	for idx in range(0, VariablesList.get_item_count()):
		if VariablesList.get_item_metadata(idx) == variable_id:
			# found it, update...
			VariablesList.set_item_text(idx, VARIABLE_IN_LIST_TEXT_TEMPLATE.format(the_variable))
			return
	printerr("Unexpected Behavior! Trying to update variable=%s which is not found in the list!")
	pass

func request_new_variable_creation() -> void:
	var selected_type = Settings.VARIABLE_TYPES_ENUM[ VariablesTypeSelect.get_selected_id() ]
	self.emit_signal("relay_request_mind", "create_variable", selected_type)
	pass

func request_remove_variable(resource_id:int = -1) -> void:
	if resource_id < 0 : # default to the selected one
		resource_id = _SELECTED_VARIABLE_BEING_EDITED_ID
	# make sure this is an existing variable resource before trying to remove it
	if _LISTED_VARIABLES_BY_ID.has(resource_id):
		self.emit_signal("relay_request_mind", "remove_resource", { "id": resource_id, "field": "variables" })
	VariablesList.unselect_all()
	smartly_toggle_editor()
	pass

func load_variable_in_editor(variable_id) -> void:
	_SELECTED_VARIABLE_BEING_EDITED_ID = variable_id
	var the_variable = _LISTED_VARIABLES_BY_ID[variable_id]
	switch_variable_initial_value_sub_editor(the_variable.type)
	VariableRawUid.set_deferred("hint_tooltip", RAW_UID_TIP_TEMPLATE % variable_id)
	VariableEditorName.set_text(the_variable.name)
	set_variable_initial_value_sub_editor(the_variable.type, the_variable.init)
	# can't it be removed ? not if it's used by other resources
	VariableEditorRemoveButton.set_disabled( (the_variable.has("use") && the_variable.use.size() > 0) )
	update_usage_pagination(variable_id)
	smartly_toggle_editor()
	pass

func refresh_variable_cache_by_id(variable_id:int) -> void:
	if variable_id >= 0 :
		var the_variable = Main.Mind.lookup_resource(variable_id, "variables", true)
		if the_variable is Dictionary:
			_LISTED_VARIABLES_BY_ID[variable_id] = the_variable
			_LISTED_VARIABLES_BY_NAME[the_variable.name] = _LISTED_VARIABLES_BY_ID[variable_id]
	pass

func os_clipboard_push_raw_uid():
	OS.set_clipboard( String(_SELECTED_VARIABLE_BEING_EDITED_ID) )
	pass

func refresh_referrers_list() -> void:
	if _SELECTED_VARIABLE_BEING_EDITED_ID >= 0:
		update_usage_pagination(_SELECTED_VARIABLE_BEING_EDITED_ID)
	pass

func update_usage_pagination(variable_id:int) -> void:
	refresh_variable_cache_by_id(variable_id)
	_SELECTED_VARIABLE_USERS_IN_THE_SCENE.clear()
	_SELECTED_VARIABLE_USER_IDS_IN_THE_SCENE.clear()
	VariableAppearanceGoToButtonPopup.clear()
	var count = {
		"total": 0,
		"here": 0
	}
	# sort,
	var the_variable = _LISTED_VARIABLES_BY_ID[variable_id]
	if the_variable.has("use"):
		for referrer_id in the_variable.use:
			var local_referrer_overview = Main.Mind.scene_owns_node(referrer_id)
			if local_referrer_overview != null:
				_SELECTED_VARIABLE_USER_IDS_IN_THE_SCENE.append(referrer_id)
				_SELECTED_VARIABLE_USERS_IN_THE_SCENE[referrer_id] = local_referrer_overview
		count.total = the_variable.use.size()
		count.here = _SELECTED_VARIABLE_USER_IDS_IN_THE_SCENE.size()
	# update ...
	VariableAppearanceGoToButton.set_text( VARIABLE_APPEARANCE_INDICATION_TEMPLATE.format(count) )
	if count.here > 0 :
		var item_index := 0
		for referrer_id in _SELECTED_VARIABLE_USER_IDS_IN_THE_SCENE:
			VariableAppearanceGoToButtonPopup.add_item(
				_SELECTED_VARIABLE_USERS_IN_THE_SCENE[referrer_id].resource.name,
				referrer_id
			)
			VariableAppearanceGoToButtonPopup.set_item_metadata(item_index, referrer_id)
			item_index += 1
	var no_goto = (! (count.here > 0))
	VariableAppearanceGoToButton.set_disabled( no_goto )
	VariableAppearanceGoToPrevious.set_disabled( no_goto )
	VariableAppearanceGoToNext.set_disabled( no_goto )
	pass

func _on_go_to_menu_button_popup_index_pressed(referrer_idx:int) -> void:
	# (We can not use `id_pressed` because currently Godot support is limited to i32 item IDs.)
	var referrer_id = _SELECTED_VARIABLE_USER_IDS_IN_THE_SCENE[referrer_idx]
	if referrer_id >= 0:
		_CURRENT_LOCATED_REF_ID = referrer_id
		Grid.call_deferred("go_to_offset_by_node_id", referrer_id, true)
	pass

func _rotate_go_to(direction: int) -> void:
	var count = _SELECTED_VARIABLE_USER_IDS_IN_THE_SCENE.size()
	if count > 0:
		var current_located_index = _SELECTED_VARIABLE_USER_IDS_IN_THE_SCENE.find(_CURRENT_LOCATED_REF_ID)
		var goto = max(-1, current_located_index + direction)
		if goto >= count:
			goto = 0
		elif goto < 0:
			goto = count - 1
		# ...
		if goto < count && goto >= 0:
			_on_go_to_menu_button_popup_index_pressed(goto) # also updates _CURRENT_LOCATED_REF_ID
	else:
		_CURRENT_LOCATED_REF_ID = -1
	pass
	
func submit_variable_modification() -> void:
	var the_variable_original = _LISTED_VARIABLES_BY_ID[ _SELECTED_VARIABLE_BEING_EDITED_ID ]
	var resource_updater = {
		"id": _SELECTED_VARIABLE_BEING_EDITED_ID, 
		"modification": {},
		"field": "variables"
	}
	var mod_name = VariableEditorName.get_text()
	var mod_initial_value = get_variable_initial_value_sub_editor(the_variable_original.type)
	if mod_name.length() > 0 && mod_name != the_variable_original.name: # name is changed
		mod_name = Utils.exposure_safe_resource_name(mod_name)
		# force using unique names ?
		if Settings.FORCE_UNIQUE_NAMES_FOR_VARIABLES == false || _LISTED_VARIABLES_BY_NAME.has(mod_name) == false:
			resource_updater.modification["name"] = mod_name
		else:
			resource_updater.modification["name"] = ( mod_name + Settings.REUSED_VARIABLE_NAMES_AUTO_POSTFIX )
	if mod_initial_value != the_variable_original.init: # initial value is changed
		resource_updater.modification["init"] = mod_initial_value
	if resource_updater.modification.size() > 0 :
		self.emit_signal("relay_request_mind", "update_resource", resource_updater)
	pass

func switch_variable_initial_value_sub_editor(open_type:String) -> void:
	for editor_type in VariableEditorInitialValue:
		if editor_type == open_type:
			VariableEditorInitialValue[editor_type].set("visible", true)
		else:
			VariableEditorInitialValue[editor_type].set("visible", false)
	pass

func set_variable_initial_value_sub_editor(type:String, value) -> void:
	match type:
		"str":
			VariableEditorInitialValue["str"].set_text(value)
		"num":
			VariableEditorInitialValue["num"].set_value(value)
		"bool":
			VariableEditorInitialValue["bool"].select( VariableEditorInitialValue["bool"].get_item_index( ( 1 if value else 0 ) ) )
	pass
	
func get_variable_initial_value_sub_editor(type:String):
	var the_value
	match type:
		"str":
			the_value = VariableEditorInitialValue["str"].get_text()
		"num":
			the_value = int( VariableEditorInitialValue["num"].get_value() )
		"bool":
			var int_boolean = int( VariableEditorInitialValue["bool"].get_selected_id() )
			the_value = ( int_boolean == 1 )
	return the_value

func _on_variables_list_item_selected(idx:int)-> void:
	var variable_id = VariablesList.get_item_metadata(idx)
	load_variable_in_editor(variable_id)
	pass

func smartly_toggle_editor() -> void:
	var selected_variables_in_list = VariablesList.get_selected_items()
	if selected_variables_in_list.size() == 0 || VariablesList.get_item_metadata( selected_variables_in_list[0] ) != _SELECTED_VARIABLE_BEING_EDITED_ID:
		VariableEditorPanel.set("visible", false)
	else:
		VariableEditorPanel.set("visible", true)
	pass
	
func _on_variables_list_nothing_selected() -> void:
	VariablesList.unselect_all()
	_SELECTED_VARIABLE_BEING_EDITED_ID = -1
	smartly_toggle_editor()
	pass

func _on_list_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_echo() == false && event.is_pressed() == true:
			if event.get_control():
				match event.get_scancode():
					KEY_C:
						if event.get_shift():
							var selected = _SELECTED_VARIABLE_BEING_EDITED_ID
							if selected >= 0:
								emit_signal("relay_request_mind", "clean_clipboard", null)
								emit_signal("relay_request_mind", "os_clipboard_push", [[selected], "variables", false])
					KEY_V:
						if event.get_shift():
							emit_signal("relay_request_mind", "os_clipboard_pull", [null, null]) # (no moving)
		pass
