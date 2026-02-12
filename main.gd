extends Control
class_name Weapons


const user_folder: String = "Hytale-Weapon-Scraper" # Where this app's user data lives
var hytale_roaming_folder: String # Where THE Hytale game player data lives.

## Get Classes running
static var zip_reader := ZIPReader.new()
static var json := JSON.new()

@onready var main_gui = $"."
@onready var label_processing = $Label_processing

## App Settings Data from JSON
var run_app_headless: bool
var scrape_prerelease_assets: bool
var prerelease_assets_path: String
var prerelease_assets_filename : String
var scrape_release_assets: bool
var release_assets_path : String
var release_assets_filename : String
var csv_prerelease_save_path : String
var csv_prerelease_filename : String
var csv_release_save_path : String
var csv_release_filename : String
var compiled_json_prerelease_save_path : String
var compiled_json_prerelease_filename : String
var compiled_json_release_save_path : String
var compiled_json_release_filename : String

static var asset_zip_path: String # the chosen data source
var csv_save_path: String # the chosen data output path
var compiled_json_save_path: String # Output json file location

## The weapon dictionary is a JSON that can be user-changed as weapons are 
## added to game, or maneuvers changed.
static var weapon_dict: Dictionary ={}
## Dictionary equivalent of weapon_table output
static var weapon_compiled_dict: Dictionary ={}
## Dictionary of column name equivalents for weapon family 
## weapon_move_Xref_dict.family.column_name to get value of move name
static var weapon_move_Xref_dict: Dictionary = {}

# Weapon Table construction
# Determine how many rows are in the weapon_table by counting each weapon's descriptors
static var total_number_of_weapons:int = 0
static var weapon_table_height: int 
static var weapon_table_width: int = 0
static var weapon_table_columns: Array = []
static var weapon_table: Array[Array] = [] ## Table to contain all the data

 
##===================================================================================================
##\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
##===================================================================================================
func _ready() -> void:
	check_if_first_load() # Creates generic settings files in user folder if necessary.
	load_app_settings_from_json() # Populate app variables with data from the json.
	
	if run_app_headless:
		#main_gui.set_visible(false)
		headless_main()
		get_tree().quit() # Closes app
		
	# TODO  Check if NOT Headless from App_Settings, and deal with that in a seperate main-loop.
	else:
		print()
		#main_gui.set_visible(true)
		# wait for go from button
		## TODO if Headless=false, save_app_settings_to_json()


## Sets up app the first time it is loaded by copying files to user:// and defining assets location
func check_if_first_load() -> void:
	# Need to copy the App Setttings into the user folder, 
	# so they can be edited by the user by headless method.
	var file_name: String = "app_settings.json"
	var file_exists: bool = check_user_file_exists(file_name)
	var full_source: String
	var full_destination: String
	if not file_exists: 
		full_source = "res://" + file_name
		full_destination = "user://" + file_name
		copy_file_from_res_to_user(full_source, full_destination) # copy app_settings to user
		first_load_auto_determine_assets_location() # get target path
		# save path data into JSON
	else:
		print("User folder contains app_settings")
		
	# Copy Weapon Dictionary to user so it can be edited by user.
	file_name = "weapon_dictionary.json"
	file_exists = check_user_file_exists(file_name)
	if not file_exists: 
		full_source = "res://Weapons/" + file_name
		full_destination = "user://" + file_name
		copy_file_from_res_to_user(full_source, full_destination) # copy weapons dictinary to user
	else:
		print("User folder contains weapon_dictionary")


func copy_file_from_res_to_user (full_source: String, full_destination: String) -> void:
	# Use DirAccess.copy_absolute()
	# It copies a file from an absolute source path to an absolute destination path.
	# Note: The destination path should include the new file name.
		var error = DirAccess.copy_absolute(full_source, full_destination)
	
		if error == OK:
			print("File copied successfully to: ", full_destination)
		else:
			print("Error copying file: ", error_string(error))


## The first time app_settings is created, pre-fill file-path for assets.
func first_load_auto_determine_assets_location()->void:
	load_app_settings_from_json() # Load here so we can write over it, then save it.
	hytale_roaming_folder = retrieve_roaming_Hytale_folder_location()
	
	var _path:String = "/install/pre-release/package/game/latest/"
	prerelease_assets_path = hytale_roaming_folder + _path
	
	_path = "/install/release/package/game/latest/"
	release_assets_path = hytale_roaming_folder + _path
	
	_path = OS.get_user_data_dir() + "/"
	compiled_json_prerelease_save_path = _path
	compiled_json_release_save_path = _path
	csv_prerelease_save_path = _path
	csv_release_save_path = _path
	save_app_settings_to_json() 


