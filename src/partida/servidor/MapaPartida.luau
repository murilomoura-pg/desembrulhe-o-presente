-- Constrói o pátio da Fábrica do Papai Noel: muros, Mesa de Desembrulhar, Loja e o Portão trancado.
-- A montanha de presentes é feita em outro arquivo (Montanha.luau).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Util = require(ReplicatedStorage.Compartilhado.Util)
local Natal = require(ServerStorage.Comum.Natal)

local MapaPartida = {}

local NEVE = Color3.fromRGB(240, 246, 255)
local TIJOLO = Color3.fromRGB(150, 50, 45)
local DOURADO = Color3.fromRGB(255, 200, 50)
local VERMELHO = Color3.fromRGB(200, 30, 40)

local function luz(pai: Instance, cor: Color3, alcance: number)
	local l = Instance.new("PointLight")
	l.Color = cor
	l.Range = alcance
	l.Brightness = 1.5
	l.Parent = pai
end

local function poste(pasta: Instance, pos: Vector3)
	Util.peca({ Name = "Poste", Size = Vector3.new(1, 14, 1), Position = pos + Vector3.new(0, 7, 0), Color = Color3.fromRGB(40, 40, 50), Material = Enum.Material.Metal, Parent = pasta })
	local lampada = Util.peca({ Name = "Lampada", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.5, Position = pos + Vector3.new(0, 14.5, 0), Color = Color3.fromRGB(255, 230, 170), Material = Enum.Material.Neon, CanCollide = false, Parent = pasta })
	luz(lampada, Color3.fromRGB(255, 220, 160), 40)
end

