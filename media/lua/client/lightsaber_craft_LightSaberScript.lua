------------------------------------------------------------------------------------------------------------------------
-- Hello there! This is another rewrite of that lightsaber mod that has machetes. I don't care about
-- those machetes, I just want lightsabers, and I don't care about the clothes for now either
-- Reworked the code to be a bit more effecient and maintainable by using a data structure.
-- Also turns off the lightsaber automatically if attaching back to the hotbar.
------------------------------------------------------------------------------------------------------------------------

local lightByPlayer = {};

local function getSaberAndState(item)
    if item == nil then return nil end
    local type = item:getType();
    if type == nil then return nil end
    local t = {};
    for i in string.gmatch(type, "[^_]+") do
        t[#t + 1] = i;
    end
    return t[1], t[2];
end

local function lightUp(player, item)
    local saber, _ = getSaberAndState(item);
    if saber == nil then return end
    local color = Lightsaber[saber].LightColorData;
    lightByPlayer[player] = IsoLightSource.new(player:getX(), player:getY(), player:getZ(), color[1], color[2], color[3], 4);
    getCell():addLamppost(lightByPlayer[player]);
end

local function toggleLightSaber(player, item, item_name, state, hotbar)
    local state_int = state and 1 or 0 -- This is tricky because the state bool reflects whether the saber is off.
    player:playSound(Lightsaber[item_name][state_int].Sound);

    local inventory = player:getInventory();

    newitem = inventory:AddItem(Lightsaber[item_name][state_int].Model);
    player:setPrimaryHandItem(newitem);
    newitem:setCondition(item:getCondition());
    if not state then
        getCell():removeLamppost(lightByPlayer[player]);
    end
    inventory:Remove(item);

    if hotbar == nil then return end
    local original_slot = item:getAttachedSlot()
    local slot = hotbar.availableSlot[original_slot]
    if (slot) and (newitem) and (not hotbar:isInHotbar(newitem)) and (hotbar:canBeAttached(slot, newitem)) then
        hotbar:removeItem(item, false)
        hotbar:attachItem(newitem, slot.def.attachments[newitem:getAttachmentType()], original_slot, slot.def, false)
    end
end

local function LightSaberGlow(player)
    local SaberListOn = {};
    local item = player:getPrimaryHandItem();
    if not item then
		if lightByPlayer[player] ~= nil then
			getCell():removeLamppost(lightByPlayer[player]);
		end
		return
    end

    local saber, state = getSaberAndState(item);
    if saber == nil or state == "off" or Lightsaber[saber] == nil then return end

    if Lightsaber[saber].LightColorData ~= nil then
		table.insert(SaberListOn, item);
    end

    if lightByPlayer[player] ~= nil then
		getCell():removeLamppost(lightByPlayer[player]);
    end

    for i, it in ipairs(SaberListOn) do
		if it == item then
			lightUp(player, it);
			it:setBloodLevel(0.0);
			-- player:playSound("SaberHum") -- This was noted in the original mod, but this humming is indeed annoying
		end
    end
end

local function LightSaberUpdate(key)
    local player = getPlayer();
    if player == nil then return end

    if (key == getCore():getKey("Ignite_LS")) then
		local item = player:getPrimaryHandItem();
		if item == nil then return end

		local saber, state = getSaberAndState(item);
        if saber == nil then return end

        if Lightsaber[saber] ~= nil then
            toggleLightSaber(player, item, saber, state == "off", getPlayerHotbar(0));
        end
    else
        if player:isAttacking() then return end

        local hotbar = getPlayerHotbar(player:getPlayerNum());
        if hotbar == nil then return end

        local slotToCheck = hotbar:getSlotForKey(key);
        if slotToCheck == -1 then return end

        local item = player:getPrimaryHandItem();
        if item == nil or item:getAttachedSlot() ~= slotToCheck or item:getModID() ~= "lightsaber_craft" then return end

		local saber, state = getSaberAndState(item);
        if saber == nil then return end

        -- At this point, we can be sure that the player is trying to put away our primary equipped lightsaber
        -- Check if lightsaber is on, if it is toggle off

        if state == "on" then
            toggleLightSaber(player, item, saber, false, hotbar);
        end
    end
end

Events.OnPlayerUpdate.Add(LightSaberGlow);
Events.OnKeyStartPressed.Add(LightSaberUpdate);