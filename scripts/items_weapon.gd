class_name ItemsWeapon
extends Weapons ## Allows this class to use variables from Weapons without Weapons.variable
## Item processor for each individual weapon.
##
## This class processes all it can from the "Server/Item/Items/Weapon/" folder inside Assets.zip

const KEYS_WITH_INT_VALUES: Array = [
	"ItemLevel",
	"MaxDurability",
	"MaxStack"
]

##==============================================================================
##\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
##==============================================================================

## This function is called from weapons class. Other functions in this class result from it.
## Important Class function for getting data out of the Items/Weapons/(family folder)/(json file)
## Current_family is the weapon family (sword etc) and current_child is "crude" or "iron" etc
func scrape_weapon_item_data(
		file_path: String, current_family: String, 
		current_family_lower: String, current_child: String, 
		current_child_lower: String, xref_family_tree: Dictionary, 
		xref_common_table_headers: Dictionary, current_row: int) -> void:
	
	## Dictionary for a singular weapon, equivalent one row in the weapon table. 
	var unique_weapon: Dictionary #= {
	## "Sword_Crude" or "Mace_Copper" etc
	var weapon_id: String = current_family + "_" + current_child  
	## List of columns made by the app for catagorizing data.
	var app_headers: Dictionary = {
		"item_count": current_row,
		"id": weapon_id,
		"weapon_family": current_family,
		"descriptor": current_child,
		}
	#print()# Seperates each iteration
	print(current_row, ": ", weapon_id) # Display the current weapon being worked on.
	## === Read from ZIP, a Specific Weapon Dictionary from Assets.json ===
	## JSON as Dictionary of Weapon_Sword_Crude or whatever
	var item_weapon_as_dict: Dictionary = parse_weapon_item_info(file_path)
	
	## Skip default values if "Parent" does not exist in json.
	var current_parent: String = item_weapon_as_dict.get("Parent", "undefined")
	update_common_family_dictionaries(current_family, current_parent)
	
	 ##Create weapon_table using weapon_move_Xref_dict to correlate columns with lookup.
	for current_column in weapon_table_column_array.size():
		var columnheader_value: Dictionary = process_column(current_column, 
				xref_family_tree, item_weapon_as_dict, app_headers, 
				xref_common_table_headers, current_row)
		var column_header: String = columnheader_value.get("column_header")
		var value: Variant = columnheader_value.get("value")
		#Assign value to current child dictionary, posibly in subdictionaries or arrays.
		unique_weapon = assign_values_to_unique_dictionary(unique_weapon, column_header, value)
		
	## Add this child to the Big Dictionary under family.
	weapon_encyclopedia[current_family_lower].set(current_child_lower, unique_weapon.duplicate())


## Parse weapon server/item/items damage info json and turn it into a Dictionary 
func parse_weapon_item_info(file_path: String) -> Dictionary:
	#need the file path and name of the current weapon. Holey Canolli, it's case-sensative.
	#var file_path_inside_zip: String = "Server/Item/Items/Weapon/" + weapon_family \
			#+ "/Weapon_" + weapon_id + ".json"
			
	# Read json inside zip
	var file_buffer: PackedByteArray = FileUtils.zip_reader.read_file(file_path)
	if file_buffer.is_empty():
		print("Failed to read json weapon file or file is empty")
		return { null:null }
	else:
		#print("Successfully read file: ", file_path)
		# Convert Byte Array into String. utf8 for safety
		var _item_weapon_info_string: String = file_buffer.get_string_from_utf8()# FileAccess.get_file_as_string(file_path)
		var _item_weapon_info_as_dict: Dictionary = JSON.parse_string(_item_weapon_info_string)
		return _item_weapon_info_as_dict


## If current family not current_item_template, update current_template_family and item_template_dict
func update_common_family_dictionaries(current_family: String, current_parent: String) -> void:
	#check if template is up to date for the current family
	if current_parent != current_template_parent:
		item_template_dict = parse_template_weapon_item_info(current_family, current_parent)
		current_template_parent = current_parent
	else:
		return


