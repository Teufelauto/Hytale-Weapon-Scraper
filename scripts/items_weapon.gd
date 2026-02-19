class_name ItemsWeapon
extends Weapons
## Processor for each individual weapon
##
## When main script needs to retrieve the values to fill the table, or json, it comes here.


const KEYS_WITH_INT_VALUES: Array = [
	"ItemLevel",
	"MaxDurability",
]

static var item_template_dict: Dictionary = {} ## JSON as Dictionary of Weapon templates
static var current_template_family: String

static var item_weapon_as_dict: Dictionary = {} ## JSON as Dictionary of Weapon

##==================================================================================================
##\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
##==================================================================================================

## Gets ZIP Reader going in this scope
static func open_assets_zip()->void:
	var error = zip_reader.open(Weapons.asset_zip_path)
	if error != OK:
		print("Failed to open ZIP file: ", error)
		return


# current_family is the weapon family (sword etc) and current_child is "crude" or "iron" etc
static func scrape_weapon_item_data(current_family: String, current_family_lower: String, 
		current_child: String, current_child_lower: String, 
		xref_family_tree: Dictionary, xref_common_table_headers: Dictionary, 
		current_row: int) -> void:
	
	## Dictionary for a singular weapon, equivalent one row in the weapon table. Becomes output json
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
	
	## === A Specific Weapon Dictionary from Assets.json ===
	item_weapon_as_dict = parse_weapon_item_info(current_family, weapon_id)
	
	update_common_family_dictionaries(current_family)
	## TODO if column not in item_weapon_as_dict, inject template value...
	
	# Create weapon_table using weapon_move_Xref_dict to correlate columns with lookup.
	for current_column in Weapons.weapon_table_column_array.size():
		
		## The header that appears at the top of the Table for the column we're working on.
		var column_header = Weapons.weapon_table_column_array[current_column]
		
		## Get the value from the intermediate dict to make the key for the item weapon dict.
		## The retrieved key is for looking inside item_weapon_as_dict to find the value for filling in the table.
		var retrieved_key = xref_family_tree.get(column_header)
		
		## value to be put in the Table or unique dictionary
		var value = get_key_value(app_headers, retrieved_key, xref_common_table_headers)
		
		# make value integer if able. (item level and max durability)
		if retrieved_key in KEYS_WITH_INT_VALUES:
			value = int(value)
		
		#Assign value to Table
		var column_index_string: String = weapon_dict.weapon_table_columns.find_key(column_header)
		var column_index: int = int(column_index_string) #number was string, as a key in json
		Weapons.weapon_table[current_row][column_index] = value
		
		#Assign value to current child dictionary, posibly in subdictionaries or arrays.
		unique_weapon = assign_values_to_unique_dictionary(unique_weapon, column_header, value)
		
	## Add this child to the dictionary under family.
	weapon_compiled_dict[current_family_lower].set(current_child_lower, unique_weapon.duplicate())


