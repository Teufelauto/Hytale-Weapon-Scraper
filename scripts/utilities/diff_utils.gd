class_name DiffUtils
extends Object
## Various file diffing helper functions.
##
## Various static functions for comparing two resources or files. This class
## helps clean up the main scripts by containing oddball functions.

## Header row of diff table. Used for column indexing when converting array to dict.
enum {
	WEAPON_FAMILY,
	DESCRIPTOR,
	DIFF_PARAMETER,
	OLD_VALUE,
	NEW_VALUE,
}


## Csv based diffs - For creating easy to read table
static func do_csv_based_diff(
		csv_1_path: String = App.exported_csv_1_save_path,
		csv_2_path:String = App.exported_csv_2_save_path) -> void:
	## Do the diff compare, and return two Arrays inside Dictionary.
	## diffs.table is Array for export as csv.
	## diffs.textual is Array for displaying plain-text message of differences.
	var diffs: Dictionary = diff_compare_weapons_table(csv_1_path, csv_2_path)
	
	## Save diff table-Array to csv
	FileUtils.export_array_as_csv(diffs.table, App.diff_csv_save_path) 
	
	## Make Dictionary from Array
	var diff_dict_for_json: Dictionary = convert_diff_table_array_to_dict(diffs.table)
	
	## Export Dictionary as json
	FileUtils.export_dict_to_json(diff_dict_for_json, App.diff_json_from_csv_save_path) 


## JSON based diffs - For creating diff based upon json outputs. Very verbose
## and hard to read by human. Does not produce csv output.
static func do_json_based_diff(
		json_1_path: String = App.exported_json_1_save_path, 
		json_2_path: String = App.exported_json_2_save_path) -> void:
	
	## Do the Diff compare, and return Dictionary.
	var differences_dict: Dictionary = diff_json_compare(
			json_1_path, json_2_path)
	
	## Export Dictionary as json.
	FileUtils.export_dict_to_json(differences_dict, App.diff_json_save_path)


## Load and compare 2 weapons CSVs to see the diff.
## Returns dictionary of arrays: dictionary.textual, and dictionary.table.
static func diff_compare_weapons_table(
		csv_1_path: String, csv_2_path:String ) -> Dictionary:
	
	## Load csv files in to Arrays.
	if not FileUtils.check_os_file_exists(csv_1_path):
		return {}
	var table_1: Array = FileUtils.load_csv_data_to_array(csv_1_path)
	var table_2: Array = FileUtils.load_csv_data_to_array(csv_2_path)
	
	print()
	## Compare new and old tables
	var diffs: Dictionary = compare_weapons_arrays(table_1, table_2)
	if diffs.textual.is_empty():
		print("Old and new weapons are identical.")
		return diffs
	else:
		print("Differences found between old and new weapons:")
		for diff in diffs.textual:
			print("- " + diff)
		
		print("---------------")
		#for diff in diffs.table: ## Outputs the table version to terminal
			#print(diff)
		print()
		return diffs


## Returns a dictionary of weapon diffs with two entries. 
## "textual", and "table". Two arrays of diffs in one Dict.
static func compare_weapons_arrays(table_1: Array, table_2: Array) -> Dictionary:
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
	if table_2.size() != table_1.size():
		differences.append("Array sizes are different: %d vs %d" 
				% [table_1.size(), table_2.size()])
		diff_dict.set("textual", differences)
		
		#return diff_dict ## keep going, though different size noted.
		
		# 2. Iterate through rows (outer array) i is row
	for i in range(table_2.size()):
		## Row of interest in the new table (table2)
		var row_new: Array = table_2[i]
		
		## ----- Find matching row in table_1 -----
		## This section aligns matching rows
		## Unique identifier of Family_Desriptor to look for.
		var id_of_row: String = row_new[1]
		var row_of_old: int
		for j in range(table_1.size()):
			if table_1[j][1] != id_of_row:
				continue
			else:
				row_of_old = j
		## Row in old table that matches id of new table's row we are interested in.
		var row_old: Array  = table_1[row_of_old]

		## ----- End of special section -----
		
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
		for j in range(1, row_new.size()): ## Exclude column 0, which is irrelevant
				# Compare individual elements
			if row_new[j] != row_old[j]:
				
				## To remove row 0 text from value. This is for when a row is missing from table
				if row_of_old == 0:
					row_old.set(j, "")
				
				## Get header value for weapon-id and differing parameter.
				var id: String = table_2[i][1] # Same row, 2nd column for weapon-id
				var parameter: String = table_2[0][j] # Header row, same column
				
				## Create row in the textual array.
				differences.append("Difference in %s with %s: (Old) %s vs %s (New)" 
						% [id, parameter, str(row_old[j]), str(row_new[j]) ])
				diff_dict.set("textual", differences) # Reset the definition
				
				## Create a row on the diff_table
				diff_table.append([
					table_2[i][2],
					table_2[i][3],
					table_2[0][j],
					row_old[j],
					row_new[j],
					])
				
				## Re-set the definition of the Dictionary entry for "table" with new additions.
				diff_dict.set("table", diff_table)
	
	## -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
	## Repeat previous for loop, but backwards to detect when 
	## table_2 is missing an item that is in table_1.
	## From here, new and old are reversed.
	## 2. Iterate through rows (outer array) i is row
	for i in range(table_1.size()):
		## Row of interest in the new table (table2)
		var row_new: Array = table_1[i]
		
		## ----- Find matching row in table_1 -----
		## Unique identifier of Family_Desriptor to look for.
		var id_of_row: String = row_new[1]
		var row_of_old: int
		for j in range(table_2.size()):
			if table_2[j][1] != id_of_row:
				continue
			else:
				row_of_old = j
		## Row in old table that matches id of new table's row we are interested in.
		var row_old: Array = table_2[row_of_old]
		
		## This will prevent duplicate entries in diff.
		if id_of_row == row_old[1]:
			continue
		## ==== End of anti-dupe section ====
		
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
		for j in range(1, row_new.size()): ## exclude column 0
				# Compare individual elements
			if row_new[j] != row_old[j]:
				
				## To remove row 0 text from value (if missing row)
				if row_of_old == 0:
					row_old.set(j, "")
				
				## Get header value for weapon-id and differing parameter.
				var id: String = table_1[i][1] # Same row, 2nd column for weapon-id
				var parameter: String = table_1[0][j] # Header row, same column
				
				## Create row in the textual array.
				differences.append("Difference in %s with %s: (Old) %s vs %s (New)" 
						% [id, parameter, str(row_new[j]), str(row_old[j]) ]) ## backward dur to code reuse
				diff_dict.set("textual", differences) # Reset the definition
				
				## Create a row on the diff_table
				diff_table.append([
					table_1[i][2],
					table_1[i][3],
					table_1[0][j],
					row_new[j],
					row_old[j],
					])
				
				## Re-set the definition of the Dictionary entry for "table" with new additions.
				diff_dict.set("table", diff_table)
	
	return diff_dict


