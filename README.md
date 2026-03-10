# Hytale-Weapon-Scraper
- Turn zipped weapon assets into a JSON for easy access, and a CSV table for easy viewing.
- Compare two Game Builds of your choice for differences in weapons.
- If Hytale is not installed on machine, the app will have issues with the first run. If it creates the app_settings.json file, edit that to specify paths to your Assets.zip files.
- App may take a minute to go through the two 3 GB Assets.zip being compared with an NVME drive. It may appear frozen, but it's probably still parsing. It will save the files, and close when it's done. If running --headless in a terminal, you can see the progress as it processes each weapon.
- Produces a JSON and CSV of Weapons in a folder of your choice. Default assets path, and location of the saves can be changed to a location of your choosing by editing the app_settings.json file.

- Version 0.5.0 nests attack damage one fork higher so random damage modifier can be paraellel. Also allows other tyopes of damage beyond 'physical'.
- Version 0.4.0 saves each output with the Release/Pre-Release build-number in the filename. Compares two Assets without needing them to be reprocessed if output exists already. (Files must be in the folders identified in app_settings.json)
- More parameters will be added to output, but the goal is to not make breaking changes affecting APIs using this app.
### Example json output (with data obfuscated)
```json
{
  "sword": {
    "bronze": {
      "id": "Sword_Bronze",
      "weapon_family": "Sword",
      "descriptor": "Bronze",
      "parent": "Template_Weapon_Sword",
      "model": path,
      "texture": path,
      "icon": path,
      "item_level": int,
      "quality": string,
      "max_durability": int,
      "max_stack": 1,
      "durability_loss_on_hit": float,
      "attack": {
        "primary": {
          "physical": [
            int,
            int,
            int
          ]
        },
        "charged": {
          "physical": [
            int
          ]
        },
        "signature": {
          "physical": [
            int,
            int
          ]
        }
      }
    },  ... etc.
```
# Instructions
There is no GUI yet. It just opens a rectangle while it runs, then closes when the json and csv are written.

App creates folder:

WIN: `C:/Users/%UserName%/AppData/Roaming/Hytale-Weapon-Scraper`

LINUX:  `~/.local/share/Hytale-Weapon-Scraper`

The app creates an app_settings.json in this folder. If you want to change filenames or paths, or which version of Hytale to scrape, do it here.

## app_settings.json
The app scrapes the latest Pre-Release on your system, by default. If you wish to scrape a different version, change true to false for pre-release, and false to true for either latest release, or user_defined. Change the user_defined Assets_Path to the desired path, such as a previous version you've saved somewhere on your machine.

Values may be changed in this file to modify load-path, save-path, and filename without a GUI. run_app_headless should be set to true, because the GUI is not ready. Choose only 0ne of the assets to change to true. You can change asset path values to a different location if you wish to analyze a zip saved in a custom location. So, if you wish to analyze an older release of the Assets.zip file, you can modify the pregenerated path. All paths must use forward-slashes: ( / ). All paths must end with a forward-slash. Filenames can be whatever you like. Extensions will be added by app if forgotten.
 

Use "/" rather than "\\" in file paths, and end the path with a "/". A missed trailing slash may or may not be caught and corrected by the app.

- The JSON or CSV can be saved to a different location by changing path or name in app_settings.json. All the processed assets are saved in the `\Hytale-Weapon-Scraper\output\` folder by default. All files must be moved to the newly specified folders, if changed, to prevent reprocessing data. 
- All 3 diff files are saved in one folder named `\Hytale-Weapon-Scraper\diff_results\`. Their folders may be changed at your whim.
- The `csv_wpn_diff` is a table that can be imported into a spreadsheet. This is the easiest way for a human to view the changes at a glance, or while manually editing a wiki.
- The `json_wpn_diff` is that table turned into a cleanly formatted json.
- The `verbose_wpn_diff` is a json that explains what the diffs are, where they are, rather than just the keys and values. I'm not a fan, but someone may be able to do something progamatically with it, so it stays. Specify a garbage folder for it if you want.
  
## weapon_dictionary.json
- Editing Weapon_Dictionary.json will allow you to add new weapons or actions.
- Additional weapons are added by following the existing pattern, being very aware to match capitalization. Weapon name should be capitalized just like fond in the `Assets.zip\Server\Item\Items\Weapon`. Attack moves should be a hybrid Pascal_Snake_Case, as found in the weapon's json.

## Compiling
- Coded in Godot 4.6.1. (Because it's easy to compile.)
- Download the latest Godot 4.6.x from https://godotengine.org/
- Really, you can just open a clone of this repository in Godot 4.6.x and run it without compiling it. Exporting to an exe is done in the editor, and you simply follow the directions to download a template, and choose the target system.

