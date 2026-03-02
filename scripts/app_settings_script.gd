class_name App
extends Object
## Class relating to user-configurable app_settings.
##
## Loads, processes, verifies, corrects, saves. Becomes source for below static vars.

## App Settings Data loaded from / saved to user://app_settings.json
static var settings:Dictionary = {}
## [previous_pre_release, latest_pre_release, previous_release, latest_release] build numbers.
static var build_numbers: Array[int] = [0, 0, 0, 0]
static var build_folders: Array = ["", "", "", ""]
static var asset_1_zip_path: String ## old, or previous zip
static var asset_2_zip_path: String ## the new chosen Assets.zip data source

static var csv_save_path: String ## Output csv file path
static var compiled_json_save_path: String ## Output json file path
static var diff_csv_save_path: String ## Output diff file path follows csv
static var diff_json_from_csv_save_path: String ## Output diff file path follows csv
static var diff_json_save_path: String ## Output diff file path follows json

enum { PREVIOUS_PRE_RELEASE, LATEST_PRE_RELEASE, PREVIOUS_RELEASE, LATEST_RELEASE }

## Sets up app the first time it is loaded by copying files to user:// and defining assets location
func check_if_first_load() -> void:
	## Need to copy the App Setttings into the user folder, 
	## so they can be edited by the user by headless method.
	var file_folder: String
	var file_name: String = "app_settings.json"
	var file_short_path: String
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
		
	## Copy Weapon Dictionary to user so it can be edited by user.
	file_name = "weapon_dictionary.json"
	file_exists = FileUtils.check_user_file_exists(file_name)
	if not file_exists: 
		full_source = "res://app_user_templates/" + file_name
		full_destination = "user://" + file_name
		# copy weapons dictinary to user
		FileUtils.copy_file_from_source_to_destination(full_source, full_destination) 
	else:
		print("User folder already contains weapon_dictionary.")
	
	# Create documentation folder if necessary
	FileUtils.create_user_data_folder("docs")
	
	## Copy Instructions to user so it can be read by user.
	file_folder = "docs/"
	file_name = "Instructions.txt"
	file_short_path = file_folder + file_name
	file_exists = FileUtils.check_user_file_exists(file_short_path)
	if not file_exists: 
		full_source = "res://" + file_name
		full_destination = "user://" + file_short_path
		# copy instructions to user
		FileUtils.copy_file_from_source_to_destination(full_source, full_destination) 
	else:
		print("docs folder already contains Instructions.txt.")
		
	## Copy readme markdown to user so it can be read by user.
	file_folder = "docs/"
	file_name = "README.md"
	file_short_path = file_folder + file_name
	file_exists = FileUtils.check_user_file_exists(file_short_path)
	if not file_exists: 
		full_source = "res://" + file_name
		full_destination = "user://" + file_short_path
		# copy instructions to user
		FileUtils.copy_file_from_source_to_destination(full_source, full_destination) 
	else:
		print("docs folder already contains Instructions.txt.")
	
	## Copy license to user so it can be read by user.
	file_folder = "docs/"
	file_name = "LICENSE.txt"
	file_short_path = file_folder + file_name
	file_exists = FileUtils.check_user_file_exists(file_short_path)
	if not file_exists: 
		full_source = "res://" + file_name
		full_destination = "user://" + file_short_path
		# copy instructions to user
		FileUtils.copy_file_from_source_to_destination(full_source, full_destination) 
	else:
		print("docs folder already contains LICENSE.txt.")
	
	# Create Output folder if necessary
	FileUtils.create_user_data_folder("output")


