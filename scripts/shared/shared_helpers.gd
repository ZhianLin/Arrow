# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Shared helper classes
class_name Helpers

# Constants
const EVER_THERE_RES_FILE = Settings.EVER_THERE_RES_FILE

# Classes

# Utilities 
class Utils:
	
	# Making sure the dir path ends with "/"
	# ... also strips edges
	static func normalize_dir_path(dir_path:String) -> String:
		dir_path = dir_path.strip_edges(true, true)
		if dir_path.ends_with("/") == false:
			dir_path = dir_path + "/"
		return dir_path
		
	# Getting base directory from a path
	# Note: types are NOT annotated (dir:String -> String) because some funcs may give it a `null` and/or expect a null in cases.
	static func safe_base_dir(dir) :
		if dir is String :
			var check = Directory.new()
			if check.dir_exists(dir):
				dir = normalize_dir_path(dir)
			else:
				dir = dir.get_base_dir()
				if dir.length() == 0:
					return null
				else:
					dir = normalize_dir_path(dir)
			return dir
		else:
			return null
	
	static func is_abs_or_rel_path(path) -> bool:
		if path is String:
			return ( path.is_abs_path() || path.is_rel_path() )
		return false
	
	# This function finds absolute path to `res://`
	# by fetching base directory of an absolute path to a file that we sure is always there!
	static func get_absolute_path_to_res_dir(normalize:bool) -> String:
		var the_file = File.new();
		the_file.open(EVER_THERE_RES_FILE, File.READ)
		var res_abs_dir = the_file.get_path_absolute().get_base_dir()
		the_file.close()
		if normalize != false:
			res_abs_dir = normalize_dir_path(res_abs_dir)
		return res_abs_dir
		pass
	
	static func try_making_clean_relative_dir(path:String, normalize:bool = true):
		var abs_res_dir  = get_absolute_path_to_res_dir(false)
		var abs_user_dir = OS.get_user_data_dir()
		if path.begins_with(abs_user_dir):
			path = path.replace(abs_user_dir, "user://")
		elif path.begins_with(abs_res_dir):
			path = path.replace(abs_res_dir, "res://")
		if normalize != false:
			path = normalize_dir_path(path)
		path = path.replace("///", "//")
		return path
	
	static func get_abs_path(path:String) -> String:
		var absolute_path = path
		if path.begins_with('user://'):
			absolute_path = path.replace(
				'user://',
				normalize_dir_path( OS.get_user_data_dir() )
			)
		elif path.begins_with('res://'):
			absolute_path = path.replace(
				'res://',
				get_absolute_path_to_res_dir(true)
			)
		else:
			var dir = Directory.new()
			if dir.dir_exists(path):
				if dir.open(path) == OK:
					absolute_path = normalize_dir_path( dir.get_current_dir() )
		return absolute_path
	
	static func is_access_granted_to_dir(path:String, access_type = File.WRITE_READ) -> bool:
		var base = safe_base_dir(path)
		if base is String:
			var temp_file_path = base + 'wr_access_check.temp'
			var dir = Directory.new()
			if dir.open( base ) == OK :
				var temp_file = File.new()
				if temp_file.open(temp_file_path, access_type) == OK :
					temp_file.close()
					dir.remove(temp_file_path)
					return true
				else:
					return false
			else:
				return false
			pass
		else:
			printerr("Unexpected Behavior! Trying check [mode-", access_type, "] access permission to invalid path: ", path)
			return false
	
	static func file_exists(path: String) -> bool:
		var file = File.new()
		return file.file_exists(path)
	
	# Caution!
	# using File.Write or File.WRITE_READ will truncate the file or (re-)create it,
	# so be carefull about the parameter `mode`
	static func file_is_accessible(path:String, mode = File.READ_WRITE) -> bool:
		var file = File.new()
		if file.file_exists(path) :
			if file.open(path, mode) == OK:
				file.close()
				return true
		return false
	
	static func parse_json(text: String):
		var parsed:JSONParseResult = JSON.parse(text)
		if parsed.error == OK:
			return parsed.get_result()
		return null
	
	static func read_and_parse_json_file(path:String):
		var file = File.new()
		if file.file_exists(path) :
			if file.open(path, File.READ) == OK:
				var json_string = file.get_as_text()
				file.close()
				var parsed_or_null = parse_json(json_string)
				return parsed_or_null
		return null

	static func stringify_json(data, indent:String = Settings.PROJECT_FILE_JSON_DEFAULT_IDENT, sort_keys:bool = false) -> String:
		return JSON.print(data, indent, sort_keys)
	
	static func save_data_as_json_file(data, path:String, indent:String = "", sort_keys:bool = false):
		var data_stringified = JSON.print(data, indent, sort_keys)
		if data_stringified is String:
			var file = File.new()
			var open_file = file.open(path, File.WRITE)
			if open_file == OK:
				file.store_string(data_stringified)
				file.close()
				return OK
			else:
				return open_file
		else:
			print_stack()
			print_debug("Trying to save data as json: ", data)
			return "JSON.print result is not String!!"
	
	static func is_a_file_path(path) -> bool:
		if is_abs_or_rel_path(path):
			var file_name = path.get_file()
			if (file_name is String) && file_name.length() > 0 :
				return true
		return false
	
	static func save_from_template_file(template_path:String, save_path:String, replacements:Dictionary = {}):
		if is_a_file_path(template_path) && is_a_file_path(save_path):
			var tmpl_file = File.new()
			var tmpl_access_state = tmpl_file.open(template_path, File.READ)
			if tmpl_access_state == OK:
				var new_file = File.new()
				var new_file_write_access_state = new_file.open(save_path, File.WRITE)
				if new_file_write_access_state == OK:
					# Copy the template line by line, replacing the tags
					var the_content_line:String
					while tmpl_file.eof_reached() == false:
						the_content_line = tmpl_file.get_line()
						for tag in replacements:
							the_content_line = the_content_line.replace( tag, replacements[tag] )
						new_file.store_line(the_content_line)
					# ...
					new_file.close()
					tmpl_file.close()
					return OK
				else:
					return new_file_write_access_state
			else:
				return tmpl_access_state
		else:
			return ERR_INVALID_PARAMETER
		pass
	
	static func parse_template(template_path:String, replacements:Dictionary = {}):
		if is_a_file_path(template_path):
			var tmpl_file = File.new()
			var tmpl_access_state = tmpl_file.open(template_path, File.READ)
			if tmpl_access_state == OK:
				var parsed: String = ""
				# Copy the template line by line, replacing the tags
				var the_content_line:String
				while tmpl_file.eof_reached() == false:
					the_content_line = tmpl_file.get_line()
					for tag in replacements:
						the_content_line = the_content_line.replace( tag, replacements[tag] )
					parsed = parsed + the_content_line + "\n"
					# (^ It's a line by line append, and `get_line` seems not to keep line-feed so we add it)
				# ...
				tmpl_file.close()
				return parsed
			else:
				return tmpl_access_state
		else:
			return ERR_INVALID_PARAMETER
		pass
	
	static func read_text_file(path: String):
		var file = File.new()
		if file.file_exists(path):
			if file.open(path, File.READ) == OK:
				var content = file.get_as_text()
				file.close()
				return content
		return null
	
	# Returns OK if write is done or File Error
	static func write_text_file(path: String, content: String):
		var file = File.new()
		var file_state = file.open(path, File.WRITE)
		if file_state == OK:
			file.store_string(content)
			file.close()
		return file_state
	
	# Returns last modification time of a file, 0 for non-existent and -1 for error
	static func get_modification_time(path: String) -> int:
		var file = File.new()
		var mod_time = file.get_modified_time(path)
		return (mod_time if mod_time is int else -1)

	const SCRIPT_REGEX = "<script[a-z1-9\"'\/ =]*?src=['|\"](.*?)[\"|'][a-z1-9\"'\/ =]*?>.*</script>"
	const STYLE_REGEX = "<link[a-z1-9\"'\/ =]*?href=['|\"](.*?)[\"|'][a-z1-9\"'\/ =]*?>"
	static func read_html_head_imports(
		path: String, return_source: bool = false,
		start_mark: String = "@inline", end_mark: String = "@inline-end"
	):
		var file = File.new()
		if file.file_exists(path) :
			if file.open(path, File.READ) == OK:
				var source = file.get_as_text()
				file.close()
				var imports = { "styles": [], "scripts": [] }
				var lookup_start = source.find(start_mark)
				var lookup_end = source.find(end_mark)
				# Scripts
				var scripts_regex = RegEx.new()
				scripts_regex.compile(SCRIPT_REGEX)
				var scripts = scripts_regex.search_all(source, lookup_start, lookup_end)
				for scripts_regex_match in scripts:
					imports.scripts.append({
						"block": scripts_regex_match.get_string(0),
						"src": scripts_regex_match.get_string(1)
					})
				# Style sheets
				var styles_regex = RegEx.new()
				styles_regex.compile(STYLE_REGEX)
				var styles = styles_regex.search_all(source, lookup_start, lookup_end)
				for styles_regex_match in styles:
					imports.styles.append({
						"block": styles_regex_match.get_string(0),
						"href": styles_regex_match.get_string(1)
					})
				# ...
				if return_source:
					imports["source"] = source
				return imports
		return null

	static func inline_html_head_imports(index_path: String) -> String:
		var source_dir = Utils.safe_base_dir(Settings.HTML_JS_RUNTIME_INDEX)
		print_debug("inlining index file in source dir:", source_dir)
		var head_imports = read_html_head_imports(index_path, true)
		var index_source: String;
		if head_imports is Dictionary:
			index_source = head_imports.source
			for css in head_imports.styles:
				var css_content = read_text_file(source_dir + css.href)
				if css_content is String:
					index_source = index_source.replace(
						css.block,
						("<style>\n/*" + css.href + "*/\n\n" + css_content + "\n</style>")
					)
			for js in head_imports.scripts:
				var js_content = read_text_file(source_dir + js.src)
				if js_content is String:
					index_source = index_source.replace(
						js.block,
						("<script>\n/*" + js.src + "*/\n\n" + js_content + "\n</script>")
					)
		return index_source
	
	static func read_and_parse_variant_file(path:String):
		var file = File.new()
		if file.file_exists(path) :
			if file.open(path, File.READ) == OK:
				var variant = file.get_var(true)
				file.close()
				return variant
		return null
	
	static func save_data_as_variant_file(data, path:String):
		var file = File.new()
		var open_file = file.open(path, File.WRITE)
		if open_file == OK:
			file.store_var(data, true)
			file.close()
			return OK
		else:
			return open_file
	
	static func remove_file(path:String):
		var dir = Directory.new()
		return dir.remove(path)
	
	static func parse_time_stamp(
		time_stamp, mark_utc:bool = false, convert_to_local_time: bool = false, custom_template:String = ""
	):
		var time = time_stamp.utc if time_stamp is Dictionary && time_stamp.has("utc") else time_stamp # (backward compatibility)
		var time_dictionary: Dictionary
		if time is Dictionary:
			time_dictionary = time
		elif time is String:
			time_dictionary = Time.get_datetime_dict_from_datetime_string(time, true)
		elif time is int || time is float:
			time_dictionary = Time.get_datetime_dict_from_unix_time( int(time) )
		else:
			printerr("Unsupported time stamp format to parse! ", time)
		# ...
		if convert_to_local_time:
			var unix_time = Time.get_unix_time_from_datetime_dict(time_dictionary) # (seconds)
			var local_offset = Time.get_time_zone_from_system().bias * 60 # (bias is in minutes)
			var local_unix_time = unix_time + local_offset
			time_dictionary = Time.get_datetime_dict_from_unix_time(local_unix_time)
		# ...
		var template = (custom_template if (custom_template.length() > 0) else Settings.TIME_STAMP_TEMPLATE)
		var parsed_time_stamp = template.format(time_dictionary)
		if mark_utc:
			parsed_time_stamp += Settings.TIME_STAMP_TEMPLATE_UTC_MARK
		return parsed_time_stamp
	
	#  [x, y] -> Vector2(x: float, y: float)
	static func array_to_vector2(from:Array):
		if from.size() >= 2:
			if (from[0] is int || from[0] is float) && (from[1] is int || from[1] is float):
				return Vector2( from[0], from[1] )
			else:
				print_stack()
				printerr("Trying to convert none-numeral Array to Vector2 ! ", from)
		else:
			print_stack()
			printerr("Trying to convert Array with size < 2 to Vector2 ! ", from)
		return null
	
	# Vector2(x: float, y: float) -> [x, y]
	static func vector2_to_array(from:Vector2) -> Array:
		return [from.x, from.y]
	
	static func refactor_array(left: Array, factor: float, devide: bool = false) -> Array:
		var right = []
		for num in left:
			right.append( (num * factor) if devide == false else (num / factor) )
		return right

	static func int_to_base36(val:int = 0) -> String:
		var base36 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		var result = ""
		if val == 0:
			result = "0"
		else:
			while (val > 0 ):
				result = base36[val % 36] + result
				# warning-ignore:integer_division
				val = val / 36
		return result
	
	static func color_to_rgba_hex(from: Color, with_alpha: bool = true) -> String:
		# (Godot considers HTML color to be ARGB but CSS prefers RGBA and it's more common elsewhere.)
		var argb = from.to_html()
		var rgba = argb.substr(2, -1) + (argb.substr(0, 2) if with_alpha else "")
		return rgba.to_lower()
	
	static func rgba_hex_to_color(from: String) -> Color:
		var alpha = from.substr(6, 2) if from.length() >= 8 else "ff"
		var argb = (alpha + from.substr(0, 6))
		return Color( argb.to_lower() )

	static func objects_differ(left, right) -> bool:
		if typeof(left) == typeof(right):
			if left is Dictionary:
				# `hash` is expected to be faster
				# and most of the times this function is called with identical objects so:
				if left.hash() == right.hash():
					return false
				# yet dictionaries with the same keys/values but in a different order will have a different hash.
				# we don't care about their order in this comparison, so we shall double-check
				else:
					if left.size() == right.size():
						for property in left:
							if right.has(property):
								if objects_differ(left[property], right[property]) == true:
									return true
							else:
								return true
						return false
					else:
						return true
			elif left is Array:
				if left.hash() == right.hash():
					return false
				# though we care about order in Arrays, but arrays may contain dictionares
				# so we need to recursively check for items all
				else:
					if left.size() == right.size():
						for i in range(0, left.size()):
							if objects_differ(left[i], right[i]) == true:
								return true
						return false
					return true
			else:
				return (! (left == right) )
		else:
			return true
	
	static func recursively_update_dictionary(original:Dictionary, modification:Dictionary, ignore_new_and_strange_pairs:bool = true, updates_to_null_is_erase:bool = false, duplication:bool = false) -> Dictionary:
		var updatee = ( original if (duplication != true) else original.duplicate(true) )
		for key in modification:
			# update if the pairs are of the same type ...
			if updatee.has(key) && (typeof(updatee[key]) == typeof(modification[key])):
				if updatee[key] is Dictionary:
					# it doesn't need to duplicate original part again, because it's already a deep clone if duplication=true
					updatee[key] = recursively_update_dictionary(updatee[key], modification[key], ignore_new_and_strange_pairs, updates_to_null_is_erase, false)
				else:
					updatee[key] = modification[key]
			# otherwise don't update unless ...
			elif modification[key] == null && updates_to_null_is_erase == true:
				updatee.erase(key)
			elif ignore_new_and_strange_pairs == false:
				updatee[key] = modification[key]
		return updatee
	
	static func recursively_convert_numbers_to_int(data):
		if data is float:
			data = int(data)
		# stringified numbers in data may be a number-only title or str value, so let's keep them
		#elif data is String && String(int(data)) == data:
		#	data = int(data)
		elif data is Array:
			for index in range(0, data.size()):
				data[index] = recursively_convert_numbers_to_int( data[index] )
		elif data is Dictionary:
			var data_with_converted_keys = {}
			for key in data:
				# well, the key itself might also be a stringified int
				if String(int(key)) == key:
					var key_int = int(key)
					var value = ( data[key].duplicate(true) if (data[key] is Dictionary || data[key] is Array) else data[key] )
					data_with_converted_keys[ key_int ]  = recursively_convert_numbers_to_int( value )
				else:
					data_with_converted_keys[key] = recursively_convert_numbers_to_int( data[key] )
			data = data_with_converted_keys
		return data
	
	static func valid_filename(from_string:String, replace_discouraged_characters:bool = true) -> String:
		var filename = from_string.to_lower().strip_edges().strip_escapes()
		var safe:String = ""
		if filename.is_valid_filename() == false || replace_discouraged_characters == true :
			for character in filename:
				if (
						character.is_valid_filename() == false ||
						(
							replace_discouraged_characters == true &&
							Settings.DISCOURAGED_FILENAME_CHARACTERS.has(character)
						)
				):
					safe += "_"
				else:
					safe += character
		else:
			safe = filename
		return safe
	
	static func ellipsis(text: String, length: int) -> String:
		return text.substr(0, length) + ("..." if text.length() > length else "")
	
	# Returns a version of the name that is safe to be used with recursive parsing (text formatting with dictionary)
	static func exposure_safe_resource_name(
		name: String,
		restricted = Settings.EXPOSURE_SAFE_NAME_RESTRICTED_CHARS,
		replacement = Settings.EXPOSURE_SAFE_NAME_RESTRICTED_CHARS_REPLACEMENT
	) -> String:
		for c in restricted:
			name = name.replace(c, replacement)
		return name
	
	static func recursively_replace_string(original, old: String, new: String, case_sensitive: bool = true):
		var revised
		if original is String:
			revised = original.replace(old, new) if case_sensitive else original.replacen(old, new)
		elif original is Array:
			revised = []
			for i in range(0, original.size()):
				revised.push_back( recursively_replace_string(original[i], old, new, case_sensitive) )
		elif original is Dictionary:
			revised = {}
			for key in original:
				revised[key] = recursively_replace_string(original[key], old, new, case_sensitive)
		else:
			revised = original
		return revised
	
	static func filter_pass(text: String, filter: String, reverse: bool = false, ci: bool = true) -> bool:
		filter = "*" + filter + "*"
		var passes = text.matchn(filter) if ci else text.match(filter)
		return ( passes if reverse == false else (! passes ) )

