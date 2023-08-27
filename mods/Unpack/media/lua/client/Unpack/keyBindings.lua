require("Unpack/Constants");

local binding = {};
binding.value = "[" .. Unpack.NAME .. "]";  -- this triggers the logic to build a new heading in PZ MainOptions.lua
table.insert(keyBinding, binding);
binding = {};
binding.value = Unpack.KEY_NAME;
binding.key = 54; -- RSHIFT key
table.insert(keyBinding, binding);