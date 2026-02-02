extends Control


var current_table_row: int = 0  # for incrementing each weapon for enttry into matrix
var rows_in_array:int = WeaponShared.battleaxe.weapon_descriptor.size() + \
							WeaponShared.daggers.weapon_descriptor.size() + \
							WeaponShared.mace.weapon_descriptor.size() + \
							WeaponShared.sword.weapon_descriptor.size()
var grid_width: int = 18 # columns in array
var grid_height: int = rows_in_array + 1
var grid: Array[Array] = []

var save_path: String = "user://weapon_table.csv"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_grid()
	select_weapon()
	print_grid_to_console()
	save_array_as_csv(grid, save_path)

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


func initialize_grid() -> void:
	# Create the outer array
	for row in range(grid_height):
		# Append inner arrays to form the 2D structure
		grid.append([])
		for column in range(grid_width):
			# Initialize each cell with a default value (e.g., 0 for an empty cell)
			grid[row].append(null)
	# You can then set specific values. grid[Row][Column]
	# \/\/\/\/\/\/\ Be sure grid_width equals columns below! \/\/\/\/\/\/\/
	grid[0][0] = "Item_Count"
	grid[0][1] = "ID"
	grid[0][2] = "Weapon"
	grid[0][3] = "Descriptor"
	grid[0][4] = "Pregenerated_Icon"
	grid[0][5] = "Item_Level"
	grid[0][6] = "Quality"
	grid[0][7] = "Max_Durability"
	grid[0][8] = "Durability_Loss_On_Hit"
	grid[0][9] = "primary_attack_1_damage"
	grid[0][10] = "primary_attack_2_damage"
	grid[0][11] = "primary_attack_3_damage"
	grid[0][12] = "primary_attack_4_damage"
	grid[0][13] = "charged_attack_1_damage"
	grid[0][14] = "charged_attack_2_damage"
	grid[0][15] = "charged_attack_3_damage"
	grid[0][16] = "signature_attack_1_damage"
	grid[0][17] = "signature_attack_2_damage"


func print_grid_to_console() -> void:
	print("")
	for row in range(grid_height):
		print(grid[row])
	print("")

# steps through all weapons and descriptors
func select_weapon() -> void:
	current_table_row = 0 #start with 0 and increment each j
	
	#select weapon class- battleaxe, dagger etc
	for i in WeaponShared.melee_weapon_shared_list:
		var CurrentWeapon: Object = i
	
		for j in CurrentWeapon.weapon_descriptor:
			current_table_row +=1
			#select weapon descriptor- crude, adamantite, etc
			var current_weapon_descriptor:String = j
			scrape_weapon(CurrentWeapon, current_weapon_descriptor)
	

