ISAddSpearToGrave = ISBaseTimedAction:derive('ISAddSpearToGrave')

function ISAddSpearToGrave:isValid()
	return true
end

function ISAddSpearToGrave:waitToStart()
	self.character:faceThisObject(self.grave)
	return self.character:shouldBeTurning()
end

function ISAddSpearToGrave:update()
	self.character:faceThisObject(self.grave)
end

function ISAddSpearToGrave:start()
	self:setActionAnim('Loot')
	self.character:SetVariable('LootPosition', 'Low')
end

function ISAddSpearToGrave:stop()
	ISBaseTimedAction.stop(self);
end

function ISAddSpearToGrave:perform()

	local data = self.grave:getModData()
	local data2 = self.grave2:getModData()

	data['spears'] = data['spears'] or {}
	data2['spears'] = data['spears']

	local spears = data['spears']
	if #spears < ISEmptyGraves.getMaxCorpses(self.grave) then
		local itemName = self.spear:getName()
		local itemType = self.spear:getFullType()
		local itemCondition = self.spear:getCondition()
		local itemRepair = self.spear:getHaveBeenRepaired()
		table.insert(spears, {
			name = itemName,
			itemType = itemType,
			condition = itemCondition,
			repair = itemRepair,
		})

		ISBaseTimedAction.perform(self)
		self.character:setPrimaryHandItem(nil)
		self.character:getInventory():Remove(self.spear)

		local grave = #spears % 2 == 1 and self.grave or self.grave2
		local sq = grave:getSquare()
		local name = getSpearSprite(grave)
		local tile = IsoObject.new(sq, name, true)
		tile:setName(name)
		tile:setSprite(name)
		sq:AddTileObject(tile)
	end
end

function ISAddSpearToGrave:new(character, grave, spear, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.grave = grave
	o.grave2 = getGrave(getOtherSquare(grave))
	if not isFirstSquare(grave) then
		o.grave = o.grave2
		o.grave2 = grave
	end
	o.spear = spear
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = time
	if o.character:isTimedActionInstant() then o.maxTime = 1; end
	return o
end
