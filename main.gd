extends Control


const user_folder: String = "Hytale-Weapon-Scraper" # Where this app's user data lives
var hytale_roaming_folder: String # Where THE Hytale game player data lives.

# Get Classes running
var zip_reader := ZIPReader.new()

# TODO get weaponshared data onto user folder as a json or something so it can be edited without recompile.
const MyWeaponShared = preload("res://Weapons/WeaponShared.gd") 
var my_weapons: MyWeaponShared

# App Settings Data from JSON
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

var asset_zip_path: String # the processed data
var csv_save_path: String # the processed data



# Weapon Table construction
# Determine how many rows are in the weapon_table by counting each weapon's descriptors
var total_number_of_weapons:int
var weapon_table_height: int 
var weapon_table_columns: Array
var weapon_table_width: int
var weapon_table: Array[Array] = [] # Initialize the empty table.
var current_table_row: int = 0  # initialize for incrementing each weapon for entry into matrix

#===================================================================================================
#\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
#===================================================================================================
func _ready() -> void:
	check_if_first_load() # Creates settings file in user folder.
	load_app_settings_from_json() # Populate variables with data from the json
	# TODO  Check if Headless from App_Settings, and deal with that.
	# TODO Allow Edit app_settings.json in app
	# TODO Allow choosing release or pre-release track.
	my_weapons = MyWeaponShared.new() # for calling WeaponShared
	open_assets_zip() # Open ZIP reader at Assets.zip filepath
	
	initialize_weapon_table() # Create a mostly blank 2d array to hold csv data.
	
	scrape_template_weapon_items()
	
	step_through_weapons()
	
	zip_reader.close() #Close ZIP reader
	
	print_weapon_table_to_console()
	save_array_as_csv(weapon_table, csv_save_path)
	
	
	#ResourceSaver.save(WeaponShared, "user://app_setup.tres") # Experiment with resources
	# TODO Save app_settings.json
	
	get_tree().quit() # Closes app


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
		"CSV_Output":{
			"PreRelease":{
				"CSV_Save_Path": csv_prerelease_save_path,
				"CSV_Filename": csv_prerelease_filename},
			"Release":{
				"CSV_Save_Path": csv_release_save_path,
				"CSV_Filename": csv_release_filename}}
		}
	#print(data_to_save)
	const SAVE_PATH = "user://app_settings.json"
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data_to_save,"  ",false)
		file.store_line(json_string)
		file.close()
		print("settings saved to: " + SAVE_PATH)
	else:
		print("Failed to save settings.")
	
	
# Populate variables with data from the json
func load_app_settings_from_json() -> void:
	# Retrieve json data
	var _json = JSON.new()
	var _app_settings_string = FileAccess.get_file_as_string("user://app_settings.json")
	var _app_settings:Dictionary = JSON.parse_string(_app_settings_string)
	
	run_app_headless = _app_settings.Run_App_Headless # true/false
	scrape_prerelease_assets = _app_settings.Assets.PreRelease.Scrape_Assets # true/false
	prerelease_assets_path = _app_settings.Assets.PreRelease.Assets_Path # C:/Users/%user%/AppData/Roaming/Hytale/install/pre-release/package/game/latest/
	prerelease_assets_filename = _app_settings.Assets.PreRelease.Assets_Filename
	scrape_release_assets = _app_settings.Assets.Release.Scrape_Assets # true/false
	release_assets_path = _app_settings.Assets.Release.Assets_Path
	release_assets_filename = _app_settings.Assets.Release.Assets_Filename
	csv_prerelease_save_path = _app_settings.CSV_Output.PreRelease.CSV_Save_Path
	csv_prerelease_filename = _app_settings.CSV_Output.PreRelease.CSV_Filename
	csv_release_save_path = _app_settings.CSV_Output.Release.CSV_Save_Path
	csv_release_filename = _app_settings.CSV_Output.Release.CSV_Filename
	
	
	# Temporary assignment of pre-release, until logic is written.
	#-----------------------------------------
	var _prerelease_asset_zip_path = prerelease_assets_path + prerelease_assets_filename
	var _prerelease_csv_save_path = csv_prerelease_save_path + csv_prerelease_filename
	
	asset_zip_path = _prerelease_asset_zip_path
	csv_save_path = _prerelease_csv_save_path
	
	
