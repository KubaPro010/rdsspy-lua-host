---@meta

---This function should be defined by the user in the script
---EXIT, CONFIGURE, SHOW, MINIMIZE, RESTORE commands are not sent to the script
---@param cmd string
---@param param string
function command(cmd, param) end

---This function should be defined by the user in the script
---@param stream integer
---@param block_b_correction boolean
---@param a integer
---@param b integer
---@param c integer
---@param d integer
function group(stream, block_b_correction, a, b, c, d) end

---Open a information message box to the user
---@param body string
---@param title string
function message_box(body, title) end

---Logs a string inside the host console
---@param data string
function log(data) end

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

---@param ch string
---@return string
function db.char_conv(ch) end

---@param filename string
---@param section string
---@param key string
---@param value string
function db.save_string(filename, section, key, value) end

---@param filename string
---@param section string
---@param key string
---@param value integer
function db.save_integer(filename, section, key, value) end

---@param filename string
---@param section string
---@param key string
---@param value boolean
function db.save_boolean(filename, section, key, value) end

---@param filename string
---@param section string
---@param key string
---@param defaultValue string
---@return string
function db.load_string(filename, section, key, defaultValue) end

---@param filename string
---@param section string
---@param key string
---@param defaultValue integer|nil optional
---@return integer
function db.load_integer(filename, section, key, defaultValue) end

---@param filename string
---@param section string
---@param key string
---@param defaultValue boolean|nil optional
---@return boolean
function db.load_boolean(filename, section, key, defaultValue) end