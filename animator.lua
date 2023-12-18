local require = function(module)
    if type(module) == "string" then 
        local func, err = loadstring(game:GetService('HttpService'):GetAsync((module:sub(1,8) == "https://" and "" or "https://")..module))
        if not func then 
            warn(err) 
        else
            return func()
        end 
    else 
        return getfenv().require(module)
    end 
end

local path = 'https://vxsqi.tk/scripts/animation'
local animation = game'HttpService':JSONDecode(`{path}/idle.lua`)

local cfamodule = require(`{path}/cfa3.lua`)
local cfa = cfamodule

local anim = cfa.new(owner,animation)
anim:play()