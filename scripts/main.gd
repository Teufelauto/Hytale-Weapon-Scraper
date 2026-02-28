extends Control
class_name Scraper
## Entry Point for App
## 
## All GUI stuff shall start here.

## Instance of App settings class.
var app := App.new()
## Instance of Weapons class.
var wpns := Weapons.new() 


func _ready() -> void:
	#print("Model name of device (mother board): " + OS.get_model_name())
	print("Operating System: " + OS.get_name() + " " + OS.get_version_alias())
	#print("CPU: " + OS.get_processor_name())
	print()
	
	retrieve_app_settings()
	
	
	##--------- JSON diffing. -------------
	
	#var differences_arr: Array = [[]]
	var json_old_path: String = "user://output/weapons_encyclopedia_pre-release_old.json"
	var differences_dict: Dictionary = DiffUtils.diff_json_compare(json_old_path, 
			App.compiled_json_save_path)
	#print(differences_dict)
	
	## Export to json.
	FileUtils.export_dict_to_json(differences_dict, "user://json_diff.json")
	
	### convert the json diff data to a table fit for easy human reading.
	#var differences_arr: Array = DiffUtils.convert_diffs_dict_to_array(differences_dict)
	### Export to csv.
	#FileUtils.export_array_as_csv(differences_arr, "user://csv_diff.csv")
	##-------------------------------------
	
	
	
	
	
	#FileUtils.open_assets_zip(App.asset_2_zip_path) # Open ZIP reader at Assets.zip filepath
	#
	#
	### Check app settings to see whether to run headless.
	#if app.settings.get("run_app_headless"):
		#
		#wpns.headless_new_main()
		#
	## TODO  Check if NOT Headless from App_Settings, and deal with that in a seperate main-loop.
	#else:
		#print("Error- Not Headless.")
		##main_gui.set_visible(true)
		## wait for go from button
		## TODO Allow Edit app_settings.json in app
		### TODO if Headless=false, save_app_settings_to_json()
	#
	#
	### After run, close up shop.
	#FileUtils.zip_reader.close() # Close ZIP reader
	
	get_tree().quit() # Closes app
	


func retrieve_app_settings() -> void:
	app.check_if_first_load()
	app.load_app_settings_from_json()
	
	



	
