--[[
	ej0w @ October 2024

	[REMOTES] This is where all remotes will be instanced
	I choose to do this instead because it's a little easier on the person in studio, removes bloat
	
	Add a remote here w/ the classname and it'll be created in Remotes (instanced during runtime).
	--> {xxx: Name, xxx: ClassName}
]]

--------------------------------------------------------------------------------

return {
	{"AllocatePoints", "RemoteFunction"},
	{"BuyItem", "RemoteFunction"},
	{"CraftItem", "RemoteFunction"},
	{"PlayerCalledMagic", "RemoteFunction"},
	{"PlayerSpentMana", "RemoteFunction"},
	{"ResetAttributes", "RemoteFunction"},
	{"SellItem", "RemoteFunction"},
	{"EquipArmor", "RemoteFunction"},
	{"UnequipArmor", "RemoteFunction"},
	{"EquipAccessory", "RemoteFunction"},
	{"UnequipAccessory", "RemoteFunction"},
	{"QuestComplete", "RemoteFunction"},
	{"QuestStart", "RemoteFunction"},
	
	{"RequestTeleport", "RemoteEvent"},
	{"ExitQuest", "RemoteEvent"},
	{"ChatAlert", "RemoteEvent"},
	{"TalkToNPC", "RemoteEvent"},
	{"InformSpawnedBoss", "RemoteEvent"},
	{"DamageEntity", "RemoteEvent"},
	{"HotbarItemChanged", "RemoteEvent"},
	{"MobDamagedPlayer", "RemoteEvent"},
	{"MobProcessedFire", "RemoteEvent"},
	{"PlayerConsumedItem", "RemoteEvent"},
	{"PlayerDamagedEntity", "RemoteEvent"},
	{"PlayerUsedSpell", "RemoteEvent"},
	{"ReceiveProjectile", "RemoteEvent"},
	{"ReplicaMagicCalled", "RemoteEvent"},
	{"RequestClientTween", "RemoteEvent"},
	{"SendNotification", "RemoteEvent"},
	{"ShareProjectile", "RemoteEvent"},
	{"PlayerDamaged", "RemoteEvent"},
	{"RequestAnimateMob", "RemoteEvent"},
	{"ForceAnimateMob", "RemoteEvent"},
	{"RequestBlock", "RemoteEvent"},
	{"EquipObjectArmor", "RemoteEvent"},
	{"UnequipObjectArmor", "RemoteEvent"},
	{"ClientToServerKeybind", "RemoteEvent"},
	{"ServerToClientKeybind", "RemoteEvent"},
	{"ServerToClientCallback", "RemoteEvent"},
	{"ClientToServerCallback", "RemoteEvent"},
	{"ServerToClientEquipmentCallback", "RemoteEvent"},
	{"ServerToClientMobCallback", "RemoteEvent"},
	{"ServerToClientGlobalKeybind", "RemoteEvent"},
	{"ClientToServerGlobalKeybind", "RemoteEvent"},
	
	{"ClientRequestTeleport", "BindableEvent"},
	{"ClientToClientGlobalKeybind", "BindableEvent"},
	{"ServerToServerEquipmentCallback", "BindableEvent"},
	{"ServerToServerMobCallback", "BindableEvent"},
	{"ClientToClientCallback", "BindableEvent"},
	{"ServerToServerCallback", "BindableEvent"},
	{"RequestBossHUD", "BindableEvent"},
	{"PlayerRequestHit", "BindableEvent"},
	{"PlayerUsedWeapon", "BindableEvent"},
}