local developerMode = false;

WAConfig = scriptConfig("Warding Assistant", "Warding Assistant");
WAConfig.addParam("Version", "Version 0.3 ALPHA", SCRIPT_PARAM_INFO, false);
WAConfig.addParam("Enabled", "Script Enabled", SCRIPT_PARAM_ONOFF, true);
WAConfig.addParam("Nearby", "Only when nearby", SCRIPT_PARAM_ONOFF, true);
WAConfig.addParam("WardKey", "Put ward on spot", SCRIPT_PARAM_KEYDOWN, string.byte("Z"));
WAConfig.addParam("AutoWardKey", "Ward closest spot", SCRIPT_PARAM_KEYDOWN, string.byte("O"));
class "Point"
  function Point:__init(x, y, z)
    local pos = GetOrigin(x) or type(x) ~= "number" and x or nil
    self.x = pos and pos.x or x
    self.y = pos and pos.y or y
    self.z = pos and pos.z or z
  end

--# Warding Spots #--
local wardSpots = {

	-- 100 - Niebiescy
	-- 200 - Fioletowi

	-----------------------
	--# PurpleTeam Base #--
	-----------------------
	
	-- Defensive Wards --
	{12083,52,9407}, -- Blue Jungle Entrance
	{9753,52,12071}, -- Red Jungle Entrance
	
	--------------------------------
	--# PurpleTeam - Blue Jungle #--
	--------------------------------
	
	{11645,51,7035}, -- Blue Entrance Bush
	{11939,52,7434}, -- Blue Entrance Crossroad
	{11890,51,6964}, -- Blue/Frog Base Entrance
	{11703,50,6054}, -- Blue/Frog River Entrance
	{12684,51,5202}, -- Bottom Lane Jungle Bush Entrance
	{10046,48,6575}, -- Middle Lane River Entrance Bush (Top)
	{9752,-37,6288}, -- Middle Lane River Entrance Bush (Bot)
	{10701,63,8975}, -- Middle Lane Wolves Entrance
	{10140,51,7703}, -- Middle Lane Bush Crossroad
	{14001,52,7127}, -- Tier 2 Tower Bush (Top Side)
	{14005,52,6786}, -- Tier 2 Tower Bush (Bot Side)
	
	-------------------------------
	--# PurpleTeam - Red Jungle #--
	-------------------------------
	
    {7097,54,11353}, -- Red Bush (Right)
	{6750,53,11529}, -- Red Bush (Center)
	{6415,56,11356}, -- Red Bush (Left)
	{6343,54,10054}, -- River Crossroad Bush
	{4269,51,11752}, -- Tribush
	{5648,52,12829}, -- Krug Bush (Lane Vision)
	{5808,52,12640}, -- Krug Bush (Jungle Vision)
	{6978,52,14046}, -- Tier 2 Tower Bush (Left Side)
	{7343,52,14038}, -- Tier 2 Tower Bush (Rigth Side)
	{7701,53,11759}, -- Red Crossroad (Left)
	{5298,56,11882}, -- Red Crossroad (Right)
	{7969,56,11931}, -- Red Crossroad (Center)
	{8976,55,11344}, -- Base Entrance Bush (Jungle-side)
	{9445,52,11436}, -- Base Entrance Bush (Base-side)
	{8156,49,10270}, -- Raptor Bush (Left)
	{8392,50,10205}, -- Raptor Bush (Right)
	{6742,54,9621},  -- Raptor Crossroad

	---------------------
	--# BlueTeam Base #--
	---------------------

	{4956,51,2834}, -- Red Jungle Entrance  (Defensive Ward)
	{2697,52,5280}, -- Blue Jungle Entrance (Defensive Ward)
	{3041,95,3068}, -- Middle Lane Inhibitor Ward (Agressive Ward)
	
	-----------------------------
	--# BlueTeam - Red Jungle #--
	-----------------------------
	
	{8347,53,3534}, -- Red Bush Right
	{8108,51,3392}, -- Red Bush Center
	{7802,52,3541}, -- Red Bush Left
	{6550,50,3088}, -- Red Crossroad Left
	{6861,52,2985}, -- Red Crossroad Center
	{7143,52,3076}, -- Red Crossroad Right
	{8490,52,4926}, -- Raptors Crossroad
	{8117,53,5314}, -- Raptors Crossroad Bush
	{6689,48,4718}, -- Raptors Bush
	{9211,50,2281}, -- Krug Camp Brush
	{5835,51,3578}, -- Base side-entrance Bush (Right Side)
	{5404,51,3469}, -- Base side-entrance Bush (Left Side)
	{7629,49,830},  -- Tier 2 Tower Bush (Left Side)
	{7996,49,842},  -- Tier 2 Tower Bush (Right Side)
	{10610,48,3105},-- Bottom Lane Tribush
	
	-----------------------------
	--# BlueTeam - Blue Jungle #--
	-----------------------------
	
	{3222,51,7879}, -- Blue Bush
	{3443,50,8656}, -- Blue River Entrance
	{2822,51,7443}, -- Blue Crossroad
	{5211,-59,8583},-- Jungle River Entrance (Middle Lane Side)
	{4649,50,7247}, -- Jungle River Entrance Crossroad
	{2281,54,10124},-- Tribush (Defensive Ward)
	{2153,59,9703}, -- Tribush (Agressive Ward)
	{896,52,7930},  -- Tier 2 Tower Bush (Bot Side)
	{887,52,8341},  -- Tier 2 Tower Bush (Top Side)
	
	--# River and meeting points #--
	{9339,72,5727},  -- Dragon River Bush
	{10188,63,5269}, -- Dragon Entrance Ward (Mid Jungle Entrance)
    {10546,60,5019}, -- Dragon Entrance Ward (Blue Entrance)
	{4102,-72,9857}, -- Baron Entrance Ward
	{4684,-72,10050},-- Baron Den Ward
	{5104,-72,9152}, -- Baron Bush
	{6457,-72,8430}, -- Middle Lane Bush - Top Side
	{8483,-72,6384}, -- Middle Lane Bush - Bot Side
	{2694,52,13546}, -- Top Lane 3rd Bush - Right
	{2252,52,13254}, -- Top Lane 3rd Bush - Left
	{1893,52,13003}, -- Top Lane 2nd Bush - Right
	{1602,52,12790}, -- Top Lane 2nd Bush - Left
	{1392,52,12464}, -- Top Lane 1st Bush - Right
	{1216,52,12044}, -- Top Lane 1st Bush - Left
	{3193,-66,10760},-- Top Lane River Bush
	{11127,-71,3810},-- Bottom Lane River Entrance Bush
	{11701,71,4050}, -- Bottom Lane River Entrances Ward
	{11011,-71,5292},-- Purple Jungle Dragon Entrance
	{13453,51,2820}, -- Bottom Lane Purple Bush - Top
	{13004,51,2216}, -- Bottom Lane Purple Bush - Bot
	{12773,52,1876}, -- Bottom Lane Blue Bush - Top
	{12103,51,1328} -- Bottom Lane Blue Bush - Bot
};

