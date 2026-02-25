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
	print("CPU: " + OS.get_processor_name())
	print()
	
	retrieve_app_settings()
	
	FileUtils.open_assets_zip() # Open ZIP reader at Assets.zip filepath
	
	## Check app settings to see whether to run headless.
	if app.settings.get("run_app_headless"):
		
		wpns.headless_main()
		
	# TODO  Check if NOT Headless from App_Settings, and deal with that in a seperate main-loop.
	else:
		print("Error- Not Headless.")
		#main_gui.set_visible(true)
		# wait for go from button
		# TODO Allow Edit app_settings.json in app
		## TODO if Headless=false, save_app_settings_to_json()
	
	
	## After run, close up shop.
	FileUtils.zip_reader.close() # Close ZIP reader
	queue_free()
	get_tree().quit() # Closes app


func retrieve_app_settings() -> void:
	app.check_if_first_load()
	app.load_app_settings_from_json()
	
	



	
