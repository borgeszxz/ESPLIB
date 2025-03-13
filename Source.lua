--[[ 
    https://github.com/VoidMasterX | siper#9938. 
    Slightly modified settings table for simplification 
]]--

local module = {
    drawingcache = {},
    cache = {},
    settings = {
        enabled = false,
        refreshrate = 5,
        limitdistance = false,
        maxdistance = 2500,
        teamcheck = false,
        teamcolor = false,
        textoffset = 0,
        textfont = 3,
        textsize = 15,
        names = false,
        namescolor = Color3.new(1, 1, 1),
        distance = false,
        distancecolor = Color3.new(1, 1, 1),
        boxes = false,
        boxesfill = false,
        boxesfillcolor = Color3.new(1, 1, 1),
        boxesfilltrans = 0.5,
        boxescolor = Color3.new(1, 1, 1),
        tracers = false,
        tracerscolor = Color3.new(1, 1, 1),
        tracersorigin = "Bottom",
        healthbars = false,
        healthbarsoffset = 2,
        healthbarscolor = Color3.new(0, 1, 0),
        outlines = false
    }
}

-- Libraries
local Math = loadstring(game:HttpGet("https://raw.githubusercontent.com/iRay888/Ray/main/Math"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Cache
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Functions
function module:Create(Class, Properties)
    local Object = Drawing.new(Class)

    for i,v in pairs(Properties) do
        Object[i] = v
    end

    table.insert(self.drawingcache, Object)
    return Object
end

function module:ParseColor(Color, Player)
    local TeamColor = self:GetTeamColor(Player) or Color
    return self.settings.teamcolor and TeamColor or Color
end

function module:AddEsp(Player)
    if (Player == LocalPlayer) then
        return
    end

    local Retainer = {}

    Retainer.nameobject = self:Create("Text", {
        Visible = false,
        Text = Player.Name,
        Color = Color3.new(1, 1, 1),
        Size = 13,
        Center = true,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Font = Drawing.Fonts.Plex
    })

    Retainer.distanceobject = self:Create("Text", {
        Visible = false,
        Color = Color3.new(1, 1, 1),
        Size = 13,
        Center = true,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Font = Drawing.Fonts.Plex
    })

    Retainer.boxfillobject = self:Create("Square", {
        Visible = false,
        Transparency = 0.5,
        Color = Color3.new(1, 1, 1),
        Thickness = 1,
        Filled = true,
    })

    Retainer.boxoutlineobject = self:Create("Square", {
        Visible = false,
        Transparency = 1,
        Color = Color3.new(),
        Thickness = 3,
        Filled = false,
    })

    Retainer.boxobject = self:Create("Square", {
        Visible = false,
        Transparency = 1,
        Color = Color3.new(1, 1, 1),
        Thickness = 1,
        Filled = false,
    })

    Retainer.healthbaroutlineobject = self:Create("Square", {
        Visible = false,
        Transparency = 1,
        Color = Color3.new(),
        Thickness = 3,
        Filled = false,
    })

    Retainer.healthbarobject = self:Create("Square", {
        Visible = false,
        Transparency = 1,
        Color = Color3.new(1, 1, 1),
        Thickness = 1,
        Filled = false,
    })

    Retainer.tracerobject = self:Create("Line", {
        Thickness = 1
    })

    local CanRun = true

    RunService:BindToRenderStep(Player.Name .. "Esp", 1, function()
        if (not CanRun) then
            return
        end

        CanRun = false

        local Character, Root = self:GetCharacter(Player)

        if (Character and Root) then
            local Health, MaxHealth = self:GetHealth(Player)
            local _, OnScreen = CurrentCamera:WorldToViewportPoint(Root.Position)
            local Magnitude = (Root.Position - CurrentCamera.CFrame.p).Magnitude
            local CanShow = OnScreen and self.settings.enabled

            if (self.settings.limitdistance and Magnitude > self.settings.maxdistance) then
                CanShow = false
            end

            if (self.settings.teamcheck and not self:CheckTeam(Player)) then
                CanShow = false
            end

            if (Health <= 0) then
                CanShow = false
            end

            if (CanShow) then
                local Data = self:GetBoundingBox(Character)
                local Width, Height = math.floor(Data.Positions.TopLeft.X - Data.Positions.TopRight.X), math.floor(Data.Positions.TopLeft.Y - Data.Positions.BottomLeft.Y)
                local BoxSize = Vector2.new(Width, Height)
                local BoxPosition = Vector2.new(math.floor(Data.Positions.BottomRight.X), math.floor(Data.Positions.BottomRight.Y))
                local HealthbarSize = Vector2.new(2, math.floor(BoxSize.Y * (Health / MaxHealth)))
                local HealthbarPosition = Vector2.new(math.floor(Data.Positions.TopLeft.X - ((4 + self.settings.healthbarsoffset) + (self.settings.outlines and 1 or 0))), math.floor(Data.Positions.BottomLeft.Y))
                local ViewportSize = CurrentCamera.ViewportSize

                Retainer.nameobject.Visible = self.settings.names
                Retainer.nameobject.Outline = self.settings.outlines
                Retainer.nameobject.Size = self.settings.textsize
                Retainer.nameobject.Font = self.settings.textfont
                Retainer.nameobject.Color = self:ParseColor(self.settings.namescolor, Player)
                Retainer.nameobject.Position = Vector2.new(Data.Positions.Middle.X, (Data.Positions.TopLeft.Y - 15) + self.settings.textoffset)

                Retainer.distanceobject.Visible = self.settings.distance
                Retainer.distanceobject.Outline = self.settings.outlines
                Retainer.distanceobject.Text = math.floor(Magnitude) .. " Studs"
                Retainer.distanceobject.Size = self.settings.textsize
                Retainer.distanceobject.Font = self.settings.textfont
                Retainer.distanceobject.Color = self:ParseColor(self.settings.distancecolor, Player)
                Retainer.distanceobject.Position = Vector2.new(Data.Positions.Middle.X, (Data.Positions.BottomLeft.Y + 3) + self.settings.textoffset)

                Retainer.boxobject.Visible = self.settings.boxes
                Retainer.boxobject.Color = self:ParseColor(self.settings.boxescolor, Player)
                Retainer.boxoutlineobject.Visible = self.settings.boxes and self.settings.outlines
                Retainer.boxfillobject.Color = self:ParseColor(self.settings.boxesfillcolor, Player)
                Retainer.boxfillobject.Transparency = self.settings.boxesfilltrans
                Retainer.boxfillobject.Visible = self.settings.boxes and self.settings.boxesfill

                Retainer.boxobject.Size = BoxSize
                Retainer.boxobject.Position = BoxPosition

                Retainer.boxoutlineobject.Size = BoxSize
                Retainer.boxoutlineobject.Position = BoxPosition

                Retainer.boxfillobject.Size = BoxSize
                Retainer.boxfillobject.Position = BoxPosition

                Retainer.healthbarobject.Visible = self.settings.healthbars
                Retainer.healthbarobject.Color = self:ParseColor(self.settings.healthbarscolor, Player)
                Retainer.healthbaroutlineobject.Visible = self.settings.healthbars and self.settings.outlines

                Retainer.healthbarobject.Size = HealthbarSize
                Retainer.healthbarobject.Position = HealthbarPosition

                Retainer.healthbaroutlineobject.Size = Vector2.new(HealthbarSize.X, BoxSize.Y)
                Retainer.healthbaroutlineobject.Position = HealthbarPosition

                Retainer.tracerobject.Visible = self.settings.tracers
                Retainer.tracerobject.Color = self:ParseColor(self.settings.tracerscolor, Player)
                Retainer.tracerobject.To = Data.Positions.Middle

                local Origin, Target = self.settings.tracersorigin, Vector2.new(ViewportSize.X / 2, ViewportSize.Y / 2)

                if (Origin == "Top") then
                    Target = Vector2.new(Target.X, 0)
                elseif (Origin == "Bottom") then
                    Target = Vector2.new(Target.X, ViewportSize.Y)
                elseif (Origin == "Left") then
                    Target = Vector2.new(0, Target.Y)
                elseif (Origin == "Right") then
                    Target = Vector2.new(ViewportSize.X, Taget.Y)
                elseif (Origin == "Mouse") then
                    Target = Vector2.new(Mouse.X, Mouse.Y + 36)
                end

                Retainer.tracerobject.From = Target
            else
                for i,v in pairs(Retainer) do
                    v.Visible = false
                end
            end
        else
            for i,v in pairs(Retainer) do
                v.Visible = false
            end
        end

        task.wait(math.clamp(self.settings.refreshrate / 1000, 0, 9e9))

        CanRun = true
    end)

    self.cache[Player] = Retainer
end

function module:RemoveEsp(Player)
    local Data = self.cache[Player]

    if (Data) then
        RunService:UnbindFromRenderStep(Player.Name .. "Esp")

        for _, Object in pairs(Data) do
            Object:Remove()
        end
    end
end

function module:GetCharacter(Player)
    return Player.Character, Player.Character and Player.Character:WaitForChild("HumanoidRootPart")
end

function module:GetBoundingBox(Character)
    local Data = {}

    for i,v in pairs(Character:GetChildren()) do
        if (v:IsA("BasePart") and v.Name ~= "HumanoidRootPart") then
            for i2, v2 in pairs(Math.getpartinfo2(v.CFrame, v.Size)) do
                table.insert(Data, v2)
            end
        end
    end

    return Math.getposlist2(Data)
end

function module:GetHealth(Player)
    local Character = self:GetCharacter(Player)
    local Humanoid = Character and Character:WaitForChild("Humanoid")

    return Humanoid and Humanoid.Health, Humanoid and Humanoid.MaxHealth
end

function module:GetTeam(Player)
    return Player.Team
end

function module:GetTeamColor(Player)
    local Team = self:GetTeam(Player)
    return Team and Team.TeamColor.Color
end

function module:CheckTeam(Player)
    return Player.Team ~= LocalPlayer.Team
end

function module:Init()
    -- Adiciona ESP para jogadores
    for _, player in pairs(Players:GetPlayers()) do
        self:AddEsp(player)
    end

    -- Detecta novos jogadores entrando
    Players.PlayerAdded:Connect(function(player)
        self:AddEsp(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:RemoveEsp(player)
    end)

    -- **ADICIONA SUPORTE PARA NPCs**
    for _, npc in pairs(workspace:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            self:AddEsp(npc)
        end
    end

    -- Detecta novos NPCs adicionados ao workspace
    workspace.ChildAdded:Connect(function(npc)
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            self:AddEsp(npc)
        end
    end)

    workspace.ChildRemoved:Connect(function(npc)
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
            self:RemoveEsp(npc)
        end
    end)
end


return module
