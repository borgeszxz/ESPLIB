--[[ 
    https://github.com/VoidMasterX | siper#9938. 
    Slightly modified settings table for NPC-only ESP
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

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CurrentCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Functions
function module:Create(Class, Properties)
    local Object = Drawing.new(Class)
    for i, v in pairs(Properties) do
        Object[i] = v
    end
    table.insert(self.drawingcache, Object)
    return Object
end

-- Alterado: Filtra apenas NPCs
function module:AddEsp(NPC)
    if not NPC:IsA("Model") or not NPC:FindFirstChild("Humanoid") or Players:GetPlayerFromCharacter(NPC) then
        return
    end

    local Root = NPC:FindFirstChild("HumanoidRootPart") or NPC:FindFirstChild("Head") or NPC.PrimaryPart
    if not Root then return end

    local Retainer = {}
    
    Retainer.nameobject = self:Create("Text", {
        Visible = false,
        Text = NPC.Name,
        Color = Color3.new(1, 1, 1),
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
    RunService:BindToRenderStep(NPC.Name .. "Esp", 1, function()
        if not CanRun then return end
        CanRun = false

        if NPC.Parent == nil or not NPC:FindFirstChild("Humanoid") then
            for _, v in pairs(Retainer) do v.Visible = false end
            return
        end

        local Health, MaxHealth = NPC:FindFirstChild("Humanoid").Health, NPC:FindFirstChild("Humanoid").MaxHealth
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
            Retainer.nameobject.Text = NPC.Name
            Retainer.distanceobject.Visible = self.settings.distance
            Retainer.distanceobject.Text = string.format("%.1fm", Distance)
            Retainer.boxobject.Visible = self.settings.boxes
            Retainer.healthbarobject.Visible = self.settings.healthbars
            
            -- Atualizando posição das caixas
            local BoxSize = Vector2.new(50, 100)
            local BoxPosition = Vector2.new(CurrentCamera:WorldToViewportPoint(Root.Position).X - 25, CurrentCamera:WorldToViewportPoint(Root.Position).Y - 50)
            
            Retainer.boxobject.Size = BoxSize
            Retainer.boxobject.Position = BoxPosition
            
            local HealthbarSize = Vector2.new(3, BoxSize.Y * (Health / MaxHealth))
            local HealthbarPosition = Vector2.new(BoxPosition.X - 5, BoxPosition.Y)
            
            Retainer.healthbarobject.Size = HealthbarSize
            Retainer.healthbarobject.Position = HealthbarPosition
        else
            for _, v in pairs(Retainer) do v.Visible = false end
        end

        task.wait(math.clamp(self.settings.refreshrate / 1000, 0, 9e9))
        CanRun = true
    end)

    self.cache[NPC] = Retainer
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
