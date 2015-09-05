-- General settings --
WAConfig = scriptConfig("Warding Assistant", "Warding Assistant");
WAConfig.addParam("Version", "Version 1.0 RC 1", SCRIPT_PARAM_INFO, false);
WAConfig.addParam("Enabled", "Script Enabled", SCRIPT_PARAM_ONOFF, true);

-- Drawing options --
WAConfig.addParam("ShowUnrecommended",	"Unrecommended spots", SCRIPT_PARAM_ONOFF, false);
WAConfig.addParam("ShowEnemyTeamSpots",	"Enemy team spots", SCRIPT_PARAM_ONOFF, false);
WAConfig.addParam("ShowNearbyOnly",		"Only nearby spots", SCRIPT_PARAM_ONOFF, true);
WAConfig.addParam("ShowSafeWards",		"SafeWards spots", SCRIPT_PARAM_ONOFF, true);

-- Functionatily options --
WAConfig.addParam("wardClosestSpot",	"Snap to closest", SCRIPT_PARAM_ONOFF, true);

-- Keybind options --
WAConfig.addParam("WardKey",			"Warding Key", SCRIPT_PARAM_KEYDOWN, string.byte("Z"));

--# Classes #--
class "Point" function Point:__init(x, y, z)
    local pos = GetOrigin(x) or type(x) ~= "number" and x or nil
    self.x = pos and pos.x or x
    self.y = pos and pos.y or y
    self.z = pos and pos.z or z
end;

--# Variables #--
local playerPosition = nil;		-- Result of GetOrigin(myHero);
local cursorPosition = nil;		-- Result of Point(GetMousePos());
local wardSlot = 0;				-- Result of getWardSlot();

local lastTriggerTick = GetTickCount();		-- Script global cooldown. Used to prevent from double-warding from one command.
local closestToCursor = nil;	-- Used to determine the closest warding stop from the player cursor.
local closestToCursorRange=nil;	-- Like above.
local hoveredCircle = nil;		-- Used to determine if player selected any predefinied spots by himself.

--# Constant Variables #--
local spotVisibilityRange = 2500;
local spotCircleSize = 30;
local wardCastRange = 600;
local colorTable = {
	["red"]		= {255,0,0},
	["green"]	= {0,255,0},
	["blue"]	= {0,0,255},
	["black"]	= {0,0,0},
	["white"]	= {255,255,255}
};
local wardItems = {
	3340,	-- Warding Totem (Trinket)
	3361,	-- Greater Warding Totem (Trinket Upgrade)
	2049,	-- Sightstone (Blue Stone)
	2045,	-- Ruby Sightstone (Red Stone)
	2044	-- Stealth Ward (Grenn Ward)
}

