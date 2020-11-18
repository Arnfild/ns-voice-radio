PLUGIN.name = "Voice Radio"
PLUGIN.author = "Sample Name"
PLUGIN.desc = "You can use voice chat to communicate with other people in distance."

nut.config.add(
	"voiceRadio_icon",
	"icon32/unmuted.png",
	"Path to an image shown when radio is active.",
	nil,
	{category = PLUGIN.name}
)

nut.config.add(
	"voiceRadio_button",
	"gm_showspare2",
	"A binding that will activate the radio configuration menu.",
	nil,
	{category = PLUGIN.name}
)

nut.util.include("sv_plugin.lua")

local PLUGIN = PLUGIN

function PLUGIN:InitializedSchema()
	-- [TEAM_ENUM] = "string Frequency", that's a frequency that will be applied when pressing on faction frequency button
	-- Be aware! Your factions must be placed in SCHEMA, NOT PLUGINS. That is called when schema is initialized
	-- Frequency consists of 3 or 4 digits with 4th being separated by a dot. Examples: "153", "874.3"
	PLUGIN.factionFrequencies = {
		--[TEAM_LONER] = "454.3",
		--[TEAM_CLEARSKY] = "454.1"
	}

	-- These are the frequncies that can be joined only be certain factions
	PLUGIN.securedFrequencies = {
		--["454.3"] = { TEAM_LONER, TEAM_MONOLITH }
	}
end

