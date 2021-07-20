#include common_scripts\utility;
#include maps\mp\_utility;
#include scripts\ttt\_util;

init()
{
	precacheModel("weapon_scavenger_grenadebag");

	if (level.ttt.modEnabled) precacheItem("winchester1200_mp");

	level.ttt.pickups = spawnStruct();
	level.ttt.effects.trailEffect = loadFX("props/throwingknife_geotrail");
}

initPlayer()
{
	self.ttt.pickups = spawnStruct();
	self.ttt.pickups.canDropWeapons = true;
	self.ttt.pickups.dropVelocity = 64;
	self.ttt.pickups.dropCanDamage = false;
}

getRandomWeapon()
{
	tieredWeapons = [];
	for (i = 0; i < 3; i++) tieredWeapons[i] = [];

	tieredWeapons[0][0] = "famas";
	tieredWeapons[0][1] = "scar";
	tieredWeapons[0][2] = "fal";
	tieredWeapons[0][3] = "tavor";
	tieredWeapons[0][4] = "masada";
	tieredWeapons[0][5] = "ump45";
	tieredWeapons[0][6] = "aug";

	tieredWeapons[1][0] = "m4";
	tieredWeapons[1][1] = "ak47";
	tieredWeapons[1][2] = "mp5k";
	tieredWeapons[1][3] = "p90";
	tieredWeapons[1][4] = "uzi";
	tieredWeapons[1][5] = "kriss";
	tieredWeapons[1][6] = "rpd";
	tieredWeapons[1][7] = "m1014";
	tieredWeapons[1][8] = "beretta393_reflex";
	tieredWeapons[1][9] = "glock";

	tieredWeapons[2][0] = "fn2000";
	tieredWeapons[2][1] = "mg4";
	tieredWeapons[2][2] = "m40a3";
	tieredWeapons[2][3] = "m40a3"; // generate more sniper rifles as this is the only one in the pool
	tieredWeapons[2][4] = "usp";
	tieredWeapons[2][5] = "deserteagle";
	tieredWeapons[2][6] = "coltanaconda";
	tieredWeapons[2][7] = "pp2000";
	tieredWeapons[2][8] = "tmp";
	tieredWeapons[2][9] = "model1887";
	if (level.ttt.modEnabled)
		tieredWeapons[2][9] = "winchester1200";

	weighting = randomInt(100);
	result = undefined;
	if (weighting < 20) result = tieredWeapons[0][randomInt(tieredWeapons[0].size)];
	else if (weighting < 50) result = tieredWeapons[1][randomInt(tieredWeapons[1].size)];
	else result = tieredWeapons[2][randomInt(tieredWeapons[2].size)];

	return result + "_mp";
}

isWeaponDroppable(weaponName)
{
	return maps\mp\gametypes\_weapons::mayDropWeapon(weaponName) || scripts\ttt\items::isRoleWeapon(weaponName);
}

isWeaponLaptop(weaponName)
{
	switch (weaponName)
	{
		case "killstreak_ac130_mp": // hides UI when active
		case "killstreak_harrier_airstrike_mp":
		case "killstreak_helicopter_minigun_mp": // hides UI when active
		case "killstreak_precision_airstrike_mp":
		case "killstreak_predator_missile_mp": // hides UI when active
		case "killstreak_stealth_airstrike_mp":
			return true;
	}

	return isSubStr(weaponName, "laptop");
}

getPrimaryWeaponCount()
{
	primaryWeaponCount = self getWeaponsListPrimaries().size;
	hasKnife = self hasWeapon(level.ttt.knifeWeapon);
	isRoleWeaponOnPlayer = self scripts\ttt\items::isRoleWeaponOnPlayer();
	roleWeapon = self.ttt.items.roleInventory.item.weaponName;
	isRoleWeaponPrimary = isDefined(roleWeapon) && weaponInventoryType(roleWeapon) == "primary";

	return primaryWeaponCount - int(hasKnife) - int(isRoleWeaponOnPlayer && isRoleWeaponPrimary);
}

