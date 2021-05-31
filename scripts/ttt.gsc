#include common_scripts\utility;
#include maps\mp\_utility;
#include scripts\ttt\_util;

init()
{
	level.ttt = spawnStruct();
	level.ttt.enabled = getDvar("g_gametype") == "ttt";
	if (!level.ttt.enabled) return;

	level.ttt.modEnabled = isSubStr(getDvar("fs_game"), "ttt");
	level.ttt.maxhealth = getDvarInt("scr_player_maxhealth");
	level.ttt.headshotMultiplier = getDvarFloat("ttt_headshot_multiplier");
	level.ttt.headshotMultiplierSniper = getDvarFloat("ttt_headshot_multiplier_sniper");
	level.ttt.knifeDamage = getDvarInt("ttt_knife_damage");
	level.ttt.knifeWeaponBackstabAngle = getDvarFloat("ttt_knife_weapon_backstab_angle");
	level.ttt.rpgMultiplier = getDvarFloat("ttt_rpg_multiplier");
	level.ttt.claymoreMultiplier = getDvarFloat("ttt_claymore_multiplier");
	level.ttt.claymoreDelay = getDvarFloat("ttt_claymore_delay");
	level.ttt.preptime = max(getDvarInt("ttt_preptime"), 1);

	level.ttt.knifeWeapon = "beretta_tactical_mp";
	if (level.ttt.modEnabled)
	{
		precacheMenu("client_exec");
		precacheItem("combat_knife_mp");
		level.ttt.knifeWeapon = "combat_knife_mp";
	}

	level.ttt.prematch = true;
	level.ttt.preparing = true;

	level.ttt.effects = spawnStruct();

	level.inGracePeriod = false;

	makeDvarServerInfo("cg_overheadIconSize", 0);
	makeDvarServerInfo("cg_overheadRankSize", 0);
	makeDvarServerInfo("cg_overheadNamesSize", 0.75);

	setDvar("scr_player_forceautoassign", 1);
	setDvar("scr_player_forcerespawn", 1);
	setDvar("scr_game_hardpoints", 0);
	setDvar("scr_teambalance", 0);
	setDvar("scr_game_spectatetype", 2);
	setDvar("scr_showperksonspawn", 0);

	setDvar("bg_fallDamageMinHeight", getDvar("ttt_falldamage_min"));
	setDvar("bg_fallDamageMaxHeight", getDvar("ttt_falldamage_max"));

	setDvar("scr_ttt_timelimit", (getDvarFloat("ttt_timelimit") + level.ttt.preptime / 60));

	scripts\ttt\_weaponnames::init();
	scripts\ttt\_coords::init();
	scripts\ttt\use::init();
	scripts\ttt\items::init();
	scripts\ttt\pickups::init();
	scripts\ttt\ui::init();

	thread OnPrematchOver();
	thread OnRoundRestart();

	thread OnPlayerConnect();

	wait(0.05); // wait for other scripts to execute
	setDvar("g_deadChat", "0");
}

initPlayer()
{
	self.ttt = spawnStruct();
	self.ttt.role = undefined;
	self.ttt.bodyFound = false;
	self.ttt.incomingDamageMultiplier = 1.0;

	self scripts\ttt\use::initPlayer();
	self scripts\ttt\pickups::initPlayer();
	self scripts\ttt\items::initPlayer();
	self scripts\ttt\ui::initPlayer();

	wait(0.05);
	self setClientDvars(
		"cg_deadChatWithDead", 1,
		"cg_deadChatWithTeam", 0,
		"cg_deadHearTeamLiving", 1,
		"cg_deadHearAllLiving", 1,
		"cg_everyoneHearsEveryone", 0
	);

	self setClientDvar("ui_ttt_block_esc_menu", false);
}

OnPrematchOver()
{
	level endon("game_ended");
	level waittill("prematch_over");

	level.ttt.prematch = false;
	//visionSetNaked("sepia", 1.0);

	thread OnRoundStart();
}

OnRoundRestart()
{
	level waittill("ttt_restarting");

	thread OnRoundStart();
}

OnRoundStart()
{
	thread scripts\ttt\pickups::spawnWorldPickups();

	thread OnPreptimeEnd();
	thread OnTimelimitReached();
}

