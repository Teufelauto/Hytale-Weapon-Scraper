class_name App
extends Object
## Class relating to user-configurable app_settings.
##
## Loads, processes, verifies, corrects, saves. Becomes source for below static vars.

## App Settings Data loaded from / saved to user://app_settings.json
static var settings:Dictionary = {}

static var asset_1_zip_path: String ## old, or previous zip
static var asset_2_zip_path: String ## the new chosen Assets.zip data source
static var exported_csv_1_save_path: String ## Output csv file path
static var exported_csv_2_save_path: String ## Output csv file path
static var exported_json_1_save_path: String ## Output json file path
static var exported_json_2_save_path: String ## Output json file path
static var diff_csv_save_path: String ## Output diff file path follows csv
static var diff_json_from_csv_save_path: String ## Output diff file path follows csv
static var diff_json_save_path: String ## Output diff file path follows json
## Build numbers in order:
## [previous_pre_release, latest_pre_release, previous_release, latest_release, user1, user2] 
static var build_numbers: Array = [0, 0, 0, 0, 0, 0]
## Names of build folders in order: "build-##"
## [previous_pre_release, latest_pre_release, previous_release, latest_release, user1, user2]
static var build_folders: Array = ["", "", "", "", "", ""]
## Type of release for adding to filenames:
## pre_release, release, user, user
static var build_type: Array = ["pre-release", "pre-release", "release", "release", "user", "user"]
## Active build folders for saving scraped tables and books.
static var active_build_folders: Array = ["", ""]
## Active build type (pre, rel, usr) for diff
static var active_build_type: Array = ["", ""]
## Active build numbers for diff
static var active_build_numbers: Array = [0, 0]
## The Assets being examined. Set by app_settings. [index of enum Assets, index of enum Assets]
static var active_assets: Array = [null, null]
## True if both exported csv and json files exist for that index. 
static var assets_processed: Array = [false, false]

## Index for build_numbers and build_folders Arrays. Also for choosing active Assets.
enum Assets { 
	PREVIOUS_PRE_RELEASE, 
	LATEST_PRE_RELEASE, 
	PREVIOUS_RELEASE, 
	LATEST_RELEASE,
	USER_DEFINED_1,
	USER_DEFINED_2,
}

enum Track { ASSETS_1, ASSETS_2,  DIFF_1, DIFF_2 }


## Sets up app the first time it is loaded by copying files to user:// and defining assets location
func check_if_first_load() -> void:
	## Need to copy the App Setttings into the user folder, 
	## so they can be edited by the user by headless method.
	var file_folder: String
	var file_short_path: String
	var full_source: String
	var full_destination: String
	var file_name: String = "app_settings.json"
	var file_exists: bool = FileUtils.check_user_file_exists(file_name)
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
		full_destination = "user://" + file_short_path
		# copy instructions to user
		var app_res := AppResources.new()
		FileUtils.save_to_txt_file(app_res.INSTRUCTIONS,full_destination)
	else:
		print("docs folder already contains Instructions.txt.")
			
	## Copy license to user so it can be read by user.
	file_folder = "docs/"
	file_name = "LICENSE.txt"
	file_short_path = file_folder + file_name
	file_exists = FileUtils.check_user_file_exists(file_short_path)
	if not file_exists: 
		full_destination = "user://" + file_short_path
		# copy license to user
		var app_res := AppResources.new()
		FileUtils.save_to_txt_file(app_res.LICENSE,full_destination)
	else:
		print("docs folder already contains LICENSE.txt.")
	
	# Create Output folder if necessary
	FileUtils.create_user_data_folder("output")
	FileUtils.create_user_data_folder("diff_results")