func check_user_file_exists(file_name: String) -> bool:
	# Construct the full path using the 'user://' shorthand
	var path = "user://" + file_name
	
	# Check if the file exists
	if FileAccess.file_exists(path):
		print("File exists in user folder: " + path)
		return true
	else:
		print("File does not exist in user folder: " + path)
		return false


func retrieve_roaming_Hytale_folder_location() -> String:
	var path = OS.get_user_data_dir()
	path = path.rstrip(user_folder)
	return path + "Hytale"


func headless_main() -> void:
	
	open_weapon_dictionary_json()
	
	# TODO Allow Edit app_settings.json in app
	# TODO Allow choosing release or pre-release track.
	
	ItemsWeapon.open_assets_zip() # Open ZIP reader at Assets.zip filepath
	
	initialize_weapon_table() # Create a mostly blank 2d array to hold csv data.
	
	step_through_weapons()
	
	ItemsWeapon.zip_reader.close() # Close ZIP reader
	
	#print_weapon_table_to_console()
	save_array_as_csv(weapon_table, csv_save_path)
	save_compiled_weapons_to_json(weapon_compiled_dict)


## TODO Temporary assignment of pre-release, until logic is written.
## Populate variables with data from the json
func load_app_settings_from_json() -> void:
	# Retrieve json data
	var _app_settings_string = FileAccess.get_file_as_string("user://app_settings.json")
	var _app_settings:Dictionary = JSON.parse_string(_app_settings_string)
	
	run_app_headless = _app_settings.Run_App_Headless # true/false
	scrape_prerelease_assets = _app_settings.Assets.PreRelease.Scrape_Assets # true/false
	prerelease_assets_path = _app_settings.Assets.PreRelease.Assets_Path # C:/Users/%user%/AppData/Roaming/Hytale/install/pre-release/package/game/latest/
	prerelease_assets_filename = _app_settings.Assets.PreRelease.Assets_Filename
	scrape_release_assets = _app_settings.Assets.Release.Scrape_Assets # true/false
	release_assets_path = _app_settings.Assets.Release.Assets_Path
	release_assets_filename = _app_settings.Assets.Release.Assets_Filename
	csv_prerelease_save_path = _app_settings.Output.PreRelease.CSV_Save_Path
	csv_prerelease_filename = _app_settings.Output.PreRelease.CSV_Filename
	csv_release_save_path = _app_settings.Output.Release.CSV_Save_Path
	csv_release_filename = _app_settings.Output.Release.CSV_Filename
	compiled_json_prerelease_save_path = _app_settings.Output.PreRelease.Compiled_JSON_Save_Path
	compiled_json_prerelease_filename = _app_settings.Output.PreRelease.Compiled_JSON_Filename
	compiled_json_release_save_path = _app_settings.Output.Release.Compiled_JSON_Save_Path
	compiled_json_release_filename = _app_settings.Output.Release.Compiled_JSON_Filename
	
	# Temporary assignment of pre-release, until logic is written.
	#-----------------------------------------
	var _prerelease_asset_zip_path = prerelease_assets_path + prerelease_assets_filename
	var _prerelease_csv_save_path = csv_prerelease_save_path + csv_prerelease_filename
	var _prerelease_compiled_json_save_path = compiled_json_prerelease_save_path + compiled_json_prerelease_filename
	
	asset_zip_path = _prerelease_asset_zip_path
	csv_save_path = _prerelease_csv_save_path
	compiled_json_save_path = _prerelease_compiled_json_save_path
	

func save_app_settings_to_json() -> void:
	var data_to_save:Dictionary ={
		"Run_App_Headless": run_app_headless,
		"Assets":{
			"PreRelease":{
				"Scrape_Assets": scrape_prerelease_assets,
				"Assets_Path": prerelease_assets_path,
				"Assets_Filename": prerelease_assets_filename},
			"Release":{
				"Scrape_Assets": scrape_release_assets,
				"Assets_Path": release_assets_path,
				"Assets_Filename": release_assets_filename}},
		"Output":{
			"PreRelease":{
				"Compiled_JSON_Save_Path": compiled_json_prerelease_save_path,
				"Compiled_JSON_Filename": compiled_json_prerelease_filename,
				"CSV_Save_Path": csv_prerelease_save_path,
				"CSV_Filename": csv_prerelease_filename},
			"Release":{
				"Compiled_JSON_Save_Path": compiled_json_release_save_path,
				"Compiled_JSON_Filename": compiled_json_release_filename,
				"CSV_Save_Path": csv_release_save_path,
				"CSV_Filename": csv_release_filename}}
		}

	const SAVE_PATH = "user://app_settings.json"
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data_to_save,"  ",false)
		file.store_line(json_string)
		file.close()
		print("settings saved to: " + SAVE_PATH)
	else:
		print("Failed to save settings.")


