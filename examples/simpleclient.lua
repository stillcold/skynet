package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;myexample/e1/?.lua"

if _VERSION ~= "Lua 5.3" then
    error "Use lua 5.3"
end

local socket = require "clientsocket"
local luaB64 = require "b64InLua"
local fileMgr = require "libChao_Lua/FileMgr/WindowsFileMgr"

local fd = assert(socket.connect("120.24.98.130", 8108))
local sendrequest = function(content, bnotshow)
    if not bnotshow then
        print("send to server:", content)
    end
    
    socket.send(fd, content)
end

sendrequest("hi")

local function getrandomValidPicFile()
    math.randomseed(os.time())
    local dirs = fileMgr:GetAllDirNameInDir("G:\\www\\spics")
    local dirCount = #dirs

    local targetFile

    local count = 0
    while targetFile == nil do

        count = count + 1
        if count > 10 then
            return "testPic.png"
        end

        local randomIndex = math.random(3, dirCount)
        local chosenDir = dirs[randomIndex]
        local files = fileMgr:GetAllFileNameInDir("G:\\www\\spics\\"..chosenDir)
        local fileCount = #files

        if fileCount > 0 then
            local randomFileIdx = math.random(fileCount)
            local chosenFile = files[randomFileIdx]
            targetFile = "G:\\www\\spics\\"..chosenDir.."\\"..chosenFile
            return targetFile
        end
    end

    
end

local function curlRequest()

    local targetFile = getrandomValidPicFile()


    local fileHandler = io.open(targetFile, "rb")
    local fileContent = fileHandler:read("*a")
    -- response(id, code, fileContent, resheader)
    fileHandler:close()

    --sendrequest("anserserverheader"..luaB64.b64(fileContent))
    sendrequest("anserserver"..fileContent, true)
    sendrequest("111111", true)
    --sendrequest("anserserver200", true)
end


local ka_count = 0
while true do

    ka_count = ka_count + 1
    if ka_count > 100000000 then
        ka_count = 0
    end
    -- 接收服务器返回消息
    local str = socket.recv(fd)
    if str~=nil and str~="" then
            print("server echo: "..str)
            if string.sub(str, 1, 9) == "serverAsk" then
                --sendrequest("anserserver"..string.sub(str, 10))
                --sendrequest("anserserverhere is the pure response from client")
                -- local code,body,header = httpc.get("10.240.160.221", "/project_page.png")
                -- print(code, header)
                --sendrequest("anserserver"..200)
                curlRequest()
            end
    end

    -- 读取用户输入消息
    local readstr = socket.readstdin()
    if readstr then
        if readstr == "quit" then
            socket.close(fd)
            break
        else
            -- 把用户输入消息发送给服务器
            -- socket.send(fd, readstr)
            sendrequest(readstr)
        end
        
    else
        socket.usleep(10000)
        if ka_count % (1000 * 6) == 0 then
            sendrequest("keep-alive")
            --print(ka_count)
        end
    end
end