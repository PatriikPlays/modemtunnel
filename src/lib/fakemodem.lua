local function fakeModem(modemname, onTransmit)
    if peripheral.wrap(modemname) then
        error("fakemodem: modem with name "..modemname.." already exists, you may want to reboot")
        --return
    end

    local old = {
        getNames = _G.peripheral.getNames,
        isPresent = _G.peripheral.isPresent,
        getType = _G.peripheral.getType,
        hasType = _G.peripheral.hasType,
        getMethods = _G.peripheral.getMethods,
        call = _G.peripheral.call,
    }

    local openPorts = {}

    local function matchesFake(name)
        return name == modemname
    end

    local function proxy(oldfn, fakeFn)
        return function(name, ...)
            if matchesFake(name) then
                return fakeFn(name, ...)
            end

            return oldfn(name, ...)
        end
    end

    _G.peripheral.getNames = function()
        local names = old.getNames()
        table.insert(names, modemname)
        return names
    end

    _G.peripheral.isPresent = function(name)
        if matchesFake(name) then
            return true
        end

        return old.isPresent()
    end

    _G.peripheral.getType = proxy(old.getType, function(name)
        return "modem"
    end)

    _G.peripheral.hasType = proxy(old.hasType, function(name, type)
        return type == "modem"
    end)

    _G.peripheral.getMethods = proxy(old.getMethods, function(name)
        return {"open", "close", "isOpen", "closeAll", "transmit", "isWireless"}
    end)

    _G.peripheral.call = proxy(old.call, function(name, method, ...)
        if method == "open" then
            local port = ...
            openPorts[port] = true
            return
        elseif method == "close" then
            local port = ...
            openPorts[port] = nil
            return
        elseif method == "isOpen" then
            local port = ...
            return openPorts[port] ~= nil
        elseif method == "closeAll" then
            openPorts = {}
            return
        elseif method == "transmit" then
            local channel, replyChannel, message = ...

            onTransmit(channel, replyChannel, message)
            return
        elseif method == "isWireless" then
            return false
        end

        error("No such method " .. method)
    end)

    return {
        pushMessage = function(channel, replyChannel, message, distance)
            os.queueEvent("modem_message", modemname, channel, replyChannel, message, distance)
        end
    }
end

return fakeModem
