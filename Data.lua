--[[
    ShuffleStone - Hearthstone Toy Randomizer
    Data.lua - Master list of hearthstone toy item IDs
    Home hearthstones only (NOT Dalaran or Garrison)
]]--

local AddonName, NS = ...

-- Shared constants
NS.DEFAULT_ICON = 134414     -- hearthstone icon texture ID
NS.BASE_HEARTHSTONE = { id = 6948, name = "Hearthstone" }

-- Reference links for checking new hearthstone toys:
--   Wowpedia category: https://wowpedia.fandom.com/wiki/Category:Hearthstones
--   Wowhead toy database: https://www.wowhead.com/items/consumables/toys
NS.HEARTHSTONE_TOYS = {
    -- Classic / Always Available
    { id = 64488,  name = "The Innkeeper's Daughter" },
    { id = 54452,  name = "Ethereal Portal" },
    { id = 93672,  name = "Dark Portal" },
    { id = 142542, name = "Tome of Town Portal" },

    -- Seasonal / Holiday
    { id = 165669, name = "Lunar Elder's Hearthstone" },
    { id = 165670, name = "Peddlefeet's Lovely Hearthstone" },
    { id = 165802, name = "Noble Gardener's Hearthstone" },
    { id = 166746, name = "Fire Eater's Hearthstone" },
    { id = 166747, name = "Brewfest Reveler's Hearthstone" },
    { id = 163045, name = "Headless Horseman's Hearthstone" },
    { id = 162973, name = "Greatfather Winter's Hearthstone" },

    -- Expansion: Shadowlands
    { id = 180290, name = "Night Fae Hearthstone" },
    { id = 182773, name = "Necrolord Hearthstone" },
    { id = 183716, name = "Venthyr Sinstone" },
    { id = 184353, name = "Kyrian Hearthstone" },
    { id = 188952, name = "Dominated Hearthstone" },
    { id = 190196, name = "Enlightened Hearthstone" },

    -- Expansion: Dragonflight
    { id = 190237, name = "Broker Translocation Matrix" },
    { id = 193588, name = "Timewalker's Hearthstone" },
    { id = 200630, name = "Ohn'ir Windsage's Hearthstone" },
    { id = 206195, name = "Path of the Naaru" },
    { id = 208704, name = "Deepdweller's Earthen Hearthstone" },
    { id = 209035, name = "Hearthstone of the Flame" },

    -- Race-Specific
    { id = 210455, name = "Draenic Hologem" },

    -- Promotional / Store / Special
    { id = 168907, name = "Holographic Digitalization Hearthstone" },
    { id = 172179, name = "Eternal Traveler's Hearthstone" },
    { id = 212337, name = "Stone of the Hearth" },

    -- The War Within / Midnight
    { id = 228940, name = "Notorious Thread's Hearthstone" },
    { id = 235016, name = "Redeployment Module" },
    { id = 236687, name = "Explosive Hearthstone" },
    { id = 245970, name = "P.O.S.T. Master's Express" },
    { id = 246565, name = "Cosmic Hearthstone" },
    { id = 257736, name = "Lightcalled Hearthstone" },
    { id = 263489, name = "Naaru's Enfold" },
    { id = 263933, name = "Preyseeker's Hearthstone" },
    { id = 265100, name = "Corewarden's Hearthstone" },
}