local safeWardSpots = {

	--[[{	-- Tribush from Dragon * Not working without mastery...
		["scoutRequired"]	= false,
		["heroPosition"]	= {10072,-71.24,3908},
		["clickPosition"]	= {10297.93,49.03,3358.59},
		["wardPosition"]	= {10273.9,49.03,3257.76}
	} --]]
	
	{	-- Trisbush from Nashor
		["clickPosition"]	= {4627,-71,11311},
		["wardPosition"]	= {4473,51,11457},
		["heroPosition"]	= {4724,-71,10856}
	},
	
	{	-- Blue Top -> Solo Bush
		["clickPosition"]	= {3078,54,10868},
		["wardPosition"]	= {3078,-67,10868},
		["heroPosition"]	= {2824,54,10356}
	},
	
	{	-- Blue Mid -> round Bush
		["clickPosition"]	= {5132,51,8373},
		["wardPosition"]	= {5123,-21,8457},
		["heroPosition"]	= {5474,51,7906}
	},
	
	{	-- Blue Mid -> River Lane Bush
		["clickPosition"]	= {6202,51,8132},
		["wardPosition"]	= {6202,-67,8132},
		["heroPosition"]	= {5874,51,7656}
	},
	
	{	-- Blue Lizard -> Dragon Pass Bush
		["clickPosition"]	= {8400,53,4657},
		["wardPosition"]	= {8523,51,4707},
		["heroPosition"]	= {8022,53,4258}
	},
	
	{	-- Purple Mid -> Round Bush
		["clickPosition"]	= {9703,52,6589},
		["wardPosition"]	= {9823,23,6507},
		["heroPosition"]	= {9372,52,7008}
	},
	
	{	-- Purple Mid -> River Round Bush
		["clickPosition"]	= {8705,53,6819},
		["wardPosition"]	= {8718,95,6764},
		["heroPosition"]	= {9072,53,7158}
	},
	
	{	-- Purple Bottom -> Solo Bush
		["clickPosition"]	= {12353,51,4031},
		["wardPosition"]	= {12023,-66,3757},
		["heroPosition"]	= {12422,51,4508}
	},
	
	{	-- PPurple Lizard -> Nashor Pass Bush
		["clickPosition"]	= {6370,56,10359},
		["wardPosition"]	= {6273,53,10307},
		["heroPosition"]	= {6824,56,10656}
	},
	
	{	-- Blue Golem -> Blue Lizard
		["clickPosition"]	= {8163,51,3436},
		["wardPosition"]	= {8163,51,3436},
		["heroPosition"]	= {8272,51,2908}
	},
	
	{	-- Red Golem -> Red Lizard
		["clickPosition"]	= {6678,56,11477},
		["wardPosition"]	= {6678,53,11477},
		["heroPosition"]	= {6574,56,12006}
	},
	
	{	-- Blue Top Side Brush
		["clickPosition"]	= {2302,52,10874},
		["wardPosition"]	= {2773,-71,11307},
		["heroPosition"]	= {1774,52,10756}
	},
	
	{	-- Mid Lane Death Brush
		["clickPosition"]	= {5332,-70,8275},
		["wardPosition"]	= {5123,-21,8457},
		["heroPosition"]	= {5874,-70,8306}
	},
	
	{	-- Mid Lane Death Brush Right Side
		["clickPosition"]	= {9540,71,6657},
		["wardPosition"]	= {9773,10,6457},
		["heroPosition"]	= {9022,71,6558}
	},
	
	{	-- Blue Inner Turret Jungle
		["clickPosition"]	= {6849,50,2252},
		["wardPosition"]	= {6723,52,2507},
		["heroPosition"]	= {6874,50,1708}
	},
	
	{	-- Purple Inner Turret Jungle
		["clickPosition"]	= {8128,52,12658},
		["wardPosition"]	= {8323,56,12457},
		["heroPosition"]	= {8122,52,13206}
	}
	
};

