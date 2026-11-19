local WINDOW_SECONDS = 0.30
local hooked = {}

local printableKeys = {
    SPACE = " ", SLASH = "/", BACKSLASH = "\\", PERIOD = ".",
    COMMA = ",", SEMICOLON = ";", APOSTROPHE = "'",
    MINUS = "-", EQUALS = "=", LBRACKET = "[", RBRACKET = "]",
    GRAVE = "`", NUMPADDECIMAL = ".", NUMPADDIVIDE = "/",
    NUMPADMULTIPLY = "*", NUMPADMINUS = "-", NUMPADPLUS = "+",
}

local function getPrintableBindings()
    local chars, keys = {}, {}
    if type(GetBindingKey) ~= "function" then return chars, keys end

    local bindings = { GetBindingKey("OPENCHAT") }
    for _, key in ipairs(bindings) do
        if type(key) == "string" then
            local char
            if #key == 1 then
                char = key:lower()
            else
                char = printableKeys[key]
                if not char then char = key:match("^NUMPAD([0-9])$") end
            end
            if char then
                chars[char:lower()] = true
                keys[#keys + 1] = key
            end
        end
    end
    return chars, keys
end

local function install(editBox)
    if not editBox or hooked[editBox] then return end
    hooked[editBox] = true

    local focusedAt, handled, changing

    local function removeStrayKey(self)
        if handled or changing or not focusedAt then return end
        if GetTime() - focusedAt > WINDOW_SECONDS then
            handled = true
            return
        end
        local value = self:GetText()
        if type(value) ~= "string" or #value ~= 1 then return end
        if type(issecretvalue) == "function" and issecretvalue(value) then return end
        local chars = getPrintableBindings()
        if not chars[value:lower()] then return end
        handled = true
        changing = true
        self:SetText("")
        changing = false
    end

    editBox:HookScript("OnEditFocusGained", function(self)
        focusedAt = GetTime()
        handled = false
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if self:HasFocus() then removeStrayKey(self) end
            end)
        end
    end)

    editBox:HookScript("OnEditFocusLost", function()
        focusedAt = nil
        handled = true
    end)

    editBox:HookScript("OnTextChanged", function(self)
        if self:HasFocus() then removeStrayKey(self) end
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UPDATE_CHAT_WINDOWS")
events:SetScript("OnEvent", function()
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        install(_G["ChatFrame" .. i .. "EditBox"])
    end
end)

SLASH_CLEANCHATOPEN1 = "/cco"
SlashCmdList.CLEANCHATOPEN = function()
    local _, keys = getPrintableBindings()
    if #keys > 0 then
        print("CleanChatOpen: supported Open Chat bindings: " .. table.concat(keys, ", "))
    else
        print("CleanChatOpen: no unmodified printable Open Chat key is bound.")
    end
end
