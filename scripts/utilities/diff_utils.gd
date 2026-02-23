class_name DiffUtils
extends Object
## Various file diffing helper functions.
##
## Various static functions for comparing two resources or files. This class
## helps clean up the main scripts by containing oddball functions.


## TODO Enable ability to specify Table names and versions
## Load and compare 2 weapons CSVs to see the diff.
## Returns dictionary.textual, and dictionary.table. These are arrays.
static func diff_compare_weapons_table() -> Dictionary:
	var new_table: Array = FileUtils.load_csv_data_to_array(App.csv_save_path)
	var _previous_path: String = App.csv_save_path.replace(".csv","_previous.csv")
	var old_table: Array = FileUtils.load_csv_data_to_array(_previous_path)
	
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
