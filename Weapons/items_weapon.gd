extends Weapons
class_name ItemsWeapon

## JSON as Dictionary of Weapon templates
static var item_template_dict: Dictionary = {}
static var current_template_family: String

##===================================================================================================
##\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
##===================================================================================================

# current_family is the weapon family (sword etc) and current_child is "crude" or "iron" etc
static func scrape_weapon_item_data(current_family: String,current_child: String, 
		xref_family_tree: Dictionary, current_row: int) -> void:
	
	update_common_family_dictionaries(current_family)
	
	## Dictionary for a singular weapon, representing one row in the weapon table.
	var unique_weapon: Dictionary = {}
	
	## "Sword_Crude" or "Mace_Copper" etc
	var weapon_id: String = current_family + "_" + current_child  
	
	## === A Specific Weapon Dictionary from Assets.json ===
	var item_weapon_as_dict: Dictionary = parse_weapon_item_info(current_family, weapon_id)
	
	## List of columns made by the app for catagorizing data.
	var app_headers: Dictionary = {
		"Item_Count": current_row,
		"ID": weapon_id,
		"Weapon_Family": current_family,
		"Descriptor": current_child,
		}
	
	print()# Seperates each iteration
	print(current_row, ": ", weapon_id) # Display the current weapon being worked on.
	
	# Create weapon_table using weapon_move_Xref_dict to correlate columns with lookup.
	for current_column in Weapons.weapon_table_columns.size():
		
		## The header that appears at the top of the Table for the column we're working on.
		var column_header = Weapons.weapon_table_columns[current_column]
		
		## Get the value from the intermediate dict to make the key for the item weapon dict.
		## The retrieved key is for looking inside item_weapon_as_dict to find the value for filling in the table.
		var retrieved_key = xref_family_tree.get(column_header)
		
		## value to be put in the Table or unique dictionary
		var value = get_key_value(item_weapon_as_dict, app_headers, retrieved_key)
		
		#Assign value to current child dictionary.
		if column_header != "Item_Count": # We don't want Item Count in the JSON, as it is bad for comparing
			unique_weapon.set(column_header, value)
		
		#Assign value to Table
		var column_index_string: String = weapon_dict.Weapon_Table_Columns.find_key(column_header)
		var column_index: int = int(column_index_string) #number was string, as a key in json
		Weapons.weapon_table[current_row][column_index] = value
		
	## Add this child to the dictionary under family.
	weapon_compiled_dict[current_family].set(current_child, unique_weapon.duplicate())


## Get value for the table cell
static func get_key_value(item_dict: Dictionary, app_headers: Dictionary, key: String) -> Variant:
	
	## Skip the moves that don't exist for this weapon.
	if key == "_Damage" :
		return ""
	
	## Check if key is not in JSON, but is instead, one of the app-made headers.
	elif app_headers.has(key):
		return app_headers.get(key)
		
	## Check if key is in the first level inside JSON
	elif item_dict.has(key):
		return item_dict.get(key)
	
	## Check if key is Deep in JSON
	elif not item_dict.has(key):
		return extract_attack_dmg(item_dict, key)
	
	else:
		print("Error: Couldn't find the key value to scrape!")
		return null


## If current family not= current_item_template, update current_template_family and item_template_dict
static func update_common_family_dictionaries(current_family: String) -> void:
	#check if template is up to date for the current family
	if current_family != current_template_family:
		item_template_dict = parse_template_weapon_item_info(current_family)
		current_template_family = current_family


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


## Gets ZIP Reader going in this scope
static func open_assets_zip()->void:
	var error = zip_reader.open(Weapons.asset_zip_path)
	if error != OK:
		print("Failed to open ZIP file: ", error)
		return


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


## JSON needs special treatment for safety. All the ifs are for if a key doesn't exist in json.
## This is a lot, as the game is pre-release.
static func extract_attack_dmg(item_weapon_as_dict:Dictionary, move_name:String) -> int:
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


## Retrieve ItemLevel from Template
static func idk_item_level() -> int: 
	return 0 # TEMP -----------------------------------------------------------------------------------
