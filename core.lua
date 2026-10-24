ShaguDPS = {}

-- initialize default question dialog
StaticPopupDialogs["SHAGUMETER_QUESTION"] = {
  button1 = YES,
  button2 = NO,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

-- list of available statusbar textures
local textures = {
  "Interface\\BUTTONS\\WHITE8X8",
  "Interface\\TargetingFrame\\UI-StatusBar",
  "Interface\\Tooltips\\UI-Tooltip-Background",
  "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
  "Interface\\AddOns\\ShaguDPS\\img\\bars\\Puppeteer",
  "Interface\\AddOns\\ShaguDPS\\img\\bars\\Puppeteer-Shineless",
  "Interface\\AddOns\\ShaguDPS\\img\\bars\\Puppeteer-Flat",
}

-- names of the textures above, as the settings show them
local texture_names = {
  "Flat", "Blizzard", "Tooltip", "Skill Bar",
  "Puppeteer", "Puppeteer Shineless", "Puppeteer Flat",
}

-- a basic rounding function
local function round(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end

local function expansion()
  local _, _, _, client = GetBuildInfo()
  client = client or 11200

  -- detect client expansion
  if client >= 20000 and client <= 20400 then
    return "tbc"
  elseif client >= 30000 and client <= 30300 then
    return "wotlk"
  else
    return "vanilla"
  end
end

-- shared variables
local data = {
  damage = {
    [0] = {}, -- overall
    [1] = {}, -- current
  },

  heal = {
    [0] = {}, -- overall
    [1] = {}, -- current
  },

  classes = {},
}

local dmg_table = {}
local view_dmg_all = { }
local view_dps_all = { }
local playerClasses = {}

-- default config
local config = {
  -- size
  height = 15,
  spacing = 0,

  -- tracking
  track_all_units = 0,
  merge_pets = 1,
  source = 1,     -- 1: auto, 2: ClassicAPI, 3: Nampower, 4: chat combat log
  time_mode = 0,  -- 0: active time per unit, 1: fight duration for everyone

  -- appearance
  visible = 1,
  backdrop = 1,
  texture = 2,
  pastel = 0,
  class_icons = 1,
  lock = 0,
  theme = 1,      -- 1: classic Blizzard look, 0: original flat look
}

local internals = {
  ["_sum"] = true,
  ["_ctime"] = true,
  ["_tick"] = true,
  ["_esum"] = true,
  ["_effective"] = true,
  -- threat view
  ["_perc"] = true,
  ["_tank"] = true,
  ["_melee"] = true,
  ["_tps"] = true,
  ["_pull"] = true,
  ["_minimum"] = true,
}

-- create core component frames
local settings = CreateFrame("Frame", nil, UIParent)
local parser = CreateFrame("Frame")
local window = {}

-- make everything public
ShaguDPS.data = data
ShaguDPS.config = config
ShaguDPS.textures = textures
ShaguDPS.texture_names = texture_names
ShaguDPS.window = window
ShaguDPS.settings = settings
ShaguDPS.internals = internals
ShaguDPS.parser = parser
ShaguDPS.round = round
ShaguDPS.expansion = expansion

-- the theme is read once when the frames are built, so switching it needs a reload
StaticPopupDialogs["SHAGUDPS_RELOAD"] = {
  text = "ShaguDPS: the new theme needs a UI reload. Reload now?",
  button1 = ACCEPT,
  button2 = CANCEL,
  OnAccept = function() ReloadUI() end,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

-- the active theme: nil until the saved variables are loaded, then true for the
-- classic look. Frames built before that get their skin once it is known.
ShaguDPS.classic = nil
