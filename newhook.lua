if (SERVER) then
    AddCSLuaFile()
end

local function loadtable(size)
    local t = CompileString("return {"..("nil,"):rep(size - 1).."1}", "loadtable")()
    t[size] = nil
    return t
end

do -- do not use these, just for identification
    local i_fn_table = 1
    local i_id_table = 2
    local i_count    = 3
    local i_start    = 4
end

local internal_representation = {--[[
    HookName = {
        [i_fn_table] = {fn1, fn2, ...},
        [i_id_table] = {nil, nil, fn, nil, ...},
        [i_count]    = iter_count
    }
]]}
local external_representation = {}

local function GetTable()
    return external_representation
end

local function Remove(event, name)
    local external_event = external_representation[event]
    if (not external_event) then
        return
    end

    local fn = external_event[name]
    if (not fn) then
        return
    end
    
    external_event[name] = nil

    local new_id = type(name) ~= "string" and name or nil
    local internal_event = internal_representation[event]

    local fn_table = internal_event[1 --[[i_fn_table]]]
    local id_table = internal_event[2 --[[i_id_table]]]
    local count    = internal_event[3 --[[i_count]]   ]
    local start    = internal_event[4 --[[i_start]]   ]

    if (count == start) then
        internal_representation[event] = nil
        return
    end

    local found = false
    internal_event[4 --[[i_start]]] = start + 1

    for fn_index = count, start, -1 do
        if (fn_table[fn_index] == fn and (not new_id or id_table[fn_index] == new_id)) then
            found = true
        end
        if (found) then
            fn_table[fn_index] = fn_table[fn_index - 1]
            id_table[fn_index] = id_table[fn_index - 1]
        end
    end
end

local function Add(event, name, fn)
    assert(event ~= nil, "bad argument #1 to 'Add' (value expected)")
    if (not name or not fn) then
        return
    end

    -- external table update

    local external_event = external_representation[event]
    if (not external_event) then
        external_event = {}
        external_representation[event] = external_event
    end
    local old_fn = external_event[name]
    external_event[name] = fn
    
    -- internal table update
    local internal_event = internal_representation[event]
    local new_id = type(name) ~= "string" and name or nil
    if (new_id) then
        local real_fn = fn
        fn = function(...)
            if (IsValid(new_id)) then
                local a, b, c, d, e, f = real_fn(new_id, ...)
                if (a ~= nil) then
                    return a, b, c, d, e, f
                end
                return
            end

            Remove(event, new_id)
        end
    end

    if (old_fn) then
        -- replace the old function with the new, if multiple hooks with same function it won't matter
        local fn_table = internal_event[1 --[[i_fn_table]]]
        local id_table = internal_event[2 --[[i_id_table]]]
        for i = internal_event[4 --[[i_start]]], #fn_table do
            if (fn_table[i] == old_fn and new_id == id_table[i]) then
                fn_table[i] = fn
                break
            end
        end
    elseif (internal_event) then
        -- update

        local count = internal_event[3 --[[i_count]]]
        local start = internal_event[4 --[[i_start]]]

        local new_size = count - start + 2

        local fn_table = loadtable(new_size)
        local id_table = loadtable(new_size)
        for i = start, count do
            local start_minus_one = start - 1
            fn_table[i - start_minus_one] = internal_event[1 --[[i_fn_table]]][i]
            id_table[i - start_minus_one] = internal_event[2 --[[i_id_table]]][i]
        end
        fn_table[new_size] = fn
        id_table[new_size] = new_id
        internal_event[1 --[[i_fn_table]]] = fn_table
        internal_event[2 --[[i_id_table]]] = id_table
        internal_event[3 --[[i_count]]   ] = new_size
        internal_event[4 --[[i_start]]   ] = 1
    else 
        -- create
        internal_event = {
            -- i_fn_table
            { fn },
            -- i_id_table
            { 1 }, -- we update this later
            -- i_count
            1,
            -- i_start
            1
        }
        -- set to 
        internal_event[2 --[[ i_id_table ]]][1] = new_id
        internal_representation[event] = internal_event
    end
end

local function Call(event, gm, ...) -- as long as we pass these through select or directly to the end of a function everything will be ok
    local internal_event = internal_representation[event]

    if (internal_event) then
        local fn_table = internal_event[1 --[[i_fn_table]]]
        for i = internal_event[4 --[[i_start]]], internal_event[3 --[[i_count]]] do
            local a, b, c, d, e, f = fn_table[i](...)
            if (a ~= nil) then
                return a, b, c, d, e, f
            end
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