# List Node Helpers
class ListHelpers:
	
	static func get_item_list_as_text_array(list:ItemList) -> Array:
		var lines = []
		for idx in range(0, list.get_item_count()):
			lines.push_back( list.get_item_text(idx) )
		return lines
	
	# isolates by index
	# -1   : enable all,
	# >= 0 : disable all but this one
	static func isolate_a_list_item(list:ItemList, item_index:int = -1) -> void:
		var enable_all = false
		if item_index < 0:
			enable_all = true
		for idx in range(0, list.get_item_count()):
			list.set_item_disabled(idx, true if (enable_all == false && idx != item_index) else false)
		pass
	
	static func get_list_item_idx_from_meta_data(list:ItemList, target_meta_data) -> int:
		for idx in range(0, list.get_item_count()):
			if target_meta_data == list.get_item_metadata(idx):
				return idx
		return -1
		pass

class Vector2d:
	
	static func limit_vector2_y(vec:Vector2, by:Vector2, limit_down:bool = true, limit_padding:float = 0) -> Vector2:
		var limited = vec
		var padded_y_limit = (by.y - limit_padding)
		if limited.y > padded_y_limit:
			limited.y = padded_y_limit
		elif limit_down && limited.y < limit_padding :
			limited.y = limit_padding
		return limited
		
	static func limit_vector2_x(vec:Vector2, by:Vector2, limit_down:bool = true, limit_padding:float = 0) -> Vector2:
		var limited = vec
		var padded_x_limit = (by.x - limit_padding)
		if limited.x > padded_x_limit:
			limited.x = padded_x_limit
		elif limit_down && limited.x < limit_padding :
			limited.x = limit_padding
		return limited
	
	static func limit_vector2(vec:Vector2, by:Vector2, limit_down:bool = true, limit_padding:Vector2 = Vector2.ZERO) -> Vector2:
		var limited = limit_vector2_y(vec, by, limit_down, limit_padding.y)
		limited = limit_vector2_x(limited, by, limit_down, limit_padding.x)
		return limited

