-- General settings --
TDConfig = scriptConfig("towerDuelist", "Tower Duelist");
TDConfig.addParam("Version", "Version 0.1 Alpha", SCRIPT_PARAM_INFO, false);
TDConfig.addParam("Enabled", "Script Enabled", SCRIPT_PARAM_ONOFF, true);

-- Drawing options --
TDConfig.addParam("ShowReinforcementArmor",	"Show resist boost", SCRIPT_PARAM_ONOFF, false);
TDConfig.addParam("ShowAttacksNeeded",		"Show attacks needed", SCRIPT_PARAM_ONOFF, true);
--TDConfig.addParam("ShowDPS",				"Show your DPS", SCRIPT_PARAM_ONOFF, true);

-- Constant variables --
local playerTeam = GetTeam(GetMyHero());

-- Let's get this party started...
OnLoop(function(myHero)

	-- Don't do anything if this script is disabled.
	if TDConfig.Enabled then

		-- Scan all enemy turrets
		-- Pomysł: Powrot do bazy przerywajacy recall jesli gracz jest dostatecznie blisko i jest to wydajniejsze.
		for key,tower in pairs(objectManager.turrets) do
			local turretHP = GetCurrentHP(tower); -- Get current turret HP
			if GetTeam(tower) ~= playerTeam	-- It's not DotA. We cannot attack our own turrets so just don't show them.
			and turretHP > 1 then			-- Dont draw statistics if the turret is down (dunno why, but it happens sometimes)
			
				-- Apply damage shield if it's present
				turretHP = turretHP + GetDmgShield(tower);
			
				-- Get turret position
				local turretPosition = GetOrigin(tower);
				
				-- Get turret resistances. They're the same for every turret.
				local resistances = 300;
				-- Despite buff description, bonus armor is removed BEFORE minions will get into the turret attack range.
				local closestMinion = ClosestMinion(turretPosition, MINION_ALLY);
				if closestMinion ~= nil then
					if GetDistance(GetOrigin(closestMinion),turretPosition) < 1000 
						then resistances = 100; -- -200 Resistances bonus from Reinforcement Armor passive.
					end;
				end;
				
				-- Calculating hero current damage against this turret
				local adDamage = (GetBaseDamage(myHero)+GetBonusDmg(myHero)) * (100/(100+resistances));
				
				-- Calculating champion DPS on the turret
				-- DPS FUNCTION IS DISABLED UNTIL I FEAGURE OUT HOW TO GET BASIC ATTACK SPEED
				--[[if TDConfig.ShowDPS then
				
					local baseAttackSpeed = 0.658; -- Get hero attack speed
					local attackSpeedBonus = GetAttackSpeed(myHero) - 1; -- -1 Because we want 35% = 0.35 format instead of 1.35 !
					local attackSpeed = baseAttackSpeed + (baseAttackSpeed * attackSpeedBonus);
					local DPS = math.floor(attackSpeed * adDamage);
				end;--]]
				
				--# Showing the message #--
				local message = "";
				local modulesActive = 0;
			
				-- Player want to see his DPS?
				-- DPS FUNCTION IS DISABLED UNTIL I FEAGURE OUT HOW TO GET BASIC ATTACK SPEED
				--[[if TDConfig.ShowDPS then
					message = "DPS: " .. DPS .. "\n";
				end;--]]
			
				-- Player want to see when Reinforcement Armor is active?
				if TDConfig.ShowReinforcementArmor
				and resistances == 300 then
					message = message .. "Reinforcement Armor Active\n";
					modulesActive = modulesActive + 1;
				end;
			
				-- Player want to see attacks needed?
				if TDConfig.ShowAttacksNeeded then
					message = message .. "AA: " .. math.ceil(turretHP / math.floor(adDamage)) .. "\n" ;
					modulesActive = modulesActive + 1;
				end;
				
				-- Draw turret combat statistics
				local textPosition = WorldToScreen(1,GetOrigin(tower));
				DrawText(message,12,textPosition.x,textPosition.y-60,ARGB(255,255,255,255));
			end;
		end;
	end;
end)
