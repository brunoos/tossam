local socket = require("socket")

local function receive(sf)
  local len, msg = sf.conn:receive(1)
  if msg then
    return nil, msg
  end
  len = string.byte(len)
  if len == 0 then
    return nil, "invalid packet length"
  end
  local pkt, msg = sf.conn:receive(len)
  if msg then
    return nil, msg
  end
  return pkt
end

local function send(sf, data)
  local len = #data
  len = string.char(len)
  local succ, msg = sf.conn:send(len)
  if msg then
    return false, msg
  end
  succ, msg = sf.conn:send(data)
  if msg then
    return false, msg
  end
  return true
end

local function close(sf)
  return sf.conn:close()
end

local function settimeout(sf, v)
  sf.conn:settimeout(v)
end

local function backend(sf)
  return sf.conn
end

local meta = {
  __index = {
    receive    = receive,
    send       = send,
    close      = close,
    settimeout = settimeout,
    backend    = backend,
  }
}

local function open(host, port)
  local conn = socket.tcp()
  local succ, msg = conn:connect(host, port)
  if not succ then
    return nil, msg
  end
  conn:setoption('tcp-nodelay', true)

  -- Receive their version
  local version = conn:receive(2)
  -- Valid version?
  if version ~= "U " then
    return nil, "invalid version"
  end

  -- Send our version
  conn:send("U ")

  local sf = { conn = conn }

  return setmetatable(sf, meta)
end

--------------------------------------------------------------------------------
-- Module

return { open = open }
