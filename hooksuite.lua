-- major features of the hook library need to be considered
-- performance is eaten from in-engine hook.Call calls every few frames/ticks
-- add/remove are not super important but should be considered still

local hook_name = "HookSuite"
local call_count         = 4000000
local no_hook_call_count = 40000000

local hooks = {
    function()
    end,
    function()
    end,
    function()
    end
}

local gm = {
    [hook_name] = function() end,
    NEVERUSETHISOK = function() end
}

return {
    CallNoGM = function(lib)
        local call = lib.Call
        local bench_time, hook_name, call_count = SysTime, hook_name, call_count -- yes this is important

        local start_time = bench_time()

        for i = 1, call_count do
            call(hook_name)
        end
        local end_time = bench_time()

        return (end_time - start_time), call_count
    end,
    CallGM = function(lib)
        local call = lib.Call
        local bench_time, hook_name, call_count, gm = SysTime, hook_name, call_count, gm -- yes this is important

        local start_time = bench_time()

        for i = 1, call_count do
            call(hook_name, gm)
        end
        local end_time = bench_time()

        return (end_time - start_time), call_count
    end,
    CallNoHooks = function(lib)
        local call = lib.Call
        local bench_time, hook_name, no_hook_call_count = SysTime, "NEVERUSETHISOK", no_hook_call_count -- yes this is important

        local start_time = bench_time()

        for i = 1, no_hook_call_count do
            call(hook_name)
        end
        local end_time = bench_time()

        return (end_time - start_time), no_hook_call_count
    end,
    CallGMOnly = function(lib)
        local call = lib.Call
        local bench_time, hook_name, no_hook_call_count = SysTime, "NEVERUSETHISOK", no_hook_call_count -- yes this is important

        local start_time = bench_time()

        for i = 1, no_hook_call_count do
            call(hook_name, gm)
        end
        local end_time = bench_time()

        return (end_time - start_time), no_hook_call_count
    end,
    All = function(self, lib)
        for i = 1, #hooks do
            lib.Add(hook_name, tostring(i), hooks[i])
        end
        local rets = {}
        for k,v in pairs(self) do
            if (k ~= "All") then
                local time, amountofcalls = self[k](lib)
                rets[k] = {
                    Time = time,
                    Calls = amountofcalls
                }
            end
        end
        return rets
    end
}