# Dragable (Movable) Controls
class Dragable:
	
	var LIMIT_PADDING = Vector2(25, 50) # pixels
	
	var _DRAGABLE:Node
	var _DRAG_POINT:Node
	var _VIEWPORT:Node
	var _COMPETE_FOR_PARENT_TOP_VIEW:bool = false
	var _PARENT:Node
	
	func _init(dragable:Node, drag_point:Node, compete_for_parent_top_layer:bool = true) -> void:
		_DRAGABLE = dragable
		_DRAG_POINT = drag_point
		_VIEWPORT = _DRAGABLE.get_viewport()
		if compete_for_parent_top_layer:
			_COMPETE_FOR_PARENT_TOP_VIEW = true
			_PARENT = _DRAGABLE.get_parent()
		connect_drag()
		pass
		
	func connect_drag() -> void:
		_DRAG_POINT.connect("gui_input", self, "drag_element")
		if _COMPETE_FOR_PARENT_TOP_VIEW && _DRAGABLE.has_signal("visibility_changed"):
			_DRAGABLE.connect("visibility_changed", self, "steal_top", [], CONNECT_DEFERRED)
		pass
	
	func drag_element(event:InputEvent) -> void:
		if event is InputEventMouseMotion:
			if event.get_button_mask() == BUTTON_LEFT:
				var rel_mouse_position = event.get_relative() # ... to its previous pos
				var current_dragable_position  = _DRAGABLE.get_position()
				var the_viewport_size = _VIEWPORT.get_size()
				var new_dragable_position = (current_dragable_position + rel_mouse_position)
				new_dragable_position = Vector2d.limit_vector2(new_dragable_position, the_viewport_size, true, LIMIT_PADDING)
				_DRAGABLE.set_position(new_dragable_position)
		if event is InputEventMouseButton:
			if event.is_pressed() && _COMPETE_FOR_PARENT_TOP_VIEW == true:
				steal_top()
		pass
	
	func steal_top() -> void:
		_PARENT.move_child(_DRAGABLE, _PARENT.get_child_count())
		pass