-- faster than recall
--# Warding Spots #--
local wardSpots = {

	-- {x axis, y axis, z axis, parameters}
	-- 0 - Normal Warding Spot
	-- 1 - Recommended Ward
	-- 2 - Situational Ward
	-- 3 - Blue Team Ward
	-- 4 - Purple Team Ward
	-- 5 - Unrecommended (Hide by default) 
	-- 6 - Highlighted (for debug purposes)
	
	---------------------------
	--# Team-Specific Wards #--
	---------------------------
	
	-- Blue Team (100) --
	{4956,51,2834,3},  -- Base sideEntrance from Red Jungle
	{2697,52,5280,3},  -- Base sideEntrance from Blue Jungle
	{10046,48,6575,3}, -- Middle Lane River Entrance Bush
	
	-- Purple Team (200) --
	
	{3041,95,3068,4},  -- Middle Lane Blue Inhibitor Ward
	
	{9753,52,12071,4}, -- Base sideEntrance from Red Jungle
	{12083,52,9407,4}, -- Base sideEntrance from Blue Jungle
	{9752,-37,6288,4}, -- Middle Lane River Entrance Bush
	
	
	
	--------------------------------
	--# PurpleTeam - Blue Jungle #--
	--------------------------------
	
	{11645,51,7035}, -- Blue Entrance Bush
	{11939,52,7434}, -- Blue Entrance Crossroad
	{11890,51,6964}, -- Blue/Frog Base Entrance
	{11703,50,6054}, -- Blue/Frog River Entrance
	{12684,51,5202}, -- Bottom Lane Jungle Bush Entrance
	--{10701,63,8975}, -- Middle Lane Wolves Entrance * This spot needs rework...
	{10140,51,7703}, -- Middle Lane Bush Crossroad
	
	-------------------------------
	--# PurpleTeam - Red Jungle #--
	-------------------------------
	
	-- Universal Spots --
    {7097,54,11353}, -- Red Bush (Right Edge)
	{6343,54,10054}, -- River Crossroad Bush
	{6742,54,9621},  -- River Crossroad
	{4269,51,11752}, -- Tribush
	{5808,52,12640}, -- Krug Bush (Jungle Vision)
	{8976,55,11344}, -- Base Entrance Bush (Left Edge)
	{9445,52,11436}, -- Base Entrance Bush (Right Edge)
	
	-- Unrecommended Spots --
	{7969,56,11931,5}, -- Red Crossroad Bush (Center)
	{6750,53,11529,5}, -- Red Bush (Center Edge)
	{5648,52,12829,5}, -- Krug Bush (Lane Vision)
	
	-- Purple Team Recommendations --
	{6415,56,11356,4}, -- Red Bush (Left Edge)
	{7701,53,11759,4}, -- Red Crossroad (Left Edge)
	{8156,49,10270,4}, -- Raptor Bush (Left Edge)
	
	-- Blue Team Recommendations --
	--{5298,56,11882,6}, -- Red Crossroad (Right Edge) * Not working dunno why
	{8392,50,10205,5}, -- Raptor Bush (Right Edge)

	-----------------------------
	--# BlueTeam - Red Jungle #--
	-----------------------------
	
	-- Universal Spots --
	{7802,52,3541}, -- Red Bush (Left Edge)
	{6861,52,2985}, -- Red Crosroad Bush (Center)
	{5835,51,3578}, -- Base Entrance Bush (Right Edge)
	{5404,51,3469}, -- Base Entrance Bush (Left Edge)
	{10610,48,3105},-- Tribush
	{9211,50,2281}, -- Krug Camp Brush
	{6689,48,4718}, -- Raptors Bush
	{8490,52,4926}, -- River Crossroad
	{8117,53,5314}, -- River Crossroad Bush
	
	-- Purple Team Recommendations --
	{6550,50,3088,4}, -- Red Crossroad Bush (Left Edge)
	
	-- Blue Team Recommendations --
	{7143,52,3076,3}, -- Red Crossroad Bush (Right Edge)
	
	-- Unrecommended Spots --
	{8347,53,3534,5}, -- Red Bush (Right Edge)
	{8108,51,3392,5}, -- Red Bush (Center Edge)
	
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
	
	--# River and Lanes #--
	
	-- Universal Spots --
	{13453,51,2820}, -- Bottom Lane Purple-side Bush (Top Edge)
	{13004,51,2216}, -- Bottom Lane Purple-side Bush (Bot Edge)
	{12773,52,1876}, -- Bottom Lane Blue-side Bush (Top Edge)
	{12103,51,1328}, -- Bottom Lane Blue-side Bush (Bot Edge)
	{11127,-71,3810},-- Bottom Lane River Entrance Bush
	{11701,-71,4050}, -- Bottom Lane River Entrance
	{6457,-72,8430}, -- Middle Lane Bush - Top/Left Side
	{8483,-72,6384}, -- Middle Lane Bush - Bot/Right Side
	{2694,52,13546}, -- Top Lane 3rd Bush - Right
	{2252,52,13254}, -- Top Lane 3rd Bush - Left
	{1893,52,13003}, -- Top Lane 2nd Bush - Right
	{1602,52,12790}, -- Top Lane 2nd Bush - Left
	{1392,52,12464}, -- Top Lane 1st Bush - Right
	{1216,52,12044}, -- Top Lane 1st Bush - Left
	{3193,-66,10760},-- Top Lane River Bush
	{9339,-72,5727},  -- Dragon Bush
	{10188,-63,5269}, -- Dragon Entrance from Purple Middle Lane Jungle
	{5104,-72,9152}, -- Baron Bush
	{4102,-72,9857}, -- Baron Entrance
	{4684,-72,10050},-- Baron Den
	
	-- Blue Team Recommendations --
	{14001,52,7127,3}, -- Purple Tier 2 Bottom Tower Bush
	{732,52,14037,3},  -- Purple Tier 2 Top Tower Bush
	{7996,49,842,3},   -- Blue Tier 2 Bottom Tower Bush
	{887,52,8341,3},   -- Blue Tier 2 Top Tower Bush
    {10546,-60,5019,3}, -- Dragon Entrance from Blue
	
	-- Purple Team Recommendations --
	{14005,52,6786,4}, -- Purple Tier 2 Bottom Tower Bush
	{9030,52,14039,4}, -- Purple Tier 2 Top Tower Bush
	{7629,49,830,4},   -- Blue Tier 2 Bottom Tower Bush
	{896,52,7930,4}    -- Blue Tier 2 Top Tower Bush
};

