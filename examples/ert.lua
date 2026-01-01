local ert_group = -1
local ert_string = string.rep("_", 128)
local ert_last_carriage = -1
local ert_console_log = false

function command(cmd, param)
    if cmd:lower() == "request" and param:lower() == "decoderdata" then
        local cr_pos = ert_string:find("\r", 1, true) -- true means "plain search" (faster)
        local display_text

        if cr_pos then display_text = ert_string:sub(1, cr_pos - 1)
        else display_text = ert_string:gsub("%s+$", "")
        end
        db.add_value("ERT", display_text)
    elseif cmd:lower() == "resetdata" then
        ert_group = -1
        ert_string = string.rep("_", 128)
        ert_last_carriage = -1
        if ert_console_log then log("ERT data reset.")
        else set_console_mode(true) end
    end
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
        if d == 0x6552 and oda_group_version == 0 then
            -- ERT
            ert_group = oda_group
        elseif oda_group == ert_group then ert_group = -1 end
    elseif group == ert_group and group_version == 0 then
        local ert_state = b & 0x1f
        local char1 = string.char((c >> 8) & 0xff)
        local char2 = string.char(c & 0xff)
        local char3 = string.char((d >> 8) & 0xff)
        local char4 = string.char(d & 0xff)
        local new_chars = char1..char2..char3..char4
        local start_pos = (ert_state * 4) + 1
        ert_string = ert_string:sub(1, start_pos - 1) .. new_chars .. ert_string:sub(start_pos + 4)

        local ert_carriage = ert_string:find("\r", 1, true)
        if ert_carriage ~= ert_last_carriage and ert_carriage ~= nil and ert_console_log then
            log("New ERT string received.")
            ert_last_carriage = ert_carriage
        elseif not ert_console_log then
            local display_text

            if ert_carriage then display_text = ert_string:sub(1, ert_carriage - 1)
            else display_text = ert_string:gsub("%s+$", "") end

            set_console(string.format("ERT: %s", display_text))
        end
    end
end