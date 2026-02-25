class_name FileUtils
extends FileAccess

## Various file handling helper functions.
##
## Various static functions for loading json, csv, or saving them. This class
## helps clean up the main scripts by containing oddball functions.

static var zip_reader := ZIPReader.new()
#static var dir_a := DirAccess.new()

## Gets ZIP Reader going in this scope
static func open_assets_zip()->void:
	var error = zip_reader.open(App.asset_zip_path)
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


## Creates a copy of the weapons csv and json before they can be overwritten.
static func backup_csv_and_json(designator_for_old: String = "_old", 
		auto_save_old_csv: bool = true, auto_save_old_json: bool = true) -> void:
	## Array of arrays, so files can be cycled in for-loop
	var path_array: Array = []
	
	if auto_save_old_csv:
		## Save to var so both files can be cycled in for-loop
		path_array.append([App.diff_csv_save_path, ".csv"])
		path_array.append([App.csv_save_path, ".csv"])
	
	if auto_save_old_json:
		## Save to var so both files can be cycled in for-loop
		path_array.append([App.diff_json_save_path,".json"])
		path_array.append([App.compiled_json_save_path, ".json"])
	
	## Array filepath[0] is Sting path to file, filepath[1] is String extension.
	for filepath in path_array:
		if check_os_file_exists(filepath[0]):
			print(filepath[0] + " exists for backup.")
			
			## Looks like: _old.csv
			var constructed_suffix: String = designator_for_old + filepath[1]
			## Looks like: .../wpn_tbl_rel_old.csv
			var _previous_path: String = filepath[0].replace(filepath[1], constructed_suffix)
			
			## Rename old file if it already exists for archiving.
			if check_os_file_exists(_previous_path):
				## timestamp for renaming old file to archive.
				var date: String = Time.get_date_string_from_system()
				var time: String = Time.get_time_string_from_system()
				time = time.replace(":", ".") # Need to replace : with something else.
				## looking like: _old_2026-02-23_21.32.18.csv
				var dated_suffix: String = designator_for_old + "_" + date + "_" + time + filepath[1]
				## Path looking like: .../wpn_tbl_rel_old_2026-02-23_21.32.18.csv
				var stamped_path: String = _previous_path.replace(constructed_suffix, dated_suffix)
				
				## Copy old file to dated archive before it can be overwritten.
				copy_file_from_source_to_destination(_previous_path, stamped_path)
				
			## Copy current file to old, before it can be overwritten.
			copy_file_from_source_to_destination(filepath[0], _previous_path)
			
		else:
			print(filepath[0] + " does not exists for backup.")


static func create_user_data_folder(folder_name: String):
	
	# Construct the full path using the user:// protocol
	var dir_path = "user://" + folder_name
	
	var dir_access = DirAccess.open("user://") ## standard method

	# Check if the directory already exists
	if not dir_access.dir_exists(dir_path):
		# Create the directory and any necessary intermediate directories recursively
		var error_code = dir_access.make_dir_recursive(dir_path)
		if error_code == OK:
			print("Successfully created directory: ", dir_path)
		else:
			printerr("Failed to create directory: ", dir_path, " Error code: ", error_code)
	else:
		print("Directory already exists: ", dir_path)

## Replace the exension attached to file_name. The "." in preferred extension may
## or may not be present.
static func replace_file_extension(file_name: String, preferred_ext: String) -> String:
	
	## Strip off existing extension if so adorned.
	## count - 1 is the right index for .get_slice method.
	var count: int = file_name.get_slice_count(".") - 1 
	
	## The extension which could be any case like .ZiP
	var ext_to_snip: String = file_name.get_slice(".",count)
	 
	# strip off the extension
	file_name = file_name.rstrip(ext_to_snip) # "." remains at end
	
	# Deal with possible "." in preferred ext.
	preferred_ext = preferred_ext.trim_prefix(".")
	
	return file_name + preferred_ext ## Add the preferred extension format






	
