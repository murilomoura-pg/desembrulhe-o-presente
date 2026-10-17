-- Constrói o pátio da Oficina do Papai Noel (layout inspirado no Peel THE Potato, Capítulo 1).
-- Visto de cima (o centro da montanha é o ponto 0,0; a montanha fica em Montanha.luau):
--
--              cerca de tela (norte)
--        ┌──────────────────────────────┐
--        │        ( MONTANHA de          │
--        │          presentes, na         │
--        │          plataforma redonda )  │
--        └───┐         ↓ setas        ┌───┘
--   caixotes │       [SPAWN]          │ caixotes
--            ├────────────────────────┤  ← frente aberta da Oficina dos Elfos
--            │  B1   B2  LOJA  B3  B4 │  ← 4 bancadas + Máquina de Presentes (loja)
--            │                  (COFRE)│  ← portão de fuga no fundo, à direita
--            └────────────────────────┘
--
-- Aqui ficam só as peças que FUNCIONAM no jogo. Os enfeites (galpão, cercas, neve,
-- luzes, floresta...) ficam em DecoracaoPartida.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Util = require(ReplicatedStorage.Compartilhado.Util)
local Natal = require(ServerStorage.Comum.Natal)
local Bancadas = require(script.Parent.Bancadas)
local DecoracaoPartida = require(script.Parent.DecoracaoPartida)

local MapaPartida = {}

local P = Config.PALETA

