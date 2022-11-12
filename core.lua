local CVAR = "Sound_OutputDriverIndex"

local DriverIndexSetting

local function GetDriverIndex()
	return DriverIndexSetting:GetValue()
end

local function SetDriverIndex(index)
	DriverIndexSetting:SetValue(index);
	Sound_GameSystem_RestartSoundSystem()
end

--------------
-- DropDown --
--------------

local DropDown = CreateFrame("Frame", "Broker_AudioHardware_DropDown", UIParent, "UIDropDownMenuTemplate")
UIDropDownMenu_SetWidth(DropDown, 136)

local function DropDownButton_OnClick(self)
	local selectedDriverIndex = self.value
	if selectedDriverIndex ~= GetDriverIndex() then
		UIDropDownMenu_SetSelectedValue(DropDown, selectedDriverIndex)
		SetDriverIndex(selectedDriverIndex) -- The call to SetCVar automatically updates the data object's text
	end
end

-- Adapted from AudioOptionsSoundPanelHardwareDropDown_Initialize in FrameXML\AudioOptionsPanels.lua
local function DropDown_Init(self)
	local selectedDriverIndex = UIDropDownMenu_GetSelectedValue(self)
	local numDrivers = Sound_GameSystem_GetNumOutputDrivers()
	local info = UIDropDownMenu_CreateInfo()

	for driverIndex = 0, numDrivers - 1 do
		info.text = Sound_GameSystem_GetOutputDriverNameByIndex(driverIndex)
		info.value = driverIndex
		info.checked = selectedDriverIndex and driverIndex == selectedDriverIndex
		info.func = DropDownButton_OnClick

		UIDropDownMenu_AddButton(info)
	end
end

UIDropDownMenu_Initialize(DropDown, DropDown_Init, "MENU")

-----------------
-- Data Object --
-----------------

local DataObj = LibStub("LibDataBroker-1.1"):NewDataObject("Broker_AudioHardware", {
	type = "data source",
	text = nil,
	icon = [[Interface\ICONS\INV_Gizmo_GoblinBoomBox_01]]
})

function DataObj:OnClick()
	UIDropDownMenu_SetSelectedValue(DropDown, GetDriverIndex())
	ToggleDropDownMenu(nil, nil, DropDown, self, 0, -5)
end

function DataObj:Refresh()
	local driverIndex = GetDriverIndex()
	if driverIndex then
		DataObj.text = Sound_GameSystem_GetOutputDriverNameByIndex(driverIndex)
	end
end

EventRegistry:RegisterFrameEventAndCallback("SETTINGS_LOADED", function()
	DriverIndexSetting = Settings.GetSetting(CVAR)
	DataObj:Refresh()
end)

local function DriverSettingChangedCallback()
	DataObj:Refresh()
end

Settings.SetOnValueChangedCallback(CVAR, DriverSettingChangedCallback, DataObj);
