extends Control
class_name Scraper
## Entry Point for App
## 
## All GUI stuff shall start here.

## Instance of App settings class.
var app := App.new()


func _ready() -> void:
	#print("Model name of device (mother board): " + OS.get_model_name())
	print("Operating System: " + OS.get_name() + " " + OS.get_version_alias())
	#print("CPU: " + OS.get_processor_name())
	print()
	
	retrieve_app_settings() ## Load up all the settings saved in json
	
	## Check app settings to see whether to run headless.
	if app.settings.get("run_app_headless"):
		print()
		
		process_assets() ## Process and save books and tables.
		diff_the_assets() ## produce the diff files for selected assets.
		
	# TODO  Check if NOT Headless from App_Settings, and deal with that in a seperate main-loop.
	else:
		print("Error- Not Headless.")
		#main_gui.set_visible(true)
		
		## wait for go from button
		## TODO Allow Edit app_settings.json in app
		## TODO if Headless=false, save_app_settings_to_json()
	
	
	## After run, close up shop.
	
	app.free()
	get_tree().quit() # Closes app


func retrieve_app_settings() -> void:
	app.check_if_first_load()
	app.load_app_settings_from_json()
	app.check_for_processed_books()
	

## (Headless) Call the Weapons class for each Assets.zip to be processed
func process_assets() -> void:
	
	## Process first Asset
	if not app.assets_processed[0]:
		## Open ZIP reader at Assets.zip 1 filepath
		FileUtils.open_assets_zip(App.asset_1_zip_path) 
		
		var wpns := Weapons.new() ## Instance of Weapons class.
		wpns.headless_main(1) ## Run through all the weapons to create csv and json
		wpns.free()
		FileUtils.zip_files.clear() # Clear this so correct number of rows are in second table
		FileUtils.zip_reader.close() # Close ZIP reader
	else: 
		print(App.asset_1_zip_path + " already processed.")
		
	## Process second Asset
	if not app.assets_processed[1]:
		## Open ZIP reader at Assets.zip 2 filepath
		FileUtils.open_assets_zip(App.asset_2_zip_path) 
		
		var wpns := Weapons.new() ## Instance of Weapons class.
		wpns.headless_main(2) ## Run through all the weapons to create csv and json
		wpns.free()
		FileUtils.zip_files.clear() # No longer needed. free ram
		FileUtils.zip_reader.close() # Close ZIP reader
	else: 
		print(App.asset_2_zip_path + " already processed.")


## Compare two assets if able.
func diff_the_assets() -> void:
	
	## Catch if no csv files to compare
	if FileUtils.check_os_file_exists(App.exported_csv_1_save_path) \
			and FileUtils.check_os_file_exists(App.exported_csv_2_save_path):
		
		## Creates Diff in csv table and as json based on that table
		DiffUtils.do_csv_based_diff(App.exported_csv_1_save_path, 
				App.exported_csv_2_save_path) 
	else:
		print("No csv diff processed. Need two csv assets to compare.")
		
	## Catch if no json files to compare
	if FileUtils.check_os_file_exists(App.exported_json_1_save_path) \
			and FileUtils.check_os_file_exists(App.exported_json_2_save_path):
		
		## Creates Diff in json. Somewhat odd output is more verbose.
		DiffUtils.do_json_based_diff(App.exported_json_1_save_path, 
				App.exported_json_2_save_path) ## Creates Diff in hard to read json
	else:
		print("No json diff processed. Need two json assets to compare.")



	