## Returns a Dictionary of diffs suitable for saving as json.
static func convert_diff_table_array_to_dict(table: Array) -> Dictionary:
	
	table.remove_at(0) ## Strip row 0 (headers) out for simpler looping.
	
	var diff: Dictionary = {} ## Populated by weapon_family entries in table.
	
	## Create top-level keys for weapon family
	for row in table:
		## Skip if this family already added.
		if not diff.has(row[WEAPON_FAMILY]):
			## Set family:empty-array as top level of dict. 
			diff.set(row[WEAPON_FAMILY], {}) 
	
	## Create level-2 for descriptors
	for row in table:
		## Skip if this descriptor already added.
		if not diff[row[WEAPON_FAMILY]].has(row[DESCRIPTOR]):
			diff[row[WEAPON_FAMILY]].set(row[DESCRIPTOR], {} )
	
	## Create level-3 for parameters
	for row in table:
		## These vars are for human readability.
		var family_key: String = row[WEAPON_FAMILY]
		var descriptor_key: String = row[DESCRIPTOR]
		var parameter_key: String = row[DIFF_PARAMETER]
		var parameter_value: Array = [row[OLD_VALUE], row[NEW_VALUE]]
		
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


## Prints comparison of two jsons
static func diff_json_compare(path_1: String, path_2: String) -> Dictionary:
	## Retrieve the two json files
	
	var _app_settings_string = FileAccess.get_file_as_string(path_1)
	var dict_a = JSON.parse_string(_app_settings_string) # Define Dictionary
	
	_app_settings_string = FileAccess.get_file_as_string(path_2) 
	var dict_b = JSON.parse_string(_app_settings_string) # Define Dictionary
	
	## Run the comparison function
	return compare_deep_dictionaries(dict_a, dict_b)


## Compares 2 dictionaries, and recursively calls itself to follow branches.
static func compare_deep_dictionaries(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	## Dictionary formed of differences
	var differences: Dictionary = {}
	
	## For each key at the current depth within branches.
	for key in dict1.keys():
		## Check keys present in dict1 but missing or different in dict2
		if not dict2.has(key):
			differences[key] = {
				"_status": "_missing_in_json2", 
				"_value_json1": dict1[key],
				}
		## Shows when value goes from "undefined" to 0.45 etc.
		elif typeof(dict1[key]) != typeof(dict2[key]):
			differences[key] = {
				"_status": "_type_mismatch", 
				"_value_dict1": dict1[key], 
				"_value_dict2": dict2[key],
				}
		## If this key's value is a dictionary, need to follow the branch to expand.
		elif typeof(dict1[key]) == TYPE_DICTIONARY:
			## Funcion calls itself
			var sub_differences: Dictionary = compare_deep_dictionaries(dict1[key], dict2[key])
			if not sub_differences.is_empty():
				differences[key] = {
					"_status": "_sub-differences", 
					"_details": sub_differences,
					}
		## If this key's value is an array, like attack damage, need to check each index.
		elif typeof(dict1[key]) == TYPE_ARRAY:
			var array_differences: Dictionary = compare_deep_arrays(dict1[key], dict2[key])
			if not array_differences.is_empty():
				differences[key] = {
					"_status": "_array-differences",
					"_details": array_differences,
					}
		## Finally, if the values are different:
		elif dict1[key] != dict2[key]:
			differences[key] = {
				"_status": "_value_mismatch",
				"_value_json1": dict1[key], 
				"_value_json2": dict2[key],
				}
	# Check keys present in dict2 but missing in dict1
	for key in dict2.keys():
		if not dict1.has(key):
			differences[key] = {
				"_status": "_missing_in_json1",
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
			"_status": "_size_mismatch",
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
					"_status": "_sub-differences_at_index",
					"_details": sub_differences,
					}
		## if the index is another array, inception
		elif typeof(arr1[i]) == TYPE_ARRAY:
			var sub_differences: Dictionary = compare_deep_arrays(arr1[i], arr2[i])
			if not sub_differences.is_empty():
				differences[i] = {
					"_status": "_sub-differences_at_index",
					"_details": sub_differences,
					}
		## Finally, if the values are different, create key = index:
		elif arr1[i] != arr2[i]:
			differences[i] = {
				"_status": "_value_mismatch_at_index",
				"_value_arr1": arr1[i],
				"_value_arr2": arr2[i],
				}
	return differences
	
	
	
	
	
	
	
		
