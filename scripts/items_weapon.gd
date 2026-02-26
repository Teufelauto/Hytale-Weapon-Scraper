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

##==================================================================================================
##\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
##==================================================================================================

## This function is called from weapons class. Other functions in this class result from it.
## Important Class function for getting data out of the Items/Weapons/(family folder)/(json file)
## Current_family is the weapon family (sword etc) and current_child is "crude" or "iron" etc
func scrape_weapon_item_data(file_path: String, current_family: String, 
		current_family_lower: String, current_child: String, current_child_lower: String, 
		xref_family_tree: Dictionary, xref_common_table_headers: Dictionary, 
		current_row: int) -> void:
	
	## Dictionary for a singular weapon, equivalent one row in the weapon table. Becomes output json
	## Unusual branches constructed as needed elsewhere, such as dagger rear-attack.
	var unique_weapon: Dictionary = {
		"attack":{
			"primary": [],
			"charged": [],
			"signature": [],
		},
		#"recipee":{},
	}
	
	## "Sword_Crude" or "Mace_Copper" etc
	var weapon_id: String = current_family + "_" + current_child  
	
	## List of columns made by the app for catagorizing data.
	var app_headers: Dictionary = {
		"item_count": current_row,
		"id": weapon_id,
		"weapon_family": current_family,
		"descriptor": current_child,
		}
	
	print()# Seperates each iteration
	print(current_row, ": ", weapon_id) # Display the current weapon being worked on.
	
	## === Read from ZIP, a Specific Weapon Dictionary from Assets.json ===
	item_weapon_as_dict = parse_weapon_item_info(file_path)
	
	## Skip default values if "Parent" does not exist in json.
	if item_weapon_as_dict.has("Parent"):
		update_common_family_dictionaries(current_family)
	
	 ##Create weapon_table using weapon_move_Xref_dict to correlate columns with lookup.
	for current_column in weapon_table_column_array.size():
		
		## The header that appears at the top of the Table for the column we're working on.
		var column_header = weapon_table_column_array[current_column]
		
		## PascalCase or Pascal_Snake_Case for attack moves. Loses data for back-stabbing.
		## Get the value from the intermediate dict to make the key for the item weapon dict.
		## The retrieved key is for looking inside item_weapon_as_dict to find the value for filling in the table.
		var retrieved_key = xref_family_tree.get(column_header)
		
		## ------ This is the Meat & Potatos of it ------------
		## Value to be put in the Table or unique dictionary
		var value = get_key_value(app_headers, retrieved_key, 
				xref_common_table_headers, column_header)
		
		# Makes value integer if able. (item level and max durability. 
		#Attacks functions already return int)
		if retrieved_key in KEYS_WITH_INT_VALUES:
			value = int(value)
		
		#Assign value to Table
		var column_index_string: String = weapon_dict.weapon_table_columns.find_key(column_header)
		var column_index: int = int(column_index_string) #number was string, as a key in json
		weapon_table[current_row][column_index] = value
		
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
		print("Successfully read file: ", file_path)
		# Convert Byte Array into String. utf8 for safety
		var _item_weapon_info_string: String = file_buffer.get_string_from_utf8()# FileAccess.get_file_as_string(file_path)
		var _item_weapon_info_as_dict: Dictionary = JSON.parse_string(_item_weapon_info_string)
		return _item_weapon_info_as_dict


## If current family not current_item_template, update current_template_family and item_template_dict
func update_common_family_dictionaries(current_family: String) -> void:
	#check if template is up to date for the current family
	if current_family != current_template_family:
		item_template_dict = parse_template_weapon_item_info(current_family)
		current_template_family = current_family
	else:
		return


## Parse Template weapon server/item/itemsinfo json and turn it into a Dictionary 
func parse_template_weapon_item_info(weapon_family: String) -> Dictionary:
	#need the file path and name of the current weapon
	var parent: String = item_weapon_as_dict.get("Parent")
	var file_path_inside_zip: String = "Server/Item/Items/Weapon/" \
			+ weapon_family + "/" + parent + ".json" 
	## Prevent error by checking if exists.
	if file_path_inside_zip not in FileUtils.zip_files:
		print("Weapon Template file not in Assets")
		return { null:null }
	# Read json inside zip
	var file_buffer: PackedByteArray = FileUtils.zip_reader.read_file(file_path_inside_zip)
	if file_buffer.is_empty():
		print("Failed to read weapon template file or file is empty")
		return { null:null }
	else:
		#print("Successfully read file: ", file_path_inside_zip)
		## Convert Byte Array into String. utf8 for safety
		var _item_weapon_info_string: String = file_buffer.get_string_from_utf8()
		var _item_weapon_info_as_dict: Dictionary = JSON.parse_string(_item_weapon_info_string)
		return _item_weapon_info_as_dict


