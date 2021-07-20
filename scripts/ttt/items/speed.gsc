init()
{
	speed = spawnStruct();
	speed.name = "HYPERSPEED";
	speed.description = "^3Passive item\n^2Increases ^7your base ^2speed ^7by\n^3" + (level.ttt.speedItemMultiplier * 100 - 100) + " ^7percent.";
	speed.icon = "specialty_lightweight_upgrade";
	speed.onBuy = ::OnBuy;
	speed.getIsAvailable = scripts\ttt\items::getIsAvailablePassive;
	speed.unavailableHint = &"^1Already running at hyperspeed";

	scripts\ttt\items::registerItem(speed, "detective");
}

OnBuy()
{
	self.moveSpeedScaler = level.ttt.speedItemMultiplier;
	self setMoveSpeedScale(self.moveSpeedScaler);
}