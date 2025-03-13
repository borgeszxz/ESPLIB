--[[  
    ESP para NPCs - Corrigido Registro e Atualização Dinâmica  
]]--

local ESP = {
    Enabled = true,
    BoxEnabled = true,
    BoxColor = Color3.fromRGB(255, 255, 255),
    BoxThickness = 2, -- Espessura da borda da caixa
    OutlineEnabled = true, -- Ativar contorno preto nas caixas e textos
    OutlineColor = Color3.fromRGB(0, 0, 0),
    HealthBarEnabled = true,
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    NameEnabled = true,
    DistanceEnabled = true,
    MaxDistance = 2500,
    Font = Drawing.Fonts.Plex, -- Melhor fonte
    TextSize = 16, -- Tamanho do texto
}

local function createText()
    local text = Drawing.new("Text")
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Size = ESP.TextSize
    text.Font = ESP.Font
    text.Center = true
    text.Outline = ESP.OutlineEnabled
    text.OutlineColor = ESP.OutlineColor
    text.Visible = false
    return text
end

local function createBox()
    local box = Drawing.new("Square")
    box.Thickness = ESP.BoxThickness
    box.Filled = false
    box.Color = ESP.BoxColor
    box.Visible = false
    return box
end

local function createHealthBar()
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Color = ESP.HealthBarColor
    healthBar.Visible = false
    return healthBar
end

local current_camera = game:GetService("Workspace").CurrentCamera
local run_service = game:GetService("RunService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")

local function IsNPC(entity)
    return entity:IsA("Model") and entity:FindFirstChildOfClass("Humanoid") 
        and entity:FindFirstChild("HumanoidRootPart") 
        and not players:GetPlayerFromCharacter(entity)
end

local function calculate_box(entity)
    local character = entity
    if not character then return end

    local humanoid_root_part = character:FindFirstChild("HumanoidRootPart")
    if not humanoid_root_part then return end

    -- Captura as bordas do NPC
    local model_cframe, model_size = character:GetBoundingBox()

    -- Define os pontos da caixa 3D do NPC
    local corners = {
        model_cframe * Vector3.new(-model_size.X / 2, model_size.Y / 2, 0),
        model_cframe * Vector3.new(model_size.X / 2, model_size.Y / 2, 0),
        model_cframe * Vector3.new(-model_size.X / 2, -model_size.Y / 2, 0),
        model_cframe * Vector3.new(model_size.X / 2, -model_size.Y / 2, 0)
    }

    -- Converte para coordenadas de tela
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, corner in pairs(corners) do
        local screen_pos, on_screen = current_camera:WorldToViewportPoint(corner)
        if on_screen then
            minX, minY = math.min(minX, screen_pos.X), math.min(minY, screen_pos.Y)
            maxX, maxY = math.max(maxX, screen_pos.X), math.max(maxY, screen_pos.Y)
        end
    end

    if minX == math.huge then return end -- Se não estiver na tela, ignora

    -- Ajuste do tamanho
    local box_width = maxX - minX
    local box_height = maxY - minY

    return { X = minX, Y = minY, W = box_width, H = box_height }
end

local esp_objects = {}

local function AddNPCEsp(entity)
    if IsNPC(entity) and not esp_objects[entity] then
        local box = calculate_box(entity)
        if box then
            esp_objects[entity] = {
                BoxOutline = createBox(),
                Box = createBox(),
                Name = createText(),
                Distance = createText(),
                HealthBar = createHealthBar()
            }

            -- Contorno preto para a caixa do ESP
            if ESP.OutlineEnabled then
                esp_objects[entity].BoxOutline.Thickness = ESP.BoxThickness + 2
                esp_objects[entity].BoxOutline.Color = ESP.OutlineColor
                esp_objects[entity].BoxOutline.Visible = true
            end
        end
    end
end

local function UpdateESP()
    for entity, objects in pairs(esp_objects) do
        if not entity or not entity.Parent then
            for _, obj in pairs(objects) do
                obj.Visible = false
            end
            esp_objects[entity] = nil
        else
            local box = calculate_box(entity)
            if box then
                -- Atualiza Caixa do ESP
                objects.Box.Position = Vector2.new(box.X, box.Y)
                objects.Box.Size = Vector2.new(box.W, box.H)
                objects.Box.Color = ESP.BoxColor
                objects.Box.Thickness = 2
                objects.Box.Visible = ESP.BoxEnabled

                -- Atualiza Nome do NPC
                objects.Name.Text = entity.Name
                objects.Name.Position = Vector2.new(box.X + (box.W / 2), box.Y - 18)
                objects.Name.Visible = ESP.NameEnabled

                -- Atualiza Distância
                local distance = (entity.HumanoidRootPart.Position - players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                objects.Distance.Text = string.format("[%.1fm]", distance)
                objects.Distance.Position = Vector2.new(box.X + (box.W / 2), box.Y + box.H + 5)
                objects.Distance.Visible = ESP.DistanceEnabled

                -- Atualiza Barra de Vida
                local humanoid = entity:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local health_percent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)

                    objects.HealthBar.Size = Vector2.new(4, box.H * health_percent)
                    objects.HealthBar.Position = Vector2.new(box.X - 7, box.Y + (box.H * (1 - health_percent)))
                    objects.HealthBar.Color = ESP.HealthBarColor
                    objects.HealthBar.Visible = ESP.HealthBarEnabled
                end
            else
                -- Se o NPC estiver fora da tela, esconde o ESP
                for _, obj in pairs(objects) do
                    obj.Visible = false
                end
            end
        end
    end
end

-- Garante que todos os NPCs existentes sejam registrados
for _, entity in pairs(workspace:GetDescendants()) do
    if IsNPC(entity) then
        AddNPCEsp(entity)
    end
end

workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.1)
    if IsNPC(obj) then
        AddNPCEsp(obj)
    end
end)

run_service.RenderStepped:Connect(UpdateESP)

return ESP
