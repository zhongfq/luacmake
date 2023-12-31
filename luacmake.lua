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
        olua.rmdir("${work_dir}/output")
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
-- checkout and build targets
-------------------------------------------------------------------------------
olua.rmdir("${work_dir}/build")
olua.mkdir("${work_dir}/cache")

local luacmake_install_targets = olua.newarray("\n")

for _, target in ipairs(luacmake_packages) do
    local package_name, package_git_dir, package_manifest, build_dir, source_dir
    if target == "lua" then
        package_name = olua.format("lua${luacmake_lua_version}")
        package_git_dir = olua.format("${work_dir}/package-builtin/${package_name}")
        package_manifest = {target = "lua luac"}
    else
        package_name = olua.format("lua-${target}")
        package_git_dir = olua.format("${work_dir}/cache/${package_name}/git")
        package_manifest = olua.load_manifest("${work_dir}/package/${package_name}/manifest")
    end
    
    if not package_manifest then
        olua.error("package '${target}' not found")
    end

    build_dir = olua.format("build/${package_name}")
    source_dir = olua.format("cache/${package_name}")

    if target == "lua" then
        olua.mkdir("${work_dir}/cache/${package_name}")
    else
        if not olua.exist("${package_git_dir}/.git/config") then
            olua.exec("git clone ${package_manifest.git} ${package_git_dir}")
            if package_manifest.branch then
                olua.exec("git -C ${package_git_dir} checkout ${package_manifest.branch}")
            end
        else
            if package_manifest.branch then
                olua.exec("git -C ${package_git_dir} checkout ${package_manifest.branch}")
            end
            olua.exec("git -C ${package_git_dir} pull")
        end
        if package_manifest.commit then
            olua.exec("git -C ${package_git_dir} checkout ${package_manifest.commit}")
        end
        olua.exec("git -C ${package_git_dir} submodule init")
        olua.exec("git -C ${package_git_dir} submodule update")
    end

    local CMakeLists = olua.newarray("\n")
    CMakeLists:pushf([[
        cmake_minimum_required(VERSION 3.25)

        project(luacmake)

        set(BUILD_SHARED_LIBS OFF)

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
    ]])
    if target ~= "lua" then
        CMakeLists:pushf([[
            # package
            set(LUACMAKE_SOURCE_DIR ${package_git_dir})
            add_subdirectory(${work_dir}/package/${package_name} ${package_name})
        ]])
        CMakeLists:push("")
    end
    CMakeLists:pushf([[
        # install
        install(
          TARGETS
            ${package_manifest.target}
          DESTINATION
            ${luacmake_output}
          COMPONENT
            luacmake
        )
    ]])
    olua.write("${work_dir}/cache/${package_name}/CMakeLists.txt", tostring(CMakeLists))

    if olua.is_windows() then
        olua.exec([[
            cmake -B ${build_dir} -S ${source_dir} -A win32
            cmake --build ${build_dir} --target ${package_manifest.target} --config Release
        ]])
    else
        olua.exec([[
            cmake -B ${build_dir} -S ${source_dir} -DCMAKE_BUILD_TYPE=Release
            cmake --build ${build_dir} --target ${package_manifest.target}
        ]])
    end
    luacmake_install_targets:pushf("cmake --install ${build_dir} --component luacmake")
end

olua.exec("${luacmake_install_targets}")
