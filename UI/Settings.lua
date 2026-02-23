--[[
    ShuffleStone - Hearthstone Toy Randomizer
    UI/Settings.lua - Blizzard addon settings panel (no Ace)
]]--

local AddonName, NS = ...

local PADDING_LEFT = 16
local PADDING_TOP = -16

function NS.InitializeSettings()
    -- Create the settings panel frame
    local panel = CreateFrame("Frame", "ShuffleStoneSettingsPanel")

    -- Title + version
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", PADDING_LEFT, PADDING_TOP)
    title:SetText((NS.Title or "ShuffleStone") .. " - " .. (NS.Version or "1.0.0"))

    -- Author
    local author = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    author:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    author:SetText("by " .. (NS.Author or "asp1d"))

    -- Debug hint
    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -6)
    hint:SetText("/ss debug — print diagnostic info")
    hint:SetTextColor(unpack(NS.COLOR_GRAY))

    -- Open Editor button
    local openBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    openBtn:SetSize(160, 28)
    openBtn:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -16)
    openBtn:SetText("Open ShuffleStone")
    openBtn:SetScript("OnClick", function()
        if NS.ToggleMainFrame then
            NS.ToggleMainFrame()
        end
    end)

    -- Register with Blizzard Settings
    local category = Settings.RegisterCanvasLayoutCategory(panel, "ShuffleStone")
    category.ID = "ShuffleStone"
    Settings.RegisterAddOnCategory(category)

    NS.settingsCategory = category
end