## Find one value from item_weapon_as_dict.
func process_column(current_column: Variant, xref_family_tree: Dictionary, 
		item_weapon_as_dict: Dictionary, app_headers: Dictionary,  
			xref_common_table_headers: Dictionary, current_row: int) -> Dictionary:
	## The header that appears at the top of the Table for the column we're working on.
	var column_header = weapon_table_column_array[current_column]
	
	## PascalCase or Pascal_Snake_Case for attack moves. Loses data for back-stabbing.
	## Get the value from the intermediate dict to make the key for the item weapon dict.
	## The retrieved key is for looking inside item_weapon_as_dict to find the value for filling in the table.
	var retrieved_key = xref_family_tree.get(column_header)

	## Value to be put in the Table or unique dictionary
	var value = get_key_value(item_weapon_as_dict, app_headers, retrieved_key, 
			xref_common_table_headers, column_header)
	
	# Makes value integer if able. (item level and max durability. 
	#Attacks functions already return int)
	if retrieved_key in KEYS_WITH_INT_VALUES:
		value = int(value)
	
	#Assign value to Table
	var column_index_string: String = weapon_dict.weapon_table_columns.find_key(column_header)
	var column_index: int = int(column_index_string) #number was string, as a key in json
	weapon_table[current_row][column_index] = value
	return { "column_header": column_header, "value": value }


## Parse Template weapon server/item/itemsinfo json and turn it into a Dictionary 
func parse_template_weapon_item_info(weapon_family: String, parent: String) -> Dictionary:
	
	if parent == "undefined":
		return { null: null }
	
	var file_path_inside_zip: String = "Server/Item/Items/Weapon/" \
			+ weapon_family + "/" + parent + ".json" 
	## Prevent error by checking if exists.
	if file_path_inside_zip not in FileUtils.zip_files:
		print("Weapon Parent file not in Assets")
		return { null: null }
	# Read json inside zip
	var file_buffer: PackedByteArray = FileUtils.zip_reader.read_file(file_path_inside_zip)
	if file_buffer.is_empty():
		print("Failed to read weapon template file or file is empty")
		return { null: null }
	else:
		#print("Successfully read file: ", file_path_inside_zip)
		## Convert Byte Array into String. utf8 for safety
		var item_weapon_info_string: String = file_buffer.get_string_from_utf8()
		var item_weapon_info_as_dict: Dictionary = JSON.parse_string(item_weapon_info_string)
		return item_weapon_info_as_dict


## Get value for the table cell
func get_key_value(item_weapon_as_dict:Dictionary, app_headers: Dictionary, key: String, 
		xref_common_table_headers: Dictionary, column_header: String) -> Variant:
	
	## Skip the moves that don't exist for this weapon.
	if key == "_Damage" :
		return ""
	
	## Check if key is one of the app-made headers.
	elif app_headers.has(key):
		return app_headers.get(key)
		
	## Check if key is in the first level inside JSON.
	elif xref_common_table_headers.find_key(key) :
		# need to retrieve from template if not in item_dict
		return common_key_in_weapon_check(item_weapon_as_dict, key)
	
	## Check if key is random modifier to attack damage in JSON.
	elif column_header.begins_with("rand_pct_mod_"):
		return extract_rand_physical_attack_dmg(item_weapon_as_dict, key)
	
	## Check if key is rear attack damage in JSON.
	elif column_header.begins_with("rear_"):
		return extract_rear_physical_attack_dmg(item_weapon_as_dict, key)
	
	## Check if key is frontal attack damage in JSON.
	elif not item_weapon_as_dict.has(key):
		return extract_physical_attack_dmg(item_weapon_as_dict,key)
	
	else:
		print("Error: Couldn't find the key value to scrape!")
		return null


