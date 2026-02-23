class_name App
extends Object
## Class relating to user-configurable app_settings.
##
## 

## App Settings Data loaded from / saved to user://app_settings.json
static var settings:Dictionary = {} 
static var asset_zip_path: String ## the chosen Assets.zip data source
static var csv_save_path: String ## Output csv file path
static var compiled_json_save_path: String ## Output json file path
static var diff_csv_save_path: String ## Output diff file path follows csv
static var diff_json_save_path: String ## Output diff file path follows json

func _init() -> void:
	pass


## Sets up app the first time it is loaded by copying files to user:// and defining assets location
func check_if_first_load() -> void:
	# Need to copy the App Setttings into the user folder, 
	# so they can be edited by the user by headless method.
	var file_name: String = "app_settings.json"
	var file_exists: bool = FileUtils.check_user_file_exists(file_name)
	var full_source: String
	var full_destination: String
	if not file_exists: 
		full_source = "res://app_user_templates/" + file_name
		full_destination = "user://" + file_name
		
		# copy app_settings to user. This has default data.
		FileUtils.copy_file_from_source_to_destination(full_source, full_destination) 
		first_load_auto_determine_assets_location() # get target path and save path data into JSON
		
	else:
		print("User folder already contains app_settings.")
		
	# Copy Weapon Dictionary to user so it can be edited by user.
	file_name = "weapon_dictionary.json"
	file_exists = FileUtils.check_user_file_exists(file_name)
	if not file_exists: 
		full_source = "res://app_user_templates/" + file_name
		full_destination = "user://" + file_name
		FileUtils.copy_file_from_source_to_destination(full_source, full_destination) # copy weapons dictinary to user
	else:
		print("User folder already contains weapon_dictionary.")
	
	# Create Output folder if necessary
	FileUtils.create_user_data_folder("output")
	


## The first time app_settings is created, pre-fill file-path for assets.
func first_load_auto_determine_assets_location()->void:
	load_app_settings_from_json() # Load here so we can get default data, write over it, then save it.
	var hytale_roaming_folder = FileUtils.retrieve_roaming_Hytale_folder_location()
	
	## Pre-save paths
	var prerelease_path:String = "/install/pre-release/package/game/latest/"
	settings.assets.latest_prerelease.set("assets_path", hytale_roaming_folder + prerelease_path)
	settings.assets.user_defined.set("assets_path", hytale_roaming_folder + prerelease_path) # We give the user the most likely selection.
	
	var release_path = "/install/release/package/game/latest/"
	settings.assets.latest_release.set("assets_path", hytale_roaming_folder + release_path)
	
	# We fill in the user://output/ directery path so the user is not confused by "user://"
	var output_path = OS.get_user_data_dir() + "/output/"
	settings.output.latest_prerelease.set("compiled_json_save_path", output_path)
	settings.output.user_defined.set("compiled_json_save_path", output_path)
	settings.output.latest_release.set("compiled_json_save_path", output_path)
	settings.output.latest_prerelease.set("csv_save_path", output_path)
	settings.output.user_defined.set("csv_save_path", output_path)
	settings.output.latest_release.set("csv_save_path", output_path)
	
	## Save the app settings to the user directory
	FileUtils.save_dict_to_json(settings, "user://app_settings.json")


## Populate dictionary with data from the json and follow settings.
func load_app_settings_from_json() -> void:
	# Retrieve json data
	settings = FileUtils.load_json_data_to_dict("user://app_settings.json")
	verify_settings_formatting()
	choose_which_filepaths_to_process() 

## Ensure paths in app_settings.json that may have gotten tampered with by user 
## end with a slash "/". Also ensure correct file extensions.
func verify_settings_formatting() -> void:
	var entries_with_errors: int = 0 ## Increment for each error found
	
	## Assets slashes
	
	if not settings.assets.user_defined.assets_path.ends_with("/"):
		entries_with_errors += 1
		settings.assets.user_defined.assets_path = \
				settings.assets.user_defined.assets_path + "/"
	
	if not settings.assets.latest_prerelease.assets_path.ends_with("/"):
		entries_with_errors += 1
		settings.assets.latest_prerelease.assets_path = \
				settings.assets.latest_prerelease.assets_path + "/"
				
	if not settings.assets.latest_release.assets_path.ends_with("/"):
		entries_with_errors += 1
		settings.assets.latest_release.assets_path = \
				settings.assets.latest_release.assets_path + "/"
	
	
	## Output slashes
	
	if not settings.output.latest_prerelease.compiled_json_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.latest_prerelease.compiled_json_save_path = \
				settings.output.latest_prerelease.compiled_json_save_path + "/"
	
	
	
	
	
	## Output extensions - Need to deal with caps
	
	if not settings.output.latest_prerelease.compiled_json_filename.ends_with(".json"):
		entries_with_errors += 1
		settings.output.latest_prerelease.compiled_json_filename = \
				settings.output.latest_prerelease.compiled_json_filename + ".json"
	
	
	
	
	
	
	
	
	
	
	## Save changes to file if errors found.
	if entries_with_errors > 0:
		print("Corrected %d simple formatting error(s) in app_settings.json" % entries_with_errors)
		## Save the app settings to the user directory
		FileUtils.save_dict_to_json(settings, "user://app_settings.json")


## Assign load and save paths based upon data from app_settings.json
func choose_which_filepaths_to_process() -> void:
	var choice: String
	# If pre-release
	if settings.assets.latest_prerelease.get("scrape_assets"):
		choice = "latest_prerelease"
		
	# If Release
	elif settings.assets.latest_release.get("scrape_assets"):
		choice = "latest_release"
		
	# if User defined
	else:
		choice = "user_defined"
		
	asset_zip_path = settings.assets[choice].assets_path \
			+ settings.assets[choice].assets_filename
	csv_save_path = settings.output[choice].csv_save_path \
			+ settings.output[choice].csv_filename
	compiled_json_save_path = settings.output[choice].compiled_json_save_path \
			+ settings.output[choice].compiled_json_filename
	diff_csv_save_path = settings.output[choice].csv_save_path \
			+ settings.output.weapon_diff.csv_filename
	diff_json_save_path = settings.output[choice].compiled_json_save_path \
			+ settings.output.weapon_diff.json_filename
	
	
	
