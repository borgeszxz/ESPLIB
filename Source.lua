--[[ 
    Versão modificada para NPCs
]]--

local module = {
    drawingcache = {},
    cache = {},
    settings = {
        enabled = false,
        refreshrate = 5,
        limitdistance = false,
        maxdistance = 2500,
        teamcheck = false,          -- Pode ser removido se não aplicável
        teamcolor = false,           -- Pode ser removido se não aplicável
        textoffset = 0,
        textfont = 3,
        textsize = 15,
        names = true,
        namescolor = Color3.new(1, 1, 1),
        distance = true,
        distancecolor = Color3.new(1, 1, 1),
        boxes = true,
        boxesfill = false,
        boxesfillcolor = Color3.new(1, 1, 1),
        boxesfilltrans = 0.5,
        boxescolor = Color3.new(1, 1, 1),
        tracers = false,
        tracerscolor = Color3.new(1, 1, 1),
        tracersorigin = "Bottom",
        healthbars = true,
        healthbarsoffset = 2,
        healthbarscolor = Color3.new(0, 1, 0),
        outlines = true
    },
    npc_identifier = "NPC" -- Altere para o nome ou tag dos seus NPCs
}

-- ... (mantenha as libraries e serviços originais)

-- Funções modificadas para NPCs
function module:IsNPC(model)
    -- Modifique esta função conforme a identificação dos NPCs no seu jogo
    return model:IsA("Model") and (model.Name:find(self.npc_identifier) or model:FindFirstChild("IsNPC"))
end

function module:GetCharacter(npc)
    return npc, npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso") or npc.PrimaryPart
end

function module:GetHealth(npc)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health or 100, humanoid and humanoid.MaxHealth or 100
end

function module:AddEsp(npc)
    if self.cache[npc] then return end

    local Retainer = {}

    -- (Mantenha o mesmo código de criação de objetos de desenho)

    local CanRun = true

    RunService:BindToRenderStep(tostring(npc) .. "Esp", 1, function()
        if not CanRun then return end
        CanRun = false

        local Root = self:GetCharacter(npc)
        if not Root then
            self:RemoveEsp(npc)
            return
        end

        -- (Mantenha a lógica de renderização adaptando para NPCs)

        task.wait(math.clamp(self.settings.refreshrate / 1000, 0, 9e9))
        CanRun = true
    end)

    self.cache[npc] = Retainer
end

function module:RemoveEsp(npc)
    local Data = self.cache[npc]
    if Data then
        RunService:UnbindFromRenderStep(tostring(npc) .. "Esp")
        for _, Object in pairs(Data) do
            Object:Remove()
        end
        self.cache[npc] = nil
    end
end

function module:ScanForNPCs()
    for _, obj in ipairs(workspace:GetChildren()) do
        if self:IsNPC(obj) then
            self:AddEsp(obj)
        end
    end
end

function module:Init()
    -- Verificação inicial
    self:ScanForNPCs()

    -- Monitorar novos NPCs
    workspace.ChildAdded:Connect(function(child)
        if self:IsNPC(child) then
            self:AddEsp(child)
        end
    end)

    -- Monitorar NPCs removidos
    workspace.ChildRemoved:Connect(function(child)
        if self:IsNPC(child) then
            self:RemoveEsp(child)
        end
    end)

    -- Verificação periódica
    while true do
        wait(5)
        for npc in pairs(self.cache) do
            if not npc.Parent or npc.Parent == nil then
                self:RemoveEsp(npc)
            end
        end
    end
end

return module
