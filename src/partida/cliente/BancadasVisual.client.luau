-- 🎁 Visual das BANCADAS (só no seu computador/celular):
--   • os presentes colocados aparecem empilhados em cima da bancada (no máximo 30 caixinhas;
--     o resto aparece só no número da placa);
--   • cada presente desembrulhado solta um pouco de papel picado;
--   • o botão "Colocar presentes" só aparece na SUA bancada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Compartilhado"):WaitForChild("Config"))
local P = Config.PALETA

local player = Players.LocalPlayer
local MAX_CAIXAS = 30
local CORES = { P.vermelho, P.verdeClaro, P.dourado, P.azul, P.neve, Color3.fromRGB(150, 70, 200) }

local pasta = Instance.new("Folder")
pasta.Name = "PilhasBancadas"
pasta.Parent = workspace

local function observar(modelo: Model)
	local bandeja = modelo:WaitForChild("Bandeja", 30) :: BasePart?
	if not bandeja then
		return
	end
	local prompt = bandeja:WaitForChild("ColocarPresentes", 30) :: ProximityPrompt?
	local pilha = Instance.new("Folder")
	pilha.Name = modelo.Name
	pilha.Parent = pasta

	-- Papel picado: um emissor parado que solta um punhadinho a cada presente aberto
	local ancora = Instance.new("Part")
	ancora.Name = "Confete"
	ancora.Anchored = true
	ancora.CanCollide = false
	ancora.CanQuery = false
	ancora.CanTouch = false
	ancora.Transparency = 1
	ancora.Size = Vector3.new(3, 0.2, 2)
	ancora.CFrame = bandeja.CFrame * CFrame.new(0, 1.4, 0)
	ancora.Parent = pilha
	local confete = Instance.new("ParticleEmitter")
	confete.Texture = "rbxasset://textures/particles/SquareParticle.png"
	confete.Rate = 0
	confete.Lifetime = NumberRange.new(0.8, 1.4)
	confete.Speed = NumberRange.new(6, 10)
	confete.SpreadAngle = Vector2.new(55, 55)
	confete.EmissionDirection = Enum.NormalId.Top
	confete.Acceleration = Vector3.new(0, -22, 0)
	confete.Size = NumberSequence.new(0.22)
	confete.Rotation = NumberRange.new(0, 360)
	confete.RotSpeed = NumberRange.new(-300, 300)
	confete.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, P.vermelho),
		ColorSequenceKeypoint.new(0.33, P.dourado),
		ColorSequenceKeypoint.new(0.66, P.verdeClaro),
		ColorSequenceKeypoint.new(1, P.azul),
	})
	confete.Parent = ancora

	-- Caixinhas em grade: 5 x 3 por camada, 2 camadas
	local caixas: { BasePart } = {}
	local function lugar(i: number): CFrame
		local camada = (i - 1) // 15
		local resto = (i - 1) % 15
		local x = -2 + (resto % 5) * 1
		local z = -1 + (resto // 5) * 1
		local y = 0.125 + 0.43 + camada * 0.9
		return bandeja.CFrame * CFrame.new(x, y, z) * CFrame.Angles(0, math.rad((i * 37) % 24 - 12), 0)
	end
	local anterior = modelo:GetAttribute("Estoque") or 0
	local function atualizar()
		local estoque = modelo:GetAttribute("Estoque") or 0
		if estoque < anterior then
			confete:Emit(math.min(6 * (anterior - estoque), 30))
		end
		anterior = estoque
		local n = math.min(estoque, MAX_CAIXAS)
		while #caixas < n do
			local i = #caixas + 1
			local c = Instance.new("Part")
			c.Name = "Presente"
			c.Anchored = true
			c.CanCollide = false
			c.CanTouch = false
			c.CanQuery = true -- para o "arrastar por cima" do HUD achar a pilha
			c.CastShadow = false
			c.Size = Vector3.new(0.82, 0.8, 0.82)
			c.Color = CORES[(i * 7) % #CORES + 1]
			c.Material = Enum.Material.SmoothPlastic
			c.CFrame = lugar(i)
			c.Parent = pilha
			local fita = Instance.new("Part")
			fita.Name = "Fita"
			fita.Anchored = true
			fita.CanCollide = false
			fita.CanTouch = false
			fita.CanQuery = false
			fita.CastShadow = false
			fita.Size = Vector3.new(0.86, 0.84, 0.2)
			fita.Color = c.Color == P.dourado and P.vermelho or P.dourado
			fita.CFrame = c.CFrame
			fita.Parent = c
			table.insert(caixas, c)
		end
		while #caixas > n do
			local c = table.remove(caixas) :: BasePart
			c:Destroy()
		end
	end

	-- O botão "Colocar presentes" só aparece na minha bancada
	local function atualizarBotao()
		if prompt then
			prompt.Enabled = modelo:GetAttribute("Dono") == player.UserId
		end
	end

	modelo:GetAttributeChangedSignal("Estoque"):Connect(atualizar)
	modelo:GetAttributeChangedSignal("Dono"):Connect(atualizarBotao)
	if prompt then
		-- O servidor liga o botão quando a bancada ganha dono; aqui ele volta a sumir para os outros
		prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
			if prompt.Enabled and modelo:GetAttribute("Dono") ~= player.UserId then
				prompt.Enabled = false
			end
		end)
	end
	atualizar()
	atualizarBotao()
end

-- O mapa só aparece quando o grupo chega
local mapa = workspace:WaitForChild("MapaPartida", math.huge)
for i = 1, 4 do
	local modelo = mapa:WaitForChild("Bancada_" .. i, 30)
	if modelo and modelo:IsA("Model") then
		task.spawn(observar, modelo)
	end
end
