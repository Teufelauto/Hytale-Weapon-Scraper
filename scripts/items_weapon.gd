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
		
		var passed_data: Dictionary = { 
			"unique_child": unique_child, 
			"key": column_header, 
			"value": value,
		}
		## Assign value to current child dictionary, posibly in subdictionaries or arrays.
		unique_child = assign_values_to_unique_dictionary(passed_data)
		
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
			or column_header.begins_with("signature_attack_") \
			or column_header.begins_with("shoot_") \
			or column_header.begins_with("guard_"):
		var dmg: int = extract_physical_attack_dmg(item_child_dict,key)
		#print("Attack damage, or broken branch at: ", dmg)
		if dmg < 0: ## Negative value means no valid value found.
			dmg = extract_physical_attack_dmg(item_parent_dict,key) ## Inherit
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

#endregion

#region Assembling json. Add elif for any new move type ============================================
## add elif for any new move type ============================================   
##		unique_child: Dictionary, key: String, value: Variant
## Puts the found value in the correct place inside the unique weapon dictionary.
func assign_values_to_unique_dictionary(passed_data: Dictionary) -> Dictionary:
	
	if passed_data.key == "item_count": # We don't want Item Count in the JSON.
		return passed_data.get("unique_child") # So we skip it and go back to scrape function without assigning value.
	
	# Determine if we need to enter primary attack branch.
	if passed_data.key.begins_with("primary_attack"):
		passed_data.unique_child = enter_attack_value(passed_data, "primary", "physical")
	
	# Determine if we need to enter charged branch.
	elif passed_data.key.begins_with("charged_attack"):
		passed_data.unique_child = enter_attack_value(passed_data,  "charged", "physical")
	
	# Determine if we need to enter signature branch.
	elif passed_data.key.begins_with("signature_attack"):
		passed_data.unique_child = enter_attack_value(passed_data,  "signature", "physical")
	
	# Determine if we need to make or enter rear charged branch.
	elif passed_data.key.begins_with("rear_primary_attack"):
		passed_data.unique_child = enter_attack_value(passed_data,  "primary", "rear_physical")
	
	# Determine if we need to make or enter rear charged branch.
	elif passed_data.key.begins_with("rear_charged_attack"):
		passed_data.unique_child = enter_attack_value(passed_data,  "charged", "rear_physical")
	
	## Determine if we need to make or enter rear signature branch.
	elif passed_data.key.begins_with("rear_signature_attack"):
		passed_data.unique_child = enter_attack_value(passed_data,  "signature", "rear_physical")
	
	elif passed_data.key.begins_with("rand_pct_mod_primary_attack"):
		passed_data.unique_child = enter_attack_value(passed_data,  "primary", "rand_pct_modifier")
	
	elif passed_data.key.begins_with("rand_pct_mod_charged_attack"):
		passed_data.unique_child = enter_attack_value(passed_data,  "charged", "rand_pct_modifier")
	
	elif passed_data.key.begins_with("rand_pct_mod_signature_attack"):
		passed_data.unique_child = enter_attack_value(passed_data,  "signature", "rand_pct_modifier")
		
	# Determine if we need to enter primary projectile attack branch.
	elif passed_data.key.begins_with("shoot_primary"):
		passed_data.unique_child = enter_attack_value(passed_data,  "primary", "projectile")
		
	# Determine if we need to enter charged projectile attack branch.
	elif passed_data.key.begins_with("shoot_charged"):
		passed_data.unique_child = enter_attack_value(passed_data,  "charged", "projectile")
		
	# Determine if we need to enter signature projectile attack branch.
	elif passed_data.key.begins_with("shoot_signature"):
		passed_data.unique_child = enter_attack_value(passed_data,  "signature", "projectile")
	
	# Determine if we need to enter guard_bash branch.
	elif passed_data.key.begins_with("guard_bash"):
		passed_data.unique_child = enter_attack_value(passed_data,  "guard_bash", "physical")
	
	else:
		passed_data.unique_child.set(passed_data.key, passed_data.value)
	return passed_data.unique_child


## Determine data to enter primary attack branch of json.
func enter_attack_value(passed_data: Dictionary, sub: String, type: String ) -> Dictionary:
	# passed_data = {unique_child: Dictionary, key: String, value: Variant}
	if passed_data.value is String: # We don't need to add to array, as move does not exist.
		return passed_data.unique_child
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int = assign_move_index(passed_data.key)
	if index < 0:
		print("Error with attack index in assign_values_to_unique_dictionary")
		return passed_data.unique_child
	
	## Create branch if it doesn't exist.
	passed_data.unique_child = create_attack_branch_if_needed(passed_data.unique_child)
	passed_data.unique_child = create_attack_sub_branch_if_needed(passed_data.unique_child, sub)
	if not passed_data.unique_child.attack[sub].has(type):
		passed_data.unique_child.attack[sub].set(type, [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if passed_data.unique_child.attack[sub][type].size() < array_min_size:
		# Make array bigger if index is larger than array.
		passed_data.unique_child.attack[sub][type].resize(array_min_size)
		
	passed_data.unique_child.attack[sub][type][index] = passed_data.value # Assign value to array in proper order.
	return passed_data.unique_child


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


## Create 'attack/primary etc' branch if it doesn't exist in weapon deictionary.
func create_attack_sub_branch_if_needed(unique_child: Dictionary, branch_name: String) -> Dictionary:
	if not unique_child.attack.has(branch_name):
		unique_child.attack.set(branch_name, {} ) #It'll be at least 1 value
	return unique_child

#endregion
	
	
	
		
