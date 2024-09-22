--@alpha@
local DEBUG = true

local function debugprint(...)
	if DEBUG then
		print("B:AH DEBUG:", ...)
	end
end
--@end-alpha@

------------------
-- Driver Index --
------------------

local CVAR = "Sound_OutputDriverIndex"

local DriverIndexSetting

--- Get the currently selected driver index
--- @return integer
local function GetDriverIndex()
	return DriverIndexSetting:GetValue()
end

--- Set the currently selected driver index
--- @param index integer
local function SetDriverIndex(index)
	DriverIndexSetting:SetValue(index);
	Sound_GameSystem_RestartSoundSystem()
end

--- Is the driver index selected?
--- @param index integer
--- @return boolean
local function IsDriverIndexSelected(index)
	local selectedDriverIndex = GetDriverIndex()

	return selectedDriverIndex and index == selectedDriverIndex
end

----------------
-- Favourites --
----------------

--- The favourite driver names
--- @type string[]
BROKER_AUDIO_HARDWARE_FAVOURITES = {}

--- Get the index of the driver name in the favourites list, or nil if it's not in the list
--- @param driverName string
--- @return integer | nil
local function GetFavouritesIndex(driverName)
	for k, v in ipairs(BROKER_AUDIO_HARDWARE_FAVOURITES) do
		if v == driverName then
			return k
		end
	end
end

--- Is the driver name in the favourites list?
--- @param driverName string
--- @return boolean
local function IsFavourite(driverName)
	return not not GetFavouritesIndex(driverName)
end

--- Add or remove the driver name from the favourites list
--- @param driverName string
local function ToggleFavourite(driverName)
	local favouritesIndex = GetFavouritesIndex(driverName)

	if not favouritesIndex then
		table.insert(BROKER_AUDIO_HARDWARE_FAVOURITES, driverName)
	else
		table.remove(BROKER_AUDIO_HARDWARE_FAVOURITES, favouritesIndex)
	end
end

local function CycleToNextFavourite()
	local currentDriverIndex = GetDriverIndex()
	local currentDriverName = Sound_GameSystem_GetOutputDriverNameByIndex(currentDriverIndex)

	local currentFavouritesIndex = GetFavouritesIndex(currentDriverName) or 1
	local nextFavouritesIndex = currentFavouritesIndex % #BROKER_AUDIO_HARDWARE_FAVOURITES + 1

	local nextDriverName = BROKER_AUDIO_HARDWARE_FAVOURITES[nextFavouritesIndex]

	--@alpha@
	debugprint(
		"CycleToNextFavourite",
		"currentDriverIndex", currentDriverIndex,
		"currentDriverName", currentDriverName,
		"currentFavouritesIndex", currentFavouritesIndex,
		"nextFavouritesIndex", nextFavouritesIndex,
		"nextDriverName", nextDriverName
	)
	--@end-alpha@

	if not nextDriverName then
		--@alpha@	
		debugprint("No nextDriverName at nextFavouritesIndex", nextFavouritesIndex)
		--@end-alpha@
		return
	end

	local numDrivers = Sound_GameSystem_GetNumOutputDrivers()

	for driverIndex = 0, numDrivers - 1 do
		local driverName = Sound_GameSystem_GetOutputDriverNameByIndex(driverIndex)

		if driverName == nextDriverName then
			--@alpha@
			debugprint("Setting driverIndex", driverIndex, nextDriverName)
			--@end-alpha@

			SetDriverIndex(driverIndex)

			return
		end
	end

	--@alpha@
	debugprint("nextDriverName not found in available drivers", nextDriverName)
	--@end-alpha@
end

--@alpha
BAH = {
	GetDriverIndex = GetDriverIndex,
	SetDriverIndex = SetDriverIndex,
	IsDriverIndexSelected = IsDriverIndexSelected,
	GetFavouritesIndex = GetFavouritesIndex,
	IsFavourite = IsFavourite,
	ToggleFavourite = ToggleFavourite,
	CycleToNextFavourite = CycleToNextFavourite
}
--@end-alpha@

----------
-- Menu --
----------

local CreateContextMenu

if MenuUtil then
	CreateContextMenu = function(frame)
		return MenuUtil.CreateContextMenu(frame, function(_, rootDescription)
			local numDrivers = Sound_GameSystem_GetNumOutputDrivers()

			for driverIndex = 0, numDrivers - 1 do
				local driverName = Sound_GameSystem_GetOutputDriverNameByIndex(driverIndex)

				local subMenu = rootDescription:CreateButton(driverName)
				subMenu:CreateRadio("Select", IsDriverIndexSelected, SetDriverIndex, driverIndex)
				subMenu:CreateCheckbox("Favourite", IsFavourite, ToggleFavourite, driverName)
			end
		end)
	end
else
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

	CreateContextMenu = function(frame)
		UIDropDownMenu_SetSelectedValue(DropDown, GetDriverIndex())
		ToggleDropDownMenu(nil, nil, DropDown, frame, 0, -5)
	end
end

-----------------
-- Data Object --
-----------------

local DataObj = LibStub("LibDataBroker-1.1"):NewDataObject("Broker_AudioHardware", {
	type = "data source",
	text = nil,
	icon = [[Interface\ICONS\INV_Gizmo_GoblinBoomBox_01]]
})

function DataObj:OnClick()
	CreateContextMenu(self)
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

----------------
-- Key Binding --
----------------

_G["BROKER_AUDIO_HARDWARE"] = "Broker: Audio Hardware"
_G["BINDING_NAME_CLICK BrokerAudioHardwareCycleToNextFavouriteButton:LeftButton"] = "Cycle audio output drivers"

local cycleToNextFavouriteButton = CreateFrame("Button", "BrokerAudioHardwareCycleToNextFavouriteButton")
cycleToNextFavouriteButton:SetScript("OnClick", function()
	CycleToNextFavourite()
end)
