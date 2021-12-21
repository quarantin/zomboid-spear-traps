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

local function isFirstSquare(grave)

	local sprite = getGraveSprite(grave)
	return sprite == 'location_community_cemetary_01_33' or sprite == 'location_community_cemetary_01_34'
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

return {
	getGrave = getGrave,
	getOtherGrave = getOtherGrave,
	getOtherSquare = getOtherSquare,
	getSpearSprite = getSpearSprite,
	isFirstSquare = isFirstSquare,
	removeSpearTile = removeSpearTile,
}
