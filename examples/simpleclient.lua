package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;myexample/e1/?.lua"

if _VERSION ~= "Lua 5.3" then
    error "Use lua 5.3"
end

local socket = require "clientsocket"
local luaB64 = require "b64InLua"

local fd = assert(socket.connect("127.0.0.1", 8108))
local sendrequest = function(content, bnotshow)
    if not bnotshow then
        print("send to server:", content)
    end
    
    socket.send(fd, content)
end

sendrequest("hi")

local function curlRequest()
    local fileHandler = io.open("project_page.png", "rb")
    local fileContent = fileHandler:read("*a")
    -- response(id, code, fileContent, resheader)
    fileHandler:close()

    --sendrequest("anserserverheader"..luaB64.b64(fileContent))
    sendrequest("anserserver"..fileContent, true)
    --sendrequest("anserserver200", true)
end

while true do
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
        socket.usleep(100)
    end
end