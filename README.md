# ini-parser-luvit
INI parser for config


## Usage


config.ini 
```ini
[section]
key=value
```


In your Lua file
```lua
local ini = require('ini-parser-luvit')
local config = ini.parseFile('config.ini')
print(config.section.key)
```


