
GraveTrapMenu = {}

function GraveTrapMenu.OnFillWorldObjectContextMenu(player, context, worldobjects, test)

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
						submenu:addOption(spear:getName(), worldobjects, GraveTrapMenu.onAddSpearToGrave, grave, spear, playerObj)
					end
					return
				end

			end
		end
	end
end

function GraveTrapMenu.OnFillWorldObjectContextMenu2(player, context, worldobjects, test)

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
						submenu:addOption(name, worldobjects, GraveTrapMenu.onRemoveSpearFromGrave, grave, spear, spearIndex, playerObj)
					end
					return
				end
			end
		end
	end
end

function GraveTrapMenu.onAddSpearToGrave(worldobjects, grave, spear, player)
	if luautils.walkAdj(player, grave:getSquare(), false) then
		local primary = true
		local twoHands = false
		ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), spear, primary, twoHands)
		ISTimedActionQueue.add(ISAddSpearToGrave:new(player, grave, spear, 100))
	end
end

function GraveTrapMenu.onRemoveSpearFromGrave(worldobjects, grave, spear, spearIndex, player)
	if luautils.walkAdj(player, grave:getSquare(), false) then
		local primary = true
		local twoHands = false
		ISTimedActionQueue.add(ISRemoveSpearFromGrave:new(player, grave, spear, spearIndex, 100))
	end
end

Events.OnFillWorldObjectContextMenu.Add(GraveTrapMenu.OnFillWorldObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(GraveTrapMenu.OnFillWorldObjectContextMenu2)
