class_name DiffUtils
extends Object
## Various file diffing helper functions.
##
## Various static functions for comparing two resources or files. This class
## helps clean up the main scripts by containing oddball functions.

## Header row of diff table. Used for column indexing when converting array to dict.
enum Header {
		WEAPON_FAMILY,
		DESCRIPTOR,
		DIFF_PARAMETER,
		OLD_VALUE,
		NEW_VALUE
		}


## TODO Enable ability to specify Table names and versions
## Load and compare 2 weapons CSVs to see the diff.
## Returns dictionary.textual, and dictionary.table. These are arrays.
static func diff_compare_weapons_table(designator_for_old: String = "_old") -> Dictionary:
	var new_table: Array = FileUtils.load_csv_data_to_array(App.csv_save_path)
	var old_end: String = designator_for_old + ".csv"
	var _previous_path: String = App.csv_save_path.replace(".csv", old_end)
	var old_table: Array = FileUtils.load_csv_data_to_array(_previous_path)
	
	print()
	# Compare new and old tables
	var diffs: Dictionary = compare_weapons_arrays(new_table, old_table)
	if diffs.textual.is_empty():
		print("New and old weapons are identical.")
		return diffs
	else:
		print("Differences found between new and old weapons:")
		for diff in diffs.textual:
			print("- " + diff)
		
		print("---------------")
		#for diff in diffs.table:
			#print(diff)
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


## Returns a Dictionary of diffs suitable for saving as json.
static func convert_diff_table_array_to_dict(table: Array) -> Dictionary:
	
	table.remove_at(0) ## Strip row 0 (headers) out for simpler looping.
	
	var diff: Dictionary = {} ## Populated by weapon_family entries in table.
	
	## Create top-level keys for weapon family
	for row in table:
		## Skip if this family already added.
		if not diff.has(row[Header.WEAPON_FAMILY]):
			## Set family:empty-array as top level of dict. 
			diff.set(row[Header.WEAPON_FAMILY], {}) 
	
	## Create level-2 for descriptors
	for row in table:
		## Skip if this descriptor already added.
		if not diff[row[Header.WEAPON_FAMILY]].has(row[Header.DESCRIPTOR]):
			diff[row[Header.WEAPON_FAMILY]].set(row[Header.DESCRIPTOR], {} )
	
	## Create level-3 for parameters
	for row in table:
		## These vars are for human readability.
		var family_key: String = row[Header.WEAPON_FAMILY]
		var descriptor_key: String = row[Header.DESCRIPTOR]
		var parameter_key: String = row[Header.DIFF_PARAMETER]
		var parameter_value: Array = [row[Header.OLD_VALUE], row[Header.NEW_VALUE]]
		
		## No need to skip, because there will not be a repeat. Assign key and values.
		diff[family_key][descriptor_key].set(parameter_key, parameter_value)
	
	#print(diff)
	return diff


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


## TODO Designate correct files to compare
## Prints comparison of two jsons (poorly constructed output)
static func trial_json_compare()->void:
	
	## Retrieve the two json files
	var _app_settings_string = FileAccess.get_file_as_string(
			"user://output/weapons_encyclopedia_pre-release_oldy.json") ## unique on purpose for testing--------------------------
	var dict_a = JSON.parse_string(_app_settings_string) # Define Dictionary
	
	_app_settings_string = FileAccess.get_file_as_string(
			"user://output/weapons_encyclopedia_pre-release.json") 
	var dict_b = JSON.parse_string(_app_settings_string) # Define Dictionary
	
	## Run the compare
	var differences: Dictionary = compare_deep_dictionaries(dict_a, dict_b)
	#print(differences)
	## Export to json
	FileUtils.export_dict_to_json(differences)
	

## Compares 2 dictionaries, and recursively calls itself to follow branches.
static func compare_deep_dictionaries(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	## Dictionary formed of differences
	var differences: Dictionary = {}
	
	## For each key at the current depth within branches.
	for key in dict1.keys():
		## Check keys present in dict1 but missing or different in dict2
		if not dict2.has(key):
			differences[key] = {
				"_status": "missing_in_json2", 
				"_value_json1": dict1[key],
				}
		## For typed dictionary... idk that it's necessary here. Might catch 
		## errors in new features if I forget to define an array during dict construction.
		elif typeof(dict1[key]) != typeof(dict2[key]):
			differences[key] = {
				"_status": "type_mismatch", 
				"_value_dict1": dict1[key], 
				"_value_dict2": dict2[key],
				}
		## If this key's value is a dictionary, need to follow the branch to expand.
		elif typeof(dict1[key]) == TYPE_DICTIONARY:
			## Funcion calls itself
			var sub_differences: Dictionary = compare_deep_dictionaries(dict1[key], dict2[key])
			if not sub_differences.is_empty():
				differences[key] = {
					"_status": "sub-differences", 
					"_details": sub_differences,
					}
		## If this key's value is an array, like attack damage, need to check each index.
		elif typeof(dict1[key]) == TYPE_ARRAY:
			var array_differences: Dictionary = compare_deep_arrays(dict1[key], dict2[key])
			if not array_differences.is_empty():
				differences[key] = {
					"_status": "array-differences",
					"_details": array_differences,
					}
		## Finally, if the values are different:
		elif dict1[key] != dict2[key]:
			differences[key] = {
				"_status": "value_mismatch",
				"_value_json1": dict1[key], 
				"_value_json2": dict2[key],
				}
	# Check keys present in dict2 but missing in dict1
	for key in dict2.keys():
		if not dict1.has(key):
			differences[key] = {
				"_status": "missing_in_json1",
				"_value_json2": dict2[key],
				}
	return differences 


## Helper function for array comparison (simple version) in compare_deep_dictionaries().
static func compare_deep_arrays(arr1: Array, arr2: Array) -> Dictionary:
	## Dictionary formed of differences
	var differences : Dictionary = {}
	
	## Detect if there are more or less values in the array.
	if arr1.size() != arr2.size():
		differences["_size"] = {
			"_status": "size_mismatch",
			"_size_arr1": arr1.size(),
			"_size_arr2": arr2.size(),
			}
	## Iterate through each index
	var max_size: int = mini(arr1.size(), arr2.size())
	for i in range(max_size):
		## If the index is a dictionary, call deep_dict funcion
		if typeof(arr1[i]) == TYPE_DICTIONARY:
			var sub_differences: Dictionary = compare_deep_dictionaries(arr1[i], arr2[i])
			if not sub_differences.is_empty():
				differences[i] = {
					"_status": "sub-differences_at_index",
					"_details": sub_differences,
					}
		## if the index is another array, inception
		elif typeof(arr1[i]) == TYPE_ARRAY:
			var sub_differences: Dictionary = compare_deep_arrays(arr1[i], arr2[i])
			if not sub_differences.is_empty():
				differences[i] = {
					"_status": "sub-differences_at_index",
					"_details": sub_differences,
					}
		## Finally, if the values are different, create key = index:
		elif arr1[i] != arr2[i]:
			differences[i] = {
				"_status": "value mismatch_at_index",
				"_value_arr1": arr1[i],
				"_value_arr2": arr2[i],
				}
	return differences
	
	
	
	
	
	
		