static func assign_values_to_unique_dictionary(unique_weapon: Dictionary, 
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
	
	## Recipee integration may go here.
	#elif key.begins_with("recipee"):
		#unique_weapon.set(key, value)
		
	else:
		unique_weapon.set(key, value)
	
	return unique_weapon



## Parse weapon server/item/items damage info json and turn it into a Dictionary 
static func parse_weapon_item_info(weapon_family: String, weapon_id: String) -> Dictionary:
	#need the file path and name of the current weapon. Holey Canolli, it's case-sensative.
	var file_path_inside_zip: String = "Server/Item/Items/Weapon/" + weapon_family + "/Weapon_" + weapon_id + ".json"
	# Read json inside zip
	var file_buffer: PackedByteArray = zip_reader.read_file(file_path_inside_zip)
	if file_buffer.is_empty():
		print("Failed to read file or file is empty")
		return {null:null}
	else:
		#print("Successfully read file: ", file_path_inside_zip)
		# Convert Byte Array into String. utf8 for safety
		var _item_weapon_info_string: String = file_buffer.get_string_from_utf8()     # FileAccess.get_file_as_string(file_path)
		var _item_weapon_info_as_dict: Dictionary = JSON.parse_string(_item_weapon_info_string)
		return _item_weapon_info_as_dict


## If current family not= current_item_template, update current_template_family and item_template_dict
static func update_common_family_dictionaries(current_family: String) -> void:
	#check if template is up to date for the current family
	if current_family != current_template_family:
		item_template_dict = parse_template_weapon_item_info(current_family)
		current_template_family = current_family


## Parse Template weapon server/item/itemsinfo json and turn it into a Dictionary 
static func parse_template_weapon_item_info(weapon_family: String) -> Dictionary:
	#need the file path and name of the current weapon
	var file_path_inside_zip: String = "Server/Item/Items/Weapon/" + weapon_family + "/Template_Weapon_" + weapon_family + ".json" 
	# Read json inside zip
	var file_buffer: PackedByteArray = zip_reader.read_file(file_path_inside_zip)
	if file_buffer.is_empty():
		print("Failed to read file or file is empty")
		return {null:null}
	else:
		#print("Successfully read file: ", file_path_inside_zip)
		## Convert Byte Array into String. utf8 for safety
		var _item_weapon_info_string: String = file_buffer.get_string_from_utf8()     # FileAccess.get_file_as_string(file_path)
		var _item_weapon_info_as_dict: Dictionary = JSON.parse_string(_item_weapon_info_string)
		return _item_weapon_info_as_dict


## Get value for the table cell
static func get_key_value(app_headers: Dictionary, key: String, 
		xref_common_table_headers: Dictionary) -> Variant:
	
	## Skip the moves that don't exist for this weapon.
	if key == "_Damage" :
		return ""
	
	## Check if key is one of the app-made headers.
	elif app_headers.has(key):
		return app_headers.get(key)
		
	## Check if key is in the first level inside JSON
	elif xref_common_table_headers.find_key(key) :
		# need to retrieve from template if not in item_dict
		return common_key_in_weapon_check(key)
	
	## Check if key is Deep in JSON. (Weapon damage)
	elif not item_weapon_as_dict.has(key):
		return extract_attack_dmg(key)
	
	else:
		print("Error: Couldn't find the key value to scrape!")
		return null


## Deterimine if item weapon has key in top level. If not, tries to retrieve
## from item template.
static func common_key_in_weapon_check(key: String) -> Variant:
	# need to compare, to see if common keys are not in weapon, 
	# then check template if necessary
	
	if item_weapon_as_dict.has(key):
		return item_weapon_as_dict.get(key)
	elif item_template_dict.has(key):
		return item_template_dict.get(key)
	else:
		print("No top level key, ", key, ", in weapon's json.")
		
		return "Unknown"


## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
## This is a lot
static func extract_attack_dmg(move_name:String) -> int:
	if not item_weapon_as_dict.has("InteractionVars"): 
		return 0
	if not item_weapon_as_dict.InteractionVars.has(move_name):
		return 0
	if not item_weapon_as_dict.InteractionVars[move_name].has("Interactions"):
		return 0
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].has("DamageCalculator"): # The [0] is to deal with the array inside json.
		return 0
	if not item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator.has("BaseDamage"):
		return 0
	
	## We can finally see what kind of damage is done.
	## Return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator.BaseDamage.Physical # Does this allow null instead of 0?
	return item_weapon_as_dict.InteractionVars[move_name].Interactions[0].DamageCalculator.BaseDamage.get("Physical", 0)


## Determine data to enter primary attack branch of json.
static func key_begins_with_primary_attack(unique_weapon: Dictionary, 
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
static func key_begins_with_charged_attack(unique_weapon: Dictionary, 
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
		print("Error with charged attack index in assign_values_to_unique_dictionary")
		return unique_weapon
		
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.charged.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.charged.resize(array_min_size)
		
	unique_weapon.attack.charged[index] = value # Assign value to array in proper order.
	return unique_weapon


## Determine data to enter signature attack branch of json.
static func key_begins_with_signature_attack(unique_weapon: Dictionary, 
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
		print("Error with charged attack index in assign_values_to_unique_dictionary")
		return unique_weapon
		
	# Grow array as needed for number of attacks. Changes based on weapon family.
	var array_min_size: int = index + 1
	if unique_weapon.attack.signature.size() < array_min_size:
		# Make array bigger if index is larger than array.
		unique_weapon.attack.signature.resize(array_min_size)
		
	unique_weapon.attack.signature[index] = value # Assign value to array in proper order.
	return unique_weapon
