local socket = require("socket")

local function receive(sf)
  if not sf.len then
    local len, err = sf.conn:receive(1)
    if err then
      return true, nil, err
    end
    len = string.byte(len)
    if len == 0 then
      return true, nil, "invalid packet length"
    end
    sf.len = len
    sf.queue = {}
  end

  local data, err, part = sf.conn:receive(sf.len)
  if data then
    data = table.concat(sf.queue) .. data
    sf.len = nil
    sf.queue = nil
    return data
  elseif err == "timeout" then
    if part then
      table.insert(sf.queue, part)
      sf.len = sf.len - #part
    end
    return nil, err
  end
  sf.len = nil
  sf.queue = nil
  return nil, err
end

local function send(sf, data)
  local succ, err, last
  if data then
    local len = #data
    len = string.char(len)
    succ, err = sf.conn:send(len)
    if err then
      return false, err
    end
    sf.index = 1
    sf.data  = data
  elseif not sf.data then
    return false, "invalid state"
  end
  succ, err, last = sf.conn:send(sf.data, sf.index)
  if succ then
    sf.index = nil
    sf.data  = nil
    return true
  elseif err == "timeout" then
    sf.index = last + 1
    return false, err
  end
  sf.index = nil
  sf.data  = nil
  return false, err
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
