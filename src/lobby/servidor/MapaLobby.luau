-- Constrói o mapa do Lobby (praça de neve com as 4 salas, placares e a máquina de ajudantes).
-- Tudo é criado por código quando o servidor liga. Depois dá pra trocar por modelos bonitos no Studio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Util = require(ReplicatedStorage.Compartilhado.Util)
local Natal = require(ServerStorage.Comum.Natal)

local MapaLobby = {}

local BRANCO_NEVE = Color3.fromRGB(240, 246, 255)
local VERMELHO = Color3.fromRGB(200, 30, 40)
local DOURADO = Color3.fromRGB(255, 200, 50)
local VERDE_PINHEIRO = Color3.fromRGB(30, 110, 60)
-- Gira 180° para a "frente" da placa ficar virada para quem está na praça
local VIRAR = CFrame.Angles(0, math.pi, 0)

local function iluminacao()
	Natal.iluminacao()
end

local function pinheiro(pasta: Instance, pos: Vector3, escala: number)
	Util.peca({ Name = "Tronco", Size = Vector3.new(2, 4, 2) * escala, Position = pos + Vector3.new(0, 2 * escala, 0), Color = Color3.fromRGB(100, 60, 30), Material = Enum.Material.Wood, Parent = pasta })
	for i = 0, 3 do
		local lado = (10 - i * 2.4) * escala
		local altura = 2.6 * escala
		Util.peca({
			Name = "Folhas",
			Size = Vector3.new(lado, altura, lado),
			CFrame = CFrame.new(pos + Vector3.new(0, (4 + i * 2.6) * escala + altura / 2, 0)) * CFrame.Angles(0, math.rad(45 * (i % 2)), 0),
			Color = VERDE_PINHEIRO,
			Material = Enum.Material.Grass,
			Parent = pasta,
		})
	end
	local estrela = Util.peca({ Name = "Estrela", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.8 * escala, Position = pos + Vector3.new(0, 15.5 * escala, 0), Color = DOURADO, Material = Enum.Material.Neon, Parent = pasta })
	local luz = Instance.new("PointLight")
	luz.Color = DOURADO
	luz.Range = 14
	luz.Parent = estrela
end

local function caixaPresente(pasta: Instance, pos: Vector3, tamanho: Vector3, cor: Color3, corLaco: Color3)
	local caixa = Util.peca({ Name = "Caixa", Size = tamanho, Position = pos + Vector3.new(0, tamanho.Y / 2, 0), Color = cor, Parent = pasta })
	Util.peca({ Name = "Laco1", Size = Vector3.new(tamanho.X + 0.1, tamanho.Y + 0.1, tamanho.Z * 0.18), Position = caixa.Position, Color = corLaco, Material = Enum.Material.Foil, CanCollide = false, Parent = pasta })
	Util.peca({ Name = "Laco2", Size = Vector3.new(tamanho.X * 0.18, tamanho.Y + 0.1, tamanho.Z + 0.1), Position = caixa.Position, Color = corLaco, Material = Enum.Material.Foil, CanCollide = false, Parent = pasta })
	return caixa
end