createWeaponEnt(weaponName, ammoClip, ammoStock, item, data, origin, angles, velocity)
{
	if (!isDefined(weaponName)) return;
	if (!isDefined(ammoClip)) ammoClip = 0;
	if (!isDefined(ammoStock)) ammoStock = 0;
	if (!isDefined(item)) item = undefined;
	if (!isDefined(data)) data = undefined;
	if (!isDefined(origin)) origin = (0, 0, 0);
	if (!isDefined(angles)) angles = (0, 0, 0);
	if (!isDefined(velocity)) velocity = (0, 0, 0);

	/**
	 * Some weapons have weird models that always fall straight to the ground
	 * even when velocity is applied. Some weapons seem to not be able to have physics
	 * at all (coltanaconda). Due to this an invisible physicsEnt is used that has the
	 * model of a weapon that works correctly.
	 */

	// offset the p90 model so that it's actual center is at the specified origin
	physicsEnt = spawn("script_model", origin + anglesToForward(angles) * 12);
	physicsEnt.angles = angles;
	physicsEnt setModel(getWeaponModel("p90_mp"));
	physicsEnt hide();

	weaponEnt = spawn("script_model", origin);
	weaponEnt.angles = angles;
	switch (getWeaponClass(weaponName)) {
		case "weapon_smg":
			weaponEnt.origin += anglesToForward(angles) * 10;
			break;
		case "weapon_pistol":
		case "weapon_machine_pistol":
		case "weapon_assault":
			weaponEnt.origin += anglesToForward(angles) * 6;
			break;
		case "weapon_shotgun":
			weaponEnt.origin += anglesToForward(angles) * -2;
			break;
	}
	if (weaponName == "riotshield_mp") weaponEnt.angles = combineAngles(angles, (0, 90, 90));
	if (isWeaponLaptop(weaponName)) weaponEnt.angles = combineAngles(angles, (90, 90, 0));
	if (weaponName == "onemanarmy_mp" || isSubStr(weaponName, "oma"))
	{
		weaponEnt.angles = combineAngles(angles, (-90, 100, -35));
		weaponEnt.origin += anglesToRight(angles) * -2;
	}
	weaponEnt linkTo(physicsEnt);
	weaponEnt setModel(getWeaponModel(weaponName));
	weaponParts = getWeaponHideTags(weaponName);
	foreach (part in weaponParts) weaponEnt hidePart(part);

	weaponEnt.physicsEnt = physicsEnt;
	weaponEnt.weaponName = weaponName;
	weaponEnt.ammoClip = ammoClip;
	weaponEnt.ammoStock = ammoStock;
	weaponEnt.item = item;
	weaponEnt.data = data;

	// magic numbers to make the item receive velocity around it's center of mass
	launchOffset = 0 * anglesToRight(angles) + -10 * anglesToForward(angles) + 10 * anglesToUp(angles);

	// ... because this takes an absolute position:
	physicsEnt physicsLaunchServer(physicsEnt.origin + launchOffset, velocity);

	weaponEnt thread OnWeaponEntUsable();
	weaponEnt thread OnWeaponEntPhysicsFinish();

	return weaponEnt;
}

OnWeaponPickupTrigger(ent)
{
	self tryPickUpWeapon(ent, true);
}
OnWeaponPickupAvailable(ent)
{
	self scripts\ttt\ui::destroyUseAvailableHint();
	displayName = level.ttt.localizedWeaponNames[ent.weaponName];
	if (scripts\ttt\items::isRoleWeapon(ent.weaponName) && isDefined(ent.item))
		displayName = getRoleStringColor(ent.item.role) + ent.item.name;
	self scripts\ttt\ui::displayUseAvailableHint(&"[ ^3[{+activate}] ^7] for ^3", displayName);
}
OnWeaponPickupAvailableEnd(ent)
{
	self scripts\ttt\ui::destroyUseAvailableHint();
}

OnWeaponEntUsable()
{
	wait(0.25);

	self scripts\ttt\use::makeUsableCustom(
		::OnWeaponPickupTrigger,
		::OnWeaponPickupAvailable,
		::OnWeaponPickupAvailableEnd
	);
}

OnWeaponEntPhysicsFinish()
{
	self endon("death");

	self.physicsEnt waittill("physics_finished");

	stopFXOnTag(level.ttt.effects.trailEffect, self, "tag_weapon");

	// Rotate the laptop if it is facing the ground:
	if (isWeaponLaptop(self.weaponName) && anglesToUp(self.angles)[2] < 0)
		self.physicsEnt rotateRoll(-180, 0.5, 0.25, 0.25);

	self thread weaponEntThink();
}

weaponEntThink()
{
	self endon("death");

	pickupDistanceSq = 32 * 32;

	for (;;)
	{
		// check if anyone is trying to implicitly pick up the weapon (walking over it)
		foreach (player in getLivingPlayers())
		{
			isNearOrigin = distanceSquared(player.origin, self.origin) <= pickupDistanceSq;
			isNearEyes = distanceSquared(player getEye(), self.origin) <= pickupDistanceSq;
			if (!isNearOrigin && !isNearEyes) continue;

			player tryPickUpWeapon(self);
		}

		wait(0.1);
	}
}

