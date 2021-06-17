init()
{
	concussion = spawnStruct();
	concussion.name = "STUN GRENADE";
	concussion.description = "^3Exclusive special grenade\n^2Disorients ^7and ^2slows ^7targets\ncaught in the explosion.\n\nPress [ ^3[{+smoke}]^7 ] to throw.";
	concussion.icon = "weapon_concgrenade";
	concussion.onBuy = ::OnBuy;
	concussion.getIsAvailable = scripts\ttt\items::getIsAvailableOffhand;
	concussion.unavailableHint = scripts\ttt\items::getUnavailableHint("offhand");

	scripts\ttt\items::registerItem(concussion, "detective");
}

OnBuy()
{
	WEAPON_NAME = "concussion_grenade_mp";
	self giveWeapon(WEAPON_NAME);
	self setWeaponAmmoClip(WEAPON_NAME, 1);
	self SetOffhandSecondaryClass("smoke");
}