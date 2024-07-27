local M = {}

local script_tmpl = [[Application("com.hezongyidev.Bob").request('%s')]]

---@param request table
---@return boolean ok If the request is successful
---@return table resp The response from Bob
function M.call_bob(request)
  local json = hs.json.encode(request)
  local script = script_tmpl:format(json)
  local ok, resp = hs.osascript.javascript(script)
  if type(resp) == "string" then resp = hs.json.decode(resp) end
  return ok, resp
end

---@param body table
local function translate(body)
  local request = {
    path = "translate",
    body = body,
  }
  return M.call_bob(request)
end

function M.selection_translate() return translate { action = "selectionTranslate" } end

function M.snip_translate() return translate { action = "snipTranslate" } end

function M.input_translate() return translate { action = "inputTranslate" } end

function M.pasteboard_translate() return translate { action = "pasteboardTranslate" } end

function M.show_window() return translate { action = "showWindow" } end

local function ocr(body)
  local request = {
    path = "ocr",
    body = body,
  }
  return M.call_bob(request)
end

function M.snip_ocr(silent)
  return ocr { action = "snipOCR", isSilent = silent or false }
end

function M.silent_snip_ocr() return M.snip_ocr(true) end

return M