createAmmoEnt(origin, angles)
{
	if (!isDefined(origin)) origin = (0, 0, 0);
	if (!isDefined(angles)) angles = (0, 0, 0);

	ammoEnt = spawn("script_model", origin);
	ammoEnt setModel("weapon_scavenger_grenadebag");
	ammoEnt.angles = angles + (0, 0, 90);

	ammoEnt thread ammoEntThink();
}

ammoEntThink()
{
	self endon ("death");

	pickupDistanceSq = 32 * 32;

	for (;;)
	{
		foreach (player in getLivingPlayers())
		{
			isNearOrigin = distanceSquared(player.origin, self.origin) <= pickupDistanceSq;
			isNearEyes = distanceSquared(player getEye(), self.origin) <= pickupDistanceSq;
			if (!isNearOrigin && !isNearEyes) continue;

			currentWeaponName = player getCurrentWeapon();
			player tryPickUpAmmo(self, currentWeaponName);
			foreach (weaponName in player getWeaponsListPrimaries())
				player tryPickUpAmmo(self, weaponName);
		}

		wait(0.1);
	}
}

tryPickUpWeapon(weaponEnt, explicitPickup)
{
	if (!isDefined(explicitPickup)) explicitPickup = false;

	prevWeaponName = self getCurrentWeapon();
	hasSameWeapon = self hasWeapon(weaponEnt.weaponName);
	hasRoleWeapon = self scripts\ttt\items::hasRoleWeapon();
	isRoleWeaponOnPlayer = self scripts\ttt\items::isRoleWeaponOnPlayer();
	newIsRoleWeapon = scripts\ttt\items::isRoleWeapon(weaponEnt.weaponName);

	if (newIsRoleWeapon)
	{
		if (!explicitPickup) return;

		if (hasRoleWeapon) self dropWeapon(self.ttt.items.roleInventory.item.weaponName);

		scripts\ttt\items::setRoleInventory(weaponEnt.item, weaponEnt.ammoClip, weaponEnt.ammoStock, weaponEnt.data);
		if (isDefined(weaponEnt.item.onPickUp)) self thread [[weaponEnt.item.onPickUp]](weaponEnt.item, weaponEnt.data);
		self playLocalSound("weap_pickup");

		if (isRoleWeaponOnPlayer) self scripts\ttt\items::giveRoleWeapon();
	}
	else
	{
		if (hasSameWeapon && !explicitPickup) return;

		weaponCountPrev = self getPrimaryWeaponCount();
		lastValidWeapon = self getLastValidWeapon();

		if (weaponCountPrev >= 2 && !explicitPickup) return;

		if (hasSameWeapon)
			self dropWeapon(weaponEnt.weaponName);
		else if (weaponCountPrev >= 2)
		{
			if (isWeaponDroppable(prevWeaponName) && !isRoleWeaponOnPlayer)
				self dropWeapon(prevWeaponName);
			else
				self dropWeapon(lastValidWeapon);
		}

		self giveWeapon(weaponEnt.weaponName);
		self setWeaponAmmoClip(weaponEnt.weaponName, weaponEnt.ammoClip);
		self setWeaponAmmoStock(weaponEnt.weaponName, weaponEnt.ammoStock);

		weaponCountNew = self getPrimaryWeaponCount();

		if (self hasWeapon(level.ttt.knifeWeapon) && weaponCountNew == 2) self takeWeapon(level.ttt.knifeWeapon);
		self thread maps\mp\gametypes\_weapons::stowedWeaponsRefresh();
		self playLocalSound("weap_pickup");

		if ((weaponCountNew == 1 || explicitPickup || prevWeaponName == level.ttt.knifeWeapon) && !isRoleWeaponOnPlayer)
			self switchToWeapon(weaponEnt.weaponName);
	}

	weaponEnt.physicsEnt delete();
	weaponEnt.killCamEnt delete();
	weaponEnt delete();
}

tryPickUpAmmo(ammoEnt, weaponName)
{
	if (!self maps\mp\gametypes\_weapons::mayDropWeapon(weaponName)) return;
	if (weaponName == level.ttt.knifeWeapon) return;
	if (weaponName == "rpg_mp") return;

	maxClip = weaponClipSize(weaponName);
	currentStock = self getWeaponAmmoStock(weaponName);
	maxStock = maxClip * int(weaponMaxAmmo(weaponName) / maxClip / 3);
	if (maxStock < maxClip) maxStock = maxClip;

	if (currentStock >= maxStock) return;

	newStock = currentStock + maxClip;
	if (newStock > maxStock) newStock = maxStock;

	self setWeaponAmmoStock(weaponName, newStock);
	self playLocalSound("scavenger_pack_pickup");

	ammoEnt delete();
}

