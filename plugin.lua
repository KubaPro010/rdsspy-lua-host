---@meta

---@type integer
event_count = 0

---This function should be defined by the user in the script
---EXIT, CONFIGURE, SHOW, MINIMIZE, RESTORE, MOVEX, MOVEY commands are not sent to the script
---@param cmd string
---@param param string
function command(cmd, param) end

---@class timetable
---@field year integer
---@field month integer
---@field day integer
---@field hour integer
---@field minute integer
---@field second integer
---@field centisecond integer

---This function should be defined by the user in the script
---@param stream integer
---@param block_b_correction boolean
---@param a integer
---@param b integer
---@param c integer
---@param d integer
---@param time timetable
function group(stream, block_b_correction, a, b, c, d, time) end

---This function should be defined by the user in the script
---@param event integer
function event(event) end

---Open a information message box to the user
---@param body string
---@param title string
function message_box(body, title) end

---@param size integer
function set_font_size(size) end

---Logs a string inside the host console. Requires console mode to be false.
---@param data string
function log(data) end

---Sets the whole text of the console for display. Requires console mode to be true.
---@param data string
function set_console(data) end

---@param mode boolean
function set_console_mode(mode) end

---Settings this on makes the window move with the main RDS Spy window regardless the console is
---@param stick boolean
function set_window_stick(stick) end
---@return boolean
function get_window_stick() end

db = {}

---@param key string
---@return string|nil
function db.read_value(key) end
---@param index integer
---@return string|nil
---@return string|nil
function db.read_record(index) end

---@param key string
---@param value string
function db.add_value(key, value) end

function db.reset_values(key, value) end

---@return integer
function db.count_records(key, value) end

---@param ch integer
---@return integer
function db.char_conv(ch) end

---@param filename string|nil nil means workspace file
---@param section string
---@param key string
---@param value string
function db.save_string(filename, section, key, value) end

---@param filename string|nil nil means workspace file
---@param section string
---@param key string
---@param defaultValue string
---@return string
function db.load_string(filename, section, key, defaultValue) end