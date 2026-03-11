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

## This function is called from weapons class. Other functions in this class result from it.
## Important Class function for getting data out of the Items/Weapons/(family folder)/(json file)
## Current_family is the weapon family (sword etc) and current_child is "crude" or "iron" etc
func scrape_weapon_item_data(current_family: String, current_child: String, 
		current_row: int) -> void:
	## Dictionary for a singular weapon, equivalent one row in the weapon table. 
	var unique_child: Dictionary = {}
	## "Sword_Crude" or "Mace_Copper" etc
	var weapon_id: String = current_family + "_" + current_child  
	## List of columns made by the app for catagorizing data.
	var app_headers: Dictionary = {
		"item_count": current_row,
		"id": weapon_id,
		"weapon_family": current_family,
		"descriptor": current_child,
	}
	print("Processing ", current_row, ": ", weapon_id) # Display the current weapon being worked on.
	## Currently processing child read from source encyclopedia
	var item_child_dict: Dictionary = reference_encyclopedia.weapons \
			[current_family].get(current_child)
	
	## Weapon id'd as parent in the currently processing child. i.e. "Template_Weapon_Shortbow"
	var current_parent: String = item_child_dict.get("Parent", "undefined")
	update_item_parent_dictionary(current_family, current_parent)
	
	## Create weapon_table using weapon_move_Xref_dict to correlate columns with lookup.
	for current_column in weapon_table_column_array.size():
		## Dictionary of two results: { "column_header": column_header, "value": value }
		var columnheader_and_value: Dictionary = process_column(current_family,current_column, 
				item_child_dict, app_headers)
		var column_header: String = columnheader_and_value.get("column_header")
		var value: Variant = columnheader_and_value.get("value")
		
		## Assign value to Table
		weapon_table[current_row][current_column] = value
		
		## Assign value to current child dictionary, posibly in subdictionaries or arrays.
		unique_child = assign_values_to_unique_dictionary(unique_child, column_header, value)
		
	## Now that all columns are processed, add this child to the Big Dictionary under family.
	weapon_encyclopedia[current_family.to_lower()].set(current_child.to_lower(), 
			unique_child.duplicate())


## Define item_parent_dict, the Parent Dictionary to inherit from, if required.
func update_item_parent_dictionary(current_family: String, current_parent: String) -> void:
	#check if template is up to date for the current family
	if current_parent != bequeathing_parent:
		item_parent_dict = reference_encyclopedia.weapons[current_family].get(current_parent, {} )
		bequeathing_parent = current_parent


## Find one value from item_weapon_as_dict.
func process_column(current_family: String, current_column: int,  
		item_child_dict: Dictionary, app_headers: Dictionary) -> Dictionary:
	## The header that appears at the top of the Table for the column we're working on.
	var column_header: String = weapon_table_column_array[current_column]
	## PascalCase or Pascal_Snake_Case for attack moves. Loses data for back-stabbing.
	## Get the value from the intermediate dict to make the key for the item weapon dict.
	## The retrieved key is for looking inside item_weapon_as_dict to find the value for 
	## filling in the table.
	var retrieved_key: String = weapon_families_Xref_dict[current_family].get(column_header)

	## Value to be put in the Table or unique dictionary
	var value: Variant = get_key_value(item_child_dict, app_headers, retrieved_key, column_header)
	
	## Makes value integer if req. (item level, max durability, maxStack)
	## Attack functions already return as int)
	if retrieved_key in KEYS_WITH_INT_VALUES:
		value = int(value)
	
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


