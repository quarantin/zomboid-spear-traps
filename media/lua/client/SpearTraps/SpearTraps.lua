local spearSprites = {

	location_community_cemetary_01_32 = {
		'spear_traps_01_0',
		'spear_traps_01_4',
	},
	location_community_cemetary_01_33 = {
		'spear_traps_01_1',
		'spear_traps_01_5',
		'spear_traps_01_12',
	},
	location_community_cemetary_01_34 = {
		'spear_traps_01_2',
		'spear_traps_01_6',
		'spear_traps_01_13',
	},
	location_community_cemetary_01_35 = {
		'spear_traps_01_3',
		'spear_traps_01_7',
	},
}

local function getGraveSprite(grave)
	local sq = grave:getSquare()
	local objs = sq:getObjects()
	for i=0, objs:size() - 1 do
		local obj = objs:get(i)
		if obj:getName() == 'EmptyGraves' then
			return obj:getSprite():getName()
		end
	end
end

local function isFirstSquare(grave)

	local sprite = getGraveSprite(grave)
	return sprite == 'location_community_cemetary_01_33' or sprite == 'location_community_cemetary_01_34'
end

local function getSpearSprite(grave)
	local graveSprite = getGraveSprite(grave)
	local spearSprites = spearSprites[graveSprite]
	local data = grave:getModData()
	local spears = data['spears'] or {}
	if #spears == 1 then
		return spearSprites[1]
	elseif #spears == 2 then
		return spearSprites[1]
	elseif #spears == 3 then
		return spearSprites[2]
	elseif #spears == 4 then
		return spearSprites[2]
	elseif #spears == 5 then
		return spearSprites[3]
	end
end

local function getTile(square)
	local objs = square:getObjects()
	for i=objs:size() - 1, 0, -1 do
		local obj = objs:get(i)
		if obj ~= nil then
			local spriteName = obj:getTile()
			if spriteName ~= nil and string.find(spriteName, 'spear_traps_01') then
				return obj
			end

			spriteName = obj:getSpriteName()
			if spriteName ~= nil and string.find(spriteName, 'spear_traps_01') then
				return obj
			end

			local sprite = obj:getSprite()
			if sprite ~= nil then
				spriteName = sprite:getName()
				if spriteName ~= nil and string.find(spriteName, 'spear_traps_01') then
					return obj
				end
			end
		end
	end
end

local function findNonBrokenSpear(spears)
	for i = #spears, 1, -1 do
		local spear = spears[i]
		if spear.condition > 0 then
			return i
		end
	end
	return -1
end

local function breakSpear(grave, grave2, spears, spearIndex)
	local data = grave:getModData()
	local data2 = grave2:getModData()
	data['spears'][spearIndex].condition = 0
	data2['spears'][spearIndex].condition = 0
	grave:transmitModData()
	grave2:transmitModData()
end

local function isFilledGrave(grave)
	return grave:getModData()['corpses'] >= ISEmptyGraves.getMaxCorpses(grave)
end

-- TODO Retrieve the grave the way it was mentioned on Discord
local function getGrave(square)
	if square then
		for i=0, square:getSpecialObjects():size() - 1 do
			local grave = square:getSpecialObjects():get(i)
			if grave:getName() == 'EmptyGraves' then
				return grave
			end
		end
	end
end

local function getOtherSquare(grave)
	local data = grave:getModData()
	local sq1 = grave:getSquare()
    if grave:getNorth() then
        if data['spriteType'] == 'sprite1' then
            sq2 = getCell():getGridSquare(sq1:getX(), sq1:getY() - 1, sq1:getZ())
        elseif data['spriteType'] == 'sprite2' then
            sq2 = getCell():getGridSquare(sq1:getX(), sq1:getY() + 1, sq1:getZ())
        end
    else
        if data['spriteType'] == 'sprite1' then
            sq2 = getCell():getGridSquare(sq1:getX() - 1, sq1:getY(), sq1:getZ())
        elseif data['spriteType'] == 'sprite2' then
            sq2 = getCell():getGridSquare(sq1:getX() + 1, sq1:getY(), sq1:getZ())
        end
    end

	return sq2
end

local function getOtherGrave(grave)
	return getGrave(getOtherSquare(grave))
end

local function removeSpearTile(grave)

	local square = grave:getSquare()
	local tile = getTile(square)
	if tile ~= nil then
		square:transmitRemoveItemFromSquare(tile)
		return
	else
		square = getOtherSquare(grave)
		tile = getTile(square)
		if tile ~= nil then
			square:transmitRemoveItemFromSquare(tile)
		end
	end
end

