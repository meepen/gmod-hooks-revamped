-- major features of the hook library need to be considered
-- performance is eaten from in-engine hook.Call calls every few frames/ticks
-- add/remove are not super important but should be considered still

local hook_name = "HookSuite"
local call_count         = 4000000
local no_hook_call_count = 1000000000
local invalid_call_count = 200000

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
    CallInvalid = function(lib)
        local call, add = lib.Call, lib.Add
        local bench_time, hook_name, invalid_call_count = SysTime, "NEVERUSETHISOK", invalid_call_count -- yes this is important
        local t1, t2, t3 = 
            {IsValid = function() return false end},
            {IsValid = function() return false end},
            {IsValid = function() return false end}
        
        local function nop() end

        local start_time = bench_time()
        
        for i = 1, invalid_call_count do
            add(hook_name, t1, nop)
            add(hook_name, t2, nop)
            add(hook_name, t3, nop)
            call(hook_name, gm)
        end
        
        local end_time = bench_time()
        
        return (end_time - start_time), invalid_call_count
    end,
    Verify = function(hook)
        local HOOK_ID = "VERIFY_HOOK"
        
        local call_count = 0

        local function add() call_count = call_count + 1 end

        hook.Add(HOOK_ID, HOOK_ID, add)
        hook.Call(HOOK_ID)
        assert(call_count == 1, "Call count not sane")

        call_count = 0
        hook.Remove(HOOK_ID, HOOK_ID)
        hook.Call(HOOK_ID)
        assert(call_count == 0, "Call count not sane after remove")

        call_count = 0
        hook.Add(HOOK_ID, HOOK_ID, add)
        hook.Call(HOOK_ID)
        assert(call_count == 1, "Call count not sane after readd")

        call_count = 0
        hook.Add(HOOK_ID, HOOK_ID, add)
        hook.Call(HOOK_ID)
        assert(call_count == 1, "Call count not sane after duped add")


        call_count = 0
        local t = {IsValid = function() return true end}
        hook.Add(HOOK_ID, t, add)
        hook.Call(HOOK_ID)
        assert(call_count == 2, "Call count not sane after calling IsValid")

        hook.Add(HOOK_ID, HOOK_ID)
        assert(hook.GetTable()[HOOK_ID][HOOK_ID], "Removed instead of returning")
        call_count = 0
        hook.Call(HOOK_ID)
        assert(call_count == 2, "Wrong call count after add with nil function")

        hook.Remove(HOOK_ID, HOOK_ID)
        call_count = 0
        hook.Call(HOOK_ID)
        assert(call_count == 1, "Call count not one")

        hook.Remove(HOOK_ID, t)

        call_count = 0
        hook.Call(HOOK_ID)
        assert(call_count == 0, "Call count not zero")

        call_count = 0
        hook.Add(HOOK_ID, HOOK_ID, add)

        hook.Add(HOOK_ID, {IsValid = function() return false end}, add)
        hook.Add(HOOK_ID, {IsValid = function() return true end}, add)
        hook.Call(HOOK_ID)

        assert(call_count == 2, "Call count not two after adding isvalids "..call_count)

        return 0, 1, true
    end,
    All = function(self, lib)
        for i = 1, #hooks do
            lib.Add(hook_name, tostring(i), hooks[i])
        end
        local rets = {}
        for k,v in pairs(self) do
            if (k ~= "All") then
                local time, amountofcalls, success = self[k](lib)
                rets[k] = {
                    Time = time,
                    Calls = amountofcalls,
                    Success = success
                }
            end
        end
        return rets
    end
}