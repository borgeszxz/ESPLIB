--[[ 
    https://github.com/VoidMasterX | siper#9938. 
    Adaptado para NPCs.
]]--

local module = {
    drawingcache = {},
    cache = {},
    settings = {
        enabled = false,
        refreshrate = 5,
        limitdistance = false,
        maxdistance = 2500,
        -- As opções de time não são necessárias para NPCs
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

-- Bibliotecas
local Math = loadstring(game:HttpGet("https://raw.githubusercontent.com/iRay888/Ray/main/Math"))()

-- Serviços
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

-- Função para criar objetos de desenho
function module:Create(Class, Properties)
    local Object = Drawing.new(Class)
    for i, v in pairs(Properties) do
        Object[i] = v
    end
    table.insert(self.drawingcache, Object)
    return Object
end

-- Para NPCs não usamos cores de time; retorna a cor original
function module:ParseColor(Color, Entity)
    return Color
end

-- Adiciona ESP para um NPC
function module:AddEsp(NPC)
    local Retainer = {}

    Retainer.nameobject = self:Create("Text", {
        Visible = false,
        Text = NPC.Name,
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

    RunService:BindToRenderStep(NPC.Name .. "Esp", 1, function()
        if (not CanRun) then
            return
        end

        CanRun = false

        local Character, Root = self:GetCharacter(NPC)

        if (Character and Root) then
            local Health, MaxHealth = self:GetHealth(NPC)
            local _, OnScreen = CurrentCamera:WorldToViewportPoint(Root.Position)
            local Magnitude = (Root.Position - CurrentCamera.CFrame.p).Magnitude
            local CanShow = OnScreen and self.settings.enabled

            if (self.settings.limitdistance and Magnitude > self.settings.maxdistance) then
                CanShow = false
            end

            if (Health <= 0) then
                CanShow = false
            end

            if (CanShow) then
                local Data = self:GetBoundingBox(Character)
                local Width = math.floor(Data.Positions.TopLeft.X - Data.Positions.TopRight.X)
                local Height = math.floor(Data.Positions.TopLeft.Y - Data.Positions.BottomLeft.Y)
                local BoxSize = Vector2.new(Width, Height)
                local BoxPosition = Vector2.new(math.floor(Data.Positions.BottomRight.X), math.floor(Data.Positions.BottomRight.Y))
                local HealthbarSize = Vector2.new(2, math.floor(BoxSize.Y * (Health / MaxHealth)))
                local HealthbarPosition = Vector2.new(math.floor(Data.Positions.TopLeft.X - (4 + self.settings.healthbarsoffset)), math.floor(Data.Positions.BottomLeft.Y))
                local ViewportSize = CurrentCamera.ViewportSize

                Retainer.nameobject.Visible = self.settings.names
                Retainer.nameobject.Outline = self.settings.outlines
                Retainer.nameobject.Size = self.settings.textsize
                Retainer.nameobject.Font = self.settings.textfont
                Retainer.nameobject.Color = self:ParseColor(self.settings.namescolor, NPC)
                Retainer.nameobject.Position = Vector2.new(Data.Positions.Middle.X, (Data.Positions.TopLeft.Y - 15) + self.settings.textoffset)

                Retainer.distanceobject.Visible = self.settings.distance
                Retainer.distanceobject.Outline = self.settings.outlines
                Retainer.distanceobject.Text = math.floor(Magnitude) .. " Studs"
                Retainer.distanceobject.Size = self.settings.textsize
                Retainer.distanceobject.Font = self.settings.textfont
                Retainer.distanceobject.Color = self:ParseColor(self.settings.distancecolor, NPC)
                Retainer.distanceobject.Position = Vector2.new(Data.Positions.Middle.X, (Data.Positions.BottomLeft.Y + 3) + self.settings.textoffset)

                Retainer.boxobject.Visible = self.settings.boxes
                Retainer.boxobject.Color = self:ParseColor(self.settings.boxescolor, NPC)
                Retainer.boxoutlineobject.Visible = self.settings.boxes and self.settings.outlines
                Retainer.boxfillobject.Color = self:ParseColor(self.settings.boxesfillcolor, NPC)
                Retainer.boxfillobject.Transparency = self.settings.boxesfilltrans
                Retainer.boxfillobject.Visible = self.settings.boxes and self.settings.boxesfill

                Retainer.boxobject.Size = BoxSize
                Retainer.boxobject.Position = BoxPosition

                Retainer.boxoutlineobject.Size = BoxSize
                Retainer.boxoutlineobject.Position = BoxPosition

                Retainer.boxfillobject.Size = BoxSize
                Retainer.boxfillobject.Position = BoxPosition

                Retainer.healthbarobject.Visible = self.settings.healthbars
                Retainer.healthbarobject.Color = self:ParseColor(self.settings.healthbarscolor, NPC)
                Retainer.healthbaroutlineobject.Visible = self.settings.healthbars and self.settings.outlines

                Retainer.healthbarobject.Size = HealthbarSize
                Retainer.healthbarobject.Position = HealthbarPosition

                Retainer.healthbaroutlineobject.Size = Vector2.new(HealthbarSize.X, BoxSize.Y)
                Retainer.healthbaroutlineobject.Position = HealthbarPosition

                Retainer.tracerobject.Visible = self.settings.tracers
                Retainer.tracerobject.Color = self:ParseColor(self.settings.tracerscolor, NPC)
                Retainer.tracerobject.To = Data.Positions.Middle

                local Origin, Target = self.settings.tracersorigin, Vector2.new(ViewportSize.X / 2, ViewportSize.Y / 2)

                if (Origin == "Top") then
                    Target = Vector2.new(Target.X, 0)
                elseif (Origin == "Bottom") then
                    Target = Vector2.new(Target.X, ViewportSize.Y)
                elseif (Origin == "Left") then
                    Target = Vector2.new(0, Target.Y)
                elseif (Origin == "Right") then
                    Target = Vector2.new(ViewportSize.X, Target.Y)
                elseif (Origin == "Mouse") then
                    Target = Vector2.new(Mouse.X, Mouse.Y + 36)
                end

                Retainer.tracerobject.From = Target
            else
                for i, v in pairs(Retainer) do
                    v.Visible = false
                end
            end
        else
            for i, v in pairs(Retainer) do
                v.Visible = false
            end
        end

        task.wait(math.clamp(self.settings.refreshrate / 1000, 0, 9e9))
        CanRun = true
    end)

    self.cache[NPC] = Retainer
end

-- Remove o ESP do NPC
function module:RemoveEsp(NPC)
    local Data = self.cache[NPC]
    if (Data) then
        RunService:UnbindFromRenderStep(NPC.Name .. "Esp")
        for _, Object in pairs(Data) do
            Object:Remove()
        end
    end
end

-- Obtém o "personagem" (modelo) do NPC e seu HumanoidRootPart
function module:GetCharacter(NPC)
    return NPC, NPC:FindFirstChild("HumanoidRootPart")
end

-- Calcula a bounding box do NPC com base em seus BaseParts
function module:GetBoundingBox(Character)
    local Data = {}

    for i, v in pairs(Character:GetChildren()) do
        if (v:IsA("BasePart") and v.Name ~= "HumanoidRootPart") then
            for i2, v2 in pairs(Math.getpartinfo2(v.CFrame, v.Size)) do
                table.insert(Data, v2)
            end
        end
    end

    return Math.getposlist2(Data)
end

-- Obtém a saúde do NPC
function module:GetHealth(NPC)
    local Humanoid = NPC and NPC:FindFirstChild("Humanoid")
    return Humanoid and Humanoid.Health, Humanoid and Humanoid.MaxHealth
end

-- Funções de time não são necessárias para NPCs; funções adaptadas
function module:GetTeam(NPC)
    return nil
end

function module:GetTeamColor(NPC)
    return Color3.new(1, 1, 1)
end

function module:CheckTeam(NPC)
    return true
end

-- Inicializa o ESP para todos os NPCs na pasta "NPCs"
function module:Init()
    local NPCFolder = workspace:FindFirstChild("NPCs")
    if NPCFolder then
        for _, NPC in pairs(NPCFolder:GetChildren()) do
            self:AddEsp(NPC)
        end

        NPCFolder.ChildAdded:Connect(function(NPC)
            self:AddEsp(NPC)
        end)

        NPCFolder.ChildRemoved:Connect(function(NPC)
            self:RemoveEsp(NPC)
        end)
    else
        warn("Pasta 'NPCs' não encontrada no workspace.")
    end
end

return module
