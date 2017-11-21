--
-- TOSSAM
-- author: Bruno Silvestre
-- e-mail: brunoos@inf.ufg.br
--

local rs232 = require("luars232")

--------------------------------------------------------------------------------
local mote2baud = {
  eyesifx    = rs232.RS232_BAUD_57600,
  intelmote2 = rs232.RS232_BAUD_115200,
  iris       = rs232.RS232_BAUD_57600,
  mica       = rs232.RS232_BAUD_19200,
  mica2      = rs232.RS232_BAUD_57600,
  mica2dot   = rs232.RS232_BAUD_19200,
  micaz      = rs232.RS232_BAUD_57600,
  shimmer    = rs232.RS232_BAUD_115200,
  telos      = rs232.RS232_BAUD_115200,
  telosb     = rs232.RS232_BAUD_115200,
  tinynode   = rs232.RS232_BAUD_115200,
  tmote      = rs232.RS232_BAUD_115200,
  ucmini     = rs232.RS232_BAUD_115200,
}

local UINT32_MAX = 4294967295

local function receive(srl)
  local err, data = srl.port:read(1, srl.timeout)
  if err == rs232.RS232_ERR_NOERROR then
    return data
  elseif err == rs232.RS232_ERR_TIMEOUT then
    return nil, "timeout"
  end
  return nil, rs232.error_tostring(err)
end

local function send(srl, data)
  local err
  if srl.timeout then
    err = srl.port:write(data, srl.timeout)
  else
    err = srl.port:write(data)
  end
  if err == rs232.RS232_ERR_NOERROR then
    return true
  elseif err == rs232.RS232_ERR_TIMEOUT then
    return false, "timeout"
  end
  return false, rs232.error_tostring(err)
end

local function close(srl)
  srl.port:close()
end

local function settimeout(srl, v)
  srl.timeout = (v >= 0) and v or UINT32_MAX
end

local function backend(srl)
  return srl.port
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

local function open(portname, baud)
  if type(baud) == "string" then
    baud = mote2baud[baud]
    if not baud then
      return nil, "Invalid baud rate"
    end
  elseif type(baud) == "number" then
    baud = rs232["RS232_BAUD_" .. tostring(baud)]
    if not baud then
      return nil, "Invalid baud rate"
    end
  else
    return nil, "Invalid baud rate"
  end

  local err, port = rs232.open(portname)
  if err ~= rs232.RS232_ERR_NOERROR then
    return nil, rs232.error_tostring(err)
  end
  
  if port:set_baud_rate(baud) ~= rs232.RS232_ERR_NOERROR                    or
     port:set_data_bits(rs232.RS232_DATA_8) ~= rs232.RS232_ERR_NOERROR      or
     port:set_parity(rs232.RS232_PARITY_NONE) ~= rs232.RS232_ERR_NOERROR    or
     port:set_stop_bits(rs232.RS232_STOP_1) ~= rs232.RS232_ERR_NOERROR      or
     port:set_flow_control(rs232.RS232_FLOW_OFF) ~= rs232.RS232_ERR_NOERROR
  then
     port:close()
     return nil, "Serial port setup error"
  end

  local srl = {
    port    = port,
    timeout = UINT32_MAX,
  }

  return setmetatable(srl, meta)
end

--------------------------------------------------------------------------------
-- Module
return { open = open }
