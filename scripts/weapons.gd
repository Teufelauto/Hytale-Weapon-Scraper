class_name Weapons
extends App
## Process Weapons in the Assets.zip
##
## Creates a table for storing the info in a spreadsheet.
## Also creates a json of the data. 

## Loaded from json on App start. File can be user-changed as weapons are 
## added to game, or maneuvers changed. 
static var weapon_dict: Dictionary = {}

## Dictionary of column name equivalents for current weapon family 
## weapon_move_Xref_dict.family.column_name to get value of move name
static var weapon_families_Xref_dict: Dictionary = {}

# Weapon Table construction
## Determine how many rows are in the weapon_table by counting each weapon's files
static var total_number_of_weapons:int = 0
static var weapon_table_height: int = 0
static var weapon_table_width: int = 0
static var weapon_table_column_array: Array = []
static var weapon_table: Array[Array] = [] ## Table to contain all the data
## Dictionary equivalent of weapon_table output
static var weapon_encyclopedia: Dictionary = {}

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
	
	## Create a dict of all the jsons at once. Better for parent templates.
	enter_weapons_in_reference_encyclopedia()
	
	step_through_weapons()
	
	#print_weapon_table_to_console() # For troubleshooting
	
	choose_what_to_export(asset_being_processed)


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
		weapon_families_Xref_dict[family] = weapon_dict.common_table_headers.duplicate()
		# loop through each column in the table
		for entry in table_columns:
			# skip the common headers that are the same for all weapons.
			if weapon_families_Xref_dict[family].has(entry): 
				continue
			else:
				add_entry_key_to_xref_dict(family, entry)


## Sets weapon_move_Xref_dict
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
	
	weapon_families_Xref_dict[family].set(entry, move_name_src_key)


## Saves to App.reference_encyclopedia
func enter_weapons_in_reference_encyclopedia() -> void:
	## select weapon family- battleaxe, dagger etc
	for current_family in weapon_dict.weapon_family.keys():
		## lower_case string version of current_Family  
		reference_encyclopedia.weapons.set(current_family, {} ) 
		var target_folder: String = "Server/Item/Items/Weapon/" + current_family + "/"
		## Iterate through the files and check if they are in the target folder.
		for file_path in FileUtils.zip_files:
			## Check if the file path starts with the desired folder path
			if target_folder.is_empty() or file_path.begins_with(target_folder):
				
				var current_child: String = find_child_frm_path(\
						file_path, current_family)
				
				## Create 3rd level child dict branch.
				reference_encyclopedia.weapons[current_family].set(current_child, {} ) 
				## i.e. reference_encyclopedia.weapons.battleaxe.copper
				reference_encyclopedia.weapons[current_family][current_child] \
						= parse_weapon_item_info(file_path)
				print("Retrieving " + current_family + " " + current_child)


## Parse weapon server/item/items weapon info json and turn it into a Dictionary
func parse_weapon_item_info(file_path: String) -> Dictionary:
	# Read json inside zip
	var file_buffer: PackedByteArray = FileUtils.zip_reader.read_file(file_path)
	if file_buffer.is_empty():
		printerr("Failed to read json weapon file or file is empty")
		return { null:null }
	else:
		#print("Successfully read file: ", file_path)
		# Convert Byte Array into String. utf8 for safety
		var _item_weapon_info_string: String = file_buffer.get_string_from_utf8()
		var _item_weapon_info_as_dict: Dictionary = JSON.parse_string(_item_weapon_info_string)
		return _item_weapon_info_as_dict


## Step through all weapons and descriptors (children) to create Table and Dict
func step_through_weapons() -> void:
	var current_table_row: int  = 0 #start with 0 and increment for each value
		
	#select weapon family- battleaxe, dagger etc
	for current_family in weapon_dict.weapon_family.keys():
		weapon_encyclopedia.set(current_family.to_lower(), {}) # Top level is Family
		
		for current_child in reference_encyclopedia.weapons[current_family]:
			current_table_row += 1
			prepare_child_wpn_to_scrape(current_table_row, 
						current_family, current_child)


func prepare_child_wpn_to_scrape(current_table_row: int, current_family: String, 
		current_child: String) -> int:
	
	## Create Second level child
	weapon_encyclopedia[current_family.to_lower()].set(current_child.to_lower(), {}) 
	
	## Instance of ItemsWeapon class.
	var iw := ItemsWeapon.new()
	iw.scrape_weapon_item_data(current_family, current_child, current_table_row)
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


func choose_what_to_export(asset_being_processed: int):
	if asset_being_processed == 1:
		FileUtils.export_array_as_csv(weapon_table, exported_csv_1_save_path) # Export to csv
		FileUtils.export_dict_to_json(weapon_encyclopedia, exported_json_1_save_path) # export to json
		
	else: ## asset_being_processed == 2
		FileUtils.export_array_as_csv(weapon_table, exported_csv_2_save_path) # Export to csv
		FileUtils.export_dict_to_json(weapon_encyclopedia, exported_json_2_save_path) # export to json
		