## The first time app_settings is created, pre-fill file-path for assets.
func first_load_auto_determine_assets_location()->void:
	load_app_settings_from_json() # Load here so we can get default data, write over it, then save it.
	var hytale_roaming_folder = FileUtils.retrieve_roaming_Hytale_folder_location()
	
	## Pre-save paths. User defined pre-set to pre_release
	
	var latest_pre_release_path:String = "/install/pre-release/package/game/latest/"
	settings.assets.pre_release.latest_pre_release.set("assets_path", hytale_roaming_folder + latest_pre_release_path)
	settings.assets.user.user_defined_2.set("assets_path", hytale_roaming_folder + latest_pre_release_path) # We give the user the most likely selection.
	
	## TODO determine previous version number to create path for pre_release
	
	
	var release_path = "/install/release/package/game/latest/"
	settings.assets.release.latest_release.set("assets_path", hytale_roaming_folder + release_path)
	
	## TODO determine previous version number to create path for release
	
	
	# We fill in the user://output/ directery path so the user is not confused by "user://"
	var output_path = OS.get_user_data_dir() + "/output/"
	settings.output.latest_pre_release.set("compiled_json_save_path", output_path)
	settings.output.user_defined.set("compiled_json_save_path", output_path)
	settings.output.latest_release.set("compiled_json_save_path", output_path)
	settings.output.latest_pre_release.set("csv_save_path", output_path)
	settings.output.user_defined.set("csv_save_path", output_path)
	settings.output.latest_release.set("csv_save_path", output_path)
	
	## Save the app settings to the user directory
	FileUtils.export_dict_to_json(settings, "user://app_settings.json")


## Populate dictionary with data from the json and follow settings.
func load_app_settings_from_json() -> void:
	# Retrieve app settings from json
	settings = FileUtils.load_json_data_to_dict("user://app_settings.json")
	
	verify_settings_formatting()
	
	## Determine build numbers currently installed on system.
	build_numbers = FileUtils.determine_assets_builds()
	
	convert_build_numbers_to_names()
	
	choose_which_filepaths_to_process() 


