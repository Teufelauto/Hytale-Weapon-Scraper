class_name Utils
extends Object
## Various helper functions.
##
## Various static functions for loading json, csv, or saving them. This class
## helps clean up the main scripts by containing oddball functions.

static var zip_reader := ZIPReader.new()


## ---------------- File operations -------------------

## Gets ZIP Reader going in this scope
static func open_assets_zip()->void:
	var error = zip_reader.open(Scraper.asset_zip_path)
	if error != OK:
		print("Failed to open ZIP file: ", error)
		return

static func load_json_data_to_dict(load_path: String) -> Dictionary:
	var app_settings_string = FileAccess.get_file_as_string(load_path) # Retrieve json data
	return JSON.parse_string(app_settings_string) # Define Dictionary


## Load a csv file, and return it as a 2d array. Stripping header is optional.
static func load_csv_data_to_array(load_path: String, strip_header: bool = false) -> Array:
	var data: Array = []
	var file = FileAccess.open(load_path, FileAccess.READ)
	if file:
		# Optional: Read the header row first if you have one
		if strip_header:
			var _header= file.get_csv_line()
			#print("Header: ", _header)

		# Read the rest of the data
		while !file.eof_reached():
			var line_data = file.get_csv_line()
			# Ensure the line is not empty before processing
			if line_data.size() > 0 and line_data[0] != "":
				# You may need to cast string values to their correct types (int, float, bool)
				# e.g., line_data[0] = int(line_data[0])
				data.append(line_data)
		file.close()
		return data
	else:
		print("Failed to open file: ", load_path)
	return []


## Save a dictionary to a json file.
static func save_dict_to_json(dict: Dictionary, save_path: String = "user://new.json") -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(dict,"  ",false)
		file.store_line(json_string)
		file.close()
		print("Dictionary saved as json to: " + save_path)
	else:
		print("Failed to save dictionary as json.")


## Save Table Array into CSV at specified location
static func save_array_as_csv(table_data: Array, path: String = "user://new.csv") -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("Error opening file: ", FileAccess.get_open_error())
		return

	for line_data in table_data:
		# Convert each inner array/PackedStringArray to a format store_csv_line accepts
		var string_array := PackedStringArray()
		for value in line_data:
			string_array.append(str(value))
		file.store_csv_line(string_array)

	file.close()
	print("Data successfully saved to ", path)


## Returns true if the filename exists in user://  Folders can pre-pend the file_name
static func check_user_file_exists(file_name: String) -> bool:
	# Construct the full path using the 'user://' shorthand
	var path = "user://" + file_name
	
	# Check if the file exists
	if FileAccess.file_exists(path):
		print("File exists in user folder: " + path)
		return true
	else:
		print("File does not exist in user folder: " + path)
		return false


## Returns true if the path/filename exists.
static func check_os_file_exists(full_path: String) -> bool:
	
	# Check if the file exists
	if FileAccess.file_exists(full_path):
		print("File exists in folder: " + full_path)
		return true
	else:
		print("File does not exist in folder: " + full_path)
		return false


# It copies a file from an absolute source path to an absolute destination path.
# Can change name of new file.
static func copy_file_from_source_to_destination(full_source: String, 
		full_destination: String) -> void:
	# Use DirAccess.copy_absolute()
	# It copies a file from an absolute source path to an absolute destination path.
	# Note: The destination path should include the new file name.
		var error = DirAccess.copy_absolute(full_source, full_destination)
	
		if error == OK:
			print("File copied successfully to: ", full_destination)
		else:
			print("Error copying file: ", error_string(error))


## Returns folder where Hytale data lives.
static func retrieve_roaming_Hytale_folder_location() -> String:
	var path: String = OS.get_user_data_dir()
	var count: int = path.get_slice_count("/") - 1 ## count - 1 is the index for .get_slice method.
	var user_folder: String = path.get_slice("/",count) 
	path = path.rstrip(user_folder) # strip off the user's folder
	return path + "Hytale" # append the Hytale folder


