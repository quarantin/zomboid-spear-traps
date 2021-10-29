require 'SpearTraps/SpearTraps'
require 'TimedActions/ISBaseTimedAction'

ISRemoveSpearFromGrave = ISBaseTimedAction:derive('ISRemoveSpearFromGrave')

function ISRemoveSpearFromGrave:isValid()
	return true
end

function ISRemoveSpearFromGrave:waitToStart()
	self.character:faceThisObject(self.grave)
	return self.character:shouldBeTurning()
end

function ISRemoveSpearFromGrave:update()
	self.character:faceThisObject(self.grave)

	self.character:setMetabolicTarget(Metabolics.LightDomestic) -- TODO Find more appropriate Metabolics for this task
end

function ISRemoveSpearFromGrave:start()
	self:setActionAnim('Loot')
	self.character:SetVariable('LootPosition', 'Low')
end

function ISRemoveSpearFromGrave:stop()
	ISBaseTimedAction.stop(self);
end

function removeSpear(character, grave, data, data2, spears, spearIndex, spearItem)
	local square = grave:getSquare()
	local tile = getTile(square)
	if tile ~= nil then
		table.remove(spears, spearIndex)
		square:RemoveTileObject(tile)
		character:getInventory():AddItem(spearItem)
		return true
	end
	return false
end

function ISRemoveSpearFromGrave:perform()

	local data = self.grave:getModData()
	local data2 = self.grave2:getModData()

	data['spears'] = data['spears'] or {}
	data2['spears'] = data['spears']

	local spears = data['spears']
	if #spears > 0 then
		local spearIndex = indexOf(spears, self.spear)
		if spearIndex > 0 then
			if not removeSpear(self.character, self.grave, data, data2, spears, spearIndex, self.spearItem) then
				print('PROBLEM!')
				if removeSpear(self.character, self.grave2, data, data2, spears, spearIndex, self.spearItem) then
					print('PROBLEM SOLVED!')
				end
			end
		end
	end

	ISBaseTimedAction.perform(self)
end


function ISRemoveSpearFromGrave:new(character, grave, spear, time)
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
	o.spearItem = InventoryItemFactory.CreateItem(spear.itemType)
	o.spearItem:setCondition(spear.condition)
	o.spearItem:setHaveBeenRepaired(spear.repair)
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = time
	if o.character:isTimedActionInstant() then o.maxTime = 1; end
	return o
end