spawnWorldPickups()
{
	mapname = getDvar("mapname");
	spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray("mp_dm_spawn");
	if (isDefined(level.ttt.coords.pickups[mapname]))
		spawnPoints = array_combine(spawnPoints, level.ttt.coords.pickups[mapname]);
	spawnPoints = fisherYatesShuffle(spawnPoints);

	foreach (spawnPoint in spawnPoints)
	{
		// Spawn weapons
		isPlayerSpawnPoint = isDefined(spawnPoint.origin);

		if (isPlayerSpawnPoint) origin = spawnPoint.origin;
		else origin = spawnPoint;

		origin += (0, 0, 48); // put up to about half of the player's height

		if (isPlayerSpawnPoint)
		{
			origin = physicsTrace(
				origin,
				origin + anglesToForward(spawnPoint.angles) * randomIntRange(96, 256)
			);
			origin -= anglesToForward(spawnPoint.angles) * 24; // prevent weapons from spawning in walls
		}

		origin = physicsTrace(origin, origin + (0, 0, -1024)) + (0, 0, 8);

		weaponName = getRandomWeapon();

		createWeaponEnt(weaponName, 0, weaponClipSize(weaponName), undefined, undefined, origin, (0, randomInt(360), 0));

		// Spawn ammo
		AMMO_COUNT = 3;
		for (i = 0; i < AMMO_COUNT; i++)
		{
			ammoForwardVector = anglesToForward((0, 360 / AMMO_COUNT * i, 0));
			ammoOrigin = physicsTrace(
				origin + (0, 0, 48),
				origin + ammoForwardVector * randomIntRange(48, 96)
			);
			ammoOrigin -= ammoForwardVector * 16;
			ammoOrigin = physicsTrace(ammoOrigin, ammoOrigin + (0, 0, -1024)) + (0, 0, 0);

			createAmmoEnt(ammoOrigin, (0, randomInt(360), 0));
		}
	}
}

OnPlayerDropWeapon()
{
	self endon("disconnect");
	self endon("death");

	self notifyOnPlayerCommand("ttt_drop_weapon", "+actionslot 1");

	for (;;)
	{
		self waittill("ttt_drop_weapon");

		if (!self.ttt.pickups.canDropWeapons) continue;

		weaponName = self getCurrentWeapon();
		if (weaponName == level.ttt.knifeWeapon) continue;
		if (!isWeaponDroppable(weaponName)) continue;

		self dropWeapon(
			weaponName,
			self getVelocity() * 0.5 + anglesToForward(self getPlayerAngles()) * self.ttt.pickups.dropVelocity + (0, 0, 64)
		);
	}
}

dropWeapon(weaponName, velocity)
{
	if (!isDefined(weaponName)) return;
	if (!self hasWeapon(weaponName) && !scripts\ttt\items::hasRoleWeapon(weaponName)) return;

	weaponWasActive = (weaponName == self getCurrentWeapon());
	isRoleWeapon = scripts\ttt\items::isRoleWeapon(weaponName);
	isRoleWeaponOnPlayer = self scripts\ttt\items::isRoleWeaponOnPlayer();

	ammoClip = self getWeaponAmmoClip(weaponName);
	ammoStock = self getWeaponAmmoStock(weaponName);
	item = undefined;
	data = undefined;

	if (isRoleWeapon)
	{
		inv = self.ttt.items.roleInventory;
		item = inv.item;
		data = inv.data;

		if (!isRoleWeaponOnPlayer)
		{
			ammoClip = inv.ammoClip;
			ammoStock = inv.ammoStock;
		}

		if (isDefined(inv.item.onDrop)) self thread [[inv.item.onDrop]](item, data);
		self scripts\ttt\items::resetRoleInventory();
	}

	eyePos = self getEye();
	spawnPos = physicsTrace(
		eyePos,
		eyePos + anglesToForward(self.angles) * 32
	);
	spawnPos -= anglesToForward(self.angles) * 24;
	spawnPos = physicsTrace(spawnPos, spawnPos + (0, 0, -16)) + (0, 0, 8);

	weaponEnt = createWeaponEnt(weaponName, ammoClip, ammoStock, item, data, spawnPos, self getPlayerAngles() + (0, 90, 0), velocity);

	if (self.ttt.pickups.dropCanDamage)
	{
		self playSound("detpack_pickup");
		weaponEnt.killCamEnt = spawn("script_model", weaponEnt.origin);

		weaponEnt thread setTrailEffect();
		weaponEnt thread weaponEntKillCamEntThink(self);
		weaponEnt thread OnWeaponEntDamagePlayer(self);
	}

	if (!isAlive(self)) return;

	self takeWeapon(weaponName);

	if (self getPrimaryWeaponCount() <= 1 && !self hasWeapon(level.ttt.knifeWeapon))
		self giveKnifeWeapon();

	if (weaponWasActive) self switchToLastWeapon();
}

