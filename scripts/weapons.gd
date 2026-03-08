class_name Weapons
extends App
## Process Weapons in the Assets.zip
##
## We create a table for storing the info in a spreadsheet first. After each row 
## is populated, the line of json is added. 

## The weapon dictionary is a JSON that can be user-changed as weapons are 
## added to game, or maneuvers changed.
static var weapon_dict: Dictionary = {}
## Dictionary equivalent of weapon_table output
static var weapon_encyclopedia: Dictionary = {}
## Dictionary of column name equivalents for weapon family 
## weapon_move_Xref_dict.family.column_name to get value of move name
static var weapon_move_Xref_dict: Dictionary = {}
# Weapon Table construction
## Determine how many rows are in the weapon_table by counting each weapon's files
static var total_number_of_weapons:int = 0
static var weapon_table_height: int = 0
static var weapon_table_width: int = 0
static var weapon_table_column_array: Array = []
static var weapon_table: Array[Array] = [] ## Table to contain all the data
var item_template_dict: Dictionary = {} ## JSON as Dictionary of current Weapon template
var current_template_parent: String ## Keeps track of the currently loaded template.


##==================================================================================================
##\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
##==================================================================================================

## Process Asset. arg is: 1 or 2
func headless_main(asset_being_processed: int) -> void:
	
	## static var weapon_dict populated here.
	weapon_dict = FileUtils.load_json_data_to_dict("user://weapon_dictionary.json")
	
	initialize_weapon_table() # Create a mostly blank 2d array to hold csv data.
	
	# create a dict of all the jsons at once. Better for parent templates.
	#reference_encyclopedia = create_reference_encyclopedia()
	
	step_through_weapons()
	
	#print_weapon_table_to_console() # For troubleshooting
	
	if asset_being_processed == 1:
		FileUtils.export_array_as_csv(weapon_table, exported_csv_1_save_path) # Export to csv
		FileUtils.export_dict_to_json(weapon_encyclopedia, exported_json_1_save_path) # export to json
		
	else: ## asset_being_processed == 2
		FileUtils.export_array_as_csv(weapon_table, exported_csv_2_save_path) # Export to csv
		FileUtils.export_dict_to_json(weapon_encyclopedia, exported_json_2_save_path) # export to json
		

## This is the 2d array, matrix, or table, where the info scraped from the JSONs gets put.
## The table can be exported as CSV or used internally. 
func initialize_weapon_table() -> void:
	weapon_table.clear() ## Must clear before second go round, or extra cells
	total_number_of_weapons = 0 ## Must clear before second go round, or extra cells
	
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
	weapon_table_height = total_number_of_weapons + 1 # Add 1 for the column headers
	
	# Determine Columns from weapon dictionary json
	weapon_table_column_array = determine_weapon_table_columns()
	weapon_table_width = weapon_table_column_array.size() # columns in array
	
	# Create the outer array
	for row in range(weapon_table_height):
		# Append inner arrays to form the 2D structure
		weapon_table.append([])
		for column in range(weapon_table_width):
			# Initialize each cell with a default value
			weapon_table[row].append("")
	# Populate the Column Headers for the table.
	for column in range(weapon_table_width):
		weapon_table[0][column] = weapon_table_column_array[column]


## Gets Column headers from weapon_dictionary JSON.
func determine_weapon_table_columns() -> Array:
	var table_columns: Array = []
	for i in weapon_dict.weapon_table_columns.size():
		var i_as_string: String = str(i)
		var value: String = weapon_dict.weapon_table_columns.get \
				(i_as_string,"Error Creating Table")
		table_columns.append(value)
	family_weapon_columns_dictionary(table_columns)
	#print(table_columns)
	return table_columns


## creates Column header cross-reference for all weapons for lookup purposes.
func family_weapon_columns_dictionary(table_columns: Array) -> void:
	# loop for each weapon family
	for family in weapon_dict.weapon_family:
		weapon_move_Xref_dict[family] = weapon_dict.common_table_headers.duplicate()
		# loop through each column in the table
		for entry in table_columns:
			# skip the common headers that are the same for all weapons.
			if weapon_move_Xref_dict[family].has(entry): 
				continue
			else:
				add_entry_key_to_xref_dict(family, entry)


