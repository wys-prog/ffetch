## Fixme #1: On slow internet conditions
Git and Curl can crash due to the slow internet debit. Because of that, I don't know what happens to lua but it completely crashes out.
I also should find a way to make error() function not destroying everything. Using pcall() more frequently seems to be a great idea.
checking for dependency 'git': found at '/usr/bin/git'
checking for dependency 'curl': found at '/usr/bin/curl'
checking for dependency 'gcc': found at '/usr/bin/gcc'
checking for dependency 'g++': not found
checking for dependency 'lua': found at '/usr/bin/lua'
checking for dependency 'make': not found
checking for dependency 'cmake': not found
checking for dependency 'micro': found at '/usr/bin/micro'
unpacking 'godot'...
godot: done
lua: ffetch.lua:412: Git failed to install 'godot' (exit: 129)
stack traceback:
        [C]: in global 'assert'
        ffetch.lua:412: in field 'unpack'
        ffetch.lua:438: in field 'installone'
        ffetch.lua:455: in field '?'
        ffetch.lua:514: in main chunk
        [C]: in ?
