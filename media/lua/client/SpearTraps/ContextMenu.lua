local SpearTraps = require('SpearTraps/SpearTraps')

local function distance(sq1, sq2)
	return math.sqrt(math.pow(sq1:getX() - sq2:getX(), 2) + math.pow(sq1:getY() - sq2:getY(), 2))
end

local function getClosestSquare(player, grave)

	local square = player:getSquare()

	local sq1 = grave:getSquare()
	local sq2 = SpearTraps.getOtherSquare(grave)

	local d1 = distance(square, sq1)
	local d2 = distance(square, sq2)

	return d1 < d2 and sq1 or sq2
end

local function onAddSpear(worldobjects, grave, spear, player)
	print('DEBUG: 1')
	local closestSquare = getClosestSquare(player, grave)
	if luautils.walkAdj(player, closestSquare, false) then
		print('DEBUG: 2')
		local primary = true
		local twoHands = false
		ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), spear, primary, twoHands)
		ISTimedActionQueue.add(ISAddSpearToGrave:new(player, grave, spear, 100))
		print('DEBUG: 3')
	end
end

local function onRemoveSpear(worldobjects, grave, spear, spearIndex, player)
	local closestSquare = getClosestSquare(player, grave)
	if luautils.walkAdj(player, closestSquare, false) then
		local primary = true
		local twoHands = false
		ISTimedActionQueue.add(ISRemoveSpearFromGrave:new(player, grave, spear, spearIndex, 100))
	end
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)

	if test and ISWorldObjectContextMenu.Test then return true end

	local playerObj = getSpecificPlayer(player)
	local inventory = playerObj:getInventory()
	local items = ArrayList.new()

	inventory:getAllEvalRecurse(function(item, player)
		if item:isBroken() then return false end
		if item:getScriptItem():getCategories():contains('Spear') then return true end
		return false
	end, items)

	if items:size() <= 0 then
		return
	end

	for i,v in ipairs(worldobjects) do
		local square = v:getSquare()
		for i=0, square:getSpecialObjects():size()-1 do
			local grave = square:getSpecialObjects():get(i)
			if grave:getName() == 'EmptyGraves' then
				local data = grave:getModData()
				data['spears'] = data['spears'] or {}
				local spears = data['spears']
				local corpses = data['corpses']
				local maxCorpses = ISEmptyGraves.getMaxCorpses(grave)
				if #spears < maxCorpses and corpses < maxCorpses then
					local rootmenu = context:addOption(getText('ContextMenu_AddSpearToGrave'), worldobjects, nil)
					local submenu = context:getNew(context)
					context:addSubMenu(rootmenu, submenu)
					for i = 0, items:size() - 1 do
						local spear = items:get(i)
						submenu:addOption(spear:getName(), worldobjects, onAddSpear, grave, spear, playerObj)
					end
					return
				end

			end
		end
	end
end

local function onFillWorldObjectContextMenu2(player, context, worldobjects, test)

	if test and ISWorldObjectContextMenu.Test then return true end

	local playerObj = getSpecificPlayer(player)

	for i,v in ipairs(worldobjects) do
		local square = v:getSquare()
		for i=0, square:getSpecialObjects():size()-1 do
			local grave = square:getSpecialObjects():get(i)
			if grave:getName() == 'EmptyGraves' then
				local data = grave:getModData()
				data['spears'] = data['spears'] or {}

				local spears = data['spears']
				if #spears > 0 then
					local rootmenu = context:addOption(getText('ContextMenu_RemoveSpearFromGrave'), worldobjects, nil)
					local submenu = context:getNew(context)
					context:addSubMenu(rootmenu, submenu)
					for spearIndex, spear in pairs(spears) do
						local name = spear.name
						if spear.condition <= 0 then
							name = name .. ' (Broken)'
						end
						submenu:addOption(name, worldobjects, onRemoveSpear, grave, spear, spearIndex, playerObj)
					end
					return
				end
			end
		end
	end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu2)