#region Extract values. Add elif with any new move type ============================================
## Add elif with any new move type ============================================
## Get value for the table cell
func get_key_value(item_child_dict:Dictionary, app_headers: Dictionary, key: String, 
		column_header: String) -> Variant:
	
	## Skip the moves that don't exist for this weapon.
	if key == "_Damage" :
		return ""
	
	## Check if key is one of the app-made headers.
	elif app_headers.has(key):
		return app_headers.get(key)
		
	## Check if key is in the first level inside JSON.
	elif weapon_dict.common_table_headers.find_key(key) :
		# need to retrieve from template if not in item_dict
		return common_key_in_weapon_check(item_child_dict, key)
	
	## Check if key is frontal attack damage: "primary, charged, signature"
	elif column_header.begins_with("primary_attack_") \
			or column_header.begins_with("charged_attack_") \
			or column_header.begins_with("signature_attack_"):
		var dmg: int = extract_physical_attack_dmg(item_child_dict,key)
		#print("Attack damage, or broken branch at: ", dmg)
		if dmg < 0: ## Negative value means no valid value found.
			dmg = extract_physical_attack_dmg(item_parent_dict,key) ## Inherit
		if dmg < 0: dmg = 0 ## Not in child or parent, so make it 0
		return dmg
	
	## Check if key is shooting attack damage in JSON.
	elif column_header.begins_with("shoot_"):
		var dmg: int = extract_shoot_attack_dmg(item_child_dict, key)
		if dmg < 0:
			dmg = extract_shoot_attack_dmg(item_parent_dict, key) ## Inherit
		if dmg < 0: dmg = 0 ## Not in child or parent, so make it 0
		return dmg
	
	## Check if key is random modifier to attack damage in JSON.
	elif column_header.begins_with("rand_pct_mod_"):
		var mod: float = extract_rand_physical_attack_dmg(item_child_dict, key)
		if mod < 0:
			mod = extract_rand_physical_attack_dmg(item_parent_dict, key) ## Inherit
		if mod < 0: mod = 0 ## Not in child or parent, so make it 0
		return mod
	
	## Check if key is rear attack damage in JSON.
	elif column_header.begins_with("rear_"):
		var dmg: int = extract_rear_physical_attack_dmg(item_child_dict, key)
		if dmg < 0:
			dmg = extract_rear_physical_attack_dmg(item_parent_dict, key) ## Inherit
		if dmg < 0: dmg = 0 ## Not in child or parent, so make it 0
		return dmg
	
	## Check if key is guard bash damage in JSON.
	elif column_header.begins_with("guard_"):
		var dmg: int = extract_guard_bash_dmg(item_child_dict, key)
		if dmg < 0:
			dmg = extract_guard_bash_dmg(item_parent_dict, key) ## Inherit
		if dmg < 0: dmg = 0 ## Not in child or parent, so make it 0
		return dmg
		
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
		
	elif item_parent_dict.has(key):
		return item_parent_dict.get(key)
		
	elif key == "MaxStack": ## Special case: If MaxStack is undefined, make it = 1 (unstackable)
		return 1
	else:
		print("No key, ", key, ", in weapon's json.")
		return "undefined"


## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
## Negative returns are for inheritance flow control.
func extract_physical_attack_dmg(item_weapon_as_dict:Dictionary, move_name:String) -> int:
	if not item_weapon_as_dict.has("InteractionVars"): 
		return -1
	if not item_weapon_as_dict.InteractionVars.has(move_name):
		return -2
	if not item_weapon_as_dict.InteractionVars[move_name].has("Interactions"):
		return -3
	# The [0] is to deal with the array inside json.
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].has("DamageCalculator"): 
		return -4
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator \
			.has("BaseDamage"):
		return -5
	## We can finally see what kind of damage is done.
	return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator \
			.BaseDamage.get("Physical", -6)


## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
## Negative returns are for inheritance flow control.
func extract_shoot_attack_dmg(item_weapon_as_dict:Dictionary, move_name:String) -> int:
	if not item_weapon_as_dict.has("InteractionVars"): 
		return -1
	if not item_weapon_as_dict.InteractionVars.has(move_name):
		print(move_name)
		return -2 
	if not item_weapon_as_dict.InteractionVars[move_name].has("Interactions"):
		return -3 
	# The [0] is to deal with the array inside json.
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].has("DamageCalculator"): 
		return -4 
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator \
			.has("BaseDamage"):
		return -5 
	return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator \
			.BaseDamage.get("Projectile", -6) 


## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
## Get RandomPercentageModifier Negative returns are for inheritance flow control.
func extract_rand_physical_attack_dmg(item_weapon_as_dict:Dictionary, move_name: String) -> float:
	if not item_weapon_as_dict.has("InteractionVars"): 
		return -1
	if not item_weapon_as_dict.InteractionVars.has(move_name):
		return -2
	if not item_weapon_as_dict.InteractionVars[move_name].has("Interactions"):
		return -3
	# The [0] is to deal with the array inside json.
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].has("DamageCalculator"): 
		return -4
	return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator \
			.get("RandomPercentageModifier", -5)


