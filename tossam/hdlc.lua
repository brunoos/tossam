--
-- TOSSAM
-- author: Bruno Silvestre
-- e-mail: brunoos@inf.ufg.br
--
-- Based on TinyOS code
--

local string = require("string")
local table  = require("table")
local bit    = require("bit")

local band   = bit.band
local bor    = bit.bor
local bxor   = bit.bxor
local rshift = bit.rshift
local lshift = bit.lshift

--------------------------------------------------------------------------------
--- DEBUG
--[[
local io = require("io")
local function printf(str, ...)
  print(string.format(str, ...))
end

local function printb(buffer)
  for k, v in ipairs(buffer) do
    io.stdout:write(string.format("%X ", v))
  end
  io.stdout:write("\n")
end
--]]
--------------------------------------------------------------------------------

-- HDLC flags
local HDLC_SYNC   = 0x7E
local HDLC_ESCAPE = 0x7D
local HDLC_MAGIC  = 0x20

local MTU = 255

local function checksum(buffer)
  local crc = 0
  for k, v in ipairs(buffer) do
    crc = band(bxor(crc, lshift(v, 8)), 0xFFFF)
    for i = 1, 8 do
      if band(crc, 0x8000) == 0 then
        crc = band(lshift(crc, 1), 0xFFFF)
      else
        crc = band(bxor(lshift(crc, 1), 0x1021), 0xFFFF)
      end
    end
  end
  return crc
end

local function receive(hdlc)
  while true do
    local data, err = hdlc.back:receive()
    if data then
      data = string.byte(data)
      if hdlc.sync then
        local count = #hdlc.buffer
        if count >= MTU or (hdlc.escape and data == HDLC_SYNC) then
          hdlc.sync = false
        elseif hdlc.escape then
          hdlc.escape = false
          data = bxor(data, HDLC_MAGIC)
          table.insert(hdlc.buffer, data)
        elseif data == HDLC_ESCAPE then
          hdlc.escape = true
        elseif data == HDLC_SYNC then
          local buffer = hdlc.buffer
          hdlc.buffer = {}
          if count > 2 then
            local b1 = table.remove(buffer, count)
            local b2 = table.remove(buffer, count-1)
            local crc = bor(lshift(b1, 8), b2)
            if crc == checksum(buffer) then
              return buffer
            end
          end
        else
          table.insert(hdlc.buffer, data)
        end
      elseif data == HDLC_SYNC then
        hdlc.sync   = true
        hdlc.escape = false
        hdlc.buffer = {}
      end
    elseif err == "timeout" then
      return nil, "timeout"
    else
      hdlc.sync   = false
      hdlc.escape = false
      return nil, err
    end
  end
end

local function send(hdlc, str)
  local data = { string.byte(str, 1, #str) }
  local crc  = checksum(data)
  table.insert(data, band(crc, 0xFF))
  table.insert(data, band(rshift(crc, 8), 0xFF))

  local pck = {HDLC_SYNC}
  for k, v in ipairs(data) do
    if v == HDLC_SYNC or v == HDLC_ESCAPE then
      table.insert(pck, HDLC_ESCAPE)
      table.insert(pck, band(bxor(v, HDLC_MAGIC), 0xFF))
    else
      table.insert(pck, v)
    end
  end
  table.insert(pck, HDLC_SYNC)
  str = string.char(unpack(pck))
  return hdlc.back:send(str)
end

local function close(hdlc)
  hdlc.back:close()
end

local function settimeout(hdlc, v)
  hdlc.back:settimeout(v)
end

local function backend(hdlc)
  return hdlc.back:backend()
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
  local hdlc = {
    queue  = nil,
    escape = false,
    sync   = false,
    back   = back
  }
  return setmetatable(hdlc, meta)
end

--------------------------------------------------------------------------------
-- Module
return { wrap = wrap }
