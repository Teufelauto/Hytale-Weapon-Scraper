extends Node
class_name WeaponShared
# A common place to put shared data



const melee_weapon_shared_list: Array = [WeaponShared.battleaxe, 
										WeaponShared.daggers, 
										WeaponShared.mace, 
										WeaponShared.sword,
										]

class battleaxe:
	const weapon: String = "Battleaxe"
	const primary_attack_1_name: String   = "Swing_Down_Left"
	const primary_attack_2_name: String   = "Swing_Down_Right"
	const primary_attack_3_name: String   = "Swing_Down"
	const primary_attack_4_name: String   = ""
	const charged_attack_1_name: String   = "Downstrike"
	const charged_attack_2_name: String   = ""
	const charged_attack_3_name: String   = ""
	const signature_attack_1_name: String = "Signature_Whirlwind"
	const signature_attack_2_name: String = ""
	const weapon_descriptor: Array[String] = ["Adamantite",
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

class daggers:
	const weapon: String = "Daggers"
	const primary_attack_1_name: String   = "Swing_Left"
	const primary_attack_2_name: String   = "Swing_Right"
	const primary_attack_3_name: String   = "Stab_Left"
	const primary_attack_4_name: String   = "Stab_Right"
	const charged_attack_1_name: String   = "Pounce_Sweep"
	const charged_attack_2_name: String   = "Pounce_Stab"
	const charged_attack_3_name: String   = ""
	const signature_attack_1_name: String = "Razorstrike_Slash"
	const signature_attack_2_name: String = "Razorstrike_Sweep"
	const weapon_descriptor: Array[String] = ["Adamantite",
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

class mace:
	const weapon: String = "Mace"
	const primary_attack_1_name: String   = "Swing_Left"
	const primary_attack_2_name: String   = "Swing_Right"
	const primary_attack_3_name: String   = "Swing_Up_Left"
	const primary_attack_4_name: String   = ""
	const charged_attack_1_name: String   = "Swing_Left_Charged"
	const charged_attack_2_name: String   = "Swing_Right_Charged"
	const charged_attack_3_name: String   = "Swing_Up_Left_Charged"
	const signature_attack_1_name: String = "Groundslam"
	const signature_attack_2_name: String = ""
	const weapon_descriptor: Array[String] = ["Adamantite",
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
	
class sword:
	const weapon: String = "Sword"
	const primary_attack_1_name: String   = "Swing_Left"
	const primary_attack_2_name: String   = "Swing_Right"
	const primary_attack_3_name: String   = "Swing_Down"
	const primary_attack_4_name: String   = ""
	const charged_attack_1_name: String   = "Thrust"
	const charged_attack_2_name: String   = ""
	const charged_attack_3_name: String   = ""
	const signature_attack_1_name: String = "Vortexstrike_Spin"
	const signature_attack_2_name: String = "Vortexstrike_Stab"
	const weapon_descriptor: Array[String] = ["Adamantite",
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
	
	
	