# The first time app_settings is created, pre-fill file-path for assets.
func first_load_auto_determine_assets_location()->void:
	load_app_settings_from_json() # Load here so we can write over it, then save it.
	hytale_roaming_folder = retrieve_roaming_Hytale_folder_location()
	var _path:String = "/install/pre-release/package/game/latest/"
	prerelease_assets_path = hytale_roaming_folder + _path
	_path = "/install/release/package/game/latest/"
	release_assets_path = hytale_roaming_folder + _path
	save_app_settings_to_json() 

func retrieve_roaming_Hytale_folder_location() -> String:
	var path = OS.get_user_data_dir()
	path = path.rstrip(user_folder)
	return path + "Hytale"
	
	
# TODO Get scraped data into the table, either before or during populating.
func scrape_template_weapon_items() -> void:
	pass

func open_assets_zip()->void:
	var error = zip_reader.open(asset_zip_path)
	if error != OK:
		print("Failed to open ZIP file: ", error)
		return


# Sets up app the first time it is loaded
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
	
	
	
	# TODO Weapon Setup resource
	#file_name: String = "weapon_setup.json"
	#not_first_time = check_user_file_exists(file_name)
	#if not_first_time: # Meaning, if the file exists in the user folder, skip all this.
		#print("User folder contains WeaponShared")
	#else:
		#full_source = "res://weapons/" + file_name
		#full_destination = "user://" + file_name
		#copy_file_from_res_to_user(full_source, full_destination) # copy WeaponShared to user
	
	
func copy_file_from_res_to_user (full_source: String, full_destination: String) -> void:
	# Use DirAccess.copy_absolute()
	# It copies a file from an absolute source path to an absolute destination path.
	# Note: The destination path should include the new file name.
		var error = DirAccess.copy_absolute(full_source, full_destination)
	
		if error == OK:
			print("File copied successfully to: ", full_destination)
		else:
			print("Error copying file: ", error_string(error))
	

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

# This is the 2d array, matrix, or table, where the info scraped from the JSONs gets put.
# The table can be exported as CSV or used internally. 
func initialize_weapon_table() -> void:
	# Define the table size from tthe weapon shared file
	total_number_of_weapons = my_weapons.total_number_of_weapons
	weapon_table_height = total_number_of_weapons + 1 # Add 1 for the column headers
	weapon_table_columns = my_weapons.weapon_table_columns
	weapon_table_width = weapon_table_columns.size() # columns in array
	
	# Create the outer array
	for row in range(weapon_table_height):
		# Append inner arrays to form the 2D structure
		weapon_table.append([])
		for column in range(weapon_table_width):
			# Initialize each cell with a default value (e.g., 0 for an empty cell)
			weapon_table[row].append(null)
	# You can then set specific values. weapon_table[Row][Column]
	# Populate the Column Headers for the table.
	for column in range(weapon_table_width):
		weapon_table[0][column] = weapon_table_columns[column]


func print_weapon_table_to_console() -> void:
	print("")
	for row in range(weapon_table_height):
		print(weapon_table[row])
	print("")

# steps through all weapons and descriptors
func step_through_weapons() -> void:
	current_table_row = 0 #start with 0 and increment each j
	
	#select weapon family- battleaxe, dagger etc
	for i in my_weapons.melee_weapon_shared_list:
		var CurrentWeapon: Object = i # dagger or sword subclass etc
	
		for j in CurrentWeapon.weapon_descriptor:
			current_table_row +=1
			#select weapon descriptor- crude, adamantite, etc
			var current_weapon_descriptor:String = j # "Crude" or "iron" etc
			scrape_weapon_item_data(CurrentWeapon, current_weapon_descriptor)
	
