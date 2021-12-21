local SpearTraps = require("SpearTraps/SpearTraps")

local function isFilledGrave(grave)
	return grave:getModData()['corpses'] >= ISEmptyGraves.getMaxCorpses(grave)
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

local function breakSpear(grave, grave2, spears, spearIndex)
	local data = grave:getModData()
	local data2 = grave2:getModData()
	data['spears'][spearIndex].condition = 0
	data2['spears'][spearIndex].condition = 0
	grave:transmitModData()
	grave2:transmitModData()
end

local function onPlayerUpdate(player)

	if not player:isAlive() then
		return
	end

	local pData = player:getModData()
	local square = player:getSquare()
	local grave = SpearTraps.getGrave(square)
	if grave ~= nil and not isFilledGrave(grave) then
		local grave2 = SpearTraps.getOtherGrave(grave)
		local data = grave:getModData()
		local spears = data['spears'] or {}
		local spearIndex = findNonBrokenSpear(spears)
		if #spears > 0 and  spearIndex > 0 and not pData.onGrave then
			pData.onGrave = true
			if SandboxVars.SpearTraps.SpearTrapsKillPlayer then
				player:Kill(nil)
				SpearTraps.removeSpearTile(grave)
				breakSpear(grave, grave2, spears, spearIndex)
			else
				for i=0, #spears do
					SpearTraps.giveRandomInjury(player)
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
	local grave = SpearTraps.getGrave(square)
	if grave ~= nil and not isFilledGrave(grave) then
		local grave2 = SpearTraps.getOtherGrave(grave)
		local data = grave:getModData()
		local spears = data['spears'] or {}
		local spearIndex = findNonBrokenSpear(spears)
		if #spears > 0 and  spearIndex > 0 and not zData.onGrave then
			zData.onGrave = true
			-- TODO
			--killZombie(zombie)
			zombie:Kill(nil)
			SpearTraps.removeSpearTile(grave)
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
