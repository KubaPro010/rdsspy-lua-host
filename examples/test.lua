set_console_mode(true)

local last_pi = 0
local last_super_pi = 0

local ert_string = string.rep("_", 128)
local rt_a = string.rep("_", 64)
local rt_b = string.rep("_", 64)

local ptyn_toggle = false
local ptyn = string.rep(" ", 8)

local odas = {}
local ert_display = ""

local last_rt = false
local rta_display = ""
local rtb_display = ""

local current_menu = 1

local pty_rds = {
    "None", "News", "Current Affairs",
    "Information", "Sport", "Education",
    "Drama", "Culture", "Science",
    "Varied speech", "Pop", "Rock",
    "Easy listening", "Light classic", "Classic",
    "Other", "Weather", "Finance",
    "Children's", "Social", "Religion",
    "Phone in", "Travel", "Leisure",
    "Jazz", "Country", "National",
    "Oldies", "Folk", "Documentary",
    "Alarm Test", "Alarm !",
}
local pty_rbds = {
    "None", "News", "Information",
    "Sports", "Talk", "Rock",
    "Classic Rock", "Adult Hits", "Soft Rock",
    "Top 40", "Country", "Oldies",
    "Soft", "Nostalgia", "Jazz",
    "Classical", "R&B", "Soft R&B",
    "Foreign Language", "Religious Music", "Religious Talk",
    "Personality", "Public", "College",
    "Spanish Talk", "Spanish Music", "Hip-Hop",
    "???", "???", "Weather",
    "Emergency Test", "ALERT !",
}
local pty = 0

local tp = false
local ta = false
local dpty = false

local last_render_hash = 0
local function crc(data)
    local crc = 0xFF

    for i = 1, #data do
        crc = crc ~ data:byte(i)

        for _ = 1, 8 do
            if (crc & 0x80) ~= 0 then crc = (crc << 1) ~ 0x7
            else crc = crc << 1 end
            crc = crc & 0xFF
        end
    end

    return crc
end

