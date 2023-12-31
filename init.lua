olua = {}

function __TRACEBACK__(message)
    print(debug.traceback(message))
end

olua.os = package.cpath:find('?.dll') and 'windows' or
    ((io.popen('uname'):read("*l"):find('Darwin')) and 'macos' or 'linux')

function olua.is_windows()
    return olua.os == "windows"
end

local _ipairs = ipairs
function ipairs(t)
    local mt = getmetatable(t)
    return (mt and mt.__ipairs or _ipairs)(t)
end

local _pairs = pairs
function pairs(t)
    local mt = getmetatable(t)
    return (mt and mt.__pairs or _pairs)(t)
end

-------------------------------------------------------------------------------
-- error
-------------------------------------------------------------------------------
local willdo = ''
function olua.willdo(exp)
    willdo = olua.format(exp)
end

local function throw_error(msg)
    if #willdo > 0 then
        print(willdo)
    end
    error(msg)
end


function olua.error(exp)
    throw_error(olua.format(exp))
end

function olua.assert(cond, exp)
    if not cond then
        olua.error(exp or '<no assert info>')
    end
    return cond
end

function olua.print(exp)
    print(olua.format(exp))
end

-------------------------------------------------------------------------------
-- io
-------------------------------------------------------------------------------
function olua.mkdir(dir)
    dir = olua.format(dir)
    if olua.os == "windows" then
        dir = string.gsub(dir, "/", "\\")
        olua.exec("mkdir ${dir}")
    else
        olua.exec("mkdir -p ${dir}")
    end
end

function olua.pwd()
    local dir
    if olua.os == "windows" then
        dir = io.popen("cd"):read("*l")
        dir = dir:gsub("\\", "/")
    else
        dir = io.popen("pwd"):read("*l")
    end
    return dir
end

function olua.rmdir(dir)
    dir = olua.format(dir)
    if olua.os == "windows" then
        dir = string.gsub(dir, "/", "\\")
        olua.exec("rmdir /s /q ${dir}")
    else
        olua.exec("rm -rf ${dir}")
    end
end

function olua.rm(path)
    path = olua.format(path)
    print('rm ' .. path)
    os.remove(path)
end

function olua.exec(expr)
    expr = olua.format(expr)
    local flag = false
    for cmd in string.gmatch(expr, '[^\n\r]+') do
        if string.find(cmd, '[\\] *$') then
            if flag then
                print("      " .. cmd)
            else
                print("exec: " .. cmd)
            end
            flag = true
        else
            flag = false
            print("exec: " .. cmd)
        end
    end
    os.execute(expr)
end

function olua.load_manifest(path)
    path = olua.format(path)
    local f = io.open(path, "r")
    if not f then
        olua.print("manifest not found: ${path}")
        return
    else
        f:close()
        return dofile(path)
    end
end

function olua.write(path, data)
    path = olua.format(path)
    local f =  io.open(path, "w+b")
    f:write(data)
    f:close()
end

function olua.exist(path)
    path = olua.format(path)
    local f = io.open(path, 'r')
    if f then
        f:close()
    end
    return f ~= nil
end

