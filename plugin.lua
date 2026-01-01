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

---@param body string
---@param title string
function message_box(body, title) end
---@param data string
function log(data) end