## The first time app_settings is created, pre-fill file-path for assets.
func first_load_auto_determine_assets_location()->void:
	## Load here so we can get default data, write over it, then save it.
	load_app_settings_from_json() 
	var hytale_roaming_folder = FileUtils.retrieve_roaming_Hytale_folder_location()
	
	## Pre-save paths. User defined pre-set to pre_release
	
	var previous_pre_release_path: String = "/install/pre-release/package/game/" \
			+ build_folders[Assets.PREVIOUS_PRE_RELEASE] + "/"
	
	settings.assets.pre_release.previous_pre_release.set("assets_path", 
			hytale_roaming_folder + previous_pre_release_path)
	
	settings.assets.user.user_defined_1.set("assets_path", 
			hytale_roaming_folder + previous_pre_release_path) 
	
	var latest_pre_release_path: String = "/install/pre-release/package/game/latest/"
	
	settings.assets.pre_release.latest_pre_release.set("assets_path", 
			hytale_roaming_folder + latest_pre_release_path)
	
	settings.assets.user.user_defined_2.set("assets_path", 
			hytale_roaming_folder + latest_pre_release_path) 
	
	var previous_release_path: String = "/install/release/package/game/" \
			+ build_folders[Assets.PREVIOUS_RELEASE] + "/"
	settings.assets.release.previous_release.set("assets_path", 
			hytale_roaming_folder + previous_release_path)
	
	var latest_release_path: String = "/install/release/package/game/latest/"
	settings.assets.release.latest_release.set("assets_path", 
			hytale_roaming_folder + latest_release_path)
	
	## We fill in the user://output/ directery path so the user is not confused by "user://"
	var output_path: String = OS.get_user_data_dir().path_join("/output/") 
	settings.output.pre_release.set("exported_json_save_path", output_path)
	settings.output.user_defined.set("exported_json_save_path", output_path)
	settings.output.release.set("exported_json_save_path", output_path)
	settings.output.pre_release.set("csv_save_path", output_path)
	settings.output.user_defined.set("csv_save_path", output_path)
	settings.output.release.set("csv_save_path", output_path)
	
	## Diff default directories now in own folder
	output_path = OS.get_user_data_dir().path_join("/diff_results/")
	settings.output.weapon_diff.set("json_path", output_path)
	settings.output.weapon_diff.set("csv_path", output_path)
	settings.output.weapon_diff.set("json_from_csv_path", output_path)
	
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
	
	refresh_assets_paths()


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
	if not settings.output.user_defined.exported_json_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.user_defined.exported_json_save_path = \
				settings.output.user_defined.exported_json_save_path + "/"
	
	if not settings.output.pre_release.exported_json_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.pre_release.exported_json_save_path = \
				settings.output.pre_release.exported_json_save_path + "/"
	
	if not settings.output.release.exported_json_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.release.exported_json_save_path = \
				settings.output.release.exported_json_save_path + "/"
	
	## csv path
	if not settings.output.user_defined.csv_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.user_defined.csv_save_path = \
				settings.output.user_defined.csv_save_path + "/"
	
	if not settings.output.pre_release.csv_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.pre_release.csv_save_path = \
				settings.output.pre_release.csv_save_path + "/"
	
	if not settings.output.release.csv_save_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.release.csv_save_path = \
				settings.output.release.csv_save_path + "/"
	
	## diff path
	if not settings.output.weapon_diff.json_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.weapon_diff.json_path = \
				settings.output.weapon_diff.json_path + "/"
	
	if not settings.output.weapon_diff.csv_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.weapon_diff.csv_path = \
				settings.output.weapon_diff.csv_path + "/"
	
	if not settings.output.weapon_diff.json_from_csv_path.ends_with("/"):
		entries_with_errors += 1
		settings.output.weapon_diff.json_from_csv_path = \
				settings.output.weapon_diff.json_from_csv_path + "/"
	
	## -- Output extensions (.csv) (.json) - Need to deal with caps
	## json extension
	if not settings.output.user_defined.exported_json_filename.ends_with(".json"):
		entries_with_errors += 1
		var filename: String = settings.output.user_defined.exported_json_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.user_defined.exported_json_filename = filename + ".json"
		## Correct the extension.
		else:
			settings.output.user_defined.set("exported_json_filename", 
					FileUtils.replace_file_extension(filename, ".json"))
	
	if not settings.output.pre_release.exported_json_filename.ends_with(".json"):
		entries_with_errors += 1
		var filename: String = settings.output.pre_release.exported_json_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.pre_release.exported_json_filename = filename + ".json"
		## Correct the extension.
		else:
			settings.output.pre_release.set("exported_json_filename", 
					FileUtils.replace_file_extension(filename, ".json"))
	
	if not settings.output.release.exported_json_filename.ends_with(".json"):
		entries_with_errors += 1
		var filename: String = settings.output.release.exported_json_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.release.exported_json_filename = filename + ".json"
		## Correct the extension.
		else:
			settings.output.release.set("exported_json_filename", 
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
	
	if not settings.output.pre_release.csv_filename.ends_with(".csv"):
		entries_with_errors += 1
		var filename: String = settings.output.pre_release.csv_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.pre_release.csv_filename = filename + ".csv"
		## Correct the extension.
		else:
			settings.output.pre_release.set("csv_filename", 
					FileUtils.replace_file_extension(filename, ".csv"))
	
	if not settings.output.release.csv_filename.ends_with(".csv"):
		entries_with_errors += 1
		var filename: String = settings.output.release.csv_filename
		
		## Add extension if missing
		if not filename.contains("."):
			settings.output.release.csv_filename = filename + ".csv"
		## Correct the extension.
		else:
			settings.output.release.set("csv_filename", 
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
	build_folders[Assets.PREVIOUS_PRE_RELEASE] = \
			"build-" + str(build_numbers[Assets.PREVIOUS_PRE_RELEASE])
	
	## LATEST_PRE_RELEASE value
	build_folders[Assets.LATEST_PRE_RELEASE] = \
			"build-" + str(build_numbers[Assets.LATEST_PRE_RELEASE])
	
	## PREVIOUS_RELEASE value
	build_folders[Assets.PREVIOUS_RELEASE] = \
			"build-" + str(build_numbers[Assets.PREVIOUS_RELEASE])
	
	## LATEST_RELEASE value
	build_folders[Assets.LATEST_RELEASE] = \
			"build-" + str(build_numbers[Assets.LATEST_RELEASE])
	
	## USER_DEFINED_1 value
	
	## Retrieved from app_settings.json for user defined. If user knows where zip came from,
	## they can choose correct type for archiving.
	
	if settings.assets.user.user_defined_1.build_type.get("pre_release", false):
		build_type[Assets.USER_DEFINED_1] = "pre-release"
	elif settings.assets.user.user_defined_1.build_type.get("release", false):
		build_type[Assets.USER_DEFINED_1] = "release"
	else: ## in settings, build_type.user:true is technically optional
		build_type[Assets.USER_DEFINED_1] = "user"
	
	build_folders[Assets.USER_DEFINED_1] = "build-" \
			+ str(build_numbers[Assets.USER_DEFINED_1])
	
	## USER_DEFINED_2 value
	if settings.assets.user.user_defined_2.build_type.get("pre_release", false):
		build_type[Assets.USER_DEFINED_2] = "pre-release"
	elif settings.assets.user.user_defined_2.build_type.get("release", false):
		build_type[Assets.USER_DEFINED_2] = "release"
	else: ## in settings, build_type.user:true
		build_type[Assets.USER_DEFINED_2] = "user"
	
	build_folders[Assets.USER_DEFINED_2] = "build-" \
			+ str(build_numbers[Assets.USER_DEFINED_2])

	print(build_folders)


## Assign load and save paths based upon data from app_settings.json
func choose_which_filepaths_to_process() -> void:
	## previous, latest, of pre or rel. Or user_defined_1 or 2
	var choice: String
	## user, pre-release or release 
	var output_choice: String
	## shortcut to get inside pre, rel, user branch
	var branch: Dictionary

	## Populate active assets array so we can know which files to scrape or diff
	for i in 2:
		# If pre-release
		if settings.assets.pre_release.previous_pre_release.scrape_assets[i]:
			branch = settings.assets.get("pre_release")
			choice = "previous_pre_release"
			output_choice = "pre_release"
			active_assets[i] = Assets.PREVIOUS_PRE_RELEASE
			active_build_type[i] = "pre"
			active_build_folders[i] = build_folders[Assets.PREVIOUS_PRE_RELEASE]
			active_build_numbers[i] = build_numbers[Assets.PREVIOUS_PRE_RELEASE]
		
		elif settings.assets.pre_release.latest_pre_release.scrape_assets[i]:
			branch = settings.assets.get("pre_release")
			choice = "latest_pre_release"
			output_choice = "pre_release"
			active_assets[i] = Assets.LATEST_PRE_RELEASE
			active_build_type[i] = "pre"
			active_build_folders[i] = build_folders[Assets.LATEST_PRE_RELEASE]
			active_build_numbers[i] = build_numbers[Assets.LATEST_PRE_RELEASE]
		
		# If Release
		elif settings.assets.release.previous_release.scrape_assets[i]:
			branch = settings.assets.get("release")
			choice = "previous_release"
			output_choice = "release"
			active_assets[i] = Assets.PREVIOUS_RELEASE
			active_build_type[i] = "rel"
			active_build_folders[i] = build_folders[Assets.PREVIOUS_RELEASE]
			active_build_numbers[i] = build_numbers[Assets.PREVIOUS_RELEASE]
		
		elif settings.assets.release.latest_release.scrape_assets[i]:
			branch = settings.assets.get("release")
			choice = "latest_release"
			output_choice = "release"
			active_assets[i] = Assets.LATEST_RELEASE
			active_build_type[i] = "rel"
			active_build_folders[i] = build_folders[Assets.LATEST_RELEASE]
			active_build_numbers[i] = build_numbers[Assets.LATEST_RELEASE]
			
		# if User defined
		elif settings.assets.user.user_defined_1.scrape_assets[i]:
			branch = settings.assets.get("user")
			choice = "user_defined_1"
			output_choice = "user_defined"
			active_assets[i] = Assets.USER_DEFINED_1
			
			if build_type[Assets.USER_DEFINED_1] == "pre-release":
				active_build_type[i] = "pre"
			elif build_type[Assets.USER_DEFINED_1] == "release":
				active_build_type[i] = "rel"
			else: ## in settings, build_type.user:true is technically optional
				active_build_type[i] = "usr"

			active_build_folders[i] = build_folders[Assets.USER_DEFINED_1]
			active_build_numbers[i] = build_numbers[Assets.USER_DEFINED_1]
		
		elif settings.assets.user.user_defined_2.scrape_assets[i]:
			branch = settings.assets.get("user")
			choice = "user_defined_2"
			output_choice = "user_defined"
			active_assets[i] = Assets.USER_DEFINED_2
			
			if build_type[Assets.USER_DEFINED_2] == "pre-release":
				active_build_type[i] = "pre"
			elif build_type[Assets.USER_DEFINED_2] == "release":
				active_build_type[i] = "rel"
			else: ## in settings, build_type.user:true is technically optional
				active_build_type[i] = "usr"
			
			active_build_folders[i] = build_folders[Assets.USER_DEFINED_2]
			active_build_numbers[i] = build_numbers[Assets.USER_DEFINED_2]
		
		## Define paths to be used.
		if i == 0:
			asset_1_zip_path = branch[choice].assets_path \
					+ branch[choice].assets_filename
			exported_csv_1_save_path = settings.output[output_choice].csv_save_path \
					+ assemble_output_filename(settings.output[output_choice].csv_filename, i)
			exported_json_1_save_path = settings.output[output_choice].exported_json_save_path \
					+ assemble_output_filename(settings.output[output_choice] \
					.exported_json_filename, i)
			
			
		else:
			asset_2_zip_path = branch[choice].assets_path \
					+ branch[choice].assets_filename
			exported_csv_2_save_path = settings.output[output_choice].csv_save_path \
					+ assemble_output_filename(settings.output[output_choice].csv_filename, i)
			exported_json_2_save_path = settings.output[output_choice].exported_json_save_path \
					+ assemble_output_filename(settings.output[output_choice] \
					.exported_json_filename, i)
	
	## saving the diffs with thier respectively formatted output.
	diff_json_save_path = settings.output.weapon_diff.json_path \
			+ assemble_output_filename(settings.output.weapon_diff.json_filename, 0, true)
			
	diff_csv_save_path = settings.output.weapon_diff.csv_path \
			+ assemble_output_filename(settings.output.weapon_diff.csv_filename, 0, true)
			
	diff_json_from_csv_save_path = settings.output.weapon_diff.json_from_csv_path \
			+ assemble_output_filename(settings.output.weapon_diff.json_from_csv_filename, 0, true)
	
	#print(active_assets)
	#print(asset_1_zip_path)
	#print(asset_2_zip_path)
	#print(exported_csv_1_save_path)
	#print(exported_json_2_save_path)
	#print(active_build_folders)
	#print(diff_csv_save_path)


## index is Asset #1 (0), or Asset #2 (1) for retrieving build folder name
## index can be whatever for a diff
func assemble_output_filename(generic_filename: String, scrape_assets_index: int, 
		is_diff: bool = false) -> String:
	
	match is_diff:
		
		## Export book (encyclopedia) filenames
		false when generic_filename.ends_with(".json"):
			return generic_filename.replacen(".json", 
					"_" + active_build_type[scrape_assets_index] +
					"_" + active_build_folders[scrape_assets_index] + ".json")
			
		false when generic_filename.ends_with(".csv"):
			return generic_filename.replacen(".csv", 
					"_" + active_build_type[scrape_assets_index] +
					"_" + active_build_folders[scrape_assets_index] + ".csv")
			
		## Diff filenames:
		true when generic_filename.ends_with(".json"):
			return generic_filename.replacen(".json", "_" 
					+ active_build_type[0] + "-" + str(active_build_numbers[0]) + "_v_" 
					+ active_build_type[1] + "-" + str(active_build_numbers[1]) + ".json")
			
		true when generic_filename.ends_with(".csv"):
			return generic_filename.replacen(".csv", "_" 
					+ active_build_type[0] + "-" + str(active_build_numbers[0]) + "_v_" 
					+ active_build_type[1] + "-" + str(active_build_numbers[1]) + ".csv")
	
	return generic_filename


## Update app_settings.json 'previous paths'.
## Refresh the previous build Assets path, in case a newwer build has replaced it.
func refresh_assets_paths() -> void:
	
	var hytale_roaming_folder = FileUtils.retrieve_roaming_Hytale_folder_location()
	
	## Load paths. ==== User defined not updated. ====
	
	var previous_pre_release_path: String = "/install/pre-release/package/game/" \
			+ build_folders[Assets.PREVIOUS_PRE_RELEASE] + "/"
	
	settings.assets.pre_release.previous_pre_release.set("assets_path", 
			hytale_roaming_folder + previous_pre_release_path)

	var previous_release_path: String = "/install/release/package/game/" \
			+ build_folders[Assets.PREVIOUS_RELEASE] + "/"
	settings.assets.release.previous_release.set("assets_path", 
			hytale_roaming_folder + previous_release_path)
	
	## Save the app settings to the user directory
	FileUtils.export_dict_to_json(settings, "user://app_settings.json")


## Check if assets have been previously processed. No need to re-aquire data we 
## already have. Saves result to assets_processed
func check_for_processed_books() -> void:
	
	var csv_exists: bool = FileUtils.check_os_file_exists(exported_csv_1_save_path)
	var json_exists: bool = FileUtils.check_os_file_exists(exported_json_1_save_path)
	
	if csv_exists and json_exists:
		assets_processed[0] = true
	else:
		assets_processed[0] = false
	
	csv_exists = FileUtils.check_os_file_exists(exported_csv_2_save_path)
	json_exists = FileUtils.check_os_file_exists(exported_json_2_save_path)
	
	if csv_exists and json_exists:
		assets_processed[1] = true
	else:
		assets_processed[1] = false
	
	
		
	
	
	
	
		
