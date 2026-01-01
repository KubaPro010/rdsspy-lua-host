---@meta

---This function should be defined by the user in the script
---EXIT, CONFIGURE, SHOW commands are not sent to the script
---@param cmd string
---@param param string
function command(cmd, param) end

---@param body string
---@param title string
function message_box(body, title) end