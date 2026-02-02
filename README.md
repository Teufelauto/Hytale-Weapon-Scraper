# Hytale-Weapon-Scraper
Turn JSON weapon assets into a flat CSV.

Currently only produces a CSV of Weapons. If you use Linux, the Godot User folder is somewhere else.
# Instructions
Coded in Godot 4.6

There is no GUI. It just opens a rectangle, letting you know it ran that you then need to close. 

Compiled executable must be run once to create folder:
C:\Users\~UserName~\AppData\Roaming\Godot\app_userdata\Hytale Weapon Scraper
You may need to enable "Show Hidden Items" in File Explorer.

Copy "Item" folder from Hytale assets.zip 
C:\Users\~UserName~\AppData\Roaming\Hytale\install\pre-release\package\game\latest\Assets.zip\Server\Item

and place into the AppData folder:  
C:\Users\~UserName~\AppData\Roaming\Godot\app_userdata\Hytale Weapon Scraper

Running the app again will populate the CSV in "Hytale Weapon Scraper" with fresh weapon data. These can be compared between releases.