--# Warding Sources #--
local wardItems = {
	3340,	-- Warding Totem (Trinket)
	3361,	-- Greater Warding Totem (Trinket Upgrade)
	2049,	-- Sightstone (Blue Stone)
	2045,	-- Ruby Sightstone (Red Stone)
	2044	-- Stealth Ward (Grenn Ward)
}

--# Searching for available warding item #--
-- Thanks for ilovesona and his Simple Ward Jump script for this solution!
function getWardSlot ()
	local itemSlot = 0;
	for i=1, #wardItems, 1 do
		itemSlot = GetItemSlot(myHero,wardItems[i]);
		if itemSlot ~= 0 and CanUseSpell(myHero, itemSlot) == READY
		then return itemSlot; end;
	end;
	return 0;
end;

--# Checking if player got "Scout" from utility mastery tree #--
function getScoutStatus ()
	-- 690 Trinket z masterka 600 bes
	local itemSlot = GetItemSlot(myHero,3340);
	if itemSlot == 0 then itemSlot = GetItemSlot(myHero,3361); end;
	if itemSlot ~= 0 and GetCastRange(itemSlot) == 690
		then return true;
	end;
	return false;
end;

--# Warding Queue #--
local wardQueued = nil;
function checkWardingQueue(wardSlot)
	
	-- Don't go any futher if queue is empty!
	if wardQueued ~= nil then
	
		-- Check if the player interrupted the process?
		if KeyIsDown(0x02)	-- Right Mouse Button
		or KeyIsDown(0x41)	-- A Key (Attack)
		or KeyIsDown(0x53)	-- S Key (Stop)
		then
			-- Just clear the queue since player doesn't care anymore...
			wardQueued = nil;
		end;
		
		-- Check if player is already close enough to put this ward...
		local heroPosition = GetOrigin(myHero);
		if GetDistance(heroPosition,wardQueued) < 600 then
		
			-- Just in case if function will be executed without wardSlot variable...
			wardSlot = wardSlot or getWardSlot();
		
			-- Put ward on it's place already...
			CastSkillShot(wardSlot,wardQueued);
			
			-- Clear the queue since the job is done.
			wardQueued = nil;
		end;
	end;
end;

