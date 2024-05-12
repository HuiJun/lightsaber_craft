------------------------------------------------------------------------------------------------------------------------
-- Hello there! This is another rewrite of that lightsaber mod that has machetes. I don't care about
-- those machetes, I just want lightsabers, and I don't care about the clothes for now either
-- Reworked the code to be a bit more effecient and maintainable by using a data structure.
-- Also turns off the lightsaber automatically if attaching back to the hotbar.
------------------------------------------------------------------------------------------------------------------------

local lightByPlayer = {};

local function getSaberAndState(player, item)
    local playerSaberStates = {};
    if player == nil then
        player = getPlayer();
    end
    if player == nil then return nil,nil end
    playerSaberStates[player] = {};
    print('Player: ');
    print(player);
    if item == nil and player ~= nil then
        item = player:getPrimaryHandItem();
    end
    if item == nil then return nil,nil end
    if item:getModID() ~= "lightsaber_craft" then return nil,nil end
    local type = item:getType();
    if type == nil then return nil,nil end
    local t = {};
    for i in string.gmatch(type, "[^_]+") do
        t[#t + 1] = i;
    end
    if t[1] ~= nil and t[2] ~= nil then
        playerSaberStates[player].saber = t[1];
        playerSaberStates[player].state = t[2];
    end
    return playerSaberStates[player].saber, playerSaberStates[player].state;
end

local function handleHotbarSwap(hotbar, old_item, new_item)
    if hotbar == nil then return end
    local original_slot = old_item:getAttachedSlot();
    local slot = hotbar.availableSlot[original_slot];
    if (slot) and (new_item) and (not hotbar:isInHotbar(newitem)) and (hotbar:canBeAttached(slot, new_item)) then
        hotbar:removeItem(old_item, false);
        hotbar:attachItem(new_item, slot.def.attachments[new_item:getAttachmentType()], original_slot, slot.def, false);
    end
end

local function setAmbientLight(player, color)
    if lightByPlayer[player] ~= nil then
        getCell():removeLamppost(lightByPlayer[player]);
    end
    lightByPlayer[player] = IsoLightSource.new(player:getX(), player:getY(), player:getZ(), color[1], color[2], color[3], 4);
    getCell():addLamppost(lightByPlayer[player]);
end

local function toggleLightSaber(player, item_id, item_name, state, hotbar)
    local request_state = state and 1 or 0 -- This is tricky because the state bool reflects whether the saber is off.
    player:playSound(Lightsaber[item_name][request_state].Sound);
    local inventory = player:getInventory();

    local old_item = inventory:getItemById(item_id);
    local new_item = inventory:AddItem(Lightsaber[item_name][request_state].Model);

    if old_item ~= nil then
        new_item:setCondition(old_item:getCondition());
    end

    handleHotbarSwap(hotbar, old_item, new_item);

    if player:isPrimaryHandItem(old_item) then
        player:setPrimaryHandItem(new_item);
    end
    if player:isSecondaryHandItem(old_item) then
        player:setSecondaryHandItem(new_item);
    end

    if not state and lightByPlayer[player] ~= nil then
        getCell():removeLamppost(lightByPlayer[player]);
        lightByPlayer[player] = nil;
    end

    inventory:Remove(old_item);
    old_item = nil;
end

local function LightSaberGlow(player)
    local item = player:getPrimaryHandItem();
    local saber, state = getSaberAndState(player, item);
    if saber == nil or state == "off" or Lightsaber[saber] == nil then return end
    setAmbientLight(player, Lightsaber[saber].LightColorData);
    if item:getBloodLevel() == 0 then return end
    item:setBloodLevel(0);
    player:resetEquippedHandsModels();
    -- player:playSound("SaberHum") -- This was noted in the original mod, but this humming is indeed annoying
end

local function LightSaberReplaceInInventory(player)
    local inventory = player:getInventory();
    if inventory == nil then return end

    for saber_name, _ in pairs(Lightsaber) do
        -- Hopefully this is more performant than iterating through all of player inventory
        local saber_on = inventory:getItemFromType(saber_name.."_on", true, true);
        if saber_on ~= nil then
            local primary = player:getPrimaryHandItem();
            if primary == nil or saber_on:getType() ~= primary:getType() then
                toggleLightSaber(player, saber_on:getID(), saber_name, false, getPlayerHotbar(player:getPlayerNum()));
            end
        end
    end
end

local function LightSaberTrigger(key)
    if (key == getCore():getKey("Ignite_LS")) then
        local player = getPlayer();
        if player == nil then return end

        local primary = player:getPrimaryHandItem();
        if primary == nil then return end
        local saber, state = getSaberAndState(player, primary);
        if saber == nil then return end
        if Lightsaber[saber] ~= nil then
            toggleLightSaber(player, primary:getID(), saber, state == "off", getPlayerHotbar(player:getPlayerNum()));
        end
    end
end

local function LightSaberAutoOff(key)
    -- This section only handles putting away a saber when attached to a belt. Because it should be faster
    local player = getPlayer();
    if player == nil then return end

    if player:isAttacking() then return end

    local hotbar = getPlayerHotbar(player:getPlayerNum());
    if hotbar == nil then return end

    local slotToCheck = hotbar:getSlotForKey(key);
    if slotToCheck == -1 then return end

    local item = player:getPrimaryHandItem();
    if item == nil then return end

    local saber, _ = getSaberAndState(player, item);
    if saber == nil or item:getAttachedSlot() == -1 then return end

    -- At this point, we can be sure that the player is trying to put away our primary equipped lightsaber
    -- Toggle off

    toggleLightSaber(player, item:getID(), saber, false, hotbar);
end

Events.OnPlayerUpdate.Add(LightSaberGlow);
Events.OnPlayerUpdate.Add(LightSaberReplaceInInventory);
Events.OnKeyStartPressed.Add(LightSaberTrigger);
Events.OnKeyStartPressed.Add(LightSaberAutoOff);