## weapon_dict populated here.
func open_weapon_dictionary_json() -> void:
	# Retrieve json data
	var json_string = FileAccess.get_file_as_string("user://weapon_dictionary.json")
	weapon_dict = JSON.parse_string(json_string)
	
	
	## example iterating methods
	#for key in weapon_dict.Weapon_Family.Battleaxe.keys():
		#print("Key: ", key)
	#for i in weapon_dict.Weapon_Family.Battleaxe.weapon_child.size():
		#var value: Variant = weapon_dict.Weapon_Family.Battleaxe.weapon_child[i]
		#print("Each descriptor: ", value)


## This is the 2d array, matrix, or table, where the info scraped from the JSONs gets put.
## The table can be exported as CSV or used internally. 
func initialize_weapon_table() -> void:
	# Define the table size from the weapon-dictionary file
	# Determine Rows:
	for family in weapon_dict.Weapon_Family.keys():
		#print("family: ", family)
		total_number_of_weapons += weapon_dict.Weapon_Family[family].weapon_child.size()
		#print(total_number_of_weapons)
	weapon_table_height = total_number_of_weapons + 1 # Add 1 for the column headers
	
	# Determine Columns
	weapon_table_columns = determine_weapon_table_columns()
	#print(weapon_table_columns)
	weapon_table_width = weapon_table_columns.size() # columns in array
	
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
		weapon_table[0][column] = weapon_table_columns[column]


## Gets Column headers from weapon_dictionary JSON.
func determine_weapon_table_columns() -> Array:
	var table_columns: Array =[]
	for i in weapon_dict.Weapon_Table_Columns.size():
		var i_as_string: String = str(i)
		var value: String = weapon_dict.Weapon_Table_Columns.get(i_as_string,"Error Creating Table")
		table_columns.append(value)
	family_weapon_columns_dictionary(table_columns)
	print(table_columns)
	return table_columns


## creates Column headers for all weapons for lookup purposes.
func family_weapon_columns_dictionary(table_columns: Array) -> void:

	var common_headers: Dictionary = weapon_dict.Common_Headers
	
	# loop for each weapon family
	for family in weapon_dict.Weapon_Family:
		weapon_move_Xref_dict[family] = common_headers.duplicate()
		var xref_family_tree = weapon_move_Xref_dict[family]
		var family_tree = weapon_dict.Weapon_Family[family]
		
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
	
	# EXPERIMENT for display----------------------------------------------------------------------------
	#var wpn_str: String = "Retrieving the weapons of Hytale!"
	#label_processing.set_text(wpn_str)
	#await get_tree().create_timer(0.5).timeout
	
	#select weapon family- battleaxe, dagger etc
	for current_family in weapon_dict.Weapon_Family.keys():
		
		var xref_family_tree = weapon_move_Xref_dict[current_family]
		weapon_compiled_dict.set(current_family,{}) # Top level is Family
		
		for current_child in weapon_dict.Weapon_Family[current_family].weapon_child:
			current_table_row += 1
			weapon_compiled_dict[current_family].set(current_child, {}) # Second level is child
			
			# EXPERIMENT for display----------------------------------------------------------------------------
			#wpn_str = current_child + " " + current_family
			#label_processing.text = wpn_str
			#label_processing.queue_redraw()
			#await get_tree().create_timer(0.01).timeout
			
			ItemsWeapon.scrape_weapon_item_data(current_family, current_child, xref_family_tree,current_table_row)


## Print the table to console for troubleshooting
func print_weapon_table_to_console() -> void:
	print("")
	for row in range(weapon_table_height):
		print(weapon_table[row])
	print("")


## Save the Table Array of all weapons into CSV
func save_array_as_csv(data: Array, path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("Error opening file: ", FileAccess.get_open_error())
		return

	for line_data in data:
		# Convert each inner array/PackedStringArray to a format store_csv_line accepts
		var string_array := PackedStringArray()
		for value in line_data:
			string_array.append(str(value))
		file.store_csv_line(string_array)

	file.close()
	print("Data successfully saved to ", path)


## Save the Dictionary of all weapons into a JSON
func save_compiled_weapons_to_json(data_to_save:Dictionary) -> void:
	var save_path = compiled_json_save_path
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data_to_save,"  ",false)
		file.store_line(json_string)
		file.close()
		print("Compiled Weapons saved to: " + save_path)
	else:
		print("Failed to save Weapons JSON.")


func _on_button_chng_assets_location_pressed() -> void:
	get_tree().quit() # Closes app
	#pass # Replace with function body.


func _on_button_pressed() -> void:
	headless_main()
	#pass
