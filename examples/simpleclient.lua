package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;myexample/e1/?.lua;lualib/libChao_Lua/?.lua;"

if _VERSION ~= "Lua 5.3" then
    error "Use lua 5.3"
end

local saconfig = {
    isRlease = true
}

local config_release = {
    hostIp = "120.24.98.130",
    hostPort = 8108,
    resConfig = {
        picResDir = "G:\\www\\spics",-- G:\\www\\spics
    }
}

local config_test = {
    hostIp = "127.0.0.1",
    hostPort = 8108,
    resConfig = {
        picResDir = "D:\\Workspace\\res\\pic",
    }
}

local config = config_test
if saconfig.isRlease then
    config = config_release
end

local weightTbl = {}
local blackList = {}

local socket = require "clientsocket"
local luaB64 = require "b64InLua"
local fileMgr = require "FileMgr/WindowsFileMgr"
local huffmanWeightTbl = require "Common/huffmanWeightTbl"
local lastFilePath = ""

local fd = assert(socket.connect(config.hostIp, config.hostPort))
local sendRequestToServer = function(content, bNotShow)
    if not bNotShow then
        print("send to server:", content)
    end
    
    socket.send(fd, content)
end

sendRequestToServer("hi")

local RPC = {}


local function getrandomValidPicFileFromWeightTbl()
    print("Get from weight table")
    local filePath = huffmanWeightTbl:SelectInHuffmanTree(weightTbl)
    return config.resConfig.picResDir.."\\"..filePath
end

local function getrandomValidPicFile()
    math.randomseed(os.time())

    if huffmanWeightTbl:IsWeightTree(weightTbl) and math.random() <= 0.5 then
        return getrandomValidPicFileFromWeightTbl()
    end
    local dirs = fileMgr:GetAllDirNameInDir(config.resConfig.picResDir)
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
        local files = fileMgr:GetAllFileNameInDir(config.resConfig.picResDir.."\\"..chosenDir)
        local fileCount = #files

        if fileCount > 0 then
            local randomFileIdx = math.random(fileCount)
            local chosenFile = files[randomFileIdx]
            lastFilePath = chosenDir.."\\"..chosenFile
            targetFile = config.resConfig.picResDir.."\\"..lastFilePath

            return targetFile
        end
    end
    
end


local function saveAndQuit()
    sendRequestToServer("closeSockect")
    socket.close(fd)
end

local function serverQueryPic()
    local targetFile = getrandomValidPicFile()


    local fileHandler = io.open(targetFile, "rb")
    local fileContent = fileHandler:read("*a")
    -- response(id, code, fileContent, resheader)
    fileHandler:close()

    sendRequestToServer("anserserver"..fileContent, true)
    sendRequestToServer("111111", true)
end


function RPC:ServerQueryPic()
    serverQueryPic()
end


function RPC:badAdjust()
    if lastFilePath then
        weightTbl = huffmanWeightTbl:AddKeyWeight(nil, lastFilePath, -100)
    end
end

function RPC:goodAdjust()
    if lastFilePath then
        weightTbl = huffmanWeightTbl:AddKeyWeight(nil, lastFilePath, 100)
    end
    
end

local ka_count = 0
while true do

    ka_count = ka_count + 1
    if ka_count > 100000000 then
        ka_count = 0
    end
    local str = socket.recv(fd)
    if str~=nil and str~="" then
            print("server message: "..str)
            if RPC[str] then
                RPC[str](RPC)
            else
                RPC:ServerQueryPic()
            end
    end

    local readstr = socket.readstdin()
    if readstr then
        if readstr == "quit" then
            saveAndQuit()
            break
        else
            -- socket.send(fd, readstr)
            sendRequestToServer(readstr)
        end
        
    else
        socket.usleep(10000)
        if ka_count % (1000 * 6) == 0 then
            sendRequestToServer("keep-alive")
        end
    end
end