## Ensure paths in app_settings.json that may have gotten tampered with by user 
## end with a slash "/". Also ensure correct file extensions.
func verify_settings_formatting() -> void:
	var entries_with_errors: int = 0 ## Increment for each error found
	
	## -- Assets slashes
	for key in ["user_defined_1","user_defined_2"]:
		if not settings.assets.user[key].assets_path.ends_with("/"):
			entries_with_errors += 1
			settings.assets.user[key].assets_path = \
					settings.assets.user[key].assets_path + "/"
	
	for key in ["latest_pre_release","previous_pre_release"]:
		if not settings.assets.pre_release[key].assets_path.ends_with("/"):
			entries_with_errors += 1
			settings.assets.pre_release[key].assets_path = \
					settings.assets.pre_release[key].assets_path + "/"
	
	for key in ["latest_release","previous_release"]:
		if not settings.assets.release[key].assets_path.ends_with("/"):
			entries_with_errors += 1
			settings.assets.release[key].assets_path = \
					settings.assets.release[key].assets_path + "/"
			
	## -- Assets extensions (.zip)
	
	## User defined filename
	for key in ["user_defined_1","user_defined_2"]:
		if not settings.assets.user[key].assets_filename.ends_with(".zip"):
			entries_with_errors += 1
			var filename: String = settings.assets.user[key].assets_filename
			
			## Add extension if missing
			if not filename.contains("."):
				settings.assets.user[key].assets_filename = filename + ".zip"
			
			else:
				## Change file name anyway. it NEEDS to be a zip for rest of code to work.
				settings.assets.user[key].assets_filename = \
						FileUtils.replace_file_extension(filename, ".zip")
				print(key + " Assets filename in app_settings.json is not a zip: " + filename)
	
	## Pre-Release filename
	for key in ["latest_pre_release","previous_pre_release"]:
		if not settings.assets.pre_release[key].assets_filename.ends_with(".zip"):
			entries_with_errors += 1
			var filename: String = settings.assets.pre_release[key].assets_filename
			
			## Add extension if missing
			if not filename.containsn("."):
				settings.assets.pre_release[key].assets_filename = filename + ".zip"
			
			### Correct the extension if .ZIP, or .Zip etc.
			#elif filename.containsn(".zip"):
				#settings.assets.pre_release[key].set("assets_filename", 
						#FileUtils.replace_file_extension(filename, ".zip"))
			else:
				## Change file name anyway. it NEEDS to be a zip for rest of code to work.
				settings.assets.pre_release[key].set("assets_filename", 
						FileUtils.replace_file_extension(filename, ".zip"))
				print(key + " Assets filename in app_settings.json is not a zip: " + filename)
	
	## Release filename
	for key in ["latest_release","previous_release"]:
		if not settings.assets.release[key].assets_filename.ends_with(".zip"):
			entries_with_errors += 1
			var filename: String = settings.assets.release[key].assets_filename
			
			## Add extension if missing
			if not filename.containsn("."):
				settings.assets.release[key].assets_filename = filename + ".zip"
			
			### Correct the extension if .ZIP, or .Zip etc.
			#elif filename.containsn(".zip"):
				#settings.assets.release[key].set("assets_filename", 
						#FileUtils.replace_file_extension(filename, ".zip"))
			else:
				## Change file name anyway. it NEEDS to be a zip for rest of code to work.
				settings.assets.release[key].set("assets_filename", 
						FileUtils.replace_file_extension(filename, ".zip"))
				print(key + " Assets filename in app_settings.json is not a zip: " + filename)
	
	## -- Output slashes
	## json path
	if not settings.output.user_defined.compiled_json_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.user_defined.compiled_json_save_path = \
				settings.output.user_defined.compiled_json_save_path + "/"
	
	if not settings.output.latest_pre_release.compiled_json_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.latest_pre_release.compiled_json_save_path = \
				settings.output.latest_pre_release.compiled_json_save_path + "/"
	
	if not settings.output.latest_release.compiled_json_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.latest_release.compiled_json_save_path = \
				settings.output.latest_release.compiled_json_save_path + "/"
	
	## csv path
	if not settings.output.user_defined.csv_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.user_defined.csv_save_path = \
				settings.output.user_defined.csv_save_path + "/"
	
	if not settings.output.latest_pre_release.csv_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.latest_pre_release.csv_save_path = \
				settings.output.latest_pre_release.csv_save_path + "/"
	
	if not settings.output.latest_release.csv_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.latest_release.csv_save_path = \
				settings.output.latest_release.csv_save_path + "/"
	
	## -- Output extensions (.csv) (.json) - Need to deal with caps
	## json extension
	if not settings.output.user_defined.compiled_json_filename.ends_with(".json"):
		entries_with_errors += 1
		var filename: String = settings.output.user_defined.compiled_json_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.user_defined.compiled_json_filename = filename + ".json"
		## Correct the extension.
		else:
			settings.output.user_defined.set("compiled_json_filename", 
					FileUtils.replace_file_extension(filename, ".json"))
	
	if not settings.output.latest_pre_release.compiled_json_filename.ends_with(".json"):
		entries_with_errors += 1
		var filename: String = settings.output.latest_pre_release.compiled_json_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.latest_pre_release.compiled_json_filename = filename + ".json"
		## Correct the extension.
		else:
			settings.output.latest_pre_release.set("compiled_json_filename", 
					FileUtils.replace_file_extension(filename, ".json"))
	
	if not settings.output.latest_release.compiled_json_filename.ends_with(".json"):
		entries_with_errors += 1
		var filename: String = settings.output.latest_release.compiled_json_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.latest_release.compiled_json_filename = filename + ".json"
		## Correct the extension.
		else:
			settings.output.latest_release.set("compiled_json_filename", 
					FileUtils.replace_file_extension(filename, ".json"))
	
	## csv extension
	if not settings.output.user_defined.csv_filename.ends_with(".csv"):
		entries_with_errors += 1
		var filename: String = settings.output.user_defined.csv_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.user_defined.csv_filename = filename + ".csv"
		## Correct the extension.
		else:
			settings.output.user_defined.set("csv_filename", 
					FileUtils.replace_file_extension(filename, ".csv"))
	
	if not settings.output.latest_pre_release.csv_filename.ends_with(".csv"):
		entries_with_errors += 1
		var filename: String = settings.output.latest_pre_release.csv_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.latest_pre_release.csv_filename = filename + ".csv"
		## Correct the extension.
		else:
			settings.output.latest_pre_release.set("csv_filename", 
					FileUtils.replace_file_extension(filename, ".csv"))
	
	if not settings.output.latest_release.csv_filename.ends_with(".csv"):
		entries_with_errors += 1
		var filename: String = settings.output.latest_release.csv_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.latest_release.csv_filename = filename + ".csv"
		## Correct the extension.
		else:
			settings.output.latest_release.set("csv_filename", 
					FileUtils.replace_file_extension(filename, ".csv"))
	
	## -- Weapon diff
	if not settings.output.weapon_diff.json_filename.ends_with(".json"):
		entries_with_errors += 1
		var filename: String = settings.output.weapon_diff.json_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.weapon_diff.json_filename = filename + ".json"
		## Correct the extension.
		else:
			settings.output.weapon_diff.set("json_filename", 
					FileUtils.replace_file_extension(filename, ".json"))
	
	if not settings.output.weapon_diff.csv_filename.ends_with(".csv"):
		entries_with_errors += 1
		var filename: String = settings.output.weapon_diff.csv_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.weapon_diff.csv_filename = filename + ".csv"
		## Correct the extension.
		else:
			settings.output.weapon_diff.set("csv_filename", 
					FileUtils.replace_file_extension(filename, ".csv"))
	
	if not settings.output.weapon_diff.json_from_csv_filename.ends_with(".json"):
		entries_with_errors += 1
		var filename: String = settings.output.weapon_diff.json_from_csv_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.weapon_diff.json_from_csv_filename = filename + ".json"
		## Correct the extension.
		else:
			settings.output.weapon_diff.set("json_from_csv_filename", 
					FileUtils.replace_file_extension(filename, ".json"))
	
	## Save changes to file if errors found.
	if entries_with_errors > 0:
		print("Corrected %d simple formatting error(s) in app_settings.json" % entries_with_errors)
		## Save the app settings to the user directory
		FileUtils.export_dict_to_json(settings, "user://app_settings.json")


