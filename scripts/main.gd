extends Control
class_name GuiMain
## Entry Point for App
## 
## All GUI stuff shall start here.

var wpns := Weapons.new()


func _ready() -> void:
	
	#Utils.diff_compare_weapons_table() # for testing diffing
	
	
	
	wpns.check_if_first_load()
	wpns.load_app_settings_from_json()
	
	if wpns.app_settings.get("run_app_headless"):
		#main_gui.set_visible(false)
		wpns.headless_main()
		get_tree().quit() # Closes app
		
	# TODO  Check if NOT Headless from App_Settings, and deal with that in a seperate main-loop.
	else:
		print()
		#main_gui.set_visible(true)
		# wait for go from button
		# TODO Allow Edit app_settings.json in app
		## TODO if Headless=false, save_app_settings_to_json()
	