# Resizable Controls
class Resizable:
	
	var LIMIT_PADDING = Vector2(25, 50) # pixels
	
	var _RESIZABLE:Node
	var _RESIZE_POINT:Node
	var _USE_REVERSE_MOUSE_Y:bool
	var _RESIZE_FROM_TOP:bool
	var _VIEWPORT:Node
	
	func _init(resizable:Node, resize_point:Node, use_reverse_mouse_y:bool = true, resize_from_top:bool = true) -> void:
		_RESIZABLE = resizable
		_RESIZE_POINT = resize_point
		_USE_REVERSE_MOUSE_Y = use_reverse_mouse_y
		_RESIZE_FROM_TOP = resize_from_top
		_VIEWPORT = _RESIZABLE.get_viewport()
		connect_resize()
		pass
		
	func connect_resize() -> void:
		_RESIZE_POINT.connect("gui_input", self, "resize_element")
		pass
	
	func resize_element(event:InputEvent) -> void:
		if event is InputEventMouseMotion:
			if event.get_button_mask() == BUTTON_LEFT:
				var rel_mouse_position = event.get_relative() # ... to its previous pos
				if _USE_REVERSE_MOUSE_Y:
					rel_mouse_position.y = (rel_mouse_position.y * ( -1 ))
				var current_resizable_size  = _RESIZABLE.get_size()
				var the_viewport_size = _VIEWPORT.get_size()
				var new_resizable_size = (current_resizable_size + rel_mouse_position)
				new_resizable_size = Vector2d.limit_vector2(new_resizable_size, the_viewport_size, true, LIMIT_PADDING)
				_RESIZABLE.set_size(new_resizable_size)
				if _USE_REVERSE_MOUSE_Y && _RESIZE_FROM_TOP:
					var current_resizable_position  = _RESIZABLE.get_position()
					current_resizable_position.y = current_resizable_position.y - rel_mouse_position.y
					_RESIZABLE.set_position(current_resizable_position)
		pass