setTrailEffect()
{
	wait(0.05);
	playFXOnTag(level.ttt.effects.trailEffect, self, "tag_weapon");
}

weaponEntKillCamEntThink(attacker)
{
	self endon("death");
	self.physicsEnt endon("physics_finished");

	playerAngles = attacker getPlayerAngles();
	offset = (0, 0, 16);
	offset += anglesToForward(playerAngles) * -48;
	offset += anglesToRight(playerAngles) * -16;

	for (;;)
	{
		wait(0.1); // needs to be at least 2 ticks to allow smooth movement

		self.killCamEnt moveTo(self.physicsEnt.origin + offset, 0.1);
	}
}

OnWeaponEntDamagePlayer(attacker)
{
	self endon("death");
	self.physicsEnt endon("physics_finished");

	TICK_RATE = 20;

	distanceSq = 0.0; // Was used for damage calculation once. Currently always one-hit-kills.

	for (;;)
	{
		if (isDefined(self.physicsEnt.lastTickOrigin))
		{
			forward = anglesToForward(self.physicsEnt.angles);
			lastForward = anglesToForward(self.physicsEnt.lastTickAngles);

			/**
			 * The "collision" of the weapon is determined with 3 parallel traces
			 * that each test for intersection with a player entity.
			 * The middle one (index 1) lies in the center of the weapon.
			 */

			origins = [];
			lastTickOrigins = [];
			for (i = 0; i < 3; i++)
			{
				origins[i] = self.physicsEnt.origin + forward * (i * -12);
				lastTickOrigins[i] = self.physicsEnt.lastTickOrigin + lastForward * (i * -12);
			}

			velocitySq = lengthSquared(origins[1] * TICK_RATE - lastTickOrigins[1] * TICK_RATE);
			distanceSq += distanceSquared(origins[1], lastTickOrigins[1]);

			for (i = 0; i < origins.size; i++)
			{
				trace = bulletTrace(lastTickOrigins[i], origins[i], true, attacker);
				if (isDefined(trace["entity"]) && isPlayer(trace["entity"]) && isAlive(trace["entity"]))
				{
					if (velocitySq > 256 * 256)
					{
						// velocityFactor = min(velocitySq / (512 * 512), 1);
						// distanceFactor = min(distanceSq / (192 * 192), 1);
						// damage = level.ttt.maxhealth * velocityFactor * distanceFactor;
						damage = level.ttt.maxhealth;
						trace["entity"] thread [[level.callbackPlayerDamage]](
							self, // eInflictor The entity that causes the damage. ( e.g. a turret )
							attacker, // eAttacker The entity that is attacking.
							int(damage), // iDamage Integer specifying the amount of damage done
							0, // iDFlags Integer specifying flags that are to be applied to the damage
							"MOD_IMPACT", // sMeansOfDeath Integer specifying the method of death
							self.weaponName, // sWeapon The weapon number of the weapon used to inflict the damage
							trace["position"], // vPoint The point the damage is from?
							trace["normal"] * -1, // vDir The direction of the damage
							"none", // sHitLoc The location of the hit
							0 // psOffsetTime The time offset for the damage
						);
						trace["entity"] playSound("knife_bounce_wood");
					}

					createWeaponEnt(
						self.weaponName,
						self.ammoClip,
						self.ammoStock,
						self.item,
						self.data,
						origins[1],
						self.physicsEnt.angles,
						trace["normal"] * 64 + (0, 0, 48)
					);

					self.physicsEnt delete();
					self.killCamEnt delete();
					self delete();
					return; // function already implicitly ends due to the entity being deleted
				}
			}
		}

		self.physicsEnt.lastTickOrigin = self.physicsEnt.origin;
		self.physicsEnt.lastTickAngles = self.physicsEnt.angles;
		wait(0.05);
	}
}

giveKnifeWeapon()
{
	self giveWeapon(level.ttt.knifeWeapon);
	self SetWeaponAmmoClip(level.ttt.knifeWeapon, 0);
	self SetWeaponAmmoStock(level.ttt.knifeWeapon, 0);
}
