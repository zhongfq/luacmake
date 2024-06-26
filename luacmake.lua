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
          --arch        specify architecture
        example:
          luacmake install cjson
          luacmake install cjson --lua 5.4|5.3
          luacmake install cjson --output ./output
    ]])
end


-------------------------------------------------------------------------------
-- parsing args
-------------------------------------------------------------------------------
local luacmake_command
local luacmake_jobs = ""
local luacmake_packages = {}
local luacmake_lua_version = "54"
local luacmake_output = "output"
local luacmake_arch = ""

local args = {...}
while #args > 0 do
    local c = table.remove(args, 1)
    if c == "install" then
        luacmake_command = c
        local target = assert(table.remove(args, 1), "no install target")
        luacmake_packages[#luacmake_packages + 1] = target
    elseif c == "--arch" then
        luacmake_arch = assert(table.remove(args, 1), "no architecture")
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
    elseif c == "-j" then
        local n = assert(table.remove(args, 1), "no jobs")
        luacmake_jobs = olua.format("-j ${n}")
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

if not (string.find(luacmake_output, "^/") or string.find(luacmake_output, "^%w+:")) then
    luacmake_output = olua.format("${work_dir}/${luacmake_output}")
end
olua.print("output dir: ${luacmake_output}")

luacmake_output = string.gsub(luacmake_output, "\\", "/")

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
        package_manifest = {target = "lua luac", cmakeargs = ""}
    else
        package_name = olua.format("lua-${target}")
        package_git_dir = olua.format("${work_dir}/cache/${package_name}/git")
        package_manifest = olua.load_manifest("${work_dir}/package/${package_name}/manifest")
    end
    
    if not package_manifest then
        olua.error("package '${target}' not found")
    end

    package_manifest.cmakeargs = package_manifest.cmakeargs or ""

    build_dir = olua.format("build/${package_name}")
    source_dir = olua.format("cache/${package_name}")

    if target == "lua" then
        olua.mkdir("${work_dir}/cache/${package_name}")
    else
        olua.git_clone(
            package_git_dir,
            package_manifest.git,
            package_manifest.branch,
            package_manifest.commit
        )

        -- checkout dependencies
        for _, v in ipairs(package_manifest.dependencies or {}) do
            local name = string.match(v.git, "([^/]+)%.git$")
            local git_dir = olua.format("${package_git_dir}/${name}")
            olua.git_clone(
                git_dir,
                v.git,
                v.branch,
                v.commit
            )
        end
    end

    if luacmake_arch == "" then
        if olua.os == "windows" then
            luacmake_arch = "x64"
        elseif olua.os == "macos" then
            luacmake_arch = "x86_64;arm64"
        end
    end

    local CMakeLists = olua.newarray("\n")
    local lua_version = olua.format("lua${luacmake_lua_version}")
    CMakeLists:pushf([[
        cmake_minimum_required(VERSION 3.20)

        project(luacmake)

        if(CMAKE_SYSTEM_NAME MATCHES "Linux")
            if(NOT LINUX)
                set(LINUX TRUE)
            endif()
        endif()

        if(APPLE)
            set(CMAKE_OSX_ARCHITECTURES "${luacmake_arch}")
        endif()
    ]])
    CMakeLists:push("")
    CMakeLists:pushf([[
        # lua
        add_subdirectory(${work_dir}/package-builtin/${lua_version} lua)
        get_property(LUA_INCLUDE_DIR TARGET liblua PROPERTY INCLUDE_DIRECTORIES)
        set_target_properties(liblua PROPERTIES
            LIBRARY_OUTPUT_NAME liblua
            RUNTIME_OUTPUT_NAME ${lua_version}
        )
        set_target_properties(lua PROPERTIES
            OUTPUT_NAME ${lua_version}
        )
        set_target_properties(luac PROPERTIES
            OUTPUT_NAME luac${luacmake_lua_version}
        )
    ]])
    local lua_targets = ""
    if target ~= "lua" then
        CMakeLists:pushf([[
            # package
            set(LUACMAKE_SOURCE_DIR ${package_git_dir})
            add_subdirectory(${work_dir}/package/${package_name} ${package_name})
        ]])
        CMakeLists:push("")
    else
        lua_targets = "lua luac liblua"
    end
    CMakeLists:pushf([[
        # install
        install(
          TARGETS
            ${package_manifest.target}
            ${lua_targets}
          DESTINATION
            ${luacmake_output}
          COMPONENT
            luacmake
        )
    ]])
    olua.write("${work_dir}/cache/${package_name}/CMakeLists.txt", tostring(CMakeLists))

    if olua.is_windows() then
        olua.exec("cmake -B ${build_dir} -S ${source_dir} -A ${luacmake_arch} ${package_manifest.cmakeargs}")
        olua.exec("cmake --build ${build_dir} --target ${package_manifest.target} --config Release ${luacmake_jobs}")
    else
        olua.exec("cmake -B ${build_dir} -S ${source_dir} -DCMAKE_BUILD_TYPE=Release ${package_manifest.cmakeargs}")
        olua.exec("cmake --build ${build_dir} --target ${package_manifest.target} ${luacmake_jobs}")
    end
    luacmake_install_targets:pushf("cmake --install ${build_dir} --component luacmake")
end

for _, v in ipairs(luacmake_install_targets) do
    olua.exec(v)
end

