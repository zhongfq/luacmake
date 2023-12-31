require "init"

local work_dir = olua.pwd()
olua.print("work dir: ${work_dir}")

local function print_help()
    olua.print([[
        luacmake: no target to install
        available options are:
          install       specify library to install
          clean         remove build and cache directory
          --lua         specify lua version
          --output      specify output path
        example:
          luacmake install cjson
          luacmake install cjson --lua 5.4|5.3
          luacmake install cjson --install ./output
    ]])
end


-------------------------------------------------------------------------------
-- parsing args
-------------------------------------------------------------------------------
local luacmake_command
local luacmake_packages = {}
local luacmake_lua_version = "54"
local luacmake_output = "output"

local args = {...}
while #args > 0 do
    local c = table.remove(args, 1)
    if c == "install" then
        luacmake_command = c
        local target = assert(table.remove(args, 1), "no install target")
        luacmake_packages[#luacmake_packages + 1] = target
    elseif c == "--lua" then
        local version = assert(table.remove(args, 1), "no lua version")
        luacmake_command = c
        if version == "5.4" then
            luacmake_lua_version = "54"
        elseif version == "5.3" then
            luacmake_lua_version = "53"
        else
            olua.error("unsupport lua version: ${version}")
        end
    elseif c == "--output" then
        luacmake_command = c
        luacmake_output = assert(table.remove(args, 1), "no install path")
    elseif c == "clean" then
        luacmake_command = c
        olua.rmdir("${work_dir}/build")
        olua.rmdir("${work_dir}/cache")
        return
    elseif not string.find(c, "^[%-]") and luacmake_command == "install" then
        luacmake_packages[#luacmake_packages + 1] = c
    else
        olua.print("unknow args: ${c}")
        print_help()
        return
    end
end

if #luacmake_packages == 0 then
    print_help()
    return
end

if not string.find(luacmake_output, "^/") then
    luacmake_output = olua.format("${work_dir}/${luacmake_output}")
end
olua.print("output dir: ${luacmake_output}")

-------------------------------------------------------------------------------
-- update luacmake
-------------------------------------------------------------------------------
olua.exec("git submodule init")
olua.exec("git submodule update")

-------------------------------------------------------------------------------
-- checkout library project
-------------------------------------------------------------------------------
olua.rmdir("${work_dir}/build")
olua.mkdir("${work_dir}/cache")

local luacmake_build_targets = olua.newarray(" ")
local luacmake_build_packages = olua.newarray("\n")

for _, target in ipairs(luacmake_packages) do
    if target == "lua" then
        luacmake_build_targets:push("lua luac")
        if olua.is_windows() then
            luacmake_build_targets:push("liblua")
        end
    elseif target ~= "olua" then
        local package_name = olua.format("lua-${target}")
        local package_git_dir = olua.format("${work_dir}/cache/${package_name}")
        local manifest = olua.load_manifest("${work_dir}/package/${package_name}/manifest")
        if not manifest then
            olua.error("package '${target}' not found")
        end
        if not olua.exist("${package_git_dir}/.git/config") then
            olua.exec("git clone ${manifest.git} ${package_git_dir}")
            if manifest.branch then
                olua.exec("git -C ${package_git_dir} checkout ${manifest.branch}")
            end
        else
            if manifest.branch then
                olua.exec("git -C ${package_git_dir} checkout ${manifest.branch}")
            end
            olua.exec("git -C ${package_git_dir} pull")
        end
        if manifest.commit then
            olua.exec("git -C ${package_git_dir} checkout ${manifest.commit}")
        end
        olua.exec("git -C ${package_git_dir} submodule init")
        olua.exec("git -C ${package_git_dir} submodule update")
        luacmake_build_targets:push(manifest.target)
        luacmake_build_packages:pushf([[
            set(LUACMAKE_SOURCE_DIR ${package_git_dir})
            add_subdirectory(${work_dir}/package/${package_name} ${package_name})
        ]])
    end
end

-------------------------------------------------------------------------------
-- write build cmake file
-------------------------------------------------------------------------------
local CMakeLists = olua.newarray("\n")
CMakeLists:pushf([[
    cmake_minimum_required(VERSION 3.25)

    project(luacmake)

    if(APPLE)
        set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
    endif()
]])
CMakeLists:push("")
CMakeLists:pushf([[
    # lua
    add_subdirectory(${work_dir}/package-builtin/lua${luacmake_lua_version} lua)
    get_property(LUA_INCLUDE_DIR TARGET liblua PROPERTY INCLUDE_DIRECTORIES)

    # olua
    add_subdirectory(${work_dir}/package-builtin/olua olua)

    # package
    ${luacmake_build_packages}

    # install
    install(
      TARGETS
        ${luacmake_build_targets}
      DESTINATION
        ${luacmake_output}
      COMPONENT
        luacmake
    )
]])
olua.write("${work_dir}/cache/CMakeLists.txt", tostring(CMakeLists))
if olua.is_windows() then
    olua.exec("cmake -B build -S cache -A win32")
    olua.exec("cmake --build build --target ${luacmake_build_targets} --config Release")
else
    olua.exec("cmake -B build -S cache -DCMAKE_BUILD_TYPE=Release")
    olua.exec("cmake --build build --target ${luacmake_build_targets}")
end
olua.exec("cmake --install build --component luacmake")