-------------------------------------------------------------------------------
-- format args
-------------------------------------------------------------------------------
local function lookup(level, key)
    assert(key and #key > 0, key)

    local value

    for i = 1, 256 do
        local k, v = debug.getlocal(level, i)
        if k == key then
            value = v
        elseif not k then
            break
        end
    end

    if value then
        return value
    end

    local info1 = debug.getinfo(level, 'Sn')
    local info2 = debug.getinfo(level + 1, 'Sn')
    if info1.source == info2.source or
        string.find(info1.source, "init.lua$")
    then
        return lookup(level + 1, key)
    end
end

local function eval(line)
    return string.gsub(line, '${[%w_.?]+}', function (str)
        -- search caller file path
        local level = 1
        local path
        while true do
            local info = debug.getinfo(level, 'Sfn')
            if info then
                if string.find(info.source, "init.lua$") and
                    info.func == olua.format
                then
                    break
                else
                    level = level + 1
                end
            else
                break
            end
        end

        -- search in the functin local value
        local indent = string.match(line, ' *')
        local key = string.match(str, '[%w_]+')
        local opt = string.match(str, '%?+')
        local value = lookup(level + 1, key) or _G[key]
        for field in string.gmatch(string.match(str, "[%w_.]+"), '[^.]+') do
            if not value then
                break
            elseif field ~= key then
                value = value[field]
            end
        end

        if value == nil and not opt then
            error("value not found for '" .. str .. "'")
        end

        -- indent the value if value has multiline
        local prefix, posfix = '', ''
        if type(value) == 'table' then
            local mt = getmetatable(value)
            if mt and mt.__tostring then
                value = tostring(value)
            else
                error("no meta method '__tostring' for " .. str)
            end
        elseif value == nil then
            value = 'nil'
        elseif type(value) == 'string' then
            value = value:gsub('[\n]*$', '')
            if opt then
                value = olua.trim(value)
                if string.find(value, '[\n\r]') then
                    value = '\n' .. value
                    prefix = '[['
                    posfix =  '\n' .. indent .. ']]'
                    indent = indent .. '    '
                elseif string.find(value, '[\'"]') then
                    value = '[[' .. value .. ']]'
                else
                    value = "'" .. value .. "'"
                end
            end
        else
            value = tostring(value)
        end

        return prefix .. string.gsub(value, '\n', '\n' .. indent) .. posfix
    end)
end

local function doeval(expr)
    local arr = {}
    local idx = 1
    while idx <= #expr do
        local from, to = string.find(expr, '[\n\r]', idx)
        if not from then
            from = #expr + 1
            to = from
        end
        arr[#arr + 1] = eval(string.sub(expr, idx, from - 1))
        idx = to + 1
    end
    return table.concat(arr, '\n')
end

function olua.trim(expr, indent)
    if type(expr) == 'string' then
        expr = string.gsub(expr, '[\n\r]', '\n')
        expr = string.gsub(expr, '^[\n]*', '') -- trim head '\n'
        expr = string.gsub(expr, '[ \n]*$', '') -- trim tail '\n' or ' '

        local space = string.match(expr, '^[ ]*')
        indent = string.rep(' ', indent or 0)
        expr = string.gsub(expr, '^[ ]*', '')  -- trim head space
        expr = string.gsub(expr, '\n' .. space, '\n' .. indent)
        expr = indent .. expr
    end
    return expr
end

function olua.format(expr, indent)
    expr = doeval(olua.trim(expr, indent))

    while true do
        local s, n = string.gsub(expr, '\n[ ]+\n', '\n\n')
        expr = s
        if n == 0 then
            break
        end
    end

    while true do
        local s, n = string.gsub(expr, '\n\n\n', '\n\n')
        expr = s
        if n == 0 then
            break
        end
    end

    expr = string.gsub(expr, '{\n\n', '{\n')
    expr = string.gsub(expr, '\n\n}', '\n}')

    return expr
end

-------------------------------------------------------------------------------
-- command misc
-------------------------------------------------------------------------------
function olua.ipairs(t, walk)
    for i, v in ipairs(t) do
        walk(i, v)
    end
end

function olua.pairs(t, walk)
    for k, v in pairs(t) do
        walk(k, v)
    end
end

function olua.newarray(sep, prefix, posfix)
    local mt = {}
    mt.__index = mt

    function mt:clear()
        for i = 1, #self do
            self[i] = nil
        end
        return self
    end

    function mt:push(v)
        if v ~= nil then
            self[#self + 1] = v
        end
        return self
    end

    function mt:pushf(v)
        if v ~= nil then
            self[#self + 1] = olua.format(v)
        end
        return self
    end

    function mt:insert(v)
        if v ~= nil then
            table.insert(self, 1, v)
        end
    end

    function mt:insertf(v)
        if v ~= nil then
            table.insert(self, 1, olua.format(v))
        end
    end

    function mt:merge(t)
        for _, v in ipairs(t) do
            self[#self + 1] = v
        end
        return self
    end

    function mt:__tostring()
        sep = sep or '\n'
        prefix = prefix or ''
        posfix = posfix or ''
        return prefix .. table.concat(self, sep) .. posfix
    end

    return setmetatable({}, mt)
end

function olua.clone(t, newt)
    newt = newt or {}
    for k, v in pairs(t) do
        newt[k] = v
    end
    return newt
end

function olua.toarray(map)
    local arr = {}
    for k, v in pairs(map) do
        arr[#arr + 1] = {key = k, value = v}
    end
    table.sort(arr, function (a, b) return a.key < b.key end)
    return arr
end

function olua.newhash(map_only)
    local hash = {values = {}, map = {}}

    function hash:clear()
        hash.values = {}
        hash.map = {}
    end

    function hash:clone()
        local new = olua.newhash(map_only)
        new.values = olua.clone(hash.values, new.values)
        new.map = olua.clone(hash.map, new.map)
        return new
    end

    function hash:get(key)
        return hash.map[key]
    end

    function hash:has(key)
        return hash.map[key] ~= nil
    end

    function hash:push(key, value, message)
        if hash.map[key] then
            error(string.format('key conflict: %s %s', key, message or ''))
        end
        assert(value ~= nil, 'no value')
        hash.map[key] = value
        if not map_only then
            hash.values[#hash.values + 1] = value
        end
    end

    function hash:push_if_not_exist(key, value)
        if not hash:has(key) then
            hash:push(key, value)
        end
    end

    function hash:insert(where, curr, key, value, idx)
        assert(not map_only, 'insert not allowed for map only')
        if where == 'front' then
            idx = 1
        elseif where == 'after' then
            for i, v in ipairs(hash.values) do
                if v == curr then
                    idx = i + 1
                    break
                end
            end
        elseif where == 'before' then
            for i, v in ipairs(hash.values) do
                if v == curr then
                    idx = i
                    break
                end
            end
        elseif where == 'back' then
            idx = #hash.values + 1
        end
        if idx then
            table.insert(hash.values, idx, value)
            hash.map[key] = value
        else
            error(string.format("can't insert value: %s, because current value not found", key))
        end
    end

    function hash:replace(key, value)
        local old = hash.map[key]
        hash.map[key] = value
        if not map_only then
            assert(value ~= nil, "value is nil")
            if old then
                for i, v in ipairs(hash.values) do
                    if v == old then
                        hash.values[i] = value
                        break
                    end
                end
            else
                hash.values[#hash.values + 1] = value
            end
        end
    end

    function hash:take(key)
        local value = hash.map[key]
        hash.map[key] = nil
        if value and not map_only then
            for i, v in ipairs(hash.values) do
                if value == v then
                    table.remove(hash.values, i)
                    break
                end
            end
        end
        return value
    end

    function hash:__len()
        assert(not map_only, '__leng not allowed for map only')
        return #hash.values
    end

    function hash:__index(key)
        error('use get')
    end

    function hash:__newindex(key, value)
        error('use push')
    end

    function hash:__pairs()
        return pairs(hash.map)
    end

    function hash:__ipairs()
        assert(not map_only, 'ipairs not allowed for map only')
        return ipairs(hash.values)
    end

    return setmetatable(hash, hash)
end
