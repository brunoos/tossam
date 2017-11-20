local socket = require("socket")

local function receive(net)
  return net.conn:receive(1)
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

local function backend(net)
  return net.conn
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
  conn:setoption('tcp-nodealy', true)
  local net = { conn = conn }
  return setmetatable(net, meta)
end

--------------------------------------------------------------------------------
-- Module

return { open = open }
