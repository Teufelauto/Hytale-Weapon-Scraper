extends Control


var item_asset_path:String ="user://item/items/weapon/" # TODO Need to make a zip reader instead!
var save_path: String = "user://weapon_table.csv"
var zip_reader := ZIPReader.new()


var current_table_row: int = 0  # for incrementing each weapon for entry into matrix
#Determine how many rows are in the weapon_table by counting each weapon's descriptors
var total_number_of_weapons:int = WeaponShared.battleaxe.weapon_descriptor.size() + \
							WeaponShared.daggers.weapon_descriptor.size() + \
							WeaponShared.mace.weapon_descriptor.size() + \
							WeaponShared.sword.weapon_descriptor.size()
var weapon_table_width: int = 18 # columns in array. See initialize_weapon_table() for list
var weapon_table_height: int = total_number_of_weapons + 1 # Add 1 for the column headers
var weapon_table: Array[Array] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	check_if_first_load() # Creates settings file in user folder.
	# TODO:  Check if Headless from App_Settings.json, and deal with that.
	
	# TODO: Check it Asset.zip exists before trying to load
	open_assets_zip()
	
	initialize_weapon_table()
	step_through_weapons()
	print_weapon_table_to_console()
	save_array_as_csv(weapon_table, save_path)



func open_assets_zip()->void:
	var error = zip_reader.open("user://Assets.zip")
	if error != OK:
		print("Failed to open ZIP file: ", error)
		return


# Sets up app the first time it is loaded
func check_if_first_load() -> void:
	
	# Need to copy the app setttings into the user folder, 
	# so they can be edited by the user by headless method.
	var setttings_file: String = "app_settings.json"
	var not_first_time: bool = check_user_file_exists(setttings_file)
	if not_first_time: # Meaning, if the file exists in the user folder, skip all this.
		return
	else:
		var full_source: String = "res://" + setttings_file
		var full_destination: String = "user://" + setttings_file
		
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
	# Create the outer array
	for row in range(weapon_table_height):
		# Append inner arrays to form the 2D structure
		weapon_table.append([])
		for column in range(weapon_table_width):
			# Initialize each cell with a default value (e.g., 0 for an empty cell)
			weapon_table[row].append(null)
	# You can then set specific values. weapon_table[Row][Column]
	# \/\/\/\/\/\/\ Be sure weapon_table_width equals columns below! \/\/\/\/\/\/\/
	# These are the Column Headers for the table
	weapon_table[0][0] = "Item_Count"
	weapon_table[0][1] = "ID"
	weapon_table[0][2] = "Weapon"
	weapon_table[0][3] = "Descriptor"
	weapon_table[0][4] = "Pregenerated_Icon"
	weapon_table[0][5] = "Item_Level"
	weapon_table[0][6] = "Quality"
	weapon_table[0][7] = "Max_Durability"
	weapon_table[0][8] = "Durability_Loss_On_Hit"
	weapon_table[0][9] = "primary_attack_1_damage"
	weapon_table[0][10] = "primary_attack_2_damage"
	weapon_table[0][11] = "primary_attack_3_damage"
	weapon_table[0][12] = "primary_attack_4_damage"
	weapon_table[0][13] = "charged_attack_1_damage"
	weapon_table[0][14] = "charged_attack_2_damage"
	weapon_table[0][15] = "charged_attack_3_damage"
	weapon_table[0][16] = "signature_attack_1_damage"
	weapon_table[0][17] = "signature_attack_2_damage"


func print_weapon_table_to_console() -> void:
	print("")
	for row in range(weapon_table_height):
		print(weapon_table[row])
	print("")

# steps through all weapons and descriptors
func step_through_weapons() -> void:
	current_table_row = 0 #start with 0 and increment each j
	
	#select weapon class- battleaxe, dagger etc
	for i in WeaponShared.melee_weapon_shared_list:
		var CurrentWeapon: Object = i
	
		for j in CurrentWeapon.weapon_descriptor:
			current_table_row +=1
			#select weapon descriptor- crude, adamantite, etc
			var current_weapon_descriptor:String = j
			scrape_weapon(CurrentWeapon, current_weapon_descriptor)
	
# TODO Need to use TEMPLATE json for info not in individual files when exists.
func scrape_weapon(CurrentWeapon: Object,current_weapon_descriptor: String) -> void:
	#counting index for putting each item in its own row on table
	weapon_table[current_table_row][0] = current_table_row
	print(current_table_row)
	
	# for creating filepath of the item
	var current_weapon_as_string: String = CurrentWeapon.weapon
	var weapon_id: String = current_weapon_as_string + "_" + current_weapon_descriptor
	print(weapon_id)
	weapon_table[current_table_row][1] = weapon_id
	weapon_table[current_table_row][2] = current_weapon_as_string
	weapon_table[current_table_row][3] = current_weapon_descriptor
	
	var file_path: String = weapon_filepath(current_weapon_as_string, weapon_id) #need the file path and name of the current weapon
	
	# ============= make dictionary from the json ==========================
	var item_weapon_as_dict: Dictionary = parse_weapon_info(file_path)
	#======================================================================
	
	# Retrieve top-level dictionary stuff
	var item_icon: String = item_weapon_as_dict.get("Icon", "Unknown")
	print("Pregenerated Icon: ", item_icon)
	weapon_table[current_table_row][4] = item_icon
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
	
	# Get attack damage from inside an array inside dictionary by calling "extract_attack_dmg" function. (Yucky brackets inside JSON make this necessary)
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


# Create the file path and name, so json can be loaded.
func weapon_filepath(weapon_type: String, weapon_id: String) -> String:
	var _pathstring: String = item_asset_path + weapon_type + "/weapon_" + weapon_id + ".json" 
	print(_pathstring)
	return _pathstring
	
	
#Parse weapon item/items json and turn it into a Dictionary
func parse_weapon_info(file_path: String) -> Dictionary:
	var item_weapon_string: String = FileAccess.get_file_as_string(file_path)
	var item_weapon_as_dict: Dictionary = JSON.parse_string(item_weapon_string)
	return item_weapon_as_dict



#Array inside json needs special treatment. all the elses are for if key doesn't exist in json
func extract_attack_dmg(item_weapon_as_dict:Dictionary,move_name:String) -> int:
	if "InteractionVars" in item_weapon_as_dict:
		if move_name in item_weapon_as_dict.InteractionVars:
			if "Interactions" in item_weapon_as_dict.InteractionVars[move_name]:
				# Here we extract the Array from the Dictionary.
				var attack_damage_array: Array = item_weapon_as_dict.InteractionVars[move_name].Interactions
				# Here, we turn the Array index 0 into a Dictionary for accessing.
				var attack_damage_as_dict: Dictionary = attack_damage_array[0] 
				if "DamageCalculator" in attack_damage_as_dict:
					if "BaseDamage" in attack_damage_as_dict.DamageCalculator:
						if "Physical" in attack_damage_as_dict.DamageCalculator.BaseDamage:
							# We can finally see what kind of damage is done
							var attack_dmg_physical: int = attack_damage_as_dict.DamageCalculator.BaseDamage.Physical
							return attack_dmg_physical
						else: return 0
					else: return 0
				else: return 0
			else: return 0
		else: return 0
	else: return 0
	
	
# Choose the location of assets.zip
func _on_button_chng_assets_location_pressed() -> void:
	
	pass # Replace with function body.
