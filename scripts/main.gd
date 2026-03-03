extends Control
class_name Scraper
## Entry Point for App
## 
## All GUI stuff shall start here.

## Instance of App settings class.
var app := App.new()
## Instance of Weapons class.
#var wpns := Weapons.new() 


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
	
	
	get_tree().quit() # Closes app
	


func retrieve_app_settings() -> void:
	app.check_if_first_load()
	app.load_app_settings_from_json()
	app.check_for_processed_books()
	

## Call the Weapons class for each Assets.zip to be processed
func process_assets() -> void:
	
	## Process first Asset
	if not app.assets_processed[0]:
		## Open ZIP reader at Assets.zip 1 filepath
		FileUtils.open_assets_zip(App.asset_1_zip_path) 
		
		var wpns := Weapons.new() ## Instance of Weapons class.
		wpns.headless_main(1) ## Run through all the weapons to create csv and json
		
		FileUtils.zip_reader.close() # Close ZIP reader
		
	## Process second Asset
	if not app.assets_processed[1]:
		## Open ZIP reader at Assets.zip 2 filepath
		FileUtils.open_assets_zip(App.asset_2_zip_path) 
		
		var wpns := Weapons.new() ## Instance of Weapons class.
		wpns.headless_main(2) ## Run through all the weapons to create csv and json
		
		FileUtils.zip_reader.close() # Close ZIP reader


func diff_the_assets() -> void:
	
	#if FileUtils.check_os_file_exists(App.csv_1_save_path): ## Catch if no file to compare
		#DiffUtils.do_csv_based_diff(App.csv_1_save_path, App.csv_2_save_path) ## Creates Diff in csv table and as json
	#if FileUtils.check_os_file_exists(App.exported_json_1_save_path):  ## Catch if no file to compare
		#DiffUtils.do_json_based_diff(App.exported_json_1_save_path, 
				#App.exported_json_2_save_path) ## Creates Diff in hard to read json
	
	pass


	
