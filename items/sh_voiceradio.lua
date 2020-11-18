ITEM.name = "Voice radio"
ITEM.model = "models/gibs/shield_scanner_gib1.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Communication"

function ITEM:getDesc()
	local str
	
	if (!self.entity or !IsValid(self.entity)) then
		str = "A radio that allows you to talk to other characters in distance.\nPress %s to configure the radio."
		return Format(str, input.LookupBinding( nut.config.get("voiceRadio_button") ))
	end
end

-- If you want to create other radio items, then make sure your item has the code below:
ITEM.voiceRadio = true
ITEM:hook("drop", function(item)
	local invItems = item.player:getChar():getInv():getItems() or nil
	local radioItems = 0
	for k, item in pairs (invItems) do
		if item.voiceRadio then
			radioItems = radioItems + 1
		end
	end
	if radioItems <= 1 then
		item.player:getChar():setData("voiceRadioSwitch", false)
	end
end)