local socket = require("socket")

local function send(net, data)
  if data then
    net.index = 1
    net.data  = data
  elseif not net.data then
    return false, "invalid state"
  end

  local succ, err, last = net.conn:send(net.data, net.index)
  if succ then
    net.index = nil
    net.data  = nil
    return true
  elseif err == "timeout" then
    net.index = last + 1
    return false, err
  end
  net.index = nil
  net.data  = nil
  return false, err
end

local function receive(net)
  local  data, err = net.conn:receive(1)
  return data, err
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
  conn:setoption('tcp-nodelay', true)
  local net = { conn = conn }
  return setmetatable(net, meta)
end

--------------------------------------------------------------------------------
-- Module

return { open = open }
