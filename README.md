# Hytale-Weapon-Scraper
Turn zipped weapon assets into a JSON for easy access, and a CSV table for easy viewing.
App takes several seconds to go through the 3 GB Assets.zip on a 9800x3D computer with an NVME drive. It may appear frozen, but it's probably still parsing. It will close when it's done.
Produces a JSON and CSV of Weapons in a folder of your choice. Default assets path, and location of the saves can be changed to a location of your choosing by editing the app_settings.json file.
### Example json output
```json
{
  "battleaxe": {
    "adamantite": {
      "attack": {
        "primary": [
          integer,
          integer,
          integer
        ],
        "charged": [
          integer
        ],
        "signature": [
          integer
        ]
      },
      "id": "Battleaxe_Adamantite",
      "weapon_family": "Battleaxe",
      "descriptor": "Adamantite",
      "model": String,
      "texture": String,
      "icon": String,
      "item_level": integer,
      "quality": String,
      "max_durability": integer,
      "durability_loss_on_hit": float
    },
    "cobalt": { ... etc.
```
# Instructions
There is no GUI yet. It just opens a rectangle while it runs, then closes when the json and csv are written.

App creates folder:

WIN: C:/Users/%UserName%/AppData/Roaming/Hytale-Weapon-Scraper

LINUX:  ~/.local/share/Hytale-Weapon-Scraper

The app creates an app_settings.json in this folder. If you want to change filenames or paths, or which version of Hytale to scrape, do it here.

## app_settings.json
The app scrapes the latest Pre-Release on your system, by default. If you wish to scrape a different version, change true to false for pre-release, and false to true for either latest release, or user_defined. Change the user_defined Assets_Path to the desired path, such as a previous version.

Values may be changed in this file to modify load-path, save-path, and filename without a GUI. run_app_headless should be set to true, because the GUI is not ready. Choose only 0ne of the assets to change to true. You can change asset path values to a different location if you wish to analyze a zip saved in a custom location. So, if you wish to analyze an older release of the Assets.zip file, you can modify the pregenerated path. All paths must use forward-slashes: ( / ). All paths must end with a forward-slash. Filenames can be whatever you like.
 

Use "/" rather than "\\" in file paths, and end the path with a "/".

The JSON or CSV can be saved to a different location by changing path or name in app_settings.json
## weapon_dictionary.json
Editing Weapon_Dictionary.json will allow you to add new weapons or materials, or remove certain columns from the output. That would require a tutorial. Additional weapons are being configured. Still need to add info to table from another location in the zip, regarding attack timing. That will come after this section is working nicely.

Coded in Godot 4.6. (Because it's easy to compile.)
