local socket = require("socket")

local function recv(net, size)
  return net.conn:recv(size)
end

local function send(net, data)
  return net.conn:send(data)
end

local function close(net)
  return net.conn:close()
end

local function settimeout(net, v)
  net.conn:settimeout(v)
end

local meta = {
  __index = {
    recv       = recv,
    send       = send,
    close      = close,
    settimeout = settimeout
  }
}

local function open(host, port)
  local conn = socket.tcp()
  local succ, msg = conn:connect(host, port)
  if not succ then
    return nil, msg
  end
  conn:settimeout(1000)
  local net = { conn = conn }
  return setmetatable(net, meta)
end

--------------------------------------------------------------------------------
-- Module

return { open = open }
