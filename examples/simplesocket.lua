local skynet = require "skynet"
local socket = require "socket"
require "skynet.manager"    -- import skynet.register

local client_fd = nil
local callback = nil

local response

local function echo(id)
    -- 每当 accept 函数获得一个新的 socket id 后，并不会立即收到这个 socket 上的数据。这是因为，我们有时会希望把这个 socket 的操作权转让给别的服务去处理。
    -- 任何一个服务只有在调用 socket.start(id) 之后，才可以收到这个 socket 上的数据。
    socket.start(id)

    while true do
        local str = socket.read(id)
        if str then
            print("client say:"..str)

            if string.sub(str, 1, 11) == "anserserver" then
                print("SIMPLESOCKET debug 1", str)
                --skynet.send("SIMPLEWEB", "lua", "ANSWER"..string.sub(str, 12))
                if response then
                    response(true, str)
                end
            else
                print("SIMPLESOCKET debug 2")
            end
            
            -- 把一个字符串置入正常的写队列，skynet 框架会在 socket 可写时发送它。
            socket.write(id, str)
        else
            socket.close(id)
            return
        end
    end
end

skynet.start(function()
    print("==========Simple Socket Start=========")
    -- 监听一个端口，返回一个 id ，供 start 使用。
    local id = socket.listen("127.0.0.1", 8108)
    print("Listen socket :", "127.0.0.1", 8108)

    socket.start(id , function(id, addr)
            -- 接收到客户端连接或发送消息()
            print("connect from " .. addr .. " " .. id)

            client_fd = id

            -- 处理接收到的消息
            echo(id)
        end)

    skynet.dispatch("lua", function(session, address, cmd, ...)
        if string.sub(cmd, 1, 4) == "ping" then
            print("recieve ping info")
            
            if client_fd then
                socket.write(client_fd, "serverAsk"..1)
                response = skynet.response()
            end
        end
        end)
    --可以为自己注册一个别名。（别名必须在 32 个字符以内）
    skynet.register "SIMPLESOCKET"
end)