# Generator helpers
# ... to make random variants
class Generators:
	
	static func create_random_color() -> Color:
		var the_color:Color = Color.from_hsv(
			rand_range(0.0, 1), # hue
			rand_range(0.5, 1), # saturation
			rand_range(0.7, 1), # velocity
			1 # alpha 100%
		)
		return the_color

	static func create_random_string(length:int = 1, or_longer:bool = false, restriction_regex_pattern:String = "") -> String:
		var random_string = ""
		var restriction_regex = null
		if restriction_regex_pattern.length() > 0:
			restriction_regex = RegEx.new()
			restriction_regex.compile(restriction_regex_pattern)
		while random_string.length() < length:
			var new_substring = Utils.int_to_base36( randi() ).to_lower()
			if restriction_regex != null:
				new_substring = restriction_regex.sub(new_substring, "", true)
			random_string += new_substring
		if random_string.length() > length && or_longer == false:
			random_string = random_string.substr(0, length)
		return random_string
	
	static func random_boolean() -> bool:
		return ( randi() % 2 == 0 )
	
	static func advance_random_integer(
		from:int = 0, to:int = 0,
		negative:bool = false, even:bool = false, odd:bool = false
	) -> int:
		var result = null
		if from >= to:
			result = from
		if (to - from) <= 1:
			# we need at least one odd and one even number in the possibilities
			to += 1
		while result == null:
			result = int( rand_range( float(from), float(to) ) )
			if even != odd : # to be either odd or even
				# (both true or both false means ignore)
				var is_even = (result % 2 == 0)
				if is_even && even == false:
					result = null
				if is_even == false && odd == false:
					result = null
		if negative is bool && negative == true: # negative
			result = (result * (-1))
		print_debug("random: ", from, to, negative, even, odd, " -- result --> ", result)
		return result
	
