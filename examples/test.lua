set_console_mode(true)
set_font_size(24)

local ert_string = string.rep("_", 128)

local odas = {}
local oda_string = ""
local ert_display = ""

local last_event = -1

function event(event)
    last_event = event
end

function command(cmd, param)
    if cmd:lower() == "request" and param:lower() == "decoderdata" then
        db.add_value("ERT", ert_display)
    elseif cmd:lower() == "resetdata" then
        ert_string = string.rep("_", 128)
        odas = {}
        oda_string = ""
        ert_display = ""
    end
end

local function findODAByAID(t, targetAID)
    for grp, data in pairs(t) do
        if data.aid == targetAID then return grp, data.version end
    end
    return nil, nil
end

function group(stream, b_corr, a, b, c, d)
    if stream ~= 0 and a ~= 0 then return
    elseif stream ~= 0 and not db.load_boolean("rdsspy.ini", "General", "Tunnelling", false) then return end

    if b_corr or b < 0 or c < 0 or d < 0 then return end

    local group_type = (b & 0xf000) >> 12
    local group_version = (b & 0x800) >> 11

    if group_type == 3 and group_version == 0 then
        local target_group = (b & 0x1f) >> 1

        if odas[target_group] == nil then odas[target_group] = { aid = d, version = (b & 1) } end

        oda_string = ""
        for grp, data in pairs(odas) do
            local ver_char = (data.version == 0) and "A" or "B"
            oda_string = oda_string .. string.format("%d%s - %04X | ", grp, ver_char, data.aid)
        end

    else
        local ert_grp, ert_ver = findODAByAID(odas, 0x6552)

        if ert_grp and group_type == ert_grp and group_version == ert_ver then
            local ert_state = b & 0x1f
            local new_chars = string.char((c >> 8) & 0xff) .. string.char(c & 0xff) .. string.char((d >> 8) & 0xff) .. string.char(d & 0xff)
            local start_pos = (ert_state * 4) + 1
            ert_string = ert_string:sub(1, start_pos - 1) .. new_chars .. ert_string:sub(start_pos + 4)

            local ert_carriage = ert_string:find("\r", 1, true)
            if ert_carriage then ert_display = ert_string:sub(1, ert_carriage - 1)
            else ert_display = ert_string:gsub("%s+$", "") end
        end
    end

    set_console(string.format("ODAs: %s\r\n\r\nERT: %s\r\n\r\nLast event: %d", oda_string:sub(1, #oda_string-2), ert_display, last_event))
end