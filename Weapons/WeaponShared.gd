extends Node
class_name WeaponShared
# A common place to put shared data


# TODO:  Add Template weapons. They add data to some weapons.

var melee_weapon_shared_list: Array = [
	WeaponShared.battleaxe, 
	WeaponShared.daggers, 
	WeaponShared.mace, 
	WeaponShared.sword,
	]
var total_number_of_weapons: int = \
	WeaponShared.battleaxe.weapon_descriptor.size() + \
	WeaponShared.daggers.weapon_descriptor.size() + \
	WeaponShared.mace.weapon_descriptor.size() + \
	WeaponShared.sword.weapon_descriptor.size()
var weapon_table_columns: Array[String] = [
	"Item_Count",
	"ID",
	"Weapon_Family",
	"Descriptor",
	"Pregenerated_Icon",
	"Item_Level",
	"Quality",
	"Max_Durability",
	"Durability_Loss_On_Hit",
	"primary_attack_1_damage",
	"primary_attack_2_damage",
	"primary_attack_3_damage",
	"primary_attack_4_damage",
	"charged_attack_1_damage",
	"charged_attack_2_damage",
	"charged_attack_3_damage",
	"signature_attack_1_damage",
	"signature_attack_2_damage",
	]

# "filename_in_zip": "Template_Weapon_Sword"
var template_weapon_battleaxe: Array =[
	"Quality",
	"ItemLevel",
	"MaxDurability",
	"DurabilityLossOnHit",
	]
var template_weapon_daggers: Array =[
	"Quality",
	"ItemLevel",
	"MaxDurability",
	"DurabilityLossOnHit",
	]
var template_weapon_mace: Array =[
	"Quality",
	"ItemLevel",
	"MaxDurability",
	"DurabilityLossOnHit",
	]
var template_weapon_sword: Array =[
	"Quality",
	"ItemLevel",
	"MaxDurability",
	"DurabilityLossOnHit",
	]



class battleaxe: # Filename in zip is  weapon + "_" + weapon_descriptor
	const weapon_family: String = "Battleaxe" # Must be Capatalized for file path to work inside zip files.
	const parent: String ="Template_Weapon_Battleaxe" # Must be Capatalized for file path to work inside zip files.
	const primary_attack_1_name: String   = "Swing_Down_Left"
	const primary_attack_2_name: String   = "Swing_Down_Right"
	const primary_attack_3_name: String   = "Swing_Down"
	const primary_attack_4_name: String   = ""
	const charged_attack_1_name: String   = "Downstrike"
	const charged_attack_2_name: String   = ""
	const charged_attack_3_name: String   = ""
	const signature_attack_1_name: String = "Signature_Whirlwind"
	const signature_attack_2_name: String = ""
	# Weapon descriptor must match capitalization in filename in zip.
	const weapon_descriptor: Array[String] = [
		"Adamantite",
		"Cobalt",
		"Copper",
		"Crude",
		"Doomed",
		"Iron",
		"Mithril",
		"Onyxium",
		"Scarab",
		"Scythe_Void",
		"Steel_Rusty",
		"Stone_Trork",
		"Thorium",
		"Tribal",
		"Wood_Fence",
		]

class daggers: # Filename in zip is:  weapon + "_" + weapon_descriptor
	const weapon_family: String = "Daggers" # Must be Capatalized for file path to work inside zip files.
	const parent: String ="Template_Weapon_Daggers" # Must be Capatalized for file path to work inside zip files.
	const primary_attack_1_name: String   = "Swing_Left"
	const primary_attack_2_name: String   = "Swing_Right"
	const primary_attack_3_name: String   = "Stab_Left"
	const primary_attack_4_name: String   = "Stab_Right"
	const charged_attack_1_name: String   = "Pounce_Sweep"
	const charged_attack_2_name: String   = "Pounce_Stab"
	const charged_attack_3_name: String   = ""
	const signature_attack_1_name: String = "Razorstrike_Slash"
	const signature_attack_2_name: String = "Razorstrike_Sweep"
	# Weapon descriptor must match capitalization in filename in zip.
	const weapon_descriptor: Array[String] = [
		"Adamantite",
		"Adamantite_Saurian",
		"Bone",
		"Bronze",
		"Bronze_Ancient",
		"Claw_Bone",
		"Cobalt",
		"Copper",
		"Crude",
		"Doomed",
		"Fang_Doomed",
		"Iron",
		"Mithril",
		"Onyxium",
		"Stone_Trork",
		"Thorium",
		]

class mace: # Filename in zip is:  weapon + "_" + weapon_descriptor
	const weapon_family: String = "Mace" # Must be Capatalized for file path to work inside zip files.
	const parent: String ="Template_Weapon_Mace" # Must be Capatalized for file path to work inside zip files.
	const primary_attack_1_name: String   = "Swing_Left"
	const primary_attack_2_name: String   = "Swing_Right"
	const primary_attack_3_name: String   = "Swing_Up_Left"
	const primary_attack_4_name: String   = ""
	const charged_attack_1_name: String   = "Swing_Left_Charged"
	const charged_attack_2_name: String   = "Swing_Right_Charged"
	const charged_attack_3_name: String   = "Swing_Up_Left_Charged"
	const signature_attack_1_name: String = "Groundslam"
	const signature_attack_2_name: String = ""
	# Weapon descriptor must match capitalization in filename in zip.
	const weapon_descriptor: Array[String] = [
		"Adamantite",
		"Cobalt",
		"Copper",
		"Crude",
		"Iron",
		"Mithril",
		"Onyxium",
		"Prisma",
		"Scrap",
		"Scrap_NPC",
		"Stone_Trork",
		"Thorium",
		]
	
class sword: # Filename in zip is:  weapon + "_" + weapon_descriptor
	const weapon_family: String = "Sword" # Must be Capatalized for file path to work inside zip files.
	const parent: String ="Template_Weapon_Sword" # Must be Capatalized for file path to work inside zip files.
	const primary_attack_1_name: String   = "Swing_Left"
	const primary_attack_2_name: String   = "Swing_Right"
	const primary_attack_3_name: String   = "Swing_Down"
	const primary_attack_4_name: String   = ""
	const charged_attack_1_name: String   = "Thrust"
	const charged_attack_2_name: String   = ""
	const charged_attack_3_name: String   = ""
	const signature_attack_1_name: String = "Vortexstrike_Spin"
	const signature_attack_2_name: String = "Vortexstrike_Stab"
	# Weapon descriptor must match capitalization in filename in zip.
	const weapon_descriptor: Array[String] = [
		"Adamantite",
		"Bone",
		"Bronze",
		"Bronze_Ancient",
		"Cobalt",
		"Copper",
		"Crude",
		"Cutlass",
		"Doomed",
		"Frost",
		"Iron",
		"Mithril",
		"Nexus",
		"Onyxium",
		"Runic",
		"Scrap",
		"Silversteel",
		"Steel",
		"Steel_Incandescent",
		"Steel_Rusty",
		"Stone_Trork",
		"Thorium",
		"Wood",
		]
	
	
	
