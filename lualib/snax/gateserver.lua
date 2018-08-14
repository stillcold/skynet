local skynet = require "skynet"
local netpack = require "netpack"
local socketdriver = require "socketdriver" -- lua-socket.c 生成的dll/so文件

local gateserver = {}

local socket	-- listen socket
local queue		-- message queue
local maxclient	-- max client
local client_number = 0
local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })
local nodelay = false

local connection = {}

function gateserver.openclient(fd)
	if connection[fd] then
		socketdriver.start(fd)
	end
end

function gateserver.closeclient(fd)
	local c = connection[fd]
	if c then
		connection[fd] = false
		socketdriver.close(fd)
	end
end

function gateserver.start(handler)
	assert(handler.message)
	assert(handler.connect)

	-- 00000004: 调用到这里, source 是 watchdog, conf 是从 main 中传递过来的
	function CMD.open( source, conf )
		assert(not socket)
		local address = conf.address or "0.0.0.0"
		local port = assert(conf.port)
		maxclient = conf.maxclient or 1024
		nodelay = conf.nodelay
		skynet.error(string.format("Gateway Listen on %s:%d", address, port))
		-- 00000004: 这里终于开始监听接口
		socket = socketdriver.listen(address, port)
		socketdriver.start(socket)
		if handler.open then
			-- 00000005: handler 是 gate, 这句话会把 gate 的 watchdog 设置对
			return handler.open(source, conf)
		end
	end

	function CMD.close()
		assert(socket)
		socketdriver.close(socket)
	end

	local MSG = {}

	local function dispatch_msg(fd, msg, sz)
		if connection[fd] then
			handler.message(fd, msg, sz)
		else
			skynet.error(string.format("Drop message from fd (%d) : %s", fd, netpack.tostring(msg,sz)))
		end
	end

	MSG.data = dispatch_msg

	local function dispatch_queue()
		local fd, msg, sz = netpack.pop(queue)
		if fd then
			-- may dispatch even the handler.message blocked
			-- If the handler.message never block, the queue should be empty, so only fork once and then exit.
			skynet.fork(dispatch_queue)
			dispatch_msg(fd, msg, sz)

			for fd, msg, sz in netpack.pop, queue do
				dispatch_msg(fd, msg, sz)
			end
		end
	end

	MSG.more = dispatch_queue

	function MSG.open(fd, msg)
		if client_number >= maxclient then
			socketdriver.close(fd)
			return
		end
		if nodelay then
			socketdriver.nodelay(fd)
		end
		connection[fd] = true
		client_number = client_number + 1
		handler.connect(fd, msg)
	end

	local function close_fd(fd)
		local c = connection[fd]
		if c ~= nil then
			connection[fd] = nil
			client_number = client_number - 1
		end
	end

	function MSG.close(fd)
		if fd ~= socket then
			if handler.disconnect then
				handler.disconnect(fd)
			end
			close_fd(fd)
		else
			socket = nil
		end
	end

	function MSG.error(fd, msg)
		if fd == socket then
			socketdriver.close(fd)
			skynet.error(msg)
		else
			if handler.error then
				handler.error(fd, msg)
			end
			close_fd(fd)
		end
	end

	function MSG.warning(fd, size)
		if handler.warning then
			handler.warning(fd, size)
		end
	end

	-- 00000010: 这里应该是干了一件很傻逼的事情
	-- 应该是 PTYPE_SOCKET 类型的消息被分发到了这里的 dispatch
	-- Question: 到底有多少消息是被分发到这里的 ? 肯定不会把所有的socket的消息都分发到这里了
	skynet.register_protocol {
		name = "socket",
		id = skynet.PTYPE_SOCKET,	-- PTYPE_SOCKET = 6
		-- Question: 为啥没有提供 pack 方法
		unpack = function ( msg, sz )
			return netpack.filter( queue, msg, sz)
		end,
		dispatch = function (_, _, q, type, ...)
			queue = q
			if type then
				MSG[type](...)
			end
		end
	}

	skynet.start(function()
		skynet.dispatch("lua", function (_, address, cmd, ...)
			local f = CMD[cmd]
			-- 00000003: 调用到这里, cmd 是 open, ... 是 config
			if f then
				skynet.ret(skynet.pack(f(address, ...)))
			else
				skynet.ret(skynet.pack(handler.command(cmd, address, ...)))
			end
		end)
	end)
end

return gateserver
