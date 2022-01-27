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

local function onAddSpear(worldobjects, grave, items, player)
	local closestSquare = getClosestSquare(player, grave)
	if luautils.walkAdj(player, closestSquare, false) then
		local primary = true
		local twoHands = false
		local spears = {}
		for i = 1, math.min(5, #items) do
			table.insert(spears, items[i])
		end
		for spearIndex, spear in pairs(spears) do
			ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), spear, primary, twoHands)
			ISTimedActionQueue.add(ISAddSpearToGrave:new(player, grave, spear, 100))
		end
	end
end

local function onRemoveSpear(worldobjects, grave, spears, player)
	local closestSquare = getClosestSquare(player, grave)
	if luautils.walkAdj(player, closestSquare, false) then
		local primary = true
		local twoHands = false
		for _, item in ipairs(spears) do
			ISTimedActionQueue.add(ISRemoveSpearFromGrave:new(player, grave, item.spear, item.index, 100))
		end
	end
end

local function aggregateItems(items)

	local aggregate = {}

	for i = 0, items:size() - 1 do

		local item = items:get(i)
		local itemName = item:getName()
		if not aggregate[itemName] then
			aggregate[itemName] = {}
		end
		table.insert(aggregate[itemName], item)
	end

	return aggregate
end

local function aggregateItems2(items)

	local aggregate = {}

	for index, item in ipairs(items) do

		local itemName = item.name
		if item.condition <= 0 then
			itemName = itemName .. ' (Broken)'
		end

		if not aggregate[itemName] then
			aggregate[itemName] = {}
		end
		table.insert(aggregate[itemName], {
			index=index,
			spear=item,
		})
	end

	return aggregate
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

	items = aggregateItems(items)

	for i,v in ipairs(worldobjects) do
		local square = v:getSquare()
		for i=0, square:getSpecialObjects():size()-1 do
			local grave = square:getSpecialObjects():get(i)
			if grave:getName() == 'EmptyGraves' then
				local data = grave:getModData() or {}
				local spears = data['spears'] or {}
				local corpses = data['corpses'] or 0
				local maxCorpses = ISEmptyGraves.getMaxCorpses(grave)

				if #spears < maxCorpses and corpses < maxCorpses then
					local rootmenu = context:addOption(getText('ContextMenu_AddSpearToGrave'), worldobjects, nil)
					local submenu = context:getNew(context)
					context:addSubMenu(rootmenu, submenu)
					for name, spears in pairs(items) do
						local itemName = name
						if #spears > 1 then
							itemName = itemName .. ' (' .. tostring(#spears) .. ')'
						end
						submenu:addOption(itemName, worldobjects, onAddSpear, grave, spears, playerObj)
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
				local data = grave:getModData() or {}
				local items = data['spears'] or {}
				if #items > 0 then
					local rootmenu = context:addOption(getText('ContextMenu_RemoveSpearFromGrave'), worldobjects, nil)
					local submenu = context:getNew(context)
					context:addSubMenu(rootmenu, submenu)
					items = aggregateItems2(items)
					for name, spears in pairs(items) do
						local itemName = name
						if #spears > 1 then
							itemName = itemName .. ' (' .. tostring(#spears) .. ')'
						end
						submenu:addOption(itemName, worldobjects, onRemoveSpear, grave, spears, playerObj)
					end
					return
				end
			end
		end
	end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu2)