## Back-Stabbing Daggers get a special function. AngledDamage is the brach to follow.
## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
## Negative returns are for inheritance flow control.
func extract_rear_physical_attack_dmg(item_weapon_as_dict:Dictionary, move_name: String) -> int:
	if not item_weapon_as_dict.has("InteractionVars"): 
		return -1
	if not item_weapon_as_dict.InteractionVars.has(move_name):
		return -2
	if not item_weapon_as_dict.InteractionVars[move_name].has("Interactions"):
		return -3
	# The [0] is to deal with the array inside json.
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].has("AngledDamage"): 
		return -4
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].AngledDamage[0] \
			.has("DamageCalculator"):
		return -5
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].AngledDamage[0] \
			.DamageCalculator.has("BaseDamage"):
		return -6
	return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].AngledDamage[0] \
			.DamageCalculator.BaseDamage.get("Physical", -7)
			
## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
## Negative returns are for inheritance flow control.
func extract_guard_bash_dmg(item_weapon_as_dict:Dictionary, move_name:String) -> int:
	if not item_weapon_as_dict.has("InteractionVars"): 
		return -1
	if not item_weapon_as_dict.InteractionVars.has(move_name):
		print(move_name)
		return -2 
	if not item_weapon_as_dict.InteractionVars[move_name].has("Interactions"):
		return -3 
	# The [0] is to deal with the array inside json.
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].has("DamageCalculator"): 
		return -4 
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator \
			.has("BaseDamage"):
		return -5 
	return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator \
			.BaseDamage.get("Physical", -6) 
#endregion


