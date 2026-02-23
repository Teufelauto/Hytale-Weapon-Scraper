class_name FileUtils
extends Object
## Various file handling helper functions.
##
## Various static functions for loading json, csv, or saving them. This class
## helps clean up the main scripts by containing oddball functions.

static var zip_reader := ZIPReader.new()


## Gets ZIP Reader going in this scope
static func open_assets_zip()->void:
	var error = zip_reader.open(Scraper.asset_zip_path)
	if error != OK:
		print("Failed to open ZIP file: ", error)
		return


static func load_json_data_to_dict(load_path: String) -> Dictionary:
	var app_settings_string = FileAccess.get_file_as_string(load_path) # Retrieve json data
	return JSON.parse_string(app_settings_string) # Define Dictionary


## Load a csv file, and return it as a 2d array. Stripping header is optional.
static func load_csv_data_to_array(load_path: String, strip_header: bool = false) -> Array:
	var data: Array = []
	var file = FileAccess.open(load_path, FileAccess.READ)
	if file:
		# Optional: Read the header row first if you have one
		if strip_header:
			var _header= file.get_csv_line()
			#print("Header: ", _header)

		# Read the rest of the data
		while !file.eof_reached():
			var line_data = file.get_csv_line()
			# Ensure the line is not empty before processing
			if line_data.size() > 0 and line_data[0] != "":
				# You may need to cast string values to their correct types (int, float, bool)
				# e.g., line_data[0] = int(line_data[0])
				data.append(line_data)
		file.close()
		return data
	else:
		print("Failed to open file: ", load_path)
	return []


## Save a dictionary to a json file.
static func save_dict_to_json(dict: Dictionary, save_path: String = "user://new.json") -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(dict,"  ",false)
		file.store_line(json_string)
		file.close()
		print("Dictionary saved as json to: " + save_path)
	else:
		print("Failed to save dictionary as json.")


## Save Table Array into CSV at specified location
static func save_array_as_csv(table_data: Array, path: String = "user://new.csv") -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("Error opening file: ", FileAccess.get_open_error())
		return

	for line_data in table_data:
		# Convert each inner array/PackedStringArray to a format store_csv_line accepts
		var string_array := PackedStringArray()
		for value in line_data:
			string_array.append(str(value))
		file.store_csv_line(string_array)

	file.close()
	print("Data successfully saved to ", path)


## Returns true if the filename exists in user://  Folders can pre-pend the file_name
static func check_user_file_exists(file_name: String) -> bool:
	# Construct the full path using the 'user://' shorthand
	var path = "user://" + file_name
	
	# Check if the file exists
	if FileAccess.file_exists(path):
		print("File exists in user folder: " + path)
		return true
	else:
		print("File does not exist in user folder: " + path)
		return false


## Returns true if the path/filename exists.
static func check_os_file_exists(full_path: String) -> bool:
	
	# Check if the file exists
	if FileAccess.file_exists(full_path):
		print("File exists in folder: " + full_path)
		return true
	else:
		print("File does not exist in folder: " + full_path)
		return false


# It copies a file from an absolute source path to an absolute destination path.
# Can change name of new file.
static func copy_file_from_source_to_destination(full_source: String, 
		full_destination: String) -> void:
	# Use DirAccess.copy_absolute()
	# It copies a file from an absolute source path to an absolute destination path.
	# Note: The destination path should include the new file name.
		var error = DirAccess.copy_absolute(full_source, full_destination)
	
		if error == OK:
			print("File copied successfully to: ", full_destination)
		else:
			print("Error copying file: ", error_string(error))


## Returns folder where Hytale data lives.
static func retrieve_roaming_Hytale_folder_location() -> String:
	var path: String = OS.get_user_data_dir()
	var count: int = path.get_slice_count("/") - 1 ## count - 1 is the index for .get_slice method.
	var user_folder: String = path.get_slice("/",count) 
	path = path.rstrip(user_folder) # strip off the user's folder
	return path + "Hytale" # append the Hytale folder


## Creates a copy of the weapons csv before it can be overwritten.
static func backup_csv(auto_overwrite_old_csv: bool = true) -> void:
	
	## TODO Need to save 2nd backups with timestamp
	if auto_overwrite_old_csv:
		if check_os_file_exists(Scraper.csv_save_path):
			print("Weapon CSV exists for backup.")
			
			var new_path: String = ""
			copy_file_from_source_to_destination(Scraper.csv_save_path, new_path)
			
		else:
			print("Weapon CSV does not exists for backup.")
	else:
		print("Need logic for this. Only for gui. Headless will crush it.") #