## Creates a copy of the weapons csv before it can be overwritten.
static func backup_csv(auto_overwrite_old_csv: bool = true) -> void:
	
	## TODO Need to save 2nd backups with timestamp
	if auto_overwrite_old_csv:
		if Utils.check_os_file_exists(Scraper.csv_save_path):
			print("Weapon CSV exists for backup.")
			
			var new_path: String = ""
			Utils.copy_file_from_source_to_destination(Scraper.csv_save_path, new_path)
			
		else:
			print("Weapon CSV does not exists for backup.")
	else:
		print("Need logic for this. Only for gui. Headless will crush it.") #


## ---------------- Diff Comparisons -------------------


## TODO Enable ability to specify Table names and versions
## Load and compare 2 weapons CSVs to see the diff.
## Returns dictionary.textual, and dictionary.table. These are arrays.
static func diff_compare_weapons_table() -> Dictionary:
	var new_table: Array = load_csv_data_to_array("user://weapons_table_prerelease.csv")
	var old_table: Array = load_csv_data_to_array("user://weapons_table_prerelease_old.csv")
	
	print()
	# Compare new and old tables
	var diffs: Dictionary = compare_weapons_arrays(new_table, old_table)
	if diffs.textual.is_empty():
		print("New and old are identical.")
		return diffs
	else:
		print("Differences found between new and old:")
		for diff in diffs.textual:
			print("- " + diff)
		
		print("---------------")
		for diff in diffs.table:
			print(diff)
		print()
		return diffs


## Returns a dictionary of weapon diffs with two entries. "textual", and "table". An Array of diffs.
static func compare_weapons_arrays(new_table: Array, old_table: Array) -> Dictionary:
	var differences: Array = []
	var diff_table: Array = [[
		"weapon_family",
		"descriptor",
		"diff_parameter",
		"old_value",
		"new_value",
		]]
	var diff_dict: Dictionary = {
		"textual": differences,
		"table": diff_table,
		}
	
		# 1. Check if the overall array sizes are different
	if new_table.size() != old_table.size():
		differences.append("Array sizes are different: %d vs %d" 
				% [new_table.size(), old_table.size()])
		diff_dict.set("textual", differences)
		return diff_dict
		
		# 2. Iterate through rows (outer array) i is row
	for i in range(new_table.size()):
		var row_new: Array = new_table[i]
		var row_old: Array = old_table[i]

			# Check if the current elements are arrays (expected 2D structure)
		if typeof(row_new) != TYPE_ARRAY or typeof(row_old) != TYPE_ARRAY:
			if row_new != row_old:
				differences.append("Non-array element difference at row %d" % i)
				diff_dict.set("textual", differences)
			continue
			
			# 3. Check if the inner array (row) sizes are different
		if row_new.size() != row_old.size():
			differences.append("Row %d size difference: %d vs %d" 
					% [i, row_new.size(), row_old.size()])
			diff_dict.set("textual", differences)
			continue
			
			# 4. Iterate through columns (inner array elements) j is column
		for j in range(row_new.size()):
				# Compare individual elements
			if row_new[j] != row_old[j]:
				
				## Get header value for weapon-id and differing parameter.
				var id: String = new_table[i][1] # Same row, 2nd column for weapon-id
				var parameter: String = new_table[0][j] # Header row, same column
				
				## Create row in the textual array.
				differences.append("Difference in %s with %s: (Old) %s vs %s (New)" 
						% [id, parameter, str(row_old[j]), str(row_new[j]) ])
				diff_dict.set("textual", differences) # Reset the definition
				
				## Create a row on the diff_table
				diff_table.append([
					new_table[i][2],
					new_table[i][3],
					new_table[0][j],
					row_old[j],
					row_new[j],
					])
				
				## Reset the definition of the Dictionary entry for "table".
				diff_dict.set("table", diff_table)
				
				#differences.append("Difference at index [%d][%d]: %s vs %s" 
						#% [i, j, str(row_new[j]), str(row_old[j])])
	return diff_dict