# TODO Need to use TEMPLATE json for info not in individual files when exists.
# CurrentWeapon is tthe weapon class (sword etc) and current_weapon_descriptor is "crude" or "iron" etc
func scrape_weapon_item_data(CurrentWeapon: Object,current_weapon_descriptor: String) -> void:
	#counting index for putting each item in its own row on table
	weapon_table[current_table_row][0] = current_table_row
	print(current_table_row)
	
	var current_weapon_family_as_string: String = CurrentWeapon.weapon_family # "Battleaxe" or "Sword" etc
	var weapon_id: String = current_weapon_family_as_string + "_" + current_weapon_descriptor  # "Sword_Crude" etc
	print(weapon_id)
	weapon_table[current_table_row][1] = weapon_id # Unique name for each item
	weapon_table[current_table_row][2] = current_weapon_family_as_string
	weapon_table[current_table_row][3] = current_weapon_descriptor
	
	#need the file path and name of the current weapon
	var _items_path: String = create_weapon_items_filepath(current_weapon_family_as_string, weapon_id) 
	
	# ============= make dictionary from the json ==========================
	var item_weapon_as_dict: Dictionary = parse_weapon_item_info(_items_path)
	#======================================================================
	
	# Retrieve top-level dictionary stuff
	# TODO Fill unknowns with template data.
	
	var _item_icon: String = item_weapon_as_dict.get("Icon", "Unknown")
	print("Pregenerated Icon: ", _item_icon)
	weapon_table[current_table_row][4] = _item_icon
	var item_level: int = item_weapon_as_dict.get("ItemLevel", 0) #Can use for sorting
	print("Item Level: ", item_level)
	weapon_table[current_table_row][5] = item_level
	var item_quality: String = item_weapon_as_dict.get("Quality", "Unknown")
	print("Quality: ", item_quality)
	weapon_table[current_table_row][6] = item_quality
	var item_maxdurability: int = item_weapon_as_dict.get("MaxDurability", 0)
	print("Max Durability: ", item_maxdurability)
	weapon_table[current_table_row][7] = item_maxdurability
	var item_DurabilityLossOnHit: float = item_weapon_as_dict.get("DurabilityLossOnHit", 0)
	print("Durability Loss on Hit: ", item_DurabilityLossOnHit)	
	weapon_table[current_table_row][8] = item_DurabilityLossOnHit
	
	# get attack names for extracting damage from JSON
	var primary_attack_1_name: String = CurrentWeapon.primary_attack_1_name + "_Damage"
	var primary_attack_2_name: String = CurrentWeapon.primary_attack_2_name + "_Damage"
	var primary_attack_3_name: String = CurrentWeapon.primary_attack_3_name + "_Damage"
	var primary_attack_4_name: String = CurrentWeapon.primary_attack_4_name + "_Damage"
	var charged_attack_1_name: String = CurrentWeapon.charged_attack_1_name + "_Damage"
	var charged_attack_2_name: String = CurrentWeapon.charged_attack_2_name + "_Damage"
	var charged_attack_3_name: String = CurrentWeapon.charged_attack_3_name + "_Damage"
	var signature_attack_1_name: String = CurrentWeapon.signature_attack_1_name + "_Damage"
	var signature_attack_2_name: String = CurrentWeapon.signature_attack_2_name + "_Damage"
	
	# Get attack damage from deep inside dictionary by calling "extract_attack_dmg" function.
	# Necessary to check for existance to prevent errors when it isnt in the json.
	if not primary_attack_1_name.begins_with("_"):
		var primary_attack_1_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,primary_attack_1_name)
		print("DMG 1: ", primary_attack_1_dmg_physical)
		weapon_table[current_table_row][9] = primary_attack_1_dmg_physical
		
	if not primary_attack_2_name.begins_with("_"):
		var primary_attack_2_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,primary_attack_2_name)
		print("DMG 2: ", primary_attack_2_dmg_physical)
		weapon_table[current_table_row][10] = primary_attack_2_dmg_physical
		
	if not primary_attack_3_name.begins_with("_"):
		var primary_attack_3_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,primary_attack_3_name)
		print("DMG 3: ", primary_attack_3_dmg_physical)
		weapon_table[current_table_row][11] = primary_attack_3_dmg_physical
		
	if not primary_attack_4_name.begins_with("_"):
		var primary_attack_4_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,primary_attack_4_name)
		print("DMG 4: ", primary_attack_4_dmg_physical)
		weapon_table[current_table_row][12] = primary_attack_4_dmg_physical
	
	if not charged_attack_1_name.begins_with("_"):
		var charged_attack_1_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,charged_attack_1_name)
		print("CHG 1: ", charged_attack_1_dmg_physical)
		weapon_table[current_table_row][13] = charged_attack_1_dmg_physical
	
	if not charged_attack_2_name.begins_with("_"):
		var charged_attack_2_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,charged_attack_2_name)
		print("CHG 2: ", charged_attack_2_dmg_physical)
		weapon_table[current_table_row][14] = charged_attack_2_dmg_physical
	
	if not charged_attack_3_name.begins_with("_"):
		var charged_attack_3_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,charged_attack_3_name)
		print("CHG 3: ", charged_attack_3_dmg_physical)
		weapon_table[current_table_row][15] = charged_attack_3_dmg_physical
	
	if not signature_attack_1_name.begins_with("_"):
		var signature_attack_1_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,signature_attack_1_name)
		print("SIG 1: ", signature_attack_1_dmg_physical)
		weapon_table[current_table_row][16] = signature_attack_1_dmg_physical
	
	if not signature_attack_2_name.begins_with("_"):
		var signature_attack_2_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,signature_attack_2_name)
		print("SIG 2: ", signature_attack_2_dmg_physical)
		weapon_table[current_table_row][17] = signature_attack_2_dmg_physical
	
	print("")# Seperates each iteration


