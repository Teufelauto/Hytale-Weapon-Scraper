extends Control
class_name Scraper
## Entry Point for App
## 
## All GUI stuff shall start here.

## Instance of Weapons class
var wpns := Weapons.new() 
## App Settings Data loaded from / saved to user://app_settings.json
var app_settings:Dictionary = {} 
static var asset_zip_path: String # the chosen data source
static var csv_save_path: String # the chosen data output path
static var compiled_json_save_path: String # Output json file location


func _ready() -> void:
	
	check_if_first_load()
	load_app_settings_from_json()
	Utils.open_assets_zip() # Open ZIP reader at Assets.zip filepath
	
	
	if app_settings.get("run_app_headless"):
		
		wpns.headless_main()
		
	# TODO  Check if NOT Headless from App_Settings, and deal with that in a seperate main-loop.
	else:
		print("Error- Not Headless.")
		#main_gui.set_visible(true)
		# wait for go from button
		# TODO Allow Edit app_settings.json in app
		## TODO if Headless=false, save_app_settings_to_json()
	
	Utils.zip_reader.close() # Close ZIP reader
	get_tree().quit() # Closes app


## Sets up app the first time it is loaded by copying files to user:// and defining assets location
func check_if_first_load() -> void:
	# Need to copy the App Setttings into the user folder, 
	# so they can be edited by the user by headless method.
	var file_name: String = "app_settings.json"
	var file_exists: bool = Utils.check_user_file_exists(file_name)
	var full_source: String
	var full_destination: String
	if not file_exists: 
		full_source = "res://app_user_templates/" + file_name
		full_destination = "user://" + file_name
		
		# copy app_settings to user. This has default data.
		Utils.copy_file_from_source_to_destination(full_source, full_destination) 
		first_load_auto_determine_assets_location() # get target path and save path data into JSON
		
	else:
		print("User folder already contains app_settings.")
		
	# Copy Weapon Dictionary to user so it can be edited by user.
	file_name = "weapon_dictionary.json"
	file_exists = Utils.check_user_file_exists(file_name)
	if not file_exists: 
		full_source = "res://app_user_templates/" + file_name
		full_destination = "user://" + file_name
		Utils.copy_file_from_source_to_destination(full_source, full_destination) # copy weapons dictinary to user
	else:
		print("User folder already contains weapon_dictionary.")


## Populate dictionary with data from the json and follow settings.
func load_app_settings_from_json() -> void:
	# Retrieve json data
	app_settings = Utils.load_json_data_to_dict("user://app_settings.json")
	choose_which_filepaths_to_process() 


## The first time app_settings is created, pre-fill file-path for assets.
func first_load_auto_determine_assets_location()->void:
	load_app_settings_from_json() # Load here so we can get default data, write over it, then save it.
	var hytale_roaming_folder = Utils.retrieve_roaming_Hytale_folder_location()
	
	var _path:String = "/install/pre-release/package/game/latest/"
	app_settings.assets.latest_prerelease.set("assets_path", hytale_roaming_folder + _path)
	app_settings.assets.user_defined.set("assets_path", hytale_roaming_folder + _path) # We give the user the most likely selection.
	
	_path = "/install/release/package/game/latest/"
	app_settings.assets.latest_release.set("assets_path", hytale_roaming_folder + _path)
	
	# We fill in the user:// directery path so the user is not confused.
	_path = OS.get_user_data_dir() + "/"
	app_settings.output.latest_prerelease.set("compiled_json_save_path", _path)
	app_settings.output.user_defined.set("compiled_json_save_path", _path)
	app_settings.output.latest_release.set("compiled_json_save_path", _path)
	app_settings.output.latest_prerelease.set("csv_save_path", _path)
	app_settings.output.user_defined.set("csv_save_path", _path)
	app_settings.output.latest_release.set("csv_save_path", _path)
	
	## Save the app settings to the user directory
	Utils.save_dict_to_json(app_settings, "user://app_settings.json")


## Assign load and save paths based upon data from app_settings.json
func choose_which_filepaths_to_process() -> void:
	var choice: String
	# If pre-release
	if app_settings.assets.latest_prerelease.get("scrape_assets"):
		choice = "latest_prerelease"
		
	# If Release
	elif app_settings.assets.latest_release.get("scrape_assets"):
		choice = "latest_release"
		
	# if User defined
	else:
		choice = "user_defined"
		
	asset_zip_path = \
			app_settings.assets[choice].assets_path \
			+ app_settings.assets[choice].assets_filename
	csv_save_path = \
			app_settings.output[choice].csv_save_path \
			+ app_settings.output[choice].csv_filename
	compiled_json_save_path = \
			app_settings.output[choice].compiled_json_save_path \
		+ app_settings.output[choice].compiled_json_filename






	