if CLIENT then
	function PLUGIN:PlayerBindPress(client, bind, pressed)
		if (bind:lower():find(nut.config.get("voiceRadio_button")) and pressed) then
			if (LocalPlayer():getChar()) then
				local invItems = LocalPlayer():getChar():getInv():getItems() or nil
				for k, item in pairs (invItems) do
					if item.voiceRadio then
						local radioSetup = vgui.Create("voiceRadioSetup")
						--radioSetup.itemID = inv:getFirstItemOfType(PLUGIN.radioItems[k]):getID()
						radioSetup.itemID = item.id
						break
					end
				end
			end
			return true
		end
	end

	local voiceIcon = Material(nut.config.get("voiceRadio_icon"))
	function PLUGIN:HUDPaint()
		if !LocalPlayer():getChar() then return end
		if !LocalPlayer():getChar():getData("voiceRadioSwitch") then return end
		surface.SetMaterial(voiceIcon)
		surface.SetDrawColor(0, 255, 63, 255)
		surface.DrawTexturedRect(ScrW() * 0.95, ScrH() * 0.05, 64, 64)
	end

	local gradient_l = Material( 'vgui/gradient-l' )
	local PANEL = {}
	function PANEL:Init()
		self.number = 0
		self:SetWide(70)

		local up = self:Add("DButton")
		up:SetFont("Marlett")
		up:SetText("t")
		up:Dock(TOP)
		up:DockMargin(2, 2, 2, 2)
		up.DoClick = function(this)
			self.number = (self.number + 1)% 10
			surface.PlaySound("buttons/lightswitch2.wav")
		end

		local down = self:Add("DButton")
		down:SetFont("Marlett")
		down:SetText("u")
		down:Dock(BOTTOM)
		down:DockMargin(2, 2, 2, 2)
		down.DoClick = function(this)
			self.number = (self.number - 1)% 10
			surface.PlaySound("buttons/lightswitch2.wav")
		end

		local number = self:Add("Panel")
		number:Dock(FILL)
		number.Paint = function(this, w, h)
			draw.SimpleText(self.number, "nutDialFont", w/2, h/2, color_white, 1, 1)
		end
	end

	vgui.Register("voiceRadioDial", PANEL, "DPanel")

	PANEL = {}

	function PANEL:Init()
		self:SetTitle(L("voiceRadioFreq"))
		self:SetSize(330, 260)
		self:Center()
		self:MakePopup()

		self.submit = self:Add("DButton")
		self.submit:Dock(BOTTOM)
		self.submit:DockMargin(0, 5, 0, 0)
		self.submit:SetTall(25)
		self.submit:SetText(L("voiceRadioSubmit"))
		self.submit:SetTextColor(color_white)
		self.submit.DoClick = function()
			local str = ""
			for i = 1, 5 do
				if (i != 4) then
					str = str .. tostring(self.dial[i].number or 0)
				else
					str = str .. "."
				end
			end
			netstream.Start("voiceRadioAdjust", str, self.itemID)
			self:Close()
		end

		if PLUGIN.factionFrequencies[LocalPlayer():Team()] then
			self.factionFreq = self:Add("DButton")
			self.factionFreq:Dock(BOTTOM)
			self.factionFreq:DockMargin(0, 5, 0, 0)
			self.factionFreq:SetTall(25)
			self.factionFreq:SetText(L("voiceRadioFactionFreq") .. " " .. nut.faction.indices[LocalPlayer():Team()].name)
			self.factionFreq:SetTextColor(color_white)
			self.factionFreq.DoClick = function()
				local str = PLUGIN.factionFrequencies[LocalPlayer():Team()]
				local strArr = {}
				for i = 1, #str do
					strArr[i] = str:sub(i, i)
				end

				self.dial[1].number = strArr[1] or 0
				self.dial[2].number = strArr[2] or 0
				self.dial[3].number = strArr[3] or 0
				self.dial[5].number = strArr[5] or 0
				surface.PlaySound("buttons/lightswitch2.wav")
			end
		end

		self.switch = self:Add("DButton")
		if !LocalPlayer():getChar():getData("voiceRadioSwitch") then
			self.switch:SetText(L("voiceRadioOn"))
			timer.Simple(0.01, function()
				self:OnSwitch()
			end)
		else
			self.switch:SetText(L("voiceRadioOff"))
		end
		self.switch:Dock(TOP)
		self.switch:DockMargin(0, 0, 0, 5)
		self.switch:SetTall(25)
		self.switch:SetTextColor(color_white)
		self.switch.DoClick = function()
			self:OnSwitch()
		end

		self.dial = {}
		local freq = LocalPlayer():getChar():getData("voiceRadioFreq") or nil
		if freq then
			freqArr = {}
			for i = 1, #freq do
				freqArr[i] = freq:sub(i, i)
			end
		end
		for i = 1, 5 do
			if (i != 4) then
				self.dial[i] = self:Add("voiceRadioDial")
				self.dial[i]:Dock(LEFT)
				if (i != 3) then
					self.dial[i]:DockMargin(0, 0, 5, 0)
				end
				self.dial[i].number = freqArr[i] or 0
			else
				local dot = self:Add("Panel")
				dot:Dock(LEFT)
				dot:SetWide(30)
				dot.Paint = function(this, w, h)
					draw.SimpleText(".", "nutDialFont", w/2, h - 10, color_white, 1, 4)
				end
			end
		end
	end

	function PANEL:OnSwitch()
		if IsValid(self.switch.off) then 
			self.switch.off:Remove()
			self.switch:SetText(L("voiceRadioOff"))
			netstream.Start("voiceRadioSwitch", true, self.itemID)
			return 
		end

		self.switch.off = self:Add("DPanel")
		self.switch.off:SetSize(self.switch:GetWide(), self:GetTall() - self.switch:GetTall() - 40)
		self.switch.off:SetPos(self.switch.x, self.switch.y + self.switch:GetTall() + 5)
		self.switch.off.Paint = function(self, w, h)
			surface.SetDrawColor(255, 0, 0, 50)
			surface.SetMaterial(gradient_l)
			surface.DrawTexturedRect(0, 0, w, h)
		end
		self.switch:SetText(L("voiceRadioOn"))
		netstream.Start("voiceRadioSwitch", false, self.itemID)
	end

	function PANEL:Think()
		self:MoveToFront()
	end

	vgui.Register("voiceRadioSetup", PANEL, "DFrame")

	surface.CreateFont("nutDialFont", {
		font = "Agency FB",
		size = 100,
		weight = 1000
	})

	surface.CreateFont("nutRadioFont", {
		font = "Lucida Sans Typewriter",
		size = math.max(ScreenScale(7), 17),
		weight = 100
	})
end