-- Retorna as referências que os outros scripts precisam
function MapaLobby.construir()
	iluminacao()

	local pasta = Instance.new("Folder")
	pasta.Name = "MapaLobby"
	pasta.Parent = workspace

	-- Chão de neve
	Util.peca({ Name = "Chao", Size = Vector3.new(320, 2, 320), Position = Vector3.new(0, -1, 0), Color = BRANCO_NEVE, Material = Enum.Material.Snow, Parent = pasta })

	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, 20)
	spawn.Color = VERMELHO
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.Parent = pasta

	-- Título
	local titulo = Util.peca({ Name = "Titulo", Size = Vector3.new(70, 14, 2), CFrame = CFrame.new(0, 46, -70) * VIRAR, Color = VERMELHO, Parent = pasta })
	Util.placa(titulo, "🎁 DESEMBRULHE O PRESENTE 🎁", Enum.NormalId.Front, Color3.new(1, 1, 1))

	-- Salas
	local salas = {}
	local espacamento = 34
	local inicioX = -espacamento * (#Config.MODOS - 1) / 2
	for i, modo in Config.MODOS do
		local x = inicioX + (i - 1) * espacamento
		local z = -40
		local salaPasta = Instance.new("Folder")
		salaPasta.Name = "Sala_" .. modo.nome
		salaPasta.Parent = pasta

		local piso = Util.peca({ Name = "Piso", Size = Vector3.new(24, 1, 24), Position = Vector3.new(x, 0.5, z), Color = modo.cor, Material = Enum.Material.Neon, Transparency = 0.25, Parent = salaPasta })
		-- Paredes (a frente fica aberta)
		Util.peca({ Name = "ParedeFundo", Size = Vector3.new(26, 32, 2), Position = Vector3.new(x, 16, z - 13), Color = Color3.fromRGB(60, 40, 50), Material = Enum.Material.WoodPlanks, Parent = salaPasta })
		Util.peca({ Name = "ParedeEsq", Size = Vector3.new(2, 12, 26), Position = Vector3.new(x - 13, 6, z), Color = VERMELHO, Parent = salaPasta })
		Util.peca({ Name = "ParedeDir", Size = Vector3.new(2, 12, 26), Position = Vector3.new(x + 13, 6, z), Color = VERMELHO, Parent = salaPasta })
		-- Faixa dourada no topo das paredes laterais
		Util.peca({ Name = "FaixaEsq", Size = Vector3.new(2.4, 1, 26.4), Position = Vector3.new(x - 13, 12.5, z), Color = DOURADO, Material = Enum.Material.Neon, Parent = salaPasta })
		Util.peca({ Name = "FaixaDir", Size = Vector3.new(2.4, 1, 26.4), Position = Vector3.new(x + 13, 12.5, z), Color = DOURADO, Material = Enum.Material.Neon, Parent = salaPasta })

		-- Placa com o nome da sala
		local placaNome = Util.peca({ Name = "PlacaNome", Size = Vector3.new(22, 5, 0.5), CFrame = CFrame.new(x, 4.5, z - 11.8) * VIRAR, Color = modo.cor, Material = Enum.Material.SmoothPlastic, Parent = salaPasta })
		local icones = string.rep("👤", modo.jogadores)
		Util.placa(placaNome, modo.nome:upper() .. "  " .. icones, Enum.NormalId.Front)

		-- Placar do recorde desse modo (fica na parede do fundo, em cima)
		local placar = Util.peca({ Name = "Placar", Size = Vector3.new(22, 18, 0.5), CFrame = CFrame.new(x, 21, z - 11.8) * VIRAR, Color = Color3.fromRGB(25, 25, 40), Parent = salaPasta })

		-- Status em cima da sala (0/2, contagem...)
		local ancora = Util.peca({ Name = "AncoraStatus", Size = Vector3.one, Position = Vector3.new(x, 15, z + 4), Transparency = 1, CanCollide = false, CanQuery = false, Parent = salaPasta })
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(14, 4)
		bb.AlwaysOnTop = false
		bb.MaxDistance = 140
		bb.Parent = ancora
		local status = Instance.new("TextLabel")
		status.Size = UDim2.fromScale(1, 1)
		status.BackgroundTransparency = 1
		status.Font = Enum.Font.FredokaOne
		status.TextScaled = true
		status.TextColor3 = Color3.new(1, 1, 1)
		status.TextStrokeTransparency = 0
		status.Text = "0/" .. modo.jogadores
		status.Parent = bb

		table.insert(salas, {
			modo = modo,
			piso = piso,
			placar = placar,
			status = status,
			saida = Vector3.new(x, 3, z + 22), -- para onde o jogador vai ao sair
		})
	end

	-- Máquina de Ajudantes (um presente gigante)
	local maquina = caixaPresente(pasta, Vector3.new(-40, 0, 45), Vector3.new(12, 10, 12), Color3.fromRGB(30, 140, 70), DOURADO)
	maquina.Name = "MaquinaAjudantes"
	local placaMaq = Util.peca({ Name = "PlacaMaquina", Size = Vector3.new(18, 4, 0.5), Position = Vector3.new(-40, 15, 45), Color = VERMELHO, Parent = pasta })
	Util.placa(placaMaq, "✨ MÁQUINA DE AJUDANTES ✨", Enum.NormalId.Front)
	Util.placa(placaMaq, "✨ MÁQUINA DE AJUDANTES ✨", Enum.NormalId.Back)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Girar (" .. Config.CUSTO_GIRO .. " ⭐)"
	prompt.ObjectText = "Máquina de Ajudantes"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = maquina

	-- Placar de Renascimentos
	local placarRenasc = Util.peca({ Name = "PlacarRenascimentos", Size = Vector3.new(22, 20, 0.5), CFrame = CFrame.new(40, 12, 50), Color = Color3.fromRGB(25, 25, 40), Parent = pasta })
	Util.peca({ Name = "PostePlacar", Size = Vector3.new(1, 2, 1), Position = Vector3.new(40, 1, 50), Color = DOURADO, Parent = pasta })

	-- Decoração
	for _, pos in { Vector3.new(-90, 0, -10), Vector3.new(90, 0, -10), Vector3.new(-80, 0, 60), Vector3.new(80, 0, 70), Vector3.new(-15, 0, 70), Vector3.new(15, 0, 70) } do
		pinheiro(pasta, pos, 1.3)
	end
	local cores = { VERMELHO, Color3.fromRGB(40, 160, 80), Color3.fromRGB(60, 110, 230), Color3.fromRGB(160, 80, 220) }
	local rng = Random.new(7)
	for _ = 1, 26 do
		local pos = Vector3.new(rng:NextNumber(-130, 130), 0, rng:NextNumber(-20, 130))
		if math.abs(pos.X) > 22 or pos.Z > 80 then
			local t = rng:NextNumber(2, 4.5)
			caixaPresente(pasta, pos, Vector3.new(t, t, t), cores[rng:NextInteger(1, #cores)], DOURADO)
		end
	end

	return {
		salas = salas,
		promptMaquina = prompt,
		placarRenascimentos = placarRenasc,
		spawn = spawn,
	}
end

return MapaLobby
