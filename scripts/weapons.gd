class_name Weapons
extends App
## Process Weapons in the Assets.zip
##
## We create a table for storing the info in a spreadsheet first. After each row 
## is populated, the line of json is added. 

## The weapon dictionary is a JSON that can be user-changed as weapons are 
## added to game, or maneuvers changed.
static var weapon_dict: Dictionary ={}
## Dictionary equivalent of weapon_table output
static var weapon_encyclopedia: Dictionary ={}
## Dictionary of column name equivalents for weapon family 
## weapon_move_Xref_dict.family.column_name to get value of move name
static var weapon_move_Xref_dict: Dictionary = {}

var item_weapon_as_dict: Dictionary = {} ## JSON as Dictionary of Weapon_Sword_Crude or whatever
var item_template_dict: Dictionary = {} ## JSON as Dictionary of current Weapon template
var current_template_family: String ## Keeps track of the currently loaded template.

# Weapon Table construction
## Determine how many rows are in the weapon_table by counting each weapon's files
static var total_number_of_weapons:int = 0
static var weapon_table_height: int 
static var weapon_table_width: int = 0
static var weapon_table_column_array: Array = []
static var weapon_table: Array[Array] = [] ## Table to contain all the data


##==================================================================================================
##\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
##==================================================================================================


func headless_main() -> void:
	
	## static var weapon_dict populated here.
	weapon_dict = FileUtils.load_json_data_to_dict("user://weapon_dictionary.json")
	
	initialize_weapon_table() # Create a mostly blank 2d array to hold csv data.
		
	step_through_weapons()

	#print_weapon_table_to_console() # For troubleshooting
	
	FileUtils.backup_csv_and_json() # Backup files so they can be compared and archived.
	FileUtils.save_array_as_csv(weapon_table, csv_save_path) # Export to csv
	FileUtils.save_dict_to_json(weapon_encyclopedia, compiled_json_save_path) # export to json
	
	var diffs: Dictionary = DiffUtils.diff_compare_weapons_table() # Do the diff compare
	FileUtils.save_array_as_csv(diffs.table, diff_csv_save_path) # Save diff to csv
	var diff_dict_for_json: Dictionary = DiffUtils.convert_diff_table_array_to_dict(diffs.table)
	FileUtils.save_dict_to_json(diff_dict_for_json, diff_json_save_path) # export to json


## This is the 2d array, matrix, or table, where the info scraped from the JSONs gets put.
## The table can be exported as CSV or used internally. 
func initialize_weapon_table() -> void:
	# Define the table size from the weapon-dictionary file to only include weapons we want.
	# Determine Rows: A family is Mace, or Sword, etc
	for family in weapon_dict.weapon_family.keys():
		#print("family: ", family)
		
		var target_folder: String = "Server/Item/Items/Weapon/" + family + "/"
		## Iterate through the files and check if they are in the target folder.
		for file_path in FileUtils.zip_files:
		## Check if the file path starts with the desired folder path
			if file_path.begins_with(target_folder):
				total_number_of_weapons += 1
		#print(total_number_of_weapons)
	
	## Temp - add bunches of extra rows because we may not be usung tables for base anymore...
	weapon_table_height = total_number_of_weapons + 1 # Add 1 for the column headers
	
	# Determine Columns from weapon dictionary json
	weapon_table_column_array = determine_weapon_table_columns()
	#print(weapon_table_column_array)
	weapon_table_width = weapon_table_column_array.size() # columns in array
	
	# Create the outer array
	for row in range(weapon_table_height):
		# Append inner arrays to form the 2D structure
		weapon_table.append([])
		for column in range(weapon_table_width):
			# Initialize each cell with a default value (e.g., 0 for an empty cell)
			weapon_table[row].append("")
	# You can then set specific values. weapon_table[Row][Column]
	# Populate the Column Headers for the table.
	for column in range(weapon_table_width):
		weapon_table[0][column] = weapon_table_column_array[column]