func convert_build_numbers_to_names() -> void:
	## PREVIOUS_PRE_RELEASE value
	build_folders[PREVIOUS_PRE_RELEASE] = "build-" + str(build_numbers[PREVIOUS_PRE_RELEASE])
	
	## LATEST_PRE_RELEASE value
	build_folders[LATEST_PRE_RELEASE] = "build-" + str(build_numbers[LATEST_PRE_RELEASE])
	
	## PREVIOUS_RELEASE value
	build_folders[PREVIOUS_RELEASE] = "build-" + str(build_numbers[PREVIOUS_RELEASE])
	
	## LATEST_RELEASE value
	build_folders[LATEST_RELEASE] = "build-" + str(build_numbers[LATEST_RELEASE])
	
	#print(build_folders)


## Assign load and save paths based upon data from app_settings.json
func choose_which_filepaths_to_process() -> void:
	var choice: String
	var branch: Dictionary
	# If pre-release
	if settings.assets.pre_release.latest_pre_release.get("scrape_assets"):
		branch = settings.assets.get("pre_release")
		choice = "latest_pre_release"
		
	# If Release
	elif settings.assets.latest_release.get("scrape_assets"):
		branch = settings.assets.get("release")
		choice = "latest_release"
		
	# if User defined
	else:
		branch = settings.assets.get("user")
		choice = "user_defined_2"
		
	asset_2_zip_path = branch[choice].assets_path \
			+ branch[choice].assets_filename
	csv_save_path = settings.output[choice].csv_save_path \
			+ settings.output[choice].csv_filename
	compiled_json_save_path = settings.output[choice].compiled_json_save_path \
			+ settings.output[choice].compiled_json_filename
	
	## saving the diffs with thier respectively formatted output.
	diff_json_save_path = settings.output[choice].compiled_json_save_path \
			+ settings.output.weapon_diff.json_filename
	diff_csv_save_path = settings.output[choice].csv_save_path \
			+ settings.output.weapon_diff.csv_filename
	diff_json_from_csv_save_path = settings.output[choice].csv_save_path \
			+ settings.output.weapon_diff.json_from_csv_filename
	
