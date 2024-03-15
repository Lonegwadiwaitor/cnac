
if (SERVER) then
    return
end

CNAC = CNAC or {}

function CNAC.Menu(banwave)
    if (IsValid(CNAC.MenuFrame)) then
        CNAC.MenuFrame:Remove()
    end

    local w, h = 500, 700

    local frame = vderma:Frame()
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("CNAC")
    frame:MakePopup()

    CNAC.MenuFrame = frame

    local banWave = vderma:ArrowButton(frame)
    banWave:Dock(TOP)
    banWave:DockMargin(5, 5, 5, 5)
    banWave:SetText("Trigger Ban Wave ( "..tostring(#banwave).." pending )")
    banWave:SetTextColor(vderma.Red)
    banWave:OnClick(0.15, function()
        vderma:ConfirmBox("Are you sure you want to trigger a ban wave?", nil, nil, function(confirmed)
            if (confirmed) then
                net.Start("cnacb")
                net.SendToServer()
            end
        end)
    end)

    local scroll = vderma:ScrollPanel(frame)
    scroll:Dock(FILL)

    table.sort(banwave, function(a, b)
        return a.time > b.time
    end)

    for k, v in pairs(banwave) do
        local panel = vgui.Create("DPanel", scroll)
        panel:Dock(TOP)
        panel:DockMargin(5, 5, 5, 0)
        panel:SetHeight(60)
        function panel:Paint(w, h)
            draw.RoundedBox(0, 0, 0, w, h, vderma.PrimaryColor)
        end

        local ph = panel:GetTall()
        
        local avatar = vgui.Create("AvatarImage", panel)
        avatar:Dock(LEFT)
        avatar:DockMargin(5, 5, 5, 5)
        avatar:SetSize(ph - 10, ph - 10)
        avatar:SetSteamID(util.SteamIDTo64(v.steamid), 64)

        local fill = vgui.Create("DPanel", panel)
        fill:Dock(FILL)
        fill.Paint = nil

        local top = vgui.Create("DPanel", fill)
        top:Dock(TOP)
        top:SetHeight(panel:GetTall() * 0.5)
        top.Paint = nil

        local bottom = vgui.Create("DPanel", fill)
        bottom:Dock(BOTTOM)
        bottom:SetHeight(panel:GetTall() * 0.5)
        bottom.Paint = nil

        local name = vgui.Create("DLabel", top)
        name:Dock(FILL)
        name:DockMargin(5, 5, 5, 0)
        name:SetFont(vderma:ScaleFont(20))
        name:SetText(tostring(v.name))

        steamworks.RequestPlayerInfo(util.SteamIDTo64(v.steamid), function(steamName)
            if (IsValid(name)) then
                name:SetText(steamName)
            end
        end)

        local time = vgui.Create("DLabel", top)
        time:Dock(RIGHT)
        time:DockMargin(5, 5, 5, 0)
        time:SetFont(vderma:ScaleFont(20))
        time:SetText(os.date("%y-%m-%d %H:%M:%S", v.time))
        time:SizeToContents()

        local steamid = vgui.Create("DLabel", bottom)
        steamid:Dock(FILL)
        steamid:DockMargin(5, 0, 5, 0)
        steamid:SetFont(vderma:ScaleFont(15))
        steamid:SetText(tostring(v.steamid))

        local ban = vderma:ArrowButton(bottom)
        ban:Dock(RIGHT)
        ban:DockMargin(0, 5, 5, 5)
        ban:SetText("Ban")
        ban:SetAutoWidth(true)
        ban:SetTextColor(vderma.Red)
        ban:OnClick(0.15, function()
            vderma:ConfirmBox("Are you sure you want to ban "..name:GetText().."?", nil, nil, function(confirmed)
                if (confirmed) then
                    net.Start("cnac_ban")
                    net.WriteString(v.steamid)
                    net.SendToServer()
                end
            end)
        end)
    end
end

hook.Add("cnacb", "cnac_menu", function(banwave)
    CNAC.Menu(banwave)
end)