local function giveRandomInjury(player)

	local bodyParts = {
		BodyPartType.Foot_L,
		BodyPartType.Foot_R,
		BodyPartType.LowerLeg_L,
		BodyPartType.LowerLeg_R,
	}

	local bodyPart = player:getBodyDamage():getBodyPart(bodyParts[1 + ZombRand(4)])
	bodyPart:AddDamage(20 + ZombRand(80))
	bodyPart:setAdditionalPain(bodyPart:getAdditionalPain() + ZombRand(20))
end

local function killZombie(zombie)

	zombie:Kill(nil)
	zombie:DoCorpseInventory()
	-- TODO
	--GameClient.sendZombieDeath(zombie)
end

local function damagePart(part, destroy)

	local damage = 100
	if not destroy then
		damage = damage * (10 + ZombRand(40)) / 100
	end

	part:damage(damage)
end

local function damageRandomParts(vehicle, destroy)

	local validParts = {}

	local partLocations = {
		'FrontLeft',
		'FrontRight',
		'RearLeft',
		'RearRight',
	}

	for _, partLocation in pairs(partLocations) do
		local tire = vehicle:getPartById('Tire' .. partLocation)
		local suspension = vehicle:getPartById('Suspension' .. partLocation)
		if tire and tire:getCondition() > 0 then
			table.insert(validParts, {
				tire=tire,
				suspension=suspension,
			})
		end
	end

	local parts = validParts[ZombRand(#validParts)]
	damagePart(parts.tire, destroy)
	damagePart(parts.suspension, false)
end

local function updateVehicle(vehicle)

	local modData = vehicle:getModData()
	local square = vehicle:getSquare()
	local grave = getGrave(square)
	if grave ~= nil and not isFilledGrave(grave) then
		local grave2 = getOtherGrave(grave)
		local data = grave:getModData()
		local spears = data['spears'] or {}
		local spearIndex = findNonBrokenSpear(spears)
		if #spears > 0 and  spearIndex > 0 and not modData.onGrave then
			modData.onGrave = true
			damageRandomParts(vehicle, true)
			removeSpearTile(grave)
			breakSpear(grave, grave2, spears, spearIndex)
		elseif not modData.onGrave then
			modData.onGrave = true
			damageRandomParts(vehicle, false)
		end
	else
		modData.onGrave = nil
	end
end

local function onPlayerUpdate(player)

	if not player:isAlive() or player:isGodMod() or player:isInvincible() then
		return
	end

	local vehicle = player:getVehicle()
	if vehicle then
		return updateVehicle(vehicle)
	end

	local pData = player:getModData()
	local square = player:getSquare()
	local grave = getGrave(square)
	if grave ~= nil and not isFilledGrave(grave) then
		local grave2 = getOtherGrave(grave)
		local data = grave:getModData()
		local spears = data['spears'] or {}
		local spearIndex = findNonBrokenSpear(spears)
		if #spears > 0 and  spearIndex > 0 and not pData.onGrave then
			pData.onGrave = true
			if SandboxVars.SpearTraps.SpearTrapsKillPlayer then
				player:Kill(nil)
				removeSpearTile(grave)
				breakSpear(grave, grave2, spears, spearIndex)
			else
				for i=0, #spears do
					giveRandomInjury(player)
				end
				breakSpear(grave, grave2, spears, spearIndex)
			end
		elseif not pData.onGrave then
			pData.onGrave = true
			if player:isRunning() then
				giveRandomInjury(player)
			end
		end
	else
		pData.onGrave = nil
	end
end

local function onZombieUpdate(zombie)

	if not zombie:isAlive() then
		return
	end

	local zData = zombie:getModData()
	local square = zombie:getSquare()
	local grave = getGrave(square)
	if grave ~= nil and not isFilledGrave(grave) then
		local grave2 = getOtherGrave(grave)
		local data = grave:getModData()
		local spears = data['spears'] or {}
		local spearIndex = findNonBrokenSpear(spears)
		if #spears > 0 and  spearIndex > 0 and not zData.onGrave then
			zData.onGrave = true
			-- TODO
			--killZombie(zombie)
			zombie:Kill(nil)
			removeSpearTile(grave)
			breakSpear(grave, grave2, spears, spearIndex)
		elseif not zData.onGrave then
			zData.onGrave = true
			zombie:knockDown(true)
		end
	else
		zData.onGrave = nil
	end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
Events.OnZombieUpdate.Add(onZombieUpdate)

return {
	getGrave = getGrave,
	getOtherGrave = getOtherGrave,
	getOtherSquare = getOtherSquare,
	getSpearSprite = getSpearSprite,
	isFirstSquare = isFirstSquare,
	removeSpearTile = removeSpearTile,
}
