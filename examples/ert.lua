ert_group = -1
ert_string = string.rep(" ", 128)

function command(cmd, param)
    if cmd:lower() == "request" then
        local cr_pos = ert_string:find("\r", 1, true) -- true means "plain search" (faster)
        local display_text

        if cr_pos then
            display_text = ert_string:sub(1, cr_pos - 1)
        else
            -- No CR found yet, show the whole 128 bytes (trimmed of trailing spaces)
            display_text = ert_string:gsub("%s+$", "") 
        end
        db.add_value("ERT", display_text)
    end
end

function group(stream, b_corr, a, b, c, d)
    if stream ~= 0 and a ~= 0 then return
    elseif stream ~= 0 and not db.load_boolean("rdsspy.ini", "General", "Tunnelling", false) then return end

    if b_corr then return end

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
    end
end