OnPreptimeEnd()
{
	level endon("game_ended");

	wait(level.ttt.preptime - 0.2);
	foreach (player in getLivingPlayers()) player thread scripts\ttt\ui::pulsePlayerRoleDisplay(0.4);
	wait(0.2);
	level.ttt.preparing = false;

	drawPlayerRoles();

	foreach(player in getLivingPlayers())
	{
		player.maxhealth = level.ttt.maxhealth;
		player.health = player.maxhealth;

		player.isRadarBlocked = true;

		player scripts\ttt\items::setStartingCredits();
		player scripts\ttt\items::setStartingItems();
	}

	foreach (player in level.players) player scripts\ttt\ui::displayHeadIcons();
	level.disableSpawning = true;
	//visionSetNaked(getDvar("mapname"), 2.0);

	checkRoundWinConditions();
}

OnTimelimitReached()
{
	level endon("game_ended");

	level waittill("ttt_timelimit_reached");
	endRound("innocent", "timelimit");
}

OnAftertimeEnd()
{
	wait(getDvarInt("ttt_aftertime"));

	scripts\ttt\ui::destroyRoundEnd();

	foreach (player in level.players)
	{
		player.cancelKillcam = true;
		player scripts\ttt\use::unsetPlayerAvailableUseEnt();
	}
	level notify("round_end_finished"); // kicks off the final killcam
	while (level.showingFinalKillcam) wait(0.05);

	game["roundsPlayed"]++;
	if (game["roundsPlayed"] >= getDvarInt("ttt_roundlimit"))
	{
		// reset these because endGame expects them to be
		game["state"] = "playing";
		level.gameEnded = false;
		thread maps\mp\gametypes\_gamelogic::endGame("tie", "Round limit reached");
		return;
	}

	game["state"] = "playing";
	map_restart(true);
	level notify("ttt_restarting");
}

OnPlayerConnect()
{
	for (;;)
	{
		level waittill("connected", player);

		player thread initPlayer();

		if (getLivingPlayers().size <= 1 && !level.gameEnded && !level.ttt.preparing) map_restart(true);

		player thread OnPlayerDisconnect();
		player thread OnPlayerSpawn();
		player thread OnPlayerDeath();
		player thread OnPlayerEnemyKilled();
		player thread OnPlayerRagdoll();
		player thread OnPlayerWeaponSwitchStart();
		player thread OnPlayerScoreboardOpen();
		player thread OnPlayerScoreboardClose();
	}
}

OnPlayerDisconnect()
{
	self waittill("disconnect");

	checkRoundWinConditions();
}

OnPlayerSpawn()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("spawned_player");

		self takeAllWeapons();
		self _clearPerks();
		self SetOffhandPrimaryClass("other");
		self _SetActionSlot(1, ""); // disable nightvision
		self scripts\ttt\items::resetPlayerEquipment();

		self scripts\ttt\pickups::giveKnifeWeapon();
		self setSpawnWeapon(level.ttt.knifeWeapon);
		self scripts\ttt\ui::setupHeadIconAnchor();
		self scripts\ttt\ui::displaySelfHud();

		self thread scripts\ttt\use::OnPlayerUse();
		self thread scripts\ttt\use::playerUseEntsThink();
		self thread scripts\ttt\pickups::OnPlayerDropWeapon();
		self thread scripts\ttt\items::OnPlayerRoleWeaponToggle();
		self thread scripts\ttt\items::OnPlayerRoleWeaponEquip();
		self thread scripts\ttt\items::OnPlayerRoleWeaponActivate();
		self thread scripts\ttt\items::OnPlayerBuyMenu();
		self thread OnPlayerHealthUpdate();
		self thread OnPlayerAttack();
	}
}

OnPlayerDeath()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("death");

		self scripts\ttt\use::unsetPlayerAvailableUseEnt();
		self scripts\ttt\ui::destroySelfHud();
		self scripts\ttt\ui::displayBombHud();
		self scripts\ttt\items::unsetPlayerBuyMenu();
		checkRoundWinConditions();
	}
}

OnPlayerEnemyKilled()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("killed_enemy", victim);

		self scripts\ttt\items::awardKillCredits(victim);
	}
}