-- Let's get this party started...
OnLoop(function(myHero)
	
	-- Is Warding Assistant enabled?
	if WAConfig.Enabled then
	
		-- First of all, check if player got any wards with him...
		local wardSlot = getWardSlot();
	
		-- Check if there's any warding process on the run...
		checkWardingQueue(wardSlot);
		
		-- Don't show warding circles if player have no wards.
		if wardSlot ~= 0 then
			
			-- Hello there my old friend, I'll need your help...
			local i = 1;
			
			-- Consider 1st ward on the last as the closest one.
			local closestWard = Point(wardSpots[1][1],wardSpots[1][2],wardSpots[1][3]);
			local closestWardDistance = GetDistanceSqr(closestWard,GetOrigin(myHero));
			
			-- Check all normal warding spots
			for i=1, #wardSpots, 1 do
			
				-- Get the warding spot...
				local wardPosition = Point(wardSpots[i][1],wardSpots[i][2],wardSpots[i][3]);
			
				-- Calculate the distance
				local distance = GetDistanceSqr(wardPosition,GetOrigin(myHero));
			
				-- It is a closest ward?
				if distance < closestWardDistance then
					closestWard = wardPosition;
					closestWardDistance = distance;
				end;
			
				-- Don't show warding circles if hero is too far away
				if WAConfig.Nearby ~= true or distance < 1000000
				then
				
					-- Initialize the circle
					Circle:__init(wardPosition,30);
					
					local myszka = GetMousePos();
					local point = Point(myszka.x,myszka.y,(myszka.z+myszka.y));
					if Circle:contains(point) then
						Circle:draw(0xffff0000);
						
						-- Manual ward
						if WAConfig.WardKey then
							CastSkillShot(wardSlot,wardPosition);
						end;
						
					-- Normal circle
					else Circle:draw(0xffffffff); end;
				
				end;
			end;
			
			-- Check safeWards
			for i=1, #safeWardSpots, 1 do
			
				-- Get the warding spot...
				local wardPosition = Point(
					safeWardSpots[i]["wardPosition"][1],
					safeWardSpots[i]["wardPosition"][2],
					safeWardSpots[i]["wardPosition"][3]
				);
				
				local heroPosition = Point(
					safeWardSpots[i]["heroPosition"][1],
					safeWardSpots[i]["heroPosition"][2],
					safeWardSpots[i]["heroPosition"][3]
				);
				
				local clickPosition = Point(
					safeWardSpots[i]["clickPosition"][1],
					safeWardSpots[i]["clickPosition"][2],
					safeWardSpots[i]["clickPosition"][3]
				);
			
				-- Initialize the circle
				Circle:__init(wardPosition,20);
				Circle:draw(0x66ff0000);
				
					
				-- clickPosition Circle 
				Circle:__init(heroPosition,60);
				local myszka = GetMousePos();
				local point = Point(myszka.x,myszka.y+safeWardSpots[i]["wardPosition"][2],myszka.z);
				if Circle:contains(GetMousePos()) then
					Circle:draw(0xff00ff00);
					
						local origin = GetOrigin(myHero);
						tester = GetDistance(origin,clickPosition);
					-- Manual ward
					if WAConfig.WardKey then
						--if IsInDistance(clickPosition,690) then
						if GetDistance(origin,clickPosition) < 690 then
							CastSkillShot(wardSlot,clickPosition);
						else
							wardQueued = clickPosition;
							MoveToXYZ(heroPosition); 
						end;
					end;
					
				-- Just show the circle...
				else Circle:draw(0xffffffff); end;
				
				-- Automatic ward
				if WAConfig.AutoWardKey then
					CastSkillShot(wardSlot,closestWard);
					
				end;
			end;
		
		-- Clear pending warding process if there's no wards left (lol)
		else wardQueued =  nil; end;
		
	
		-- Just some developer tools for you to competely ingore!
		if developerMode == true then
			local origin = GetOrigin(myHero);
			local mousepos = GetMousePos();
			local myscreenpos = WorldToScreen(1,origin.x,origin.y,origin.z);
			DrawText(" " .. math.floor(mousepos.x) .. " " .. math.floor(mousepos.y) .. " " .. math.floor(mousepos.z),24,myscreenpos.x,myscreenpos.y-20,0xff00ff00); 
			
			local text =
				"Trinket R:    " .. " " .. GetCastRange(myHero,GetItemSlot(myHero,2044)) .. "\n" ..
				"TrinkUpgr:  " .. GetItemSlot(myHero,3361) .. " " .. CanUseSpell(myHero, GetItemSlot(myHero,3361)) .. "\n" ..
				"Sightstone: " .. GetItemSlot(myHero,2049) .. " " .. CanUseSpell(myHero, GetItemSlot(myHero,2049)) .. "\n" ..
				"Rubystone:  " .. GetItemSlot(myHero,2045) .. " " .. CanUseSpell(myHero, GetItemSlot(myHero,2045)) .. "\n" ..
				"NormalWard: " .. GetItemSlot(myHero,2044) .. " " .. CanUseSpell(myHero, GetItemSlot(myHero,2044));
				
			--DrawText(text,24,myscreenpos.x,myscreenpos.y-50,0xff00ff00); 
		end; 
	end;
end)