## Gets Column headers from weapon_dictionary JSON.
func determine_weapon_table_columns() -> Array:
	var table_columns: Array =[]
	for i in weapon_dict.weapon_table_columns.size():
		var i_as_string: String = str(i)
		var value: String = weapon_dict.weapon_table_columns.get(i_as_string,"Error Creating Table")
		table_columns.append(value)
	family_weapon_columns_dictionary(table_columns)
	#print(table_columns)
	return table_columns


## creates Column headers for all weapons for lookup purposes.
func family_weapon_columns_dictionary(table_columns: Array) -> void:

	var common_headers: Dictionary = weapon_dict.common_table_headers
	
	# loop for each weapon family
	for family in weapon_dict.weapon_family:
		weapon_move_Xref_dict[family] = common_headers.duplicate()
		var xref_family_tree = weapon_move_Xref_dict[family]
		var family_tree = weapon_dict.weapon_family[family]
		
		#print(family)
		#print(xref_family_tree)
		
		# loop through each column in the table
		for entry in table_columns:
			# skip the common headers that are the same for all weapons.
			if xref_family_tree.has(entry): 
				continue
			else:
				# Assign unique sub-dictionary entries for remaining columns in family
				# modify header string to match dictionary string
				var look: String = entry.replace("_damage","_name") 
				var move_name: String = family_tree.get(look,"")
				
				# Append "_Damage" to end for making key to scrape json 
				move_name = move_name + "_Damage"
				
				# "key":"value" -> "primary_attack_1_name":"Swing_Down_Damage"
				xref_family_tree.set(entry, move_name)
	#print(weapon_move_Xref_dict)


## Step through all weapons and descriptors (children) to create Table and Dict
func step_through_weapons() -> void:
	var current_table_row: int  = 0 #start with 0 and increment for each value
	var xref_common_table_headers: Dictionary = weapon_dict.common_table_headers
	# EXPERIMENT for gui display----------------------------------------------------------------------------
	#var wpn_str: String = "Retrieving the weapons of Hytale!"
	#label_processing.set_text(wpn_str)
	#await get_tree().create_timer(0.5).timeout
	
	#select weapon family- battleaxe, dagger etc
	for current_family in weapon_dict.weapon_family.keys():
		
		var xref_family_tree = weapon_move_Xref_dict[current_family]
		
		## lower_case string version of current_Family  
		var current_family_lower: String = current_family.to_lower()
		weapon_encyclopedia.set(current_family_lower,{}) # Top level is Family
		
		var target_folder: String = "Server/Item/Items/Weapon/" + current_family + "/"
		
		## Iterate through the files and check if they are in the target folder.
		for file_path in FileUtils.zip_files:
		## Check if the file path starts with the desired folder path
		## (e.g., "my_folder/" or "res://my_folder/").
		## If target_folder is empty, it processes all files.
			if target_folder.is_empty() or file_path.begins_with(target_folder):
				print()
				print("Found weapon file in target folder: ", file_path)
				
				current_table_row += 1
				
				## The below block pulls out the current_child String from path.
				## count is the index for .get_slice method.
				var count: int = file_path.get_slice_count("/")  - 1
				## current_child is the descriptor, such as crude, or copper.
				var current_child: String = file_path.get_slice("/",count) 
				current_child = current_child.trim_suffix(".json")
				var left_stripper: String = "Weapon_" + current_family + "_"
				current_child = current_child.trim_prefix(left_stripper)
				#print(current_child)
				
				## lower_case string version of current_Child
				var current_child_lower: String = current_child.to_lower()
				# Second level is child
				weapon_encyclopedia[current_family_lower].set(current_child_lower, {}) 
							
				## Instance of ItemsWeapon class.
				var iw := ItemsWeapon.new()
				
				iw.scrape_weapon_item_data(file_path, current_family, current_family_lower, \
						current_child, current_child_lower, xref_family_tree, \
						xref_common_table_headers, current_table_row)
				
				
			
		
		

## Call this to print the table to console for troubleshooting
func print_weapon_table_to_console() -> void:
	print("")
	for row in range(weapon_table_height):
		print(weapon_table[row])
	print("")
