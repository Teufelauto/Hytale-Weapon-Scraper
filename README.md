# Hytale-Weapon-Scraper
Turn zipped weapon assets into a JSON and flat CSV for easy viewing.
App takes several seconds to go through the 3 GB Assets.zip on a 9800x3D computer with an NVME drive. It may appear frozen, but it's probably still parsing. It will close when it's done.
Currently produces a JSON and CSV of Weapons in the folder below. Default assets path, and location of the saves can be changed to a location of your choosing by editing the app_settings.json file.
# Instructions
There is no GUI yet. It just opens a rectangle while it runs, then closes when the json and csv are written.

App creates folder:

WIN: C:/Users/%UserName%/AppData/Roaming/Hytale-Weapon-Scraper

LINUX:  ~/.local/share/Hytale-Weapon-Scraper

The app creates an app_settings.json in this folder. If you want to change filenames or paths, do it here.

The app scrapes the latest Pre-Release on your system. If you wish to scrape a different version, change the PreRelease Assets_Path to the desired path. The Release section is for future use.

Use "/" rather than "\\" in file paths, and end the path with a "/".

The JSON or CSV can be saved to a different location by changing Output PreRelease path or name in app_settings.json


Coded in Godot 4.6. (Because it's easy to compile.)
