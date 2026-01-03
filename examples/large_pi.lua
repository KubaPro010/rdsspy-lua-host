set_console_mode(true)
set_font_size(148)

local last_pi = "----"
local last_ps = "--------"
function group(...)
    local pi = db.read_value("PI") or "----"
    local ps = db.read_value("PS") or "--------"
    if last_pi ~= pi or last_ps ~= ps then
        set_console(string.format("%s\r\n%s", pi, ps))
        last_pi = pi
        last_ps = ps
    end
end

function event(event)
    if event == 1 then
        set_window_stick(not get_window_stick())
    end
end