-- raio = raio da montanha (o pátio cresce junto com ela)
function MapaPartida.construir(raio: number)
	Natal.semente(1712)
	Natal.iluminacao()

	local pasta = Instance.new("Folder")
	pasta.Name = "MapaPartida"

	-- Medidas do layout (todas a partir do centro da montanha)
	local L = {
		raio = raio,
		zSpawn = raio + 32, -- spawn, olhando para a montanha (~2 s andando até ela)
		zFrente = raio + 46, -- frente aberta da Oficina dos Elfos
		zFundo = raio + 76, -- parede do fundo da oficina
		zBancadas = raio + 56, -- linha das 4 bancadas (~3 s andando da montanha)
		zCintura = raio + 12, -- onde o pátio fica da largura da oficina
		metadeGalpao = 35, -- a oficina tem 70 de largura
		alturaGalpao = 22,
		metadePatio = math.max(raio + 16, 40), -- metade da largura do pátio em volta da montanha
		zNorte = -(raio + 24), -- cerca atrás da montanha
		xPortao = 27, -- o cofre fica no fundo, à direita das bancadas
	}

	-- Plataforma redonda de pedra embaixo da montanha, com anel dourado na borda
	local disco = CFrame.Angles(0, 0, math.rad(90))
	Natal.solida(pasta, { Name = "AnelDourado", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.36, (raio + 6.2) * 2, (raio + 6.2) * 2), CFrame = CFrame.new(0, 0.12, 0) * disco, Color = P.dourado, Material = Enum.Material.Foil })
	Natal.solida(pasta, { Name = "Plataforma", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, (raio + 5) * 2, (raio + 5) * 2), CFrame = CFrame.new(0, 0.15, 0) * disco, Color = Color3.fromRGB(176, 182, 196), Material = Enum.Material.Slate })

	-- Spawn de frente para a montanha (o jogador nasce olhando para -Z)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, L.zSpawn)
	spawn.Color = P.vermelho
	spawn.Duration = 0
	spawn.Parent = pasta

	-- As 4 bancadas, em linha dentro da oficina, viradas para a frente aberta
	local posicoes = {}
	for _, x in { -21, -9, 9, 21 } do
		table.insert(posicoes, Vector3.new(x, 0, L.zBancadas))
	end
	Bancadas.construir(pasta, posicoes, -Vector3.zAxis)

	-- Máquina de Presentes (a Loja de Melhorias), no meio das bancadas
	local loja = Util.peca({ Name = "Loja", Size = Vector3.new(6.5, 4, 4.5), Position = Vector3.new(0, 2, L.zBancadas), Color = P.vermelho, Material = Enum.Material.SmoothPlastic, Parent = pasta })
	local promptLoja = Instance.new("ProximityPrompt")
	promptLoja.ActionText = "Abrir Loja"
	promptLoja.ObjectText = "Máquina de Presentes"
	promptLoja.HoldDuration = 0
	promptLoja.MaxActivationDistance = 12
	promptLoja.RequiresLineOfSight = false
	promptLoja.Parent = loja

	-- Caixotes com as melhorias (as mesmas da loja), encostados nas cercas perto do spawn
	local caixotes = {}
	local lugares = {
		{ -1, L.zCintura + 6 },
		{ -1, L.zCintura + 14 },
		{ -1, L.zCintura + 22 },
		{ 1, L.zCintura + 10 },
		{ 1, L.zCintura + 18 },
	}
	for i, m in Config.MELHORIAS do
		local lugar = lugares[i]
		if not lugar then
			break
		end
		local pos = Vector3.new(lugar[1] * (L.metadeGalpao - 3.5), 0, lugar[2])
		local modelo = Instance.new("Model")
		modelo.Name = "Caixote_" .. m.id
		modelo:SetAttribute("Melhoria", m.id)
		modelo.Parent = pasta
		local caixa = Natal.solida(modelo, { Name = "Caixa", Size = Vector3.new(3.6, 3.6, 3.6), CFrame = CFrame.lookAt(pos + Vector3.yAxis * 1.8, Vector3.new(0, 1.8, pos.Z)), Color = P.madeira, Material = Enum.Material.WoodPlanks })
		caixa.CanTouch = true
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Ver na Loja"
		prompt.ObjectText = m.nome
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = caixa
		table.insert(caixotes, { id = m.id, caixa = caixa, prompt = prompt })
	end

	-- Portão de fuga: a porta redonda do COFRE do Papai Noel, no fundo da oficina.
	-- (o nome "Portao", o "Cadeado" e o botão continuam os mesmos que a fuga usa)
	local diametro = 13.2
	local zPorta = L.zFundo - 0.75 - 0.65
	local centroPorta = Vector3.new(L.xPortao, diametro / 2, zPorta)
	local portao = Util.peca({
		Name = "Portao",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, diametro, diametro),
		CFrame = CFrame.fromMatrix(centroPorta, Vector3.zAxis, Vector3.yAxis),
		Color = Color3.fromRGB(150, 156, 170),
		Material = Enum.Material.DiamondPlate,
		Parent = pasta,
	})
	local cadeado = Util.peca({
		Name = "Cadeado",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 4.6, 4.6),
		CFrame = CFrame.fromMatrix(centroPorta - Vector3.zAxis * 1, Vector3.zAxis, Vector3.yAxis),
		Color = P.dourado,
		Material = Enum.Material.Foil,
		CanCollide = false,
		Parent = pasta,
	})
	-- (formato redondo primeiro, tamanho depois, para o Roblox não mexer no tamanho)
	portao.Shape = Enum.PartType.Cylinder
	portao.Size = Vector3.new(1.2, diametro, diametro)
	cadeado.Shape = Enum.PartType.Cylinder
	cadeado.Size = Vector3.new(0.8, 4.6, 4.6)
	local placaPortao = Util.peca({ Name = "PlacaPortao", Size = Vector3.new(15, 2.8, 0.4), Position = Vector3.new(L.xPortao, diametro + 2.4, L.zFundo - 1), Color = P.madeira, Material = Enum.Material.WoodPlanks, Parent = pasta })
	Util.placa(placaPortao, "🔒 SAÍDA — PRECISA DA CHAVE", Enum.NormalId.Front, P.luz)
	local promptPortao = Instance.new("ProximityPrompt")
	promptPortao.ActionText = "Usar a Chave 🔑"
	promptPortao.ObjectText = "Cofre do Papai Noel"
	promptPortao.HoldDuration = 1
	promptPortao.MaxActivationDistance = 16
	promptPortao.RequiresLineOfSight = false
	promptPortao.Enabled = false
	promptPortao.Parent = cadeado
	-- Brilho dourado que aparece quando alguém acha a chave
	local destaquePortao = Instance.new("Highlight")
	destaquePortao.FillColor = P.dourado
	destaquePortao.OutlineColor = P.luz
	destaquePortao.FillTransparency = 0.72
	destaquePortao.OutlineTransparency = 0
	destaquePortao.Enabled = false
	destaquePortao.Parent = portao

	-- A porta do cofre abre girando na dobradiça da direita (para dentro da oficina)
	local dobradica = CFrame.new(L.xPortao + diametro / 2, centroPorta.Y, zPorta)
	local relativo = dobradica:Inverse() * portao.CFrame
	local function abrirPortao()
		local giro = Instance.new("NumberValue")
		giro.Changed:Connect(function(a)
			portao.CFrame = dobradica * CFrame.Angles(0, math.rad(-80 * a), 0) * relativo
		end)
		local t = TweenService:Create(giro, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = 1 })
		t.Completed:Connect(function()
			giro:Destroy()
		end)
		t:Play()
	end

	-- Barreiras invisíveis (ninguém pula a cerca nem sai pelo cofre antes da hora)
	local W, G = L.metadePatio, L.metadeGalpao
	local function barreira(a: Vector3, b: Vector3)
		local meio = (a + b) / 2
		Util.peca({ Name = "Barreira", Size = Vector3.new(2, 200, (b - a).Magnitude + 2), CFrame = CFrame.lookAt(meio + Vector3.yAxis * 100, b + Vector3.yAxis * 100), Transparency = 1, CanQuery = false, Parent = pasta })
	end
	for _, lado in { -1, 1 } do
		barreira(Vector3.new(lado * W, 0, L.zNorte), Vector3.new(lado * W, 0, L.zCintura))
		barreira(Vector3.new(lado * W, 0, L.zCintura), Vector3.new(lado * G, 0, L.zCintura))
		barreira(Vector3.new(lado * G, 0, L.zCintura), Vector3.new(lado * G, 0, L.zFundo))
	end
	barreira(Vector3.new(-W, 0, L.zNorte), Vector3.new(W, 0, L.zNorte))
	barreira(Vector3.new(-G, 0, L.zFundo + 3), Vector3.new(G, 0, L.zFundo + 3))

	-- Decoração de Natal (oficina, cercas, neve, luzes, floresta...)
	L.portao = portao
	L.cadeado = cadeado
	L.placaPortao = placaPortao
	L.loja = loja
	L.caixotes = caixotes
	L.bancadas = Bancadas.lista
	L.diametroPorta = diametro
	DecoracaoPartida.construir(pasta, L)

	pasta.Parent = workspace

	return {
		promptLoja = promptLoja,
		promptPortao = promptPortao,
		portao = portao,
		cadeado = cadeado,
		destaquePortao = destaquePortao,
		placaPortao = placaPortao,
		spawn = spawn,
		caixotes = caixotes,
		abrirPortao = abrirPortao,
	}
end

return MapaPartida