local safeWardSpots = {

	--[[{	-- Tribush from Dragon * Not working without mastery atm...
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

--# Searching for available warding item #--
-- Thanks for ilovesona and his Simple Ward Jump script for this solution!
local function getWardSlot()
	local itemSlot = 0;
	for i=1, #wardItems, 1 do
		itemSlot = GetItemSlot(myHero,wardItems[i]);
		if itemSlot ~= 0 and CanUseSpell(myHero, itemSlot) == READY
		then return itemSlot; end;
	end;
	return 0;
end;

--# FUNCTION: Put ward at the selected spot
local function putWard(wardPosition)
	CastSkillShot(wardSlot,wardPosition);
	-- This function is pretty useless after last update, but i won't remove it just yet...
end;

--# Warding Queue #--
local wardingQueue = {};
local queueStarted = false;
function queueReset() wardingQueue = {}; queueStarted = false; end;
function queueAdd(value) table.insert(wardingQueue,value); end;
function doScheduledTasks(wardSlot)
	if next(wardingQueue) ~= nil then -- Just exit from the function is queue is empty.
	
		-- Check if the player interrupted the process?
		if KeyIsDown(0x02) 							-- RMB
		or (KeyIsDown(0x01) and KeyIsDown(0x10))	-- SHIFT + LMB
		or KeyIsDown(0x42)							-- B (Recall)
		or KeyIsDown(0x53)							-- S (Stop)
		then queueReset();
		
		-- Try to compleate current task
		elseif queueStarted == true then
			if GetDistance(wardingQueue[1][1],playerPosition) < wardCastRange then
				putWard(wardingQueue[1][1]);	-- Put current ward according to the plan
				table.remove(wardingQueue,1);	-- Delete current task and get next one
				queueStarted = false;			-- This step is finished.
			end;
				
		-- Force hero to move to the warding position
		else
			MoveToXYZ(wardingQueue[1][2]);
			queueStarted = true;
		end;
	end;
end;

--# FUNCTION: Checking spot restrictions
function verifyRestrictions(spotStatus)

	-- First of all check if there're any restrictions for this spot...
	if spotStatus ~= nil then
	
		-- Players is in Blue Team and this spot is dedicated for Blue Team?
		if (GetTeam(myHero) == 100 and spotStatus == 3)
		
		-- Players is in Purple Team and this spot is dedicated for Purple Team?
		or (GetTeam(myHero) == 200 and spotStatus == 4)
		
		-- This spot is team-specific but player choosed to see both team spots?
		or ((spotStatus == 3 or spotStatus == 4) and WAConfig.ShowEnemyTeamSpots)
		
		-- This spot is unrecommended but player choosed to see those spots?
		or (WAConfig.ShowUnrecommended and spotStatus == 5)
		
		-- This spot is marked by developer for some debug reason. Always show those spots.
		or spotStatus == 6
		
		-- If any of those statements is true then just show the spot...
		then return true;
		else return false;
		end;
	end;
	
	-- Just pass the spot if there's no restrictions...
	return true;
end;

--# PROCEDURE: Warding key trigger
local function wardingKeyTrigger()
	local currentTriggerTick = GetTickCount();
	if WAConfig.WardKey								-- Execute only if player pressed his warding key
	and currentTriggerTick > (lastTriggerTick + 1000)	-- And only it the warding key is not on cooldown (1 second)
	then
	
		-- Update the last trigger tick data
		lastTriggerTick = currentTriggerTick;
		
		-- There is an active circle on the map, so add this circle to the queue
		if hoveredCircle ~= nil then
			queueAdd(hoveredCircle);
		PrintChat("HOVER!");
		
		-- If there's no active circles on the map, enable warding to the closest spot.
		elseif WAConfig.wardClosestSpot then
			putWard(closestToCursor);
			queueReset(); -- This action will broke the queue process, so we need to reset the queue.
			
		-- If absolutely nothing happend, then just decrease warding cooldown by 0.6s.
		else lastTriggerTick = lastTriggerTick - 600; end;
	else 
	end;
end;

--# PROCEDURE: Draw classic warding spot circle
local function drawClassicSpot(wardPosition,distanceFromHero,color)
	local RGB = {};
	local opacity = 0;
	
	-- Initialize circle position
	Circle:__init(wardPosition, spotCircleSize);
	
	-- Determine ward closest to player cursor
	local distanceFromCursor = GetDistance(wardPosition,cursorPosition);
	if closestToCursor == nil then
		closestToCursor = wardPosition;
		closestToCursorRange = distanceFromCursor;
	elseif distanceFromCursor < closestToCursorRange or closestToCursor == nil then
		closestToCursor = wardPosition;
		closestToCursorRange = distanceFromCursor;
	end;
	
	-- Special color an trigger for targeted spots
	if Circle:contains(cursorPosition) then
		hoveredCircle = {wardPosition,wardPosition};
		RGB = {255,255,255};
		opacity = 255;
	
	-- Use standard colors if spot is not targeted by the player
	else
	
		-- Set silver as default circle color
		RGB = {180,180,180};
		opacity = math.floor((1 - (distanceFromHero / spotVisibilityRange)) * 255);
		
		-- Determine circle color
		if color ~= nil then
			local variableType = type(color);
			if variableType == "table" then
				RGB = {color[1], color[2], color[3]};
			elseif variableType == "string" then
				RGB = {colorTable[color][1],colorTable[color][2],colorTable[color][3]}; -- Using colorTable is faster than using elseif for each color.
			end;
		end;
	end;
	
	-- Draw the warding spot with opacity depending on distance from the spot.
	Circle:draw(ARGB(opacity,RGB[1],RGB[2],RGB[3]));
end;

--# PROCEDURE: Draw safe warding spot circle
local function drawSafeSpot(wardPosition,heroPosition,clickPosition,distanceFromHero)
	local opacity = 255;

	-- Ward destination place circle
	Circle:__init(wardPosition, math.ceil(spotCircleSize/2));
	Circle:draw(ARGB(170,255,255,255));
	
	-- Required hero position circle
	Circle:__init(heroPosition,math.floor(spotCircleSize*1.8));
	if Circle:contains(cursorPosition) then
		hoveredCircle = {clickPosition,heroPosition};
	else opacity = math.floor((1 - (distanceFromHero / spotVisibilityRange)) * 255);
	end;
	Circle:draw(ARGB(opacity,255,255,255));
end;

--# FUNCTION: Check if warding spot is in visible range
local function isVisible(heroDistance)
	if WAConfig.ShowNearbyOnly == false
	or heroDistance < spotVisibilityRange then
		return true;
	end;
	return false;
end;

--# PROCEDURE: Draw all warding spots
local function drawWardingSpots()

	-- Classic Warding Spots
	for i=1, #wardSpots, 1 do
		if verifyRestrictions(wardSpots[i][4]) then
			local wardPosition = Point(wardSpots[i][1],wardSpots[i][2],wardSpots[i][3]);
			local distanceFromHero = GetDistance(wardPosition,playerPosition);
			if isVisible(distanceFromHero) then
				drawClassicSpot(wardPosition,distanceFromHero)
			end;
		end;
	end;
	
	-- Safe Warding Spots
	for i=1, #safeWardSpots, 1 do
		local wardPosition = Point(		-- Ward destination
			safeWardSpots[i]["wardPosition"][1],
			safeWardSpots[i]["wardPosition"][2],
			safeWardSpots[i]["wardPosition"][3]);
		local heroPosition = Point(		-- Required hero position
			safeWardSpots[i]["heroPosition"][1],
			safeWardSpots[i]["heroPosition"][2],
			safeWardSpots[i]["heroPosition"][3]);
		local clickPosition = Point(	-- Trigger zone
			safeWardSpots[i]["clickPosition"][1],
			safeWardSpots[i]["clickPosition"][2],
			safeWardSpots[i]["clickPosition"][3]);
		local distanceFromHero = GetDistance(wardPosition,playerPosition);
		if isVisible(distanceFromHero) then
			drawSafeSpot(wardPosition,heroPosition,clickPosition,distanceFromHero);
		end;
	end;
end;

--# MAIN SCRIPT #--
OnLoop(function(myHero)
	if WAConfig.Enabled then
		-- Disable Warding Assistant if player have no wards
		wardSlot = getWardSlot();	
		if wardSlot ~= 0 then
			playerPosition = GetOrigin(myHero);		-- Update current player champion position
			cursorPosition = Point(GetMousePos());	-- Update current player cursor position
			closestToCursor = nil;	-- Value reset 
			hoveredCircle = nil;	-- Value reset
			doScheduledTasks();	-- Check current wards in queue
			drawWardingSpots();	-- Draw all warding spots on the map
			wardingKeyTrigger();-- Check warding key trigger
		end;
	end;
end)
