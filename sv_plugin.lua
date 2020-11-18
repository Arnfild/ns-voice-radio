local PLUGIN = PLUGIN

netstream.Hook("voiceRadioAdjust", function(client, freq, id)
    if string.len(freq) > 5 then return end
    if !client:getChar() then return end
    if PLUGIN.securedFrequencies[freq] then
        if !table.HasValue(PLUGIN.securedFrequencies[freq], client:Team()) then
            client:notifyLocalized("voiceRadioSecuredFreq")
            return false
        end
    end

    local inv = client:getChar():getInv() or nil

    if (inv) then
        local item

        if (id) then
            item = nut.item.instances[id]
        end

        if (item and item.voiceRadio and item:getOwner() == client) then
            client:EmitSound("buttons/combine_button1.wav", 50, 170)
            client:getChar():setData("voiceRadioFreq", freq)
        else
            client:notifyLocalized("voiceRadioNoRadio")
        end
    end
end)

netstream.Hook("voiceRadioSwitch", function(client, switch, id)
    if !isbool(switch) then return end
    if !client:getChar() then return end

    local inv = client:getChar():getInv() or nil

    if (inv) then
        local item

        if (id) then
            item = nut.item.instances[id]
        end

        if (item and item.voiceRadio and item:getOwner() == client) then
            client:getChar():setData("voiceRadioSwitch", switch)
        else
            client:notifyLocalized("voiceRadioNoRadio")
        end
    end
end)

function PLUGIN:PlayerCanHearPlayersVoice(listener, speaker)
    if speaker:getChar() and listener:getChar() then
        if speaker:getChar():getData("voiceRadioSwitch") and listener:getChar():getData("voiceRadioSwitch") then
            if speaker:getChar():getData("voiceRadioFreq") == listener:getChar():getData("voiceRadioFreq") then 
                return true, true
            end
        end
    end
end