## Get value for the table cell
func get_key_value(app_headers: Dictionary, key: String, 
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
		return common_key_in_weapon_check(key)
	
	## Check if key is rear attack damage in JSON.
	elif column_header.begins_with("rear_"):
		return extract_rear_attack_dmg(key)
	
	## Check if key is frontal attack damage in JSON.
	elif not item_weapon_as_dict.has(key):
		return extract_attack_dmg(key)
	
	else:
		print("Error: Couldn't find the key value to scrape!")
		return null


## Deterimine if item weapon has key in top level. If not, tries to retrieve
## from item template.
func common_key_in_weapon_check(key: String) -> Variant:
	# need to compare, to see if common keys are not in weapon, 
	# then check template if necessary
	
	if item_weapon_as_dict.has(key):
		return item_weapon_as_dict.get(key)
	elif item_template_dict.has(key) and not item_weapon_as_dict.has("Parent"): ## Deal with non-parented children.
		return item_template_dict.get(key)
	elif key == "MaxStack": ## Special case: If MaxStack is undefined, make it = 1 (unstackable)
		return 1
	else:
		print("No top level key, ", key, ", in weapon's json.")
		return "undefined"


## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
## This is a lot
func extract_attack_dmg(move_name:String) -> int:
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


## Back-Stabbing Daggers get a special function. AngledDamage is the brach to follow.
## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
func extract_rear_attack_dmg(move_name:String) -> int:
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
	elif key.begins_with("rear_charged_attack"):
		unique_weapon = key_begins_with_rear_charged_attack(unique_weapon, key, value)
	
	# Determine if we need to make or enter rear signature branch.
	elif key.begins_with("rear_signature_attack"):
		unique_weapon = key_begins_with_rear_signature_attack(unique_weapon, key, value)
	
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
	var index: int
	# Assign index of value inside array.
	if key.contains("1"):
		index = 0
	elif key.contains("2"):
		index = 1
	elif key.contains("3"):
		index = 2
	elif key.contains("4"):
		index = 3
	else :
		print("Error with primary attack index in  assign_values_to_unique_dictionary")
		return unique_weapon
		
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.primary.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.primary.resize(array_min_size)
		
	unique_weapon.attack.primary[index] = value # Assign value to array in proper order.
	return unique_weapon


## Determine data to enter charged attack branch of json.
func key_begins_with_charged_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int
	# Assign index of value inside array.
	if key.contains("1"):
		index = 0
	elif key.contains("2"):
		index = 1
	elif key.contains("3"):
		index = 2
	elif key.contains("4"):
		index = 3
	else :
		print("Error with charged attack index in key_begins_with_charged_attack")
		return unique_weapon
		
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.charged.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.charged.resize(array_min_size)
		
	unique_weapon.attack.charged[index] = value # Assign value to array in proper order.
	return unique_weapon


## Determine data to enter signature attack branch of json.
func key_begins_with_signature_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int
	# Assign index of value inside array.
	if key.contains("1"):
		index = 0
	elif key.contains("2"):
		index = 1
	elif key.contains("3"):
		index = 2
	elif key.contains("4"):
		index = 3
	else :
		print("Error with attack index in key_begins_with_signature_attack")
		return unique_weapon
		
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.signature.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.signature.resize(array_min_size)
		
	unique_weapon.attack.signature[index] = value # Assign value to array in proper order.
	return unique_weapon


## Determine data to enter rear charged attack branch of json.
func key_begins_with_rear_charged_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int
	# Assign index of value inside array.
	if key.contains("1"):
		index = 0
	elif key.contains("2"):
		index = 1
	elif key.contains("3"):
		index = 2
	elif key.contains("4"):
		index = 3
	else :
		print("Error with rear charged attack index in key_begins_with_rear_charged_attack")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	if not unique_weapon.attack.has("rear_charged"):
		unique_weapon.attack.set("rear_charged", [0]) #It'll be at least 1 value
		
	## Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.rear_charged.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.rear_charged.resize(array_min_size)
		
	unique_weapon.attack.rear_charged[index] = value # Assign value to array in proper order.
	return unique_weapon


## Determine data to enter rear signature attack branch of json.
func key_begins_with_rear_signature_attack(unique_weapon: Dictionary, 
		key: String, value: Variant) -> Dictionary:
	
	if value is String: # We don't need to add to array, as move does not exist.
		return unique_weapon
	
	## Index of the move within array, such as attack 1 would index to 0
	var index: int
	# Assign index of value inside array.
	if key.contains("1"):
		index = 0
	elif key.contains("2"):
		index = 1
	elif key.contains("3"):
		index = 2
	elif key.contains("4"):
		index = 3
	else :
		print("Error with rear signature attack index in key_begins_with_rear_signature_attack")
		return unique_weapon
	
	## Create branch if it doesn't exist.
	if not unique_weapon.attack.has("rear_signature"):
		unique_weapon.attack.set("rear_signature", [0]) #It'll be at least 1 value
	
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.rear_signature.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.rear_signature.resize(array_min_size)
		
	unique_weapon.attack.rear_signature[index] = value # Assign value to array in proper order.
	return unique_weapon
