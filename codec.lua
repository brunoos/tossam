local re     = require("re")
local struct = require("struct")

local string = require("string")
local table  = require("table")

local print    = print
local type     = type
local pairs    = pairs
local ipairs   = ipairs
local tonumber = tonumber

module("tossam.codec")

local grammar = [==[
structs <- s {| struct+ (!. / error) |}
error <- {| {:pos: {} :} {:kind: . -> 'ERROR':} |}
struct <- {| s
             "nx_struct" S
             {:name: name :} s
             "[" s {:id: num :}  s "]" s
             {:block: block :} s
             ";" s
         |}
block  <- {|
            "{" s
            (vector / scalar)+
            "}" s
          |}
scalar <- {|
             {:kind: "" -> "SCALAR" :}
             {:type: type :} S
             {:name: name :} s
             ";" s
           |}
vector <- {|
             {:kind: "" -> "VECTOR" :}
             {:type: type :} s
             {:name: name :} s
             "[" s
             {:size: (numSize / varSize) :} s
             "]" s
             ";" s
           |}
type   <- {
            "nx_int8_t"     / "nx_int16_t"    /
            "nx_int32_t"    / "nx_int64_t"    /
            "nx_uint8_t"    / "nx_uint16_t"   /
            "nx_uint32_t"   / "nx_uint64_t"   /
            "nxle_int8_t"   / "nxle_int16_t"  /
            "nxle_int32_t"  / "nxle_int64_t"  /
            "nxle_uint8_t"  / "nxle_uint16_t" /
            "nxle_uint32_t" / "nxle_uint64_t" /
            "nx_float"
          }
varSize  <- {|
              {:kind: "" -> "VAR" :}
              {:var: name :}
            |}
numSize  <- {|
              {:kind: "" -> "NUM" :}
              {:value: num :}
            |}
name   <- { ([a-zA-Z] / "_") ([a-zA-Z0-9] / "_")* }
num    <- { [0-9]+ }
s      <- (%s / %nl)*
S      <- (%s / %nl)+
]==]

local format = {
   nx_int8_t     = ">i1",
   nx_int16_t    = ">i2",
   nx_int32_t    = ">i4",
   nx_int64_t    = ">i8",
   nx_uint8_t    = ">I1",
   nx_uint16_t   = ">I2",
   nx_uint32_t   = ">I4",
   nx_uint64_t   = ">I8",
   nxle_int8_t   = "<i1",
   nxle_int16_t  = "<i2",
   nxle_int32_t  = "<i4",
   nxle_int64_t  = "<i8",
   nxle_uint8_t  = "<I1",
   nxle_uint16_t = "<I2",
   nxle_uint32_t = "<I4",
   nxle_uint64_t = "<I8",
   nx_float      =   "f",
}

--------------------------------------------------------------------------------

local function check(def)
  def.vars = {}
  def.id = tonumber(def.id)
  for k, var in ipairs(def.block) do
    if def.vars[var.name] then
      return false
    end
    if var.kind == "VECTOR" then
      if var.size.kind == "NUM" then
        var.size.value = tonumber(var.size.value)
      elseif (not def.vars[var.size.var]) or
             (def.vars[var.size.var].type == "nx_float")
      then
        -- Variable must be already declared
        return false
      end
    end
    def.vars[var.name] = var
  end
  return true
end

function parser(str)
  local defs = re.match(str, grammar)
  local err = defs[#defs]
  if err.kind == "ERROR" then
    return nil, "Parser error at " .. tostring(err.pos)
  end
  for i, def in ipairs(defs) do
    if not def or not check(def) then
      return nil, "Parser error"
    end
  end
  return defs
end

--------------------------------------------------------------------------------

function decode(def, data, pos)
  local fmt, value
  local payload = {}
  for k, field in ipairs(def.block) do
     if field.kind == "SCALAR" then
        value, pos = struct.unpack(format[field.type], data, pos)
        payload[field.name] = value
     elseif field.size.kind == "NUM" then
        local tb = {
          struct.unpack(
            string.rep(format[field.type], field.size.value),
            data,
            pos)
        }
        pos = table.remove(tb, #tb)
        payload[field.name] = tb
     elseif type(payload[field.size.var]) == "number" and 
            payload[field.size.var] > 0 
     then
        local tb = {
          struct.unpack(
            string.rep(format[field.type], payload[field.size.var]),
            data,
            pos)
        }
        pos = table.remove(tb, #tb)
        payload[field.name] = tb
     else
        return nil
     end
  end
  return payload
end

function encode(def, payload)
  local fmt, value
  local data = {}
  for k, field in ipairs(def.block) do
     if field.kind == "SCALAR" and 
        type(payload[field.name]) == "number"
     then
        data[#data+1] = struct.pack(
           format[field.type],
           payload[field.name])
     elseif field.size.kind == "NUM" and 
            type(payload[field.name]) == "table" 
     then
        for i = 1, field.size.value do
          data[#data+1] = struct.pack(
             format[field.type],
             payload[field.name][i])
        end
        -- Padding with zero
        for i = 1, (field.size.value - #payload[field.name]) do
          data[#data+1] = struct.pack(format[field.type], 0)
        end
     elseif type(payload[field.size.var]) == "number" and 
            payload[field.size.var] > 0               and
            type(payload[field.name]) == "table"
     then
        for i = 1, payload[field.size.var] do
          data[#data+1] = struct.pack(
             format[field.type],
             payload[field.name][i])
        end
        -- Padding with zero
        for i = 1, (payload[field.size.var] - #payload[field.name]) do
          data[#data+1] = struct.pack(format[field.type], 0)
        end
     else
        return nil
     end
  end
  return table.concat(data)
end