function render_menu()
    out = string.format("Menu %d\r\n------\r\n", current_menu)
    if current_menu == 1 then
        set_font_size(64) -- largest as i can do, this is directly from the public's wants (https://pira.cz/forum/index.php?topic=1124.0)
        out = out .. string.format("PI: %X (SPI: %X)\r\n", last_pi, last_super_pi)
        out = out .. string.format("PS: %s", db.read_value("PS"))
    elseif current_menu == 2 then
        set_font_size(24)
        out = out .. string.format("PTY: %d (%s / %s)\r\n", pty, pty_rds[pty+1], pty_rbds[pty+1])
        out = out .. string.format("TP %s | TA %s | DPTY %s\r\n", tp and "+" or "-", ta and "+" or "-", dpty and "+" or "-")
        out = out .. string.format("PTYN: %s\r\n\r\n", ptyn)
        out = out .. string.format("RT[A]: %s%s\r\n", last_rt and ">" or " ", rta_display)
        out = out .. string.format("RT[B]: %s%s\r\n\r\n", (not last_rt) and ">" or " ", rtb_display)
        out = out .. string.format("ERT: %s\r\n", ert_display)
    elseif current_menu == 3 then
        set_font_size(24)
        local oda_string = ""
        for grp, data in pairs(odas) do
            local ver_char = (data.version == 0) and "A" or "B"
            oda_string = oda_string .. string.format("%d%s - %04X | ", grp, ver_char, data.aid)
        end
        out = out .. string.format("ODA: %s\r\n", oda_string:sub(1, #oda_string-2))
    end

    local hash = crc(out)
    if hash ~= last_render_hash then
        set_console(out)
        last_render_hash = hash
    end
end

function event(event)
    current_menu = event
end

function command(cmd, param)
    if cmd:lower() == "request" and param:lower() == "decoderdata" then
        db.add_value("RT.A", rta_display)
        db.add_value("RT.B", rtb_display)
        db.add_value("RT.Type", "0" and last_rt or "1")
        db.add_value("PTYN", ptyn)
        db.add_value("ERT", ert_display)
    elseif cmd:lower() == "resetdata" then
        ert_string = string.rep("_", 128)
        rt_a = string.rep("_", 64)
        rt_b = string.rep("_", 64)
        odas = {}
        last_pi = 0
        last_super_pi = 0
        pty = 0
        tp = false
        ta = false
        dpty = false
        ptyn = string.rep(" ", 8)
        ptyn_toggle = false
    elseif cmd:lower() == "superpi" then
        last_super_pi = tonumber(param, 16)
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

    if a ~= 0 then last_pi = a end

    if b_corr or b < 0 or c < 0 or d < 0 then return end

    pty = (b >> 5) & 0x1f
    tp = ((b >> 10) & 1) ~= 0

    local group_type = (b & 0xf000) >> 12
    local group_version = (b & 0x800) >> 11

    if group_type == 3 and group_version == 0 then
        local target_group = (b & 0x1f) >> 1

        if odas[target_group] == nil then odas[target_group] = { aid = d, version = (b & 1) } end
    else
        local ert_grp, ert_ver = findODAByAID(odas, 0x6552)

        if ert_grp and group_type == ert_grp and group_version == ert_ver then
            local ert_state = b & 0x1f
            local new_chars = string.char((c >> 8) & 0xff) .. string.char(c & 0xff) .. string.char((d >> 8) & 0xff) .. string.char(d & 0xff)
            local start_pos = (ert_state * 4) + 1
            ert_string = ert_string:sub(1, start_pos - 1) .. new_chars .. ert_string:sub(start_pos + 4)

            local carriage = ert_string:find("\r", 1, true)
            if carriage then ert_display = ert_string:sub(1, carriage - 1)
            else ert_display = ert_string:gsub("%s+$", "") end
        else
            if group_type == 0 then
                ta = ((b & 0x10) >> 4) ~= 0
                local di_bit = ((b & 0x4) >> 2) ~= 0
                local segment = b & 0x3
                if di_bit and segment == 0 then dpty = true
                elseif segment == 0 then dpty = false end
            elseif group_type == 10 and group_version == 0 then
                local toggle = ((b & 0x10) >> 4) ~= 0
                if toggle ~= ptyn_toggle then
                    ptyn = string.rep(" ", 8)
                    ptyn_toggle = toggle
                end
                local segment = b & 1
                local new_chars = string.char(db.char_conv((c >> 8) & 0xff)) .. string.char(db.char_conv(c & 0xff)) .. string.char(db.char_conv((d >> 8) & 0xff)) .. string.char(db.char_conv(d & 0xff))
                local start_pos = (segment * 4) + 1
                ptyn = rt_a:sub(1, ptyn - 1) .. new_chars .. rt_a:sub(ptyn + 4)

            elseif group_type == 2 and group_version == 0 then -- TODO 2B
                local rt_state = b & 0xF
                local rt_toggle = (b >> 4) & 1
                local new_chars = string.char(db.char_conv((c >> 8) & 0xff)) .. string.char(db.char_conv(c & 0xff)) .. string.char(db.char_conv((d >> 8) & 0xff)) .. string.char(db.char_conv(d & 0xff))
                local start_pos = (rt_state * 4) + 1

                if rt_toggle == 0 then
                    last_rt = true
                    rt_a = rt_a:sub(1, start_pos - 1) .. new_chars .. rt_a:sub(start_pos + 4)

                    local carriage = rt_a:find("\r", 1, true)
                    if carriage then rta_display = rt_a:sub(1, carriage - 1)
                    else rta_display = rt_a:gsub("%s+$", "") end
                else
                    last_rt = false
                    rt_b = rt_b:sub(1, start_pos - 1) .. new_chars .. rt_b:sub(start_pos + 4)

                    local carriage = rt_b:find("\r", 1, true)
                    if carriage then rtb_display = rt_b:sub(1, carriage - 1)
                    else rtb_display = rt_b:gsub("%s+$", "") end
                end
            end
        end
    end

    render_menu()
end