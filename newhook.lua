if (SERVER and not MENU_DLL) then
    AddCSLuaFile()
end

do 
    local i_fn      = 1
    local i_id      = 2
    local i_next    = 3
    local i_real_fn = 5
    local i_last    = 5
end

local event_table = {}

local function GetTable()
    -- TODO: implement better
    local out = {}
    for event, hooklist in pairs(event_table) do
        out[event] = {}
        ::startloop::
            out[event][hooklist[2 --[[i_id]]]] = hooklist[4 --[[i_real_fn]]]
            hooklist = hooklist[3 --[[i_next]]] 
        if (hooklist) then
            goto startloop
        end
    end
    return out
end

local function Remove(event, name)

    if (not name) then
        return
    end

    local hook = event_table[event]
    if (not hook) then
        return
    end

    local found = false

    local event_start = hook
    ::startloop::
        if (hook[2 --[[i_id]]] == name) then
        
            if (hook == event_start) then
                event_table[event] = hook[3 --[[i_next]]]
            end

            local last, next = hook[5 --[[i_last]]], hook[3 --[[i_next]]]
            if (last) then
                last[3 --[[i_next]]] = hook[3 --[[i_next]]]
            end
            if (next) then
                next[5 --[[i_last]]] = hook[5 --[[i_last]]]
            end
            found = true
            goto breakloop
        end
        hook = hook[3 --[[i_next]]]
    if (hook) then
        goto startloop
    end
    ::breakloop::
    


    if (not found) then
        return
    end
    
    local start = event_table[event]
    if (not start) then
        return
    end

end
local function Add(event, name, fn)
    assert(event ~= nil, "bad argument #1 to 'Add' (value expected)")
    if (not name or not fn) then
        return
    end
    local real_fn = fn
    if (type(name) ~= "string") then
        fn = function(...)
            if (IsValid(name)) then
                local a, b, c, d, e, f = real_fn(name, ...)
                if (a ~= nil) then
                    return a, b, c, d, e, f
                end
                return
            end

            Remove(event, name)
        end
    end

    local hook = event_table[event]
    local event_start = hook
    
    local new_hook
    local found = false

    if (hook) then
        ::startloop::
            if (hook[2 --[[i_id]]] == name) then
                new_hook = hook
                found = true
                goto breakloop
            end
            hook = hook[3 --[[i_next]]]
        if (hook) then
            goto startloop
        end
    end
    ::breakloop::

    if (found) then
        new_hook[1 --[[i_fn]]     ] = fn
        new_hook[4 --[[i_real_fn]]] = real_fn
    else
        new_hook = {
            -- i_fn
            fn,
            -- i_id
            name,
            -- i_next
            event_start,
            -- i_real_fn
            real_fn,
            -- i_last
            1
        }
        new_hook[5 --[[i_last]]] = nil
        if (event_start) then
            event_start[5 --[[i_last]]] = new_hook
        end
        event_table[event] = new_hook
    end
end

local function Call(event, gm, ...)

    -- TODO: hooks
    local hook = event_table[event]

    if (hook) then
        ::startloop::
            local a, b, c, d, e, f = hook[1 --[[i_fn]]](...)
            if (a ~= nil) then
                return a, b, c, d, e, f
            end

            hook = hook[3 --[[i_next]]]
        if (hook) then
            goto startloop
        end
    end

    if (gm) then
        local fn = gm[event]
        if (fn) then
            return fn(gm, ...)
        end
    end
end

local function Run(event, ...)
    return Call(event, gmod and gmod.GetGamemode() or nil, ...)
end

return {
    Remove = Remove,
    GetTable = GetTable,
    Add = Add,
    Call = Call,
    Run = Run
}