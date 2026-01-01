local ert_string = string.rep("_", 128)
local ert_last_carriage = -1
local ert_console_log = false -- not state

local odas = {}
local oda_string = ""
local ert_display = ""

function command(cmd, param)
    if cmd:lower() == "request" and param:lower() == "decoderdata" then
        db.add_value("ERT", ert_display)
    elseif cmd:lower() == "resetdata" then
        ert_string = string.rep("_", 128)
        ert_last_carriage = -1
        odas = {}
        oda_string = ""
        ert_display = ""
        if ert_console_log then log("ERT data reset.")
        else set_console_mode(true) end
    end
end

local function getKeyByValue(t, targetValue)
    for key, value in pairs(t) do
        if value == targetValue then
            return key
        end
    end
    return nil -- Return nil if the value isn't found
end

function group(stream, b_corr, a, b, c, d)
    if stream ~= 0 and a ~= 0 then return
    elseif stream ~= 0 and not db.load_boolean("rdsspy.ini", "General", "Tunnelling", false) then return end

    if b_corr or b < 0 or c < 0 or d < 0 then return end

    local group = (b & 0xf000) >> 12
    local group_version = (b & 0x800) >> 11

    if group == 3 and group_version == 0 then
        local oda_group = (b & 0x1f) >> 1
        local oda_group_version = b & 1
        if odas[oda_group] == nil then odas[oda_group] = d end
        oda_string = ""
        for key, value in pairs(odas) do
            oda_string = oda_string .. string.format("%d: %X |", key, value)
        end
    elseif group == getKeyByValue(odas, 0x6552) and group_version == 0 then
        local ert_state = b & 0x1f
        local char1 = string.char((c >> 8) & 0xff)
        local char2 = string.char(c & 0xff)
        local char3 = string.char((d >> 8) & 0xff)
        local char4 = string.char(d & 0xff)
        local new_chars = char1..char2..char3..char4
        local start_pos = (ert_state * 4) + 1
        ert_string = ert_string:sub(1, start_pos - 1) .. new_chars .. ert_string:sub(start_pos + 4)

        local ert_carriage = ert_string:find("\r", 1, true)
        if ert_carriage then ert_display = ert_string:sub(1, ert_carriage - 1)
        else ert_display = ert_string:gsub("%s+$", "") end

        if ert_carriage ~= ert_last_carriage and ert_carriage ~= nil and ert_console_log then
            log("New ERT string received.")
            ert_last_carriage = ert_carriage
        end
    end
    set_console(string.format("ODAs: %s\r\nERT: %s", oda_string, ert_display))
end