# Create the file path and name, so json can be loaded inside assets.zip
# Holey Canolli, it's case-sensative.
func create_weapon_items_filepath(weapon_type: String, weapon_id: String) -> String:
	var _pathstring: String = "Server/Item/Items/Weapon/" + weapon_type + "/Weapon_" + weapon_id + ".json" 
	print(_pathstring)
	return _pathstring
	
	
#Parse weapon server/item/items damage info json and turn it into a Dictionary 
func parse_weapon_item_info(file_path_inside_zip: String) -> Dictionary:
	# Read json inside zip
	var file_buffer: PackedByteArray = zip_reader.read_file(file_path_inside_zip)
	
	if file_buffer.is_empty():
		print("Failed to read file or file is empty")
		return {null:null}
	else:
		print("Successfully read file: ", file_path_inside_zip)
		# Convert Byte Array into String. utf8 for safety
		var _item_weapon_info_string: String = file_buffer.get_string_from_utf8()     # FileAccess.get_file_as_string(file_path)
		var _item_weapon_info_as_dict: Dictionary = JSON.parse_string(_item_weapon_info_string)
		return _item_weapon_info_as_dict


# json needs special treatment. all the ifs are for if a key doesn't exist in json
func extract_attack_dmg(item_weapon_as_dict:Dictionary,move_name:String) -> int:
	if "InteractionVars" not in item_weapon_as_dict:
		return 0
	if move_name not in item_weapon_as_dict.InteractionVars:
		return 0
	if "Interactions" not in item_weapon_as_dict.InteractionVars[move_name]:
		return 0
	if "DamageCalculator" not in item_weapon_as_dict.InteractionVars[move_name].Interactions[0]: # The [0] is to deal with the array inside json.
		return 0
	if "BaseDamage" not in item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator:
		return 0
	if "Physical" in item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator.BaseDamage:
		# We can finally see what kind of damage is done
		return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator.BaseDamage.Physical # Does this allow null instead of 0?
		# return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator.BaseDamage.get("Physical", 0)
	else: return 0
	
	
# Choose the location of assets.zip
func _on_button_chng_assets_location_pressed() -> void:
	
	pass # Replace with function body.