-- raio = raio da montanha (o pátio cresce junto com ela)
function MapaPartida.construir(raio: number)
	Natal.iluminacao()

	local pasta = Instance.new("Folder")
	pasta.Name = "MapaPartida"

	local meio = math.floor(raio + 55)
	local alturaMuro = 26

	Util.peca({ Name = "Chao", Size = Vector3.new(meio * 2 + 20, 2, meio * 2 + 20), Position = Vector3.new(0, -1, 0), Color = NEVE, Material = Enum.Material.Snow, Parent = pasta })

	-- Muros (o muro norte tem um buraco para o portão)
	local larguraPortao = 30
	local function muro(nome: string, tamanho: Vector3, pos: Vector3)
		Util.peca({ Name = nome, Size = tamanho, Position = pos, Color = TIJOLO, Material = Enum.Material.Brick, Parent = pasta })
		Util.peca({ Name = nome .. "_Topo", Size = Vector3.new(tamanho.X + 0.6, 1.5, tamanho.Z + 0.6), Position = pos + Vector3.new(0, tamanho.Y / 2 + 0.75, 0), Color = NEVE, Material = Enum.Material.Snow, Parent = pasta })
	end
	muro("MuroSul", Vector3.new(meio * 2, alturaMuro, 4), Vector3.new(0, alturaMuro / 2, meio))
	muro("MuroLeste", Vector3.new(4, alturaMuro, meio * 2), Vector3.new(meio, alturaMuro / 2, 0))
	muro("MuroOeste", Vector3.new(4, alturaMuro, meio * 2), Vector3.new(-meio, alturaMuro / 2, 0))
	local ladoNorte = (meio * 2 - larguraPortao) / 2
	muro("MuroNorteEsq", Vector3.new(ladoNorte, alturaMuro, 4), Vector3.new(-meio + ladoNorte / 2, alturaMuro / 2, -meio))
	muro("MuroNorteDir", Vector3.new(ladoNorte, alturaMuro, 4), Vector3.new(meio - ladoNorte / 2, alturaMuro / 2, -meio))
	muro("MuroNorteCima", Vector3.new(larguraPortao, 4, 4), Vector3.new(0, alturaMuro - 2, -meio))
	-- Barreira invisível para ninguém pular o muro
	for _, dados in {
		{ Vector3.new(meio * 2, 200, 2), Vector3.new(0, 100, meio + 2) },
		{ Vector3.new(meio * 2, 200, 2), Vector3.new(0, 100, -meio - 2) },
		{ Vector3.new(2, 200, meio * 2), Vector3.new(meio + 2, 100, 0) },
		{ Vector3.new(2, 200, meio * 2), Vector3.new(-meio - 2, 100, 0) },
	} do
		Util.peca({ Name = "Barreira", Size = dados[1], Position = dados[2], Transparency = 1, CanQuery = false, Parent = pasta })
	end

	-- Portão trancado
	local portao = Util.peca({ Name = "Portao", Size = Vector3.new(larguraPortao, alturaMuro - 4, 3), Position = Vector3.new(0, (alturaMuro - 4) / 2, -meio), Color = Color3.fromRGB(70, 70, 85), Material = Enum.Material.DiamondPlate, Parent = pasta })
	local cadeado = Util.peca({ Name = "Cadeado", Size = Vector3.new(4, 5, 1), Position = portao.Position + Vector3.new(0, 0, 2), Color = DOURADO, Material = Enum.Material.Foil, CanCollide = false, Parent = pasta })
	local placaPortao = Util.peca({ Name = "PlacaPortao", Size = Vector3.new(28, 5, 0.5), Position = Vector3.new(0, alturaMuro + 4, -meio + 1), Color = VERMELHO, Parent = pasta })
	Util.placa(placaPortao, "🔒 SAÍDA — PRECISA DA CHAVE", Enum.NormalId.Back)
	local promptPortao = Instance.new("ProximityPrompt")
	promptPortao.ActionText = "Usar a Chave 🔑"
	promptPortao.ObjectText = "Portão"
	promptPortao.HoldDuration = 1
	promptPortao.MaxActivationDistance = 16
	promptPortao.RequiresLineOfSight = false
	promptPortao.Enabled = false
	promptPortao.Parent = cadeado
	local destaquePortao = Instance.new("Highlight")
	destaquePortao.FillColor = DOURADO
	destaquePortao.OutlineColor = DOURADO
	destaquePortao.FillTransparency = 0.6
	destaquePortao.Enabled = false
	destaquePortao.Parent = portao

	-- Spawn (no lado sul)
	local zSul = meio - 18
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, zSul)
	spawn.Color = VERMELHO
	spawn.Duration = 0
	spawn.Parent = pasta

	-- Mesa de Desembrulhar (esquerda do spawn)
	local mesaPos = Vector3.new(-26, 0, zSul - 4)
	Util.peca({ Name = "MesaDesembrulhar", Size = Vector3.new(16, 3.5, 7), Position = mesaPos + Vector3.new(0, 1.75, 0), Color = Color3.fromRGB(110, 70, 40), Material = Enum.Material.Wood, Parent = pasta })
	Util.peca({ Name = "TampoMesa", Size = Vector3.new(16.4, 0.4, 7.4), Position = mesaPos + Vector3.new(0, 3.7, 0), Color = Color3.fromRGB(60, 200, 110), Material = Enum.Material.Neon, CanCollide = false, Parent = pasta })
	local placaMesa = Util.peca({ Name = "PlacaMesa", Size = Vector3.new(16, 4, 0.5), Position = mesaPos + Vector3.new(0, 9, -3), Color = Color3.fromRGB(40, 150, 80), Parent = pasta })
	Util.placa(placaMesa, "✂️ MESA DE DESEMBRULHAR", Enum.NormalId.Front)
	Util.placa(placaMesa, "✂️ MESA DE DESEMBRULHAR", Enum.NormalId.Back)
	Util.peca({ Name = "AreaMesa", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, Config.RAIO_MESA * 2, Config.RAIO_MESA * 2), CFrame = CFrame.new(mesaPos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 200, 110), Material = Enum.Material.Neon, Transparency = 0.7, CanCollide = false, CanQuery = false, Parent = pasta })
	luz(placaMesa, Color3.fromRGB(150, 255, 180), 25)

	-- Loja (direita do spawn)
	local lojaPos = Vector3.new(26, 0, zSul - 4)
	local balcao = Util.peca({ Name = "Loja", Size = Vector3.new(14, 4, 5), Position = lojaPos + Vector3.new(0, 2, 0), Color = VERMELHO, Parent = pasta })
	Util.peca({ Name = "TampoLoja", Size = Vector3.new(14.4, 0.4, 5.4), Position = lojaPos + Vector3.new(0, 4.2, 0), Color = DOURADO, Material = Enum.Material.Foil, Parent = pasta })
	Util.peca({ Name = "ToldoLoja", Size = Vector3.new(16, 0.6, 8), CFrame = CFrame.new(lojaPos + Vector3.new(0, 11, 1)) * CFrame.Angles(math.rad(-12), 0, 0), Color = Color3.fromRGB(240, 240, 240), CanCollide = false, Parent = pasta })
	for _, x in { -7, 7 } do
		Util.peca({ Name = "ColunaLoja", Size = Vector3.new(0.8, 11, 0.8), Position = lojaPos + Vector3.new(x, 5.5, -2), Color = DOURADO, Parent = pasta })
	end
	local placaLoja = Util.peca({ Name = "PlacaLoja", Size = Vector3.new(14, 3.5, 0.5), Position = lojaPos + Vector3.new(0, 8, -2), Color = Color3.fromRGB(150, 20, 30), Parent = pasta })
	Util.placa(placaLoja, "🛒 LOJA DE MELHORIAS", Enum.NormalId.Front)
	Util.placa(placaLoja, "🛒 LOJA DE MELHORIAS", Enum.NormalId.Back)
	local promptLoja = Instance.new("ProximityPrompt")
	promptLoja.ActionText = "Abrir Loja"
	promptLoja.ObjectText = "Melhorias"
	promptLoja.HoldDuration = 0
	promptLoja.MaxActivationDistance = 14
	promptLoja.RequiresLineOfSight = false
	promptLoja.Parent = balcao

	-- Postes de luz em volta da montanha
	for i = 0, 7 do
		local a = math.rad(i * 45 + 22.5)
		poste(pasta, Vector3.new(math.cos(a) * (raio + 22), 0, math.sin(a) * (raio + 22)))
	end

	pasta.Parent = workspace

	return {
		mesaPos = mesaPos,
		promptLoja = promptLoja,
		promptPortao = promptPortao,
		portao = portao,
		cadeado = cadeado,
		destaquePortao = destaquePortao,
		placaPortao = placaPortao,
		spawn = spawn,
	}
end

return MapaPartida
