--[[ 
    ESP Library Modificada - Apenas NPCs
    Baseado na biblioteca original de VoidMasterX | siper#9938.
]]--

local module = {
    drawingcache = {},
    cache = {},
    settings = {
        enabled = false,
        refreshrate = 5,
        limitdistance = false,
        maxdistance = 2500,
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
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CurrentCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Função para criar elementos visuais
function module:Create(Class, Properties)
    local Object = Drawing.new(Class)
    for i, v in pairs(Properties) do
        Object[i] = v
    end
    table.insert(self.drawingcache, Object)
    return Object
end

-- Alterado: Apenas NPCs são adicionados ao ESP
function module:AddEsp(Entity)
    if not Entity:IsA("Model") or not Entity:FindFirstChild("Humanoid") or Players:GetPlayerFromCharacter(Entity) then
        return
    end

    local Root = Entity:FindFirstChild("HumanoidRootPart") or Entity:FindFirstChild("Head") or Entity.PrimaryPart
    if not Root then return end

    local Retainer = {}
    
    Retainer.nameobject = self:Create("Text", {
        Visible = false,
        Text = Entity.Name,
        Color = self.settings.namescolor,
        Size = self.settings.textsize,
        Center = true,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Font = Drawing.Fonts.Plex
    })
    
    Retainer.distanceobject = self:Create("Text", {
        Visible = false,
        Color = self.settings.distancecolor,
        Size = self.settings.textsize,
        Center = true,
        Outline = true,
        OutlineColor = Color3.new(0, 0, 0),
        Font = Drawing.Fonts.Plex
    })
    
    Retainer.boxobject = self:Create("Square", {
        Visible = false,
        Transparency = 1,
        Color = self.settings.boxescolor,
        Thickness = 1,
        Filled = false
    })
    
    Retainer.healthbarobject = self:Create("Square", {
        Visible = false,
        Transparency = 1,
        Color = self.settings.healthbarscolor,
        Thickness = 1,
        Filled = false
    })
    
    local CanRun = true
    RunService:BindToRenderStep(Entity.Name .. "Esp", 1, function()
        if not CanRun then return end
        CanRun = false

        if Entity.Parent == nil or not Entity:FindFirstChild("Humanoid") then
            for _, v in pairs(Retainer) do v.Visible = false end
            return
        end

        local Health, MaxHealth = Entity:FindFirstChild("Humanoid").Health, Entity:FindFirstChild("Humanoid").MaxHealth
        local _, OnScreen = CurrentCamera:WorldToViewportPoint(Root.Position)
        local Distance = (Root.Position - CurrentCamera.CFrame.p).Magnitude
        local CanShow = OnScreen and self.settings.enabled
        
        if self.settings.limitdistance and Distance > self.settings.maxdistance then
            CanShow = false
        end
        
        if Health <= 0 then
            CanShow = false
        end
        
        if CanShow then
            Retainer.nameobject.Visible = self.settings.names
            Retainer.nameobject.Text = Entity.Name
            Retainer.distanceobject.Visible = self.settings.distance
            Retainer.distanceobject.Text = string.format("%.1fm", Distance)
            Retainer.boxobject.Visible = self.settings.boxes
            Retainer.healthbarobject.Visible = self.settings.healthbars
            
            -- Mantendo as caixas e barras no formato correto
            local Data = module:GetBoundingBox(Entity)
            Retainer.boxobject.Size = Data.Size
            Retainer.boxobject.Position = Data.Position
            
            local HealthbarSize = Vector2.new(3, Data.Size.Y * (Health / MaxHealth))
            local HealthbarPosition = Vector2.new(Data.Position.X - 5, Data.Position.Y)
            
            Retainer.healthbarobject.Size = HealthbarSize
            Retainer.healthbarobject.Position = HealthbarPosition
        else
            for _, v in pairs(Retainer) do v.Visible = false end
        end

        task.wait(math.clamp(self.settings.refreshrate / 1000, 0, 9e9))
        CanRun = true
    end)

    self.cache[Entity] = Retainer
end

-- Função para obter Bounding Box corretamente
function module:GetBoundingBox(Character)
    local Data = {}
    for _, v in pairs(Character:GetChildren()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            for _, v2 in pairs(Math.getpartinfo2(v.CFrame, v.Size)) do
                table.insert(Data, v2)
            end
        end
    end
    return Math.getposlist2(Data)
end

-- Alterado: Apenas NPCs são adicionados ao ESP
function module:Init()
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(npc) then
            self:AddEsp(npc)
        end
    end

    workspace.ChildAdded:Connect(function(obj)
        task.wait(1)
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
            self:AddEsp(obj)
        end
    end)
end

return module
