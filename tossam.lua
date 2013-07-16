local codec  = require("tossam.codec")
local serial = require("tossam.serial")

local string = require("string")
local table  = require("table")

local type         = type
local print        = print
local pairs        = pairs
local ipairs       = ipairs
local setmetatable = setmetatable

module("tossam")

local strheader = [[
nx_struct header[0] {
  nx_uint8_t  am;
  nx_uint16_t dst;
  nx_uint16_t src;
  nx_uint8_t  len;
  nx_uint8_t  grp;
  nx_uint8_t  type;
};
]]

local defheader = (codec.parser(strheader))[1]

local function register(srl, str)
   local defs, err = codec.parser(str)
   if err then return false, err end
   local tmp = {}
   for i, def in ipairs(defs) do
     if srl.defs[def.id] or tmp[def.id] then
        return false, "AM type already defined: " .. def.name
     else
        tmp[def.id] = true
     end
   end
   for i, def in ipairs(defs) do
     srl.defs[def.id]   = def
     srl.defs[def.name] = def
   end
   return true
end

local function registered(srl)
  local defs = {}
  for k, v in pairs(srl.defs) do
    if type(k) == "string" then
      defs[k] = v.id
    end
  end
  return defs
end

local function unregister(srl, id)
  local def = srl.defs[id]
  if def then
    srl.defs[def.id]   = nil
    srl.defs[def.name] = nil
    return true
  end
  return false
end

local function close(srl)
   return serial.close(srl.port)
end

local function receive(srl)
   local pck = serial.recv(srl.port)
   if not pck then return nil end
   local head = codec.decode(defheader, pck, 1)
   local def = srl.defs[head.type]
   if not def then
      return nil, "Unknown AM type"
   end
   -- skip the header
   local payload = codec.decode(def, pck, 9)
   payload[1] = def.id
   payload[2] = def.name
   return payload
end

local function send(srl, payload, def)
   def = def or payload[1]
   if (type(def) ~= "number" and type(def) ~= "string") then
      return false, "Invalid parameters"
   end
   def = srl.defs[def]
   if not def then
      return false, "Unknown AM type"
   end
   payload = codec.encode(def, payload)
   local head = {
      am   = 0,
      src  = 0,
      dst  = 0xFFFF,
      len  = #payload,
      grp  = 0,
      type = def.id,
   }
   head = codec.encode(defheader, head)
   if serial.send(srl.port, head..payload) then
      return true
   end
   return false, "Could not send the message"
end

local meta = { }
meta.__index = {
  close      = close,
  send       = send,
  receive    = receive,
  register   = register,
  registered = registered,
  unregister = unregister,
}

function connect(dev, baud)
  local port, err = serial.open(dev, baud)
  if err then return nil, err end
  local srl = { port = port, defs = {} }
  return setmetatable(srl, meta)
end