## Deterimine if item weapon has key in top level. If not, tries to retrieve
## from item template.
func common_key_in_weapon_check(item_weapon_as_dict:Dictionary, key: String) -> Variant:
	# need to compare, to see if common keys are not in weapon, 
	# then check template if necessary
	
	if item_weapon_as_dict.has(key):
		return item_weapon_as_dict.get(key)
		
	elif item_template_dict.has(key):
		return item_template_dict.get(key)
		
	elif key == "MaxStack": ## Special case: If MaxStack is undefined, make it = 1 (unstackable)
		return 1
	else:
		print("No top level key, ", key, ", in weapon's json.")
		return "undefined"


## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
## This is a lot
func extract_physical_attack_dmg(item_weapon_as_dict:Dictionary, move_name:String) -> int:
	if not item_weapon_as_dict.has("InteractionVars"): 
		return 0
	if not item_weapon_as_dict.InteractionVars.has(move_name):
		return 0
	if not item_weapon_as_dict.InteractionVars[move_name].has("Interactions"):
		return 0
	# The [0] is to deal with the array inside json.
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].has("DamageCalculator"): 
		return 0
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator \
			.has("BaseDamage"):
		return 0
	
	## We can finally see what kind of damage is done.
	return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator \
			.BaseDamage.get("Physical", 0)


## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
## Get RandomPercentageModifier
func extract_rand_physical_attack_dmg(item_weapon_as_dict:Dictionary, move_name: String) -> float:
	if not item_weapon_as_dict.has("InteractionVars"): 
		return 0
	if not item_weapon_as_dict.InteractionVars.has(move_name):
		return 0
	if not item_weapon_as_dict.InteractionVars[move_name].has("Interactions"):
		return 0
	# The [0] is to deal with the array inside json.
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].has("DamageCalculator"): 
		return 0
	return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator \
			.get("RandomPercentageModifier",0)


## Back-Stabbing Daggers get a special function. AngledDamage is the brach to follow.
## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
func extract_rear_physical_attack_dmg(item_weapon_as_dict:Dictionary, move_name: String) -> int:
	if not item_weapon_as_dict.has("InteractionVars"): 
		return 0
	if not item_weapon_as_dict.InteractionVars.has(move_name):
		return 0
	if not item_weapon_as_dict.InteractionVars[move_name].has("Interactions"):
		return 0
	# The [0] is to deal with the array inside json.
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].has("AngledDamage"): 
		return 0
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].AngledDamage[0] \
			.has("DamageCalculator"):
		return 0
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].AngledDamage[0] \
			.DamageCalculator.has("BaseDamage"):
		return 0
	
	## We can finally see what kind of damage is done.
	return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].AngledDamage[0] \
			.DamageCalculator.BaseDamage.get("Physical", 0)


## Puts the found value in the correct place inside the unique weapon dictionary.
func assign_values_to_unique_dictionary(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if key == "item_count": # We don't want Item Count in the JSON.
		return unique_weapon # So we skip it and go back to scrape function without assigning value.
	
	# Determine if we need to enter primary attack branch.
	if key.begins_with("primary_attack"):
		unique_weapon = key_begins_with_primary_attack(unique_weapon, key, value)
	
	# Determine if we need to enter charged branch.
	elif key.begins_with("charged_attack"):
		unique_weapon = key_begins_with_charged_attack(unique_weapon, key, value)
	
	# Determine if we need to enter signature branch.
	elif key.begins_with("signature_attack"):
		unique_weapon = key_begins_with_signature_attack(unique_weapon, key, value)
	
	# Determine if we need to make or enter rear charged branch.
	elif key.begins_with("rear_primary_attack"):
		unique_weapon = key_begins_with_rear_primary_attack(unique_weapon, key, value)
	
	# Determine if we need to make or enter rear charged branch.
	elif key.begins_with("rear_charged_attack"):
		unique_weapon = key_begins_with_rear_charged_attack(unique_weapon, key, value)
	
	# Determine if we need to make or enter rear signature branch.
	elif key.begins_with("rear_signature_attack"):
		unique_weapon = key_begins_with_rear_signature_attack(unique_weapon, key, value)
	
	elif key.begins_with("rand_pct_mod_primary_attack"):
		unique_weapon = key_begins_with_rand_pct_mod_primary_attack(unique_weapon, key, value)
	
	elif key.begins_with("rand_pct_mod_charged_attack"):
		unique_weapon = key_begins_with_rand_pct_mod_charged_attack(unique_weapon, key, value)
	
	elif key.begins_with("rand_pct_mod_signature_attack"):
		unique_weapon = key_begins_with_rand_pct_mod_signature_attack(unique_weapon, key, value)
		
	## Recipee integration may go here.
	#elif key.begins_with("recipee"):
		#unique_weapon.set(key, value)
	else:
		unique_weapon.set(key, value)
	return unique_weapon


## Determine data to enter primary attack branch of json.
func key_begins_with_primary_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with primary attack index in assign_values_to_unique_dictionary")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	unique_weapon = create_attack_branch_if_needed(unique_weapon)
	unique_weapon = create_attack_primary_branch_if_needed(unique_weapon)
	if not unique_weapon.attack.primary.has("physical"):
		unique_weapon.attack.primary.set("physical", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.primary.physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.primary.physical.resize(array_min_size)
		
	unique_weapon.attack.primary.physical[index] = value # Assign value to array in proper order.
	return unique_weapon


## Assign index of value inside array.
## Helper for key_begins_with_ group of functions.
func assign_move_index(key: String) -> int:
	# Arbitrarily incorrect to not be valid value.
	var index: int = -1
	if key.contains("1"):
		index = 0
	elif key.contains("2"):
		index = 1
	elif key.contains("3"):
		index = 2
	elif key.contains("4"):
		index = 3
	return index


## Create 'attack' branch if it doesn't exist in weapon deictionary.
func create_attack_branch_if_needed(unique_weapon: Dictionary) -> Dictionary:
	if not unique_weapon.has("attack"):
		unique_weapon.set("attack", {} ) #It'll be at least 1 value
	return unique_weapon


## Create 'attack/primary' branch if it doesn't exist in weapon deictionary.
func create_attack_primary_branch_if_needed(unique_weapon: Dictionary) -> Dictionary:
	if not unique_weapon.attack.has("primary"):
		unique_weapon.attack.set("primary", {} ) #It'll be at least 1 value
	return unique_weapon


## Determine data to enter charged attack branch of json.
func key_begins_with_charged_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with charged attack index in key_begins_with_charged_attack")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	unique_weapon = create_attack_branch_if_needed(unique_weapon)
	unique_weapon = create_attack_charged_branch_if_needed(unique_weapon)
	if not unique_weapon.attack.charged.has("physical"):
		unique_weapon.attack.charged.set("physical", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.charged.physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.charged.physical.resize(array_min_size)
		
	unique_weapon.attack.charged.physical[index] = value # Assign value to array in proper order.
	return unique_weapon


## Create 'attack' branch if it doesn't exist in weapon deictionary.
func create_attack_charged_branch_if_needed(unique_weapon: Dictionary) -> Dictionary:
	if not unique_weapon.attack.has("charged"):
		unique_weapon.attack.set("charged", {} ) #It'll be at least 1 value
	return unique_weapon


## Determine data to enter signature attack branch of json.
func key_begins_with_signature_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with attack index in key_begins_with_signature_attack")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	unique_weapon = create_attack_branch_if_needed(unique_weapon)
	unique_weapon = create_attack_signature_branch_if_needed(unique_weapon)
	if not unique_weapon.attack.signature.has("physical"):
		unique_weapon.attack.signature.set("physical", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.signature.physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.signature.physical.resize(array_min_size)
	
	unique_weapon.attack.signature.physical[index] = value # Assign value to array in proper order.
	return unique_weapon


## Create 'attack' branch if it doesn't exist in weapon deictionary.
func create_attack_signature_branch_if_needed(unique_weapon: Dictionary) -> Dictionary:
	if not unique_weapon.attack.has("signature"):
		unique_weapon.attack.set("signature", {} ) #It'll be at least 1 value
	return unique_weapon


## Determine data to enter rear primary attack branch of json. (Not used by daggers)
## This is a 'Just in case' function.
func key_begins_with_rear_primary_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rear primary attack index in key_begins_with_rear_primary_attack")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	unique_weapon = create_attack_branch_if_needed(unique_weapon)
	unique_weapon = create_attack_charged_branch_if_needed(unique_weapon)
	if not unique_weapon.attack.primary.has("rear_physical"):
		unique_weapon.attack.primary.set("rear_physical", [0]) #It'll be at least 1 value
	

	## Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.primary.rear_physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.primary.rear_physical.resize(array_min_size)
		
	unique_weapon.attack.primary.rear_physical[index] = value # Assign value to array in proper order.
	return unique_weapon
	

## Determine data to enter rear charged attack branch of json.
func key_begins_with_rear_charged_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rear charged attack index in key_begins_with_rear_charged_attack")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	unique_weapon = create_attack_branch_if_needed(unique_weapon)
	unique_weapon = create_attack_charged_branch_if_needed(unique_weapon)
	if not unique_weapon.attack.charged.has("rear_physical"):
		unique_weapon.attack.charged.set("rear_physical", [0]) #It'll be at least 1 value
	

	## Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.charged.rear_physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.charged.rear_physical.resize(array_min_size)
		
	unique_weapon.attack.charged.rear_physical[index] = value # Assign value to array in proper order.
	return unique_weapon


## Determine data to enter rear signature attack branch of json.
func key_begins_with_rear_signature_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rear signature attack index in key_begins_with_rear_signature_attack")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	unique_weapon = create_attack_branch_if_needed(unique_weapon)
	unique_weapon = create_attack_signature_branch_if_needed(unique_weapon)
	if not unique_weapon.attack.signature.has("rear_physical"):
		unique_weapon.attack.signature.set("rear_physical", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.signature.rear_physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.signature.rear_physical.resize(array_min_size)
		
	unique_weapon.attack.signature.rear_physical[index] = value # Assign value to array in proper order.
	return unique_weapon


## Determine data to enter pct mod attack branch of json.
func key_begins_with_rand_pct_mod_primary_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rand modifier")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	unique_weapon = create_attack_branch_if_needed(unique_weapon)
	unique_weapon = create_attack_primary_branch_if_needed(unique_weapon)
	if not unique_weapon.attack.primary.has("rand_pct_modifier"):
		unique_weapon.attack.primary.set("rand_pct_modifier", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.primary.rand_pct_modifier.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.primary.rand_pct_modifier.resize(array_min_size)
		
	unique_weapon.attack.primary.rand_pct_modifier[index] = value # Assign value to array in proper order.
	return unique_weapon
	
	
	## Determine data to enter pct mod attack branch of json.
func key_begins_with_rand_pct_mod_charged_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rand modifier")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	unique_weapon = create_attack_branch_if_needed(unique_weapon)
	unique_weapon = create_attack_primary_branch_if_needed(unique_weapon)
	if not unique_weapon.attack.charged.has("rand_pct_modifier"):
		unique_weapon.attack.charged.set("rand_pct_modifier", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.charged.rand_pct_modifier.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.charged.rand_pct_modifier.resize(array_min_size)
		
	unique_weapon.attack.charged.rand_pct_modifier[index] = value # Assign value to array in proper order.
	return unique_weapon
	
	
	## Determine data to enter pct mod attack branch of json.
func key_begins_with_rand_pct_mod_signature_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rand modifier")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	unique_weapon = create_attack_branch_if_needed(unique_weapon)
	unique_weapon = create_attack_primary_branch_if_needed(unique_weapon)
	if not unique_weapon.attack.signature.has("rand_pct_modifier"):
		unique_weapon.attack.signature.set("rand_pct_modifier", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.signature.rand_pct_modifier.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.signature.rand_pct_modifier.resize(array_min_size)
		
	unique_weapon.attack.signaturery.rand_pct_modifier[index] = value # Assign value to array in proper order.
	return unique_weapon
	
	
	
		
