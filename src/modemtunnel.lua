local fakemodem = require("fakemodem")
local argparse = require("cc-argparse.src.argparse")
local customRednetRepeat = require("rednetrepeat")

local function parseArgs(...)
  local parser = argparse("modemtunnel", "Secure modem tunnel")
  parser:argument("name", "Fakemodem name")
  parser:option("-k", "Encryption key"):target("key"):argname("<key>"):count(1)
  parser:option("-p", "Modem channel", 36356):target("port"):argname("<port>"):convert(tonumber)
  parser:option("-m", "Modem to tunnel over"):target("modem"):argname("<modem>")
  parser:option("-r", "Repeat rednet between this modem and the tunnel modem"):target("rednetModem"):argname("<rednetModem>")

  return parser:parse({ ... })
end

local args = parseArgs(...)
assert(#args.key == 32, "Encryption key should be 32 characters")

if args.rednetModem then
  assert(peripheral.wrap(args.rednetModem), "Cant find rednet modem.")

  print("Using "..args.rednetModem.." as rednet modem")
end

local modem = assert(args.modem and peripheral.wrap(args.modem) or peripheral.find("modem"), "No modem found.")
print("Using "..peripheral.getName(modem).." as modem")

local snet = require("snet")(modem, args.port, args.key, nil, 1048576)

local fm = fakemodem(args.name, function(channel, replyChannel, message)
  snet.send(textutils.serialize({
    channel = channel,
    replyChannel = replyChannel,
    message = message
  }))
end)

parallel.waitForAny(snet.run, function()
  while true do
    local message = snet.receive()

    local s,e = pcall(function()
      local unser = textutils.unserialize(message)
      if unser and type(unser.channel) == "number" and type(unser.replyChannel) == "number" then
        fm.pushMessage(unser.channel, unser.replyChannel, unser.message, 0)
      end
    end)
    if not s then printError(e) end
  end
end, args.rednetModem and function()
  customRednetRepeat(args.name, args.rednetModem)
end or nil)