## This function will need to grow as new types of keys are entered in the dictionary.
## "key":"value" -> "primary_attack_1_name":"Swing_Down_Damage"
func add_entry_key_to_xref_dict(family:String, entry:String ) -> void:
	## Assign unique sub-dictionary entries for remaining columns in family
	## Modify header string to match dictionary string
	var look: String = ""
	if entry.ends_with("_damage"):
		look = entry.replace("_damage","_name") 
	var move_name_src_key: String = weapon_dict.weapon_family[family].get(look,"")
	
	if move_name_src_key.contains("Damage"): # "Damage" already in name, like projectiles
		pass
	else:
		## Append "_Damage" to end for making key to scrape json.
		## Breaks projectiles (or anything without Damage at end of key)
		move_name_src_key = move_name_src_key + "_Damage"
	
	weapon_move_Xref_dict[family].set(entry, move_name_src_key)


func create_reference_encyclopedia() -> Dictionary:
	var current_table_row: int  = 0 #start with 0 and increment for each value
	var xref_common_table_headers: Dictionary = weapon_dict.common_table_headers
	
	#select weapon family- battleaxe, dagger etc
	for current_family in weapon_dict.weapon_family.keys():
		
		var child_xref_header_to_simple: Dictionary = weapon_move_Xref_dict[current_family]
		
		## lower_case string version of current_Family  
		var current_family_lower: String = current_family.to_lower()
		reference_encyclopedia.weapons.set(current_family_lower, {}) # Top level is Family
		
		var target_folder: String = "Server/Item/Items/Weapon/" + current_family + "/"
		
		## Iterate through the files and check if they are in the target folder.
		for file_path in FileUtils.zip_files:
			## Check if the file path starts with the desired folder path
			## (e.g., "my_folder/" or "res://my_folder/").
			if target_folder.is_empty() or file_path.begins_with(target_folder):
				## returns int for row numbering purposes.
				current_table_row += 1
	
				var current_child: String = find_child_frm_path(file_path, current_family)
				# Second level is child
				reference_encyclopedia.weapons[current_family_lower].set(current_child.to_lower(), {}) 
				
				## Instance of ItemsWeapon class. Inside for-loop, so will get reset like any var.
				var iw := ItemsWeapon.new()
				iw.scrape_weapon_item_data(file_path, current_family, current_child,
						child_xref_header_to_simple, xref_common_table_headers, current_table_row)
				iw.free()
	
	return {}


## Step through all weapons and descriptors (children) to create Table and Dict
func step_through_weapons() -> void:
	var current_table_row: int  = 0 #start with 0 and increment for each value
	var xref_common_table_headers: Dictionary = weapon_dict.common_table_headers
	
	#select weapon family- battleaxe, dagger etc
	for current_family in weapon_dict.weapon_family.keys():
		
		var child_xref_header_to_simple: Dictionary = weapon_move_Xref_dict[current_family]
		
		## lower_case string version of current_Family  
		var current_family_lower: String = current_family.to_lower()
		weapon_encyclopedia.set(current_family_lower, {}) # Top level is Family
		
		var target_folder: String = "Server/Item/Items/Weapon/" + current_family + "/"
		
		## Iterate through the files and check if they are in the target folder.
		for file_path in FileUtils.zip_files:
			## Check if the file path starts with the desired folder path
			## (e.g., "my_folder/" or "res://my_folder/").
			if target_folder.is_empty() or file_path.begins_with(target_folder):
				## returns int for row numbering purposes.
				current_table_row = prepare_child_wpn_to_scrape(current_table_row, 
						file_path, current_family, current_family_lower,
						child_xref_header_to_simple, xref_common_table_headers)


func prepare_child_wpn_to_scrape(current_table_row: int, file_path: String,
		current_family: String, current_family_lower: String,
		xref_child: Dictionary, xref_common_table_headers: Dictionary) -> int:
	current_table_row += 1
	
	var current_child: String = find_child_frm_path(file_path, current_family)
	# Second level is child
	weapon_encyclopedia[current_family_lower].set(current_child.to_lower(), {}) 
	
	## Instance of ItemsWeapon class. Inside for-loop, so will get reset like any var.
	var iw := ItemsWeapon.new()
	iw.scrape_weapon_item_data(file_path, current_family, current_child,
			xref_child, xref_common_table_headers, current_table_row)
	iw.free()
	return current_table_row


## Pulls out the current_child String from path.
func find_child_frm_path(file_path: String, current_family: String)-> String:
	var count: int = file_path.get_slice_count("/") - 1
	## current_child is the descriptor, such as crude, or copper.
	var current_child: String = file_path.get_slice("/", count) 
	current_child = current_child.trim_suffix(".json")
	var left_stripper: String = "Weapon_" + current_family + "_"
	current_child = current_child.trim_prefix(left_stripper)
	#print(current_child)
	return current_child


## Call this to print the table to console for troubleshooting
func print_weapon_table_to_console() -> void:
	print("")
	for row in range(weapon_table_height):
		print(weapon_table[row])
	print("")
