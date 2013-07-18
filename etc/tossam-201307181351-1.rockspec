rockspec_format = "1.0"
package = "tossam"
version = "201307181351-1"

description = {
  summary = "TinyOS Serial AM message for Lua",
  detailed = "",
  homepage = "http://www.inf.ufg.br/~brunoos/tossam/",
  license = "MIT/X11",
  maintainer = "Bruno Silvestre <brunoos@inf.ufg.br>",
}

source = {
  url = "http://www.inf.ufg.br/~brunoos/tossam/download/tossam-201307181351.tar.gz",
}

dependencies = {
  "lua == 5.1",
  "luars232 == 1.0.3-1",
  "bitlib == 23-2",
  "lpeg == 0.12-1",
  "struct == 1.4-1",
}

build = {
  type = "builtin",
  modules = {
    ["tossam"]        = "tossam.lua",
    ["tossam.serial"] = "serial.lua",
    ["tossam.codec"]  = "codec.lua",
  },
}