#region Assembling json. Add elif for any new move type ============================================
## add elif for any new move type ============================================
## Puts the found value in the correct place inside the unique weapon dictionary.
func assign_values_to_unique_dictionary(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if key == "item_count": # We don't want Item Count in the JSON.
		return unique_child # So we skip it and go back to scrape function without assigning value.
	
	# Determine if we need to enter primary attack branch.
	if key.begins_with("primary_attack"):
		unique_child = key_begins_with_primary_attack(unique_child, key, value)
	
	# Determine if we need to enter charged branch.
	elif key.begins_with("charged_attack"):
		unique_child = key_begins_with_charged_attack(unique_child, key, value)
	
	# Determine if we need to enter signature branch.
	elif key.begins_with("signature_attack"):
		unique_child = key_begins_with_signature_attack(unique_child, key, value)
	
	# Determine if we need to make or enter rear charged branch.
	elif key.begins_with("rear_primary_attack"):
		unique_child = key_begins_with_rear_primary_attack(unique_child, key, value)
	
	# Determine if we need to make or enter rear charged branch.
	elif key.begins_with("rear_charged_attack"):
		unique_child = key_begins_with_rear_charged_attack(unique_child, key, value)
	
	# Determine if we need to make or enter rear signature branch.
	elif key.begins_with("rear_signature_attack"):
		unique_child = key_begins_with_rear_signature_attack(unique_child, key, value)
	
	elif key.begins_with("rand_pct_mod_primary_attack"):
		unique_child = key_begins_with_rand_pct_mod_primary_attack(unique_child, key, value)
	
	elif key.begins_with("rand_pct_mod_charged_attack"):
		unique_child = key_begins_with_rand_pct_mod_charged_attack(unique_child, key, value)
	
	elif key.begins_with("rand_pct_mod_signature_attack"):
		unique_child = key_begins_with_rand_pct_mod_signature_attack(unique_child, key, value)
		
	# Determine if we need to enter primary projectile attack branch.
	elif key.begins_with("shoot_primary"):
		unique_child = key_begins_with_shoot_primary_attack(unique_child, key, value)
	
	# Determine if we need to enter primary projectile attack branch.
	elif key.begins_with("shoot_signature"):
		unique_child = key_begins_with_shoot_signature_attack(unique_child, key, value)
	
	# Determine if we need to enter guard_bash branch.
	elif key.begins_with("guard_bash"):
		unique_child = key_begins_with_guard_bash_attack(unique_child, key, value)
	
	else:
		unique_child.set(key, value)
	return unique_child


## Determine data to enter primary attack branch of json.
func key_begins_with_primary_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with primary attack index in assign_values_to_unique_dictionary")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_primary_branch_if_needed(unique_child)
	if not unique_child.attack.primary.has("physical"):
		unique_child.attack.primary.set("physical", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.primary.physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.primary.physical.resize(array_min_size)
		
	unique_child.attack.primary.physical[index] = value # Assign value to array in proper order.
	return unique_child


## Determine data to enter charged attack branch of json.
func key_begins_with_charged_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with charged attack index in key_begins_with_charged_attack")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_charged_branch_if_needed(unique_child)
	if not unique_child.attack.charged.has("physical"):
		unique_child.attack.charged.set("physical", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.charged.physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.charged.physical.resize(array_min_size)
		
	unique_child.attack.charged.physical[index] = value # Assign value to array in proper order.
	return unique_child


## Determine data to enter signature attack branch of json.
func key_begins_with_signature_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with attack index in key_begins_with_signature_attack")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_signature_branch_if_needed(unique_child)
	if not unique_child.attack.signature.has("physical"):
		unique_child.attack.signature.set("physical", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.signature.physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.signature.physical.resize(array_min_size)
	
	unique_child.attack.signature.physical[index] = value # Assign value to array in proper order.
	return unique_child


## Determine data to enter rear primary attack branch of json. (Not used by daggers)
## This is a 'Just in case' function.
func key_begins_with_rear_primary_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rear primary attack index in key_begins_with_rear_primary_attack")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_charged_branch_if_needed(unique_child)
	if not unique_child.attack.primary.has("rear_physical"):
		unique_child.attack.primary.set("rear_physical", [0]) #It'll be at least 1 value
	
	## Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.primary.rear_physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.primary.rear_physical.resize(array_min_size)
		
	unique_child.attack.primary.rear_physical[index] = value # Assign value to array in proper order.
	return unique_child
	

## Determine data to enter rear charged attack branch of json.
func key_begins_with_rear_charged_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rear charged attack index in key_begins_with_rear_charged_attack")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_charged_branch_if_needed(unique_child)
	if not unique_child.attack.charged.has("rear_physical"):
		unique_child.attack.charged.set("rear_physical", [0]) #It'll be at least 1 value
	

	## Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.charged.rear_physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.charged.rear_physical.resize(array_min_size)
		
	unique_child.attack.charged.rear_physical[index] = value # Assign value to array in proper order.
	return unique_child


## Determine data to enter rear signature attack branch of json.
func key_begins_with_rear_signature_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rear signature attack index in key_begins_with_rear_signature_attack")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_signature_branch_if_needed(unique_child)
	if not unique_child.attack.signature.has("rear_physical"):
		unique_child.attack.signature.set("rear_physical", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.signature.rear_physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.signature.rear_physical.resize(array_min_size)
		
	unique_child.attack.signature.rear_physical[index] = value # Assign value to array in proper order.
	return unique_child


## Determine data to enter pct mod attack branch of json.
func key_begins_with_rand_pct_mod_primary_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rand modifier")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_primary_branch_if_needed(unique_child)
	if not unique_child.attack.primary.has("rand_pct_modifier"):
		unique_child.attack.primary.set("rand_pct_modifier", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.primary.rand_pct_modifier.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.primary.rand_pct_modifier.resize(array_min_size)
		
	unique_child.attack.primary.rand_pct_modifier[index] = value # Assign value to array in proper order.
	return unique_child


## Determine data to enter pct mod attack branch of json.
func key_begins_with_rand_pct_mod_charged_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rand modifier")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_charged_branch_if_needed(unique_child)
	if not unique_child.attack.charged.has("rand_pct_modifier"):
		unique_child.attack.charged.set("rand_pct_modifier", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.charged.rand_pct_modifier.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.charged.rand_pct_modifier.resize(array_min_size)
		
	unique_child.attack.charged.rand_pct_modifier[index] = value # Assign value to array in proper order.
	return unique_child


## Determine data to enter pct mod attack branch of json.
func key_begins_with_rand_pct_mod_signature_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with rand modifier")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_primary_branch_if_needed(unique_child)
	if not unique_child.attack.signature.has("rand_pct_modifier"):
		unique_child.attack.signature.set("rand_pct_modifier", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.signature.rand_pct_modifier.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.signature.rand_pct_modifier.resize(array_min_size)
		
	unique_child.attack.signature.rand_pct_modifier[index] = value # Assign value to array in proper order.
	return unique_child


## Determine data to enter primary attack branch of json.
func key_begins_with_shoot_primary_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with primary attack index in assign_values_to_unique_dictionary")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_primary_branch_if_needed(unique_child)
	if not unique_child.attack.primary.has("projectile"):
		unique_child.attack.primary.set("projectile", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.primary.projectile.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.primary.projectile.resize(array_min_size)
		
	unique_child.attack.primary.projectile[index] = value # Assign value to array in proper order.
	return unique_child


## Determine data to enter signature attack branch of json.
func key_begins_with_shoot_signature_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with attack index in key_begins_with_signature_attack")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_signature_branch_if_needed(unique_child)
	if not unique_child.attack.signature.has("projectile"):
		unique_child.attack.signature.set("projectile", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.signature.projectile.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.signature.projectile.resize(array_min_size)
	
	unique_child.attack.signature.projectile[index] = value # Assign value to array in proper order.
	return unique_child
	
	
	## Determine data to enter guard bash branch of json.
func key_begins_with_guard_bash_attack(unique_child: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(key)
	if index < 0:
		print("Error with guard bash index")
		return unique_child
	
	## Create branch if it doesn't exist.
	unique_child = create_attack_branch_if_needed(unique_child)
	unique_child = create_attack_guard_bash_branch_if_needed(unique_child)
	if not unique_child.attack.guard_bash.has("physical"):
		unique_child.attack.guard_bash.set("physical", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_child.attack.guard_bash.physical.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_child.attack.guard_bash.physical.resize(array_min_size)
		
	unique_child.attack.guard_bash.physical[index] = value # Assign value to array in proper order.
	return unique_child
#endregion


#region Assembling json helper functions
## Assign index of value inside array.
## Helper for key_begins_with_ group of functions.
func assign_move_index(key: String) -> int:
	# Assign impossible value so invalid key will return indication.
	var index: int = -1
	if key.contains("1"):
		index = 0
	elif key.contains("2"):
		index = 1
	elif key.contains("3"):
		index = 2
	elif key.contains("4"):
		index = 3
	elif key.contains("5"):
		index = 4
	return index


## Create 'attack' branch if it doesn't exist in weapon deictionary.
func create_attack_branch_if_needed(unique_child: Dictionary) -> Dictionary:
	if not unique_child.has("attack"):
		unique_child.set("attack", {} ) #It'll be at least 1 value
	return unique_child


## Create 'attack/primary' branch if it doesn't exist in weapon deictionary.
func create_attack_primary_branch_if_needed(unique_child: Dictionary) -> Dictionary:
	if not unique_child.attack.has("primary"):
		unique_child.attack.set("primary", {} ) #It'll be at least 1 value
	return unique_child

	
## Create 'charged' branch if it doesn't exist in weapon deictionary.
func create_attack_charged_branch_if_needed(unique_child: Dictionary) -> Dictionary:
	if not unique_child.attack.has("charged"):
		unique_child.attack.set("charged", {} ) #It'll be at least 1 value
	return unique_child


## Create 'signature' branch if it doesn't exist in weapon deictionary.
func create_attack_signature_branch_if_needed(unique_child: Dictionary) -> Dictionary:
	if not unique_child.attack.has("signature"):
		unique_child.attack.set("signature", {} ) #It'll be at least 1 value
	return unique_child


## Create 'guard_bash' branch if it doesn't exist in weapon deictionary.
func create_attack_guard_bash_branch_if_needed(unique_child: Dictionary) -> Dictionary:
	if not unique_child.attack.has("guard_bash"):
		unique_child.attack.set("guard_bash", {} ) #It'll be at least 1 value
	return unique_child
#endregion
	
		
