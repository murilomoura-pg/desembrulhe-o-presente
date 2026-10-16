-- Mostra os ajudantes (pets) seguindo cada jogador. Roda no Lobby e na Partida.
-- É só visual (cada jogador desenha no próprio computador/celular), por isso fica leve.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Compartilhado"):WaitForChild("Config"))

local pasta = Instance.new("Folder")
pasta.Name = "AjudantesVisuais"
pasta.Parent = workspace

local pets: { [Player]: { BasePart } } = {}

local function criarPet(id: string): BasePart
	local info = Config.ajudantePorId(id)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * 1.6
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = info and info.cor or Color3.new(1, 1, 1)
	p.Transparency = 0.2

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(3.2, 3.2)
	bb.LightInfluence = 0
	bb.MaxDistance = 120
	bb.Parent = p
	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.fromScale(1, 1)
	emoji.BackgroundTransparency = 1
	emoji.TextScaled = true
	emoji.Text = info and info.emoji or "❓"
	emoji.Parent = bb

	if info then
		local brilho = Instance.new("PointLight")
		brilho.Range = 6
		brilho.Brightness = 0.6
		brilho.Color = Config.CORES_RARIDADE_AJUDANTE[info.raridade] or Color3.new(1, 1, 1)
		brilho.Parent = p
	end
	p.Parent = pasta
	return p
end

local function atualizar(player: Player)
	for _, p in (pets[player] or {}) :: { BasePart } do
		p:Destroy()
	end
	pets[player] = {}
	local texto = player:GetAttribute("Equipados") or ""
	for id in string.gmatch(texto, "[^,]+") do
		table.insert(pets[player], criarPet(id))
	end
end

local function observar(player: Player)
	atualizar(player)
	player:GetAttributeChangedSignal("Equipados"):Connect(function()
		atualizar(player)
	end)
end

Players.PlayerAdded:Connect(observar)
for _, p in Players:GetPlayers() do
	observar(p)
end
Players.PlayerRemoving:Connect(function(player)
	for _, p in (pets[player] or {}) :: { BasePart } do
		p:Destroy()
	end
	pets[player] = nil
end)

-- Faz os pets seguirem o dono, flutuando atrás dele
RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for player, lista in pets do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			continue
		end
		local n = #lista
		for i, pet in lista do
			local angulo = math.rad(180 + (i - (n + 1) / 2) * 40)
			local deslocamento = Vector3.new(math.sin(angulo) * 5, 1.5 + math.sin(t * 3 + i) * 0.4, math.cos(angulo) * 5)
			local alvo = root.CFrame * CFrame.new(-deslocamento.X, deslocamento.Y, -deslocamento.Z)
			local alpha = math.clamp(dt * 8, 0, 1)
			pet.CFrame = pet.CFrame:Lerp(CFrame.new(alvo.Position), alpha)
		end
	end
end)
