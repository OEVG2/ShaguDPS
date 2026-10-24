-- load public variables into local
local settings = ShaguDPS.settings
local window = ShaguDPS.window
local parser = ShaguDPS.parser
local skin = ShaguDPS.skin

local config = ShaguDPS.config
local textures = ShaguDPS.textures

-- default backdrops (flat theme)
local backdrop = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

local backdrop_window = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local backdrop_border = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- labels of the selectors that aren't plain numbers or textures
local labels = {
  source = { "Auto", "ClassicAPI", "Nampower", "Chat Log" },
  time_mode = { [0] = "Active Time", [1] = "Fight Duration" },
  theme = { [0] = "Flat", [1] = "Classic" },
}

local function p(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffDPS:|cffffddcc " .. msg)
end

-- name of the data source in use
local function ActiveSource()
  local name = parser.active_source
  return name and parser.source_labels[name] or "none"
end

-- why the selected source isn't the one in use, if it isn't
local function SourceProblem()
  if not parser.unavailable then return end
  return parser.source_labels[parser.unavailable] .. ": " .. (parser.unavailable_reason or "not available")
end

-- things that need more than a window refresh when they change
local function OnConfigChanged(entry)
  if entry == "source" then
    parser:SelectSource()
    if settings.status then settings.status:Update() end
    local problem = SourceProblem()
    if problem then
      p("|cffff6060" .. problem .. "|cffffddcc, using " .. ActiveSource() .. " instead.")
    else
      p("Data source: " .. ActiveSource())
    end
  elseif entry == "theme" then
    StaticPopup_Show("SHAGUDPS_RELOAD")
  end
end

-- row layout
local ROW = 20

local function RowY(self)
  return -self.top - (self.entries - 1) * ROW
end

local function CreateSelector(self, values, entry)
  local classic = ShaguDPS.classic
  local input = CreateFrame("Frame", nil, self)
  input.values = values
  input.entry = entry

  input:Hide()
  input:SetHeight(18)
  input:SetWidth(values and 112 or 54)
  input:SetPoint("TOPRIGHT", self, "TOPRIGHT", classic and -16 or -8, RowY(self) + 1)
  input:SetScript("OnShow", function() input:change() end)

  if not classic then
    input:SetBackdrop(backdrop)
    input:SetBackdropColor(.2,.2,.2,1)
    input:SetBackdropBorderColor(.4,.4,.4,1)
  end

  input.texture = input:CreateTexture(nil, "ARTWORK")
  input.texture:SetPoint("TOPLEFT", input, "TOPLEFT", classic and 18 or 13, -3)
  input.texture:SetPoint("BOTTOMRIGHT", input, "BOTTOMRIGHT", classic and -18 or -13, 3)
  input.texture:SetVertexColor(.8, .4, .2)

  input.caption = input:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  input.caption:SetAllPoints()
  if classic then skin.Font(input.caption, 10) else input.caption:SetFont(STANDARD_TEXT_FONT, 10) end
  input.caption:SetText("Select")

  local function Arrow(dir)
    local button = CreateFrame("Button", nil, input)
    button:SetPoint(dir < 0 and "LEFT" or "RIGHT", input, dir < 0 and "LEFT" or "RIGHT", dir < 0 and 1 or -1, 0)

    if classic then
      -- the stock spellbook page arrows
      local file = dir < 0 and "PrevPage" or "NextPage"
      button:SetWidth(18)
      button:SetHeight(18)
      button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. file .. "-Up")
      button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. file .. "-Down")
      button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. file .. "-Disabled")
      button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    else
      button:SetWidth(12)
      button:SetHeight(16)
      button:SetBackdrop(backdrop)
      button:SetBackdropColor(.2,.2,.2,1)
      button:SetBackdropBorderColor(.4,.4,.4,1)
      button:SetScript("OnEnter", function() this:SetBackdropBorderColor(1.0, 0.8, 0.0, 1) end)
      button:SetScript("OnLeave", function() this:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
      button.caption = button:CreateFontString(nil, "OVERLAY", "GameFontWhite")
      button.caption:SetFont(STANDARD_TEXT_FONT, 10)
      button.caption:SetText(dir < 0 and "<" or ">")
      button.caption:SetAllPoints()
    end

    button:SetScript("OnClick", function() input:change(dir) end)
    return button
  end

  input.left = Arrow(-1)
  input.right = Arrow(1)

  local function SetEnabled(button, enabled)
    if classic then
      if enabled then button:Enable() else button:Disable() end
    else
      button:SetAlpha(enabled and 1 or .25)
    end
  end

  input.change = function(self, mod)
    local value = config[self.entry] or 1

    if mod and (not self.values or self.values[value + mod]) then
      config[self.entry] = math.ceil(value + mod)
    end

    local current = config[self.entry]
    if self.values and self.values[current] then
      local _, _, clean = string.find(self.values[current], ".+\\(.+)")
      self.caption:SetText(clean or self.values[current])
    else
      self.caption:SetText(current)
    end

    SetEnabled(self.right, not self.values or self.values[current + 1])
    SetEnabled(self.left, not self.values or self.values[current - 1])

    if self.entry == "texture" then
      local texture = textures[current]
      if texture then
        self.texture:SetTexture(texture)
      else
        self.texture:SetTexture()
      end
    end

    window.Refresh(true)
    if mod then OnConfigChanged(self.entry) end
  end

  return input
end

local function CreateConfig(self, caption, entry, check)
  local classic = ShaguDPS.classic
  self.entries = self.entries and self.entries + 1 or 1
  local y = RowY(self)

  local text = self:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  text:SetPoint("TOPLEFT", self, "TOPLEFT", classic and 20 or 10, y)
  text:SetWidth(170)
  text:SetHeight(ROW)
  text:SetJustifyH("LEFT")
  text:SetText(caption)

  if classic then
    skin.Font(text, 10)
    text:SetTextColor(1, 1, 1)
  else
    text:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  end

  if check == "header" then
    text:SetPoint("TOPLEFT", self, "TOPLEFT", classic and 16 or 8, y - 3)

    if classic then
      -- "Header ———" in gold, the rule trailing the text
      skin.Font(text, 11)
      text:SetTextColor(1, .82, 0)
      text:SetWidth(text:GetStringWidth() + 2)

      local rule = skin.TrailingRule(self)
      rule:SetPoint("LEFT", text, "RIGHT", 6, 0)
      rule:SetPoint("RIGHT", self, "RIGHT", -18, 0)
    else
      text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
      text:SetTextColor(1, .8, 0)
    end
  elseif check == "status" then
    -- read-only line below the setting it belongs to
    text:SetPoint("TOPLEFT", self, "TOPLEFT", classic and 28 or 18, y + 4)
    text:SetWidth(classic and 280 or 270)
    text:SetTextColor(.6, .6, .6)
    text.Update = function(self)
      if parser.unavailable then
        -- the selected source can't be used: say why
        self:SetText("|cffff6060" .. parser.source_labels[parser.unavailable] .. " unavailable|r, using |cffffffff" .. ActiveSource())
      else
        self:SetText("Active: |cffffffff" .. ActiveSource())
      end
    end
    text:Update()
    return text
  elseif check == "boolean" then
    local input = CreateFrame("CheckButton", nil, self, "OptionsCheckButtonTemplate")
    input:Hide()
    input:SetHeight(classic and 22 or 18)
    input:SetWidth(classic and 22 or 18)
    input:SetPoint("TOPRIGHT", self, "TOPRIGHT", classic and -16 or -8, y)
    input:SetScript("OnShow", function()
      this:SetChecked(config[entry] == 1)
    end)

    input:SetScript("OnClick", function()
      config[entry] = this:GetChecked() and 1 or 0
      window.Refresh(true)
    end)

    self.checks = self.checks or {}
    self.checks[entry] = input

    input:Show()
  elseif check == "number" then
    self:CreateSelector(nil, entry):Show()
  elseif type(check) == "table" then
    self:CreateSelector(check, entry):Show()
  end

  return text
end

-- the settings window is built the first time it opens, when the theme is known
local function Build()
  local classic = ShaguDPS.classic
  settings.CreateConfig = CreateConfig
  settings.CreateSelector = CreateSelector
  settings.top = classic and 30 or 26

  if classic then
    settings:SetBackdrop(skin.backdrop_dialog)
    skin.HeaderPlate(settings, "ShaguDPS")

    local close = CreateFrame("Button", nil, settings, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", settings, "TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() settings:Hide() end)
  else
    -- window background
    settings:SetBackdrop(backdrop_window)
    settings:SetBackdropColor(.5,.5,.5,.9)

    -- window border
    settings.border = CreateFrame("Frame", nil, settings)
    settings.border:ClearAllPoints()
    settings.border:SetPoint("TOPLEFT", settings, "TOPLEFT", -1,1)
    settings.border:SetPoint("BOTTOMRIGHT", settings, "BOTTOMRIGHT", 1,-1)
    settings.border:SetFrameLevel(100)
    settings.border:SetBackdrop(backdrop_border)
    settings.border:SetBackdropBorderColor(.7,.7,.7,1)

    settings.title = settings:CreateTexture(nil, "NORMAL")
    settings.title:SetTexture(0,0,0,.6)
    settings.title:SetHeight(20)
    settings.title:SetPoint("TOPLEFT", 2, -2)
    settings.title:SetPoint("TOPRIGHT", -2, -2)

    settings.caption = settings:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    settings.caption:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    settings.caption:SetText("|cffffcc00Shagu|cffffffffDPS")
    settings.caption:SetAllPoints(settings.title)

    settings.btnClose = CreateFrame("Button", nil, settings)
    settings.btnClose:SetPoint("RIGHT", settings.title, "RIGHT", -4, 0)
    settings.btnClose:SetHeight(16)
    settings.btnClose:SetWidth(16)
    settings.btnClose:SetBackdrop(backdrop)
    settings.btnClose:SetBackdropColor(.2,.2,.2,1)
    settings.btnClose:SetBackdropBorderColor(.4,.4,.4,1)

    settings.btnClose.caption = settings.btnClose:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    settings.btnClose.caption:SetFont(STANDARD_TEXT_FONT, 14)
    settings.btnClose.caption:SetText("x")
    settings.btnClose.caption:SetAllPoints()
    settings.btnClose:SetScript("OnEnter", function() this:SetBackdropBorderColor(1.0, 0.8, 0.0, 1) end)
    settings.btnClose:SetScript("OnLeave", function() this:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
    settings.btnClose:SetScript("OnClick", function() settings:Hide() end)
  end

  settings:CreateConfig("Data", nil, "header")
  settings:CreateConfig("Data Source", "source", labels.source)
  settings.status = settings:CreateConfig(nil, nil, "status")
  settings:CreateConfig("Per Second Time", "time_mode", labels.time_mode)
  settings:CreateConfig("Track All Nearby Units", "track_all_units", "boolean")
  settings:CreateConfig("Merge Pets With Owner", "merge_pets", "boolean")

  settings:CreateConfig("Window", nil, "header")
  settings:CreateConfig("Theme", "theme", labels.theme)
  settings:CreateConfig("Bar Texture", "texture", ShaguDPS.texture_names)
  settings:CreateConfig("Bar Height", "height", "number")
  settings:CreateConfig("Bar Spacing", "spacing", "number")
  settings:CreateConfig("Pastel Colors", "pastel", "boolean")
  settings:CreateConfig("Show Backdrops", "backdrop", "boolean")
  settings:CreateConfig("Lock Windows", "lock", "boolean")

  settings:SetWidth(classic and 340 or 316)
  settings:SetHeight(settings.top + settings.entries * ROW + (classic and 16 or 8))
end

-- Load settings on Login
settings:RegisterEvent("PLAYER_ENTERING_WORLD")
settings:SetScript("OnEvent", function()
  if not this.loaded then
    this.loaded = true

    if ShaguDPS_Config then
      for k, v in pairs(ShaguDPS_Config) do
        config[k] = v
      end
    end

    ShaguDPS_Config = config

    -- the theme is fixed for the session; skin the frames built so far
    ShaguDPS.classic = config.theme == 1
    window.ApplyTheme()
  end

  parser:SelectSource()
  if settings.status then settings.status:Update() end
  window.Refresh(true)
end)

settings:Hide()
settings:SetPoint("CENTER", UIParent, "CENTER", 0, 32)
settings:SetWidth(252)
settings:SetHeight(300)
settings:SetMovable(true)
settings:EnableMouse(true)
settings:SetClampedToScreen(true)
settings:RegisterForDrag("LeftButton")
settings:SetScript("OnDragStart", function() this:StartMoving() end)
settings:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
settings:SetFrameStrata("DIALOG")
settings:SetScript("OnShow", function()
  if not this.built then
    this.built = true
    Build()
  end
end)

-- close with escape
setglobal("ShaguDPSSettings", settings)
table.insert(UISpecialFrames, "ShaguDPSSettings")

-- Provide Slash Commands
SLASH_SHAGUMETER1, SLASH_SHAGUMETER2, SLASH_SHAGUMETER3 = "/shagudps", "/sdps", "/sd"
SlashCmdList["SHAGUMETER"] = function(msg, editbox)
  local function out(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
  end

  if (msg == "" or msg == nil) then
    out("|cffffcc00Shagu|cffffffffDPS: |cffaaaaaa(data source: " .. ActiveSource() .. ")")
    out("  /sdps config |cffcccccc- Open the settings")
    out("  /sdps visible " .. config.visible .. " |cffcccccc- Show main window")
    out("  /sdps height " .. config.height .. " |cffcccccc- Bar height")
    out("  /sdps spacing " .. config.spacing .. " |cffcccccc- Bar spacing")
    out("  /sdps trackall " .. config.track_all_units .. " |cffcccccc- Track all nearby units")
    out("  /sdps mergepet " .. config.merge_pets .. " |cffcccccc- Merge pets into owner data")
    out("  /sdps source " .. config.source .. " |cffcccccc- Data source (1 auto, 2 ClassicAPI, 3 Nampower, 4 chat log)")
    out("  /sdps time " .. config.time_mode .. " |cffcccccc- Per second time (0 active time, 1 fight duration)")
    out("  /sdps texture " .. config.texture .. " |cffcccccc- Set the statusbar texture")
    out("  /sdps pastel " .. config.pastel .. " |cffcccccc- Use pastel colors")
    out("  /sdps backdrop " .. config.backdrop .. " |cffcccccc- Show window backdrop and border")
    out("  /sdps theme " .. config.theme .. " |cffcccccc- Theme (0 flat, 1 classic, needs a reload)")
    out("  /sdps lock " .. config.lock .. " |cffcccccc- Lock window")
    out("  /sdps toggle |cffcccccc- Toggle window")
    return
  end

  local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
  cmd = strlower(cmd or "")
  local num = tonumber(args)

  -- options: command -> config entry, min, max, caption
  local options = {
    visible  = { "visible", 0, 1, "Visible" },
    lock     = { "lock", 0, 1, "Lock" },
    trackall = { "track_all_units", 0, 1, "Track all units" },
    mergepet = { "merge_pets", 0, 1, "Merge pet" },
    pastel   = { "pastel", 0, 1, "Use pastel colors" },
    backdrop = { "backdrop", 0, 1, "Show window backdrop" },
    time     = { "time_mode", 0, 1, "Per second time" },
    theme    = { "theme", 0, 1, "Theme" },
    source   = { "source", 1, 4, "Data source" },
    texture  = { "texture", 1, table.getn(textures), "Texture" },
    height   = { "height", 1, 999, "Bar height" },
    spacing  = { "spacing", 0, config.height, "Bar spacing" },
  }

  if cmd == "threatdebug" then
    ShaguDPS.threat:Measure()
  elseif cmd == "toggle" then
    config.visible = config.visible == 1 and 0 or 1
    window.Refresh(true)
    p("Visible: " .. config.visible)
  elseif cmd == "config" or cmd == "settings" then
    if settings:IsShown() then settings:Hide() else settings:Show() end
  elseif options[cmd] then
    local o = options[cmd]
    if num and num >= o[2] and num <= o[3] and math.floor(num) == num then
      config[o[1]] = num
      window.Refresh(true)
      p(o[4] .. ": " .. num)
      OnConfigChanged(o[1])
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Shagu|cffffffffDPS:|cffff5511 Valid Options are " .. o[2] .. "-" .. o[3])
    end
  end
end