class Mood:
	
	var snippet: String = ""
	var purged: String
	
	var kind: String = ""
	var level: int = 0
	var reset: bool = true
	
	# Moods are tags added at the beginning of a content mostly as machine readable metadata.
	# This patterns helps extracting mood snippets like [code]Happy,2,true[/code] (inside brackets) (i.e. mood-kind, level, auto-reset)
	# from beginning of a string. We should ignore similar snippets if they are not at the beginning.
	const _REGEX_MOOD_SNIPPET_PATTERN := "^\\s*\\[([a-zA-z \\-_]*)?\\s*,?\\s*(\\-?\\+?[0-9]*)?\\s*,?\\s*(false|keep|~|true|reset)?\\]\\s*"
	
	# This method tries to default for each mood segment (even for empty array) to `["", 0, true]`.
	# It also returns an object with blank snippet and default parameters if no mood is there.
	# This method accepts the sign `~` and "keep" as alternatives for `false` reset value, and every thing else for `true`.
	# For example, `[Excited,~]` is equal to `[Excited,false]`.
	func _init(from: String):
		var regex = RegEx.new()
		var compiled = regex.compile(_REGEX_MOOD_SNIPPET_PATTERN)
		self.purged = from
		if compiled == OK:
			var matched = regex.search(from)
			if matched != null:
				self.snippet = matched.get_string(0)
				self.purged = from.replace(matched.get_string(0), "")
				self.kind = matched.get_string(1).strip_edges()
				self.level = int(matched.get_string(2).strip_edges())
				self.reset = false if ["false", "keep", "~"].has(matched.get_string(3).strip_edges().to_lower()) else true
		else:
			printerr("Unexpectedly unable to compile the Mood._REGEX_MOOD_SNIPPET_PATTERN to extract moods")

	static func purge(from: String) -> String:
		var regex = RegEx.new()
		var compiled = regex.compile(_REGEX_MOOD_SNIPPET_PATTERN)
		if compiled == OK:
			var matched = regex.search(from)
			if matched != null:
				return from.replace(matched.get_string(0), "")
		return from
