local socket = require("socket")

--------------------------------------------------------------------------------

local function lowsend(net, data)
  local i = 1
  while true do
    local succ, msg, last = net.conn:send(data, i)
    if succ then
      return true
    elseif msg ~= "timeout" then
      return false, msg
    else
      if last >= i then
        i = last + 1
      end
      coroutine.yield(false, "timeout")
    end
  end
end

--------------------------------------------------------------------------------

local function send(net, data)
  if not data and not net.current then
    return false, "invalid state"
  elseif data then
    net.current = coroutine.create(lowsend)
  end

  local status, err, msg = coroutine.resume(net.current, net, data)

  if not status then
    net.current = nil
    return false, err
  elseif err then
    net.current = nil
    return true
  elseif msg ~= "timeout" then
    net.current = nil
    return false, msg
  end

  return false, "timeout"
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