func scrape_weapon(CurrentWeapon: Object,current_weapon_descriptor: String) -> void:
	#counting index for table
	grid[current_table_row][0] = current_table_row
	print(current_table_row)
	
	# for creating filepath 
	var current_weapon_as_string: String = CurrentWeapon.weapon
	var weapon_id: String = current_weapon_as_string + "_" + current_weapon_descriptor
	print(weapon_id)
	grid[current_table_row][1] = weapon_id
	grid[current_table_row][2] = current_weapon_as_string
	grid[current_table_row][3] = current_weapon_descriptor
	
	var file_path: String = weapon_filepath(current_weapon_as_string, weapon_id) #need the file path and name of the current weapon
	
	# =============make dictionary from the json ==========================
	var item_weapon_as_dict: Dictionary = parse_weapon_info(file_path)
	
	# Retrieve top-level dictionary stuff
	var item_icon: String = item_weapon_as_dict.get("Icon", "Unknown")
	print("Pregenerated Icon: ", item_icon)
	grid[current_table_row][4] = item_icon
	var item_level: int = item_weapon_as_dict.get("ItemLevel", 0) #Can use for sorting
	print("Item Level: ", item_level)
	grid[current_table_row][5] = item_level
	var item_quality: String = item_weapon_as_dict.get("Quality", "Unknown")
	print("Quality: ", item_quality)
	grid[current_table_row][6] = item_quality
	var item_maxdurability: int = item_weapon_as_dict.get("MaxDurability", 0)
	print("Max Durability: ", item_maxdurability)
	grid[current_table_row][7] = item_maxdurability
	var item_DurabilityLossOnHit: float = item_weapon_as_dict.get("DurabilityLossOnHit", 0)
	print("Durability Loss on Hit: ", item_DurabilityLossOnHit)	
	grid[current_table_row][8] = item_DurabilityLossOnHit
	
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
	
	# Get attack damage from inside an array inside dictionary. (Yucky brackets inside JSON)
	if not primary_attack_1_name.begins_with("_"):
		var primary_attack_1_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,primary_attack_1_name)
		print("DMG 1: ", primary_attack_1_dmg_physical)
		grid[current_table_row][9] = primary_attack_1_dmg_physical
		
	if not primary_attack_2_name.begins_with("_"):
		var primary_attack_2_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,primary_attack_2_name)
		print("DMG 2: ", primary_attack_2_dmg_physical)
		grid[current_table_row][10] = primary_attack_2_dmg_physical
		
	if not primary_attack_3_name.begins_with("_"):
		var primary_attack_3_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,primary_attack_3_name)
		print("DMG 3: ", primary_attack_3_dmg_physical)
		grid[current_table_row][11] = primary_attack_3_dmg_physical
		
	if not primary_attack_4_name.begins_with("_"):
		var primary_attack_4_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,primary_attack_4_name)
		print("DMG 4: ", primary_attack_4_dmg_physical)
		grid[current_table_row][12] = primary_attack_4_dmg_physical
	
	if not charged_attack_1_name.begins_with("_"):
		var charged_attack_1_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,charged_attack_1_name)
		print("CHG 1: ", charged_attack_1_dmg_physical)
		grid[current_table_row][13] = charged_attack_1_dmg_physical
	
	if not charged_attack_2_name.begins_with("_"):
		var charged_attack_2_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,charged_attack_2_name)
		print("CHG 2: ", charged_attack_2_dmg_physical)
		grid[current_table_row][14] = charged_attack_2_dmg_physical
	
	if not charged_attack_3_name.begins_with("_"):
		var charged_attack_3_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,charged_attack_3_name)
		print("CHG 3: ", charged_attack_3_dmg_physical)
		grid[current_table_row][15] = charged_attack_3_dmg_physical
	
	if not signature_attack_1_name.begins_with("_"):
		var signature_attack_1_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,signature_attack_1_name)
		print("SIG 1: ", signature_attack_1_dmg_physical)
		grid[current_table_row][16] = signature_attack_1_dmg_physical
	
	if not signature_attack_2_name.begins_with("_"):
		var signature_attack_2_dmg_physical: int = extract_attack_dmg(item_weapon_as_dict,signature_attack_2_name)
		print("SIG 2: ", signature_attack_2_dmg_physical)
		grid[current_table_row][17] = signature_attack_2_dmg_physical
	
	print("")# Seperates each iteration


# Create the file path and name, so json can be loaded.
func weapon_filepath(weapon_type: String, weapon_id: String) -> String:
	var _pathstring: String = "user://item/items/weapon/" + weapon_type + "/weapon_" + weapon_id + ".json" 
	print(_pathstring)
	return _pathstring
	
	
#Parse weapon info json
func parse_weapon_info(file_path: String) -> Dictionary:
	var item_weapon_string: String = FileAccess.get_file_as_string(file_path)
	var item_weapon_as_dict: Dictionary = JSON.parse_string(item_weapon_string)
	return item_weapon_as_dict



#Array inside json needs special treatment
func extract_attack_dmg(item_weapon_as_dict:Dictionary,move_name:String) -> int:
	if "InteractionVars" in item_weapon_as_dict:
		if move_name in item_weapon_as_dict.InteractionVars:
			if "Interactions" in item_weapon_as_dict.InteractionVars[move_name]:
				var attack_damage_array: Array = item_weapon_as_dict.InteractionVars[move_name].Interactions
				var attack_damage_as_dict: Dictionary = attack_damage_array[0]
				if "DamageCalculator" in attack_damage_as_dict:
					if "BaseDamage" in attack_damage_as_dict.DamageCalculator:
						if "Physical" in attack_damage_as_dict.DamageCalculator.BaseDamage:
							var attack_dmg_physical: int = attack_damage_as_dict.DamageCalculator.BaseDamage.Physical
							return attack_dmg_physical
						else: return 0
					else: return 0
				else: return 0
			else: return 0
		else: return 0
	else: return 0
	
	
	
	
	
	

	
	
	
	
	
	
