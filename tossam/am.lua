--
-- TOSSAM
-- author: Bruno Silvestre
-- e-mail: brunoos@inf.ufg.br
--

local string = require("string")
local table  = require("table")

--------------------------------------------------------------------------------

-- Framer-level message type
local SERIAL_PROTO_ACK            = 67
local SERIAL_PROTO_PACKET_ACK     = 68
local SERIAL_PROTO_PACKET_NOACK   = 69
local SERIAL_PROTO_PACKET_UNKNOWN = 255

local seqno = 42

local function receive(am)
  while true do
    local pck, err = am.back:receive()
    if not pck then
      return nil, err
    end
    local kind = table.remove(pck, 1)
    if kind == SERIAL_PROTO_ACK then
      -- ignored
    elseif kind == SERIAL_PROTO_PACKET_NOACK then
      return string.char(unpack(pck))
    elseif kind == SERIAL_PROTO_PACKET_ACK then
      -- remove 'seqno'
      table.remove(pck, 1)
      return string.char(unpack(pck))
    else
      return nil, "unknown AM package"
    end
  end
end

local function send(am, str)
  seqno = ((seqno + 1) % 255)
  str = string.char(SERIAL_PROTO_PACKET_ACK) ..
        string.char(seqno) ..
        str
  local succ, err = am.back:send(str)
  if not succ then
    return false, err
  end
  return true
end
  
local function close(am)
  am.back:close()
end

local function settimeout(am, v)
  am.back:settimeout(v)
end
  
local function backend(am)
  return am.back:backend()
end
  
local meta = {
  __index = {
    receive    = receive,
    send       = send,
    close      = close,
    settimeout = settimeout,
    backend    = backend
  }
}
  
local function wrap(back)
  local am = { back = back }
  return setmetatable(am, meta)
end
  
--------------------------------------------------------------------------------
-- Module
return { wrap = wrap }
  