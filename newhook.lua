if (SERVER and not MENU_DLL) then
    AddCSLuaFile()
end

do 
    local i_fn      = 1
    local i_id      = 2
    local i_next    = 3
    local i_count   = 4
    local i_real_fn = 5
    local i_last    = 6
end

local event_table = {}

local function GetTable()
    -- TODO: implement better
    local out = {}
    for event, hooklist in pairs(event_table) do
        out[event] = {}
        for i = 1, hooklist[4 --[[i_count]]] do
            out[event][hooklist[2 --[[i_id]]]] = hooklist[5 --[[i_real_fn]]]
            hooklist = hooklist[3 --[[i_next]]] 
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
    for i = 1, hook[4 --[[i_count]]] do
        if (hook[2 --[[i_id]]] == name) then
            local last, next = hook[6 --[[i_last]]], hook[3 --[[i_next]]]
            if (last) then
                last[3 --[[i_next]]] = hook[3 --[[i_next]]]
            end
            if (next) then
                next[6 --[[i_last]]] = hook[6 --[[i_last]]]
            end
            found = true
            break
        end
        hook = hook[3 --[[i_next]]]
    end
    
    if (not found) then
        return
    end
    
    local start = event_table[event]
    if (not start) then
        return
    end

    start[4 --[[i_count]]] = start[4 --[[i_count]]] - 1

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
        for i = 1, hook[4 --[[i_count]]] do
            if (hook[2 --[[i_id]]] == name) then
                new_hook = hook
                found = true
                break
            end
            hook = hook[3 --[[i_next]]]
        end
    end

    if (found) then
        new_hook[1 --[[i_fn]]     ] = fn
        new_hook[5 --[[i_real_fn]]] = real_fn
    else
        new_hook = {
            -- i_fn
            fn,
            -- i_id
            name,
            -- i_next
            event_start,
            --i_count
            1, 
            -- i_real_fn
            real_fn,
            -- i_last
            1
        }
        new_hook[6 --[[i_last]]] = nil
        if (event_start) then
            event_start[6 --[[i_last]]] = new_hook
            new_hook[4 --[[i_count]]] = event_start[4 --[[i_count]]] + 1
        end
        event_table[event] = new_hook
    end
end

local function Call(event, gm, ...)

    -- TODO: hooks
    local hook = event_table[event]

    if (hook) then
        for i = 1, hook[4 --[[i_count]]] do
            local a, b, c, d, e, f = hook[1 --[[i_fn]]](...)
            if (a ~= nil) then
                return a, b, c, d, e, f
            end

            hook = hook[3 --[[i_next]]]
        end
    end

    if (not gm) then
        return
    end

    local fn = gm[event]
    if (not fn) then
        return
    end

    return fn(gm, ...)
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