OnPlayerRagdoll()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("start_ragdoll");

		if (level.ttt.preparing) continue;

		body = spawn("script_model", self.body.origin);
		body.owner = self;
		body linkTo(self.body, "tag_origin", (0, 0, 16), (0, 0, 0));
		body scripts\ttt\use::makeUsableCustom(
			::OnBodyInspectTrigger,
			::OnBodyInspectAvailable,
			::OnBodyInspectAvailableEnd,
			undefined,
			undefined,
			10
		);
	}
}

OnBodyInspectTrigger(ent)
{
	self scripts\ttt\items::awardBodyInspectCredits(ent.owner);

	playerName = removeColorsFromString(self.name);
	ownerName = removeColorsFromString(ent.owner.name);
	ownerRoleColor = getRoleStringColor(ent.owner.ttt.role);

	if (!ent.owner.ttt.bodyFound)
	{
		ent.owner.ttt.bodyFound = true;
		ent.usePriority = 0;
		foreach (p in level.players)
		{
			if (p == self)
				p iPrintLnBold("You found the body of ^3" + ownerName + "^7. They were " + ownerRoleColor + ent.owner.ttt.role + "^7.");
			else
				p iPrintLnBold(playerName + "^7 found the body of ^3" + ownerName + "^7. They were " + ownerRoleColor + ent.owner.ttt.role + "^7.");

			p playLocalSound("copycat_steal_class");
		}
		foreach (p in scripts\ttt\use::getUseEntAvailablePlayers(ent))
			p scripts\ttt\ui::updateUseAvailableHint(undefined, ownerRoleColor + ownerName + "^7\n[ ^3[{+activate}]^7 ] to inspect");
	}
	else self iPrintLnBold("This is the body of ^3" + ownerName + "^7. They were " + ownerRoleColor + ent.owner.ttt.role + "^7.");
}
OnBodyInspectAvailable(ent)
{
	self scripts\ttt\ui::destroyUseAvailableHint();

	if (ent.owner.ttt.bodyFound)
	{
		ownerName = removeColorsFromString(ent.owner.name);
		ownerRoleColor = getRoleStringColor(ent.owner.ttt.role);
		self scripts\ttt\ui::displayUseAvailableHint(undefined, ownerRoleColor + ownerName + "^7\n[ ^3[{+activate}]^7 ] to inspect");
	}
	else
		self scripts\ttt\ui::displayUseAvailableHint(undefined, "^3Unidentified body^7\n[ ^3[{+activate}]^7 ] to inspect");
}
OnBodyInspectAvailableEnd(ent)
{
	self scripts\ttt\ui::destroyUseAvailableHint();
}

OnPlayerWeaponSwitchStart()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("weapon_switch_started", weaponName);

		self thread OnPlayerWeaponSwitchCancel(weaponName);
	}
}

OnPlayerWeaponSwitchCancel(weaponName)
{
	self endon("disconnect");
	self endon("weapon_change");

	for (;;)
	{
		while (self isSwitchingWeapon() || self getCurrentWeapon() == "none") wait(0.05);

		self notify("ttt_weapon_switch_canceled", weaponName);
		break;
	}
}

OnPlayerHealthUpdate()
{
	self endon("disconnect");
	self endon("death");

	for (;;)
	{
		self scripts\ttt\ui::updatePlayerHealthDisplay();
		wait(0.1);
	}
}

OnPlayerAttack()
{
	self endon("disconnect");
	self endon("death");

	self notifyOnPlayerCommand("ttt_attack", "+attack");

	for (;;)
	{
		self waittill("ttt_attack");
		if (self getCurrentWeapon() == level.ttt.knifeWeapon) self clientExec("+melee; -melee");
	}
}

OnPlayerScoreboardOpen()
{
	self endon("disconnect");

	self notifyOnPlayerCommand("ttt_scoreboard_open", "+scores");

	for (;;)
	{
		self waittill("ttt_scoreboard_open");

		// Hide the scoreboard using a hack
		self setClientDvar("cg_scoreboardWidth", 10000);
		self setClientDvar("cg_scoreboardHeight", 0);

		//self scripts\ttt\ui::destroyHeadIcons();
		self thread scoreboardThink();
	}
}

OnPlayerScoreboardClose()
{
	self endon("disconnect");

	self notifyOnPlayerCommand("ttt_scoreboard_close", "-scores");

	for (;;)
	{
		self waittill("ttt_scoreboard_close");

		self scripts\ttt\ui::destroyScoreboard();
		//self scripts\ttt\ui::displayHeadIcons();

		// Restore default scoreboard settings
		self setClientDvar("cg_scoreboardWidth", 500);
		self setClientDvar("cg_scoreboardHeight", 435);

		// Try to destroy again a tick later (for whenever +scores and -scores are sent simultaneously)
		wait(0.05);
		self scripts\ttt\ui::destroyScoreboard();
	}
}

scoreboardThink()
{
	self endon("disconnect");
	self endon("ttt_scoreboard_close");

	for (;;)
	{
		self scripts\ttt\ui::destroyScoreboard();
		self scripts\ttt\ui::displayScoreboard();
		wait(0.25);
	}
}

checkRoundWinConditions()
{
	if (level.ttt.preparing) return;

	if (level.players.size == 0 || (level.players.size == 1 && getLivingPlayers().size == 1)) return;
	aliveCounts = [];
	aliveCounts["innocent"] = 0;
	aliveCounts["detective"] = 0;
	aliveCounts["traitor"] = 0;
	foreach (player in getLivingPlayers()) aliveCounts[player.ttt.role]++;

	if ((aliveCounts["innocent"] + aliveCounts["detective"]) == 0) endRound("traitor", "death");
	else if (aliveCounts["traitor"] == 0) endRound("innocent", "death");
}

drawPlayerRoles()
{
	traitorPct = getDvarFloat("ttt_traitor_pct");
	detectivePct = getDvarFloat("ttt_detective_pct");

	playerCount = level.aliveCount["allies"] + level.aliveCount["axis"];
	traitorCount = int(playerCount * traitorPct);
	detectiveCount = int(playerCount * detectivePct);
	if (traitorCount < 1) traitorCount = 1;
	else if (traitorCount > playerCount) traitorCount = playerCount;

	if (detectiveCount > playerCount) detectiveCount = playerCount;

	// The array_randomize function in common utils is biased.
	randomizedPlayers = fisherYatesShuffle(getLivingPlayers());

	for (i = 0; i < randomizedPlayers.size; i++)
	{
		role = "innocent";
		if (i < traitorCount) role = "traitor";
		else if (i < traitorCount + detectiveCount) role = "detective";

		randomizedPlayers[i].ttt.role = role;
	}

	foreach (player in level.players)
	{
		if (traitorCount == 1) player iPrintLnBold("There is ^1" + traitorCount + "^7 traitor among us");
		else player iPrintLnBold("There are ^1" + traitorCount + "^7 traitors among us");
		player scripts\ttt\ui::updatePlayerRoleDisplay();
	}

	logPrint("TTT_ROUND_START;" + playerCount + ";" + traitorCount + ";" + detectiveCount + "\n");
}

endRound(winner, reason)
{
	if (level.gameEnded) return;
	level.gameEnded = true;
	game["state"] = "postgame";
	setDvar("g_deadChat", "1");
	if (reason == "death") setDvar("scr_gameended", 2); // primarily sets "Round Winning Kill" in killcam

	scripts\ttt\ui::displayRoundEnd(winner, reason);
	foreach (player in level.players)
	{
		playerTeam = "innocent";
		if (isDefined(player.ttt.role) && player.ttt.role == "traitor") playerTeam = "traitor";
		if (winner == playerTeam) player playLocalSound("mp_bonus_start");
		else player playLocalSound("mp_bonus_end");
	}

	visionSetNaked("mpOutro", 2.0);
	logPrint("TTT_ROUND_END;" + winner + ";" + reason + ";" + (getSecondsPassed() - level.ttt.preptime) + "\n");

	level thread maps\mp\gametypes\_damage::doFinalKillcam(
		5.0,
		level.lastDeath.victim,
		level.lastDeath.attacker,
		level.lastDeath.attackerNum,
		level.lastDeath.killcamentityindex,
		level.lastDeath.killcamentitystarttime,
		level.lastDeath.sWeapon,
		level.lastDeath.deathTimeOffset,
		level.lastDeath.psOffsetTime
	);

	thread OnAftertimeEnd();

	level notify("game_ended");
}
