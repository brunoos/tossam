local codec  = require("tossam.codec")
local serial = require("tossam.serial")

local string = require("string")
local table  = require("table")

local type         = type
local print        = print
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

local defheader = codec.parser(strheader)

local function register(srl, str)
   local def, err = codec.parser(str)
   if err then return false, err end
   if srl.db[def.type] then
      return false, "AM type already registered"
   end
   srl.db[def.id]   = def
   srl.db[def.name] = def
   return true
end

local function close(srl)
   return serial.close(srl.fd)
end

local function receive(srl)
   local pck = serial.read(srl.fd)
   if not pck then return nil end
   local head = codec.decode(defheader, pck, 1)
   local def = srl.db[head.type]
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
   def = srl.db[def]
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
   if serial.write(srl.fd, head..payload) then
      return true
   end
   return false, "Could not send the message"
end

local function getfd(srl)
   return serial.getfd(srl.fd)
end

local meta = { }
meta.__index = {
  close    = close,
  getfd    = getfd,
  send     = send,
  receive  = receive,
  register = register,
}

function connect(dev, baud, nonblocking)
  local fd, err
  nonblocking = (nonblocking and true) or false
  if type(baud) == "string" then
    baud, err = serial.baud(baud)
    if not baud then
      return nil, err
    end
  end
  fd, err = serial.open(dev, baud, nonblocking)
  if err then return nil, err end
  local srl = { fd = fd, db = {} }
  return setmetatable(srl, meta)
end