## Generic table compare
static func compare_2d_arrays(array1: Array, array2: Array) -> Array:
	var differences: Array = []

		# 1. Check if the overall array sizes are different
	if array1.size() != array2.size():
		differences.append("Array sizes are different: %d vs %d" 
				% [array1.size(), array2.size()])
		return differences
		
		# 2. Iterate through rows (outer array)
	for i in range(array1.size()):
		var row1: Array = array1[i]
		var row2: Array = array2[i]

			# Check if the current elements are arrays (expected 2D structure)
		if typeof(row1) != TYPE_ARRAY or typeof(row2) != TYPE_ARRAY:
			if row1 != row2:
				differences.append("Non-array element difference at row %d" % i)
			continue
			
			# 3. Check if the inner array (row) sizes are different
		if row1.size() != row2.size():
			differences.append("Row %d size difference: %d vs %d" 
					% [i, row1.size(), row2.size()])
			continue
			
			# 4. Iterate through columns (inner array elements)
		for j in range(row1.size()):
				# Compare individual elements
			if row1[j] != row2[j]:
				differences.append("Difference at index [%d][%d]: %s vs %s" 
						% [i, j, str(row1[j]), str(row2[j])])
		
	return differences


## Prints comparison of two jsons (poorly constructed output)
static func practical_application_json_compare()->void:
	
	# Retrieve json data
	var _app_settings_string = FileAccess.get_file_as_string(
			"user://weapons_encyclopedia_prerelease.json")
	var dict_a = JSON.parse_string(_app_settings_string) # Define Dictionary
	
	_app_settings_string = FileAccess.get_file_as_string(
			"user://weapons_encyclopedia_prerelease_old.json")
	var dict_b = JSON.parse_string(_app_settings_string) # Define Dictionary
	
	var differences = compare_deep_dictionaries(dict_a, dict_b)
	print(differences)


static func compare_deep_dictionaries(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	
	var differences: Dictionary = {}
	
	# Check keys present in dict1 but missing or different in dict2
	for key in dict1.keys():
		if not dict2.has(key):
			differences[key] = {"status": "missing in dict2", "value_dict1": dict1[key]}
		elif typeof(dict1[key]) != typeof(dict2[key]):
			differences[key] = {"status": "type mismatch", "value_dict1": dict1[key], "value_dict2": dict2[key]}
		elif typeof(dict1[key]) == TYPE_DICTIONARY:
			var sub_differences: Dictionary = compare_deep_dictionaries(dict1[key], dict2[key])
			if not sub_differences.is_empty():
				differences[key] = {"status": "sub-differences", "details": sub_differences}
		elif typeof(dict1[key]) == TYPE_ARRAY:
			var array_differences: Dictionary = compare_deep_arrays(dict1[key], dict2[key])
			if not array_differences.is_empty():
				differences[key] = {"status": "array-differences", "details": array_differences}
		elif dict1[key] != dict2[key]:
			differences[key] = {"status": "value mismatch", "value_dict1": dict1[key], "value_dict2": dict2[key]}

	# Check keys present in dict2 but missing in dict1
	for key in dict2.keys():
		if not dict1.has(key):
			differences[key] = {"status": "missing in dict1", "value_dict2": dict2[key]}

	return differences


# Helper function for array comparison (simple version) in compare_deep_dictionaries
static func compare_deep_arrays(arr1: Array, arr2: Array) -> Dictionary:
	var differences : Dictionary = {}
	if arr1.size() != arr2.size():
		differences["_size"] = {"status": "size mismatch", "size_arr1": arr1.size(), "size_arr2": arr2.size()}

	var max_size: int = mini(arr1.size(), arr2.size())
	for i in range(max_size):
		if typeof(arr1[i]) == TYPE_DICTIONARY:
			var sub_differences: Dictionary = compare_deep_dictionaries(arr1[i], arr2[i])
			if not sub_differences.is_empty():
				differences[i] = {"status": "sub-differences at index", "details": sub_differences}
		elif typeof(arr1[i]) == TYPE_ARRAY:
			var sub_differences: Dictionary = compare_deep_arrays(arr1[i], arr2[i])
			if not sub_differences.is_empty():
				differences[i] = {"status": "sub-differences at index", "details": sub_differences}
		elif arr1[i] != arr2[i]:
			differences[i] = {"status": "value mismatch at index", "value_arr1": arr1[i], "value_arr2": arr2[i]}
			
	return differences
