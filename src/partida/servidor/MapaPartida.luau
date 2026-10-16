-- Constrói o pátio da Oficina do Papai Noel: muros, Mesa de Desembrulhar, Loja e o Portão trancado.
-- A montanha de presentes é feita em outro arquivo (Montanha.luau).
-- Aqui ficam só as peças que FUNCIONAM no jogo. Os enfeites de Natal (fachada da oficina,
-- luzes, guirlandas, floresta, neve...) ficam em DecoracaoPartida.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Util = require(ReplicatedStorage.Compartilhado.Util)
local Natal = require(ServerStorage.Comum.Natal)
local DecoracaoPartida = require(script.Parent.DecoracaoPartida)

local MapaPartida = {}

local P = Config.PALETA
local VERDE_MESA = Color3.fromRGB(60, 200, 110)

-- raio = raio da montanha (o pátio cresce junto com ela)
function MapaPartida.construir(raio: number)
	Natal.semente(1712)
	Natal.iluminacao()

	local pasta = Instance.new("Folder")
	pasta.Name = "MapaPartida"

	local meio = math.floor(raio + 55)
	local alturaMuro = 26

	-- O chão agora é TERRENO de neve (feito no DecoracaoPartida), sempre na altura 0.

	-- Muros de pedra com neve em cima (o muro norte tem um buraco para o portão)
	local larguraPortao = 30
	local function muro(nome: string, tamanho: Vector3, pos: Vector3)
		Util.peca({ Name = nome, Size = tamanho, Position = pos, Color = P.pedra, Material = Enum.Material.Cobblestone, Parent = pasta })
		Util.peca({ Name = nome .. "_Topo", Size = Vector3.new(tamanho.X + 0.6, 1.5, tamanho.Z + 0.6), Position = pos + Vector3.new(0, tamanho.Y / 2 + 0.75, 0), Color = P.neve, Material = Enum.Material.Snow, Parent = pasta })
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

	-- Portão trancado (portão de madeira da oficina, com cadeado dourado)
	local portao = Util.peca({ Name = "Portao", Size = Vector3.new(larguraPortao, alturaMuro - 4, 3), Position = Vector3.new(0, (alturaMuro - 4) / 2, -meio), Color = P.madeira, Material = Enum.Material.WoodPlanks, Parent = pasta })
	local cadeado = Util.peca({ Name = "Cadeado", Size = Vector3.new(4, 5, 1), Position = portao.Position + Vector3.new(0, 0, 2), Color = P.dourado, Material = Enum.Material.Foil, CanCollide = false, Parent = pasta })
	local placaPortao = Util.peca({ Name = "PlacaPortao", Size = Vector3.new(28, 5, 0.5), Position = Vector3.new(0, alturaMuro + 4, -meio + 1), Color = P.madeira, Material = Enum.Material.WoodPlanks, Parent = pasta })
	Util.placa(placaPortao, "🔒 SAÍDA — PRECISA DA CHAVE", Enum.NormalId.Back, P.luz)
	local promptPortao = Instance.new("ProximityPrompt")
	promptPortao.ActionText = "Usar a Chave 🔑"
	promptPortao.ObjectText = "Portão"
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

	-- Spawn (no lado sul)
	local zSul = meio - 18
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, zSul)
	spawn.Color = P.vermelho
	spawn.Duration = 0
	spawn.Parent = pasta

	-- Mesa de Desembrulhar (esquerda do spawn): bancada de madeira com tampo verde aceso
	local mesaPos = Vector3.new(-26, 0, zSul - 4)
	Util.peca({ Name = "MesaDesembrulhar", Size = Vector3.new(16, 3.5, 7), Position = mesaPos + Vector3.new(0, 1.75, 0), Color = P.madeiraClara, Material = Enum.Material.Wood, Parent = pasta })
	Util.peca({ Name = "TampoMesa", Size = Vector3.new(16.4, 0.4, 7.4), Position = mesaPos + Vector3.new(0, 3.7, 0), Color = VERDE_MESA, Material = Enum.Material.Neon, CanCollide = false, Parent = pasta })
	local placaMesa = Util.peca({ Name = "PlacaMesa", Size = Vector3.new(16, 4, 0.5), Position = mesaPos + Vector3.new(0, 9, -3), Color = P.madeira, Material = Enum.Material.WoodPlanks, Parent = pasta })
	Util.placa(placaMesa, "✂️ MESA DE DESEMBRULHAR", Enum.NormalId.Front, P.luz)
	Util.placa(placaMesa, "✂️ MESA DE DESEMBRULHAR", Enum.NormalId.Back, P.luz)
	Util.peca({ Name = "AreaMesa", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, Config.RAIO_MESA * 2, Config.RAIO_MESA * 2), CFrame = CFrame.new(mesaPos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = VERDE_MESA, Material = Enum.Material.Neon, Transparency = 0.7, CanCollide = false, CanQuery = false, Parent = pasta })
	Natal.luz(placaMesa, Color3.fromRGB(150, 255, 180), 20, 1.5)

	-- Loja (direita do spawn): barraquinha de mercado natalino
	local lojaPos = Vector3.new(26, 0, zSul - 4)
	local balcao = Util.peca({ Name = "Loja", Size = Vector3.new(14, 4, 5), Position = lojaPos + Vector3.new(0, 2, 0), Color = P.vermelho, Material = Enum.Material.Wood, Parent = pasta })
	Util.peca({ Name = "TampoLoja", Size = Vector3.new(14.4, 0.4, 5.4), Position = lojaPos + Vector3.new(0, 4.2, 0), Color = P.dourado, Material = Enum.Material.Foil, Parent = pasta })
	local toldo = Util.peca({ Name = "ToldoLoja", Size = Vector3.new(16, 0.6, 8), CFrame = CFrame.new(lojaPos + Vector3.new(0, 11, 1)) * CFrame.Angles(math.rad(-12), 0, 0), Color = P.vermelho, Material = Enum.Material.Fabric, CanCollide = false, Parent = pasta })
	local colunas = {}
	for _, x in { -7, 7 } do
		table.insert(colunas, Util.peca({ Name = "ColunaLoja", Size = Vector3.new(0.8, 11, 0.8), Position = lojaPos + Vector3.new(x, 5.5, -2), Color = P.neve, Parent = pasta }))
	end
	local placaLoja = Util.peca({ Name = "PlacaLoja", Size = Vector3.new(14, 3.5, 0.5), Position = lojaPos + Vector3.new(0, 8, -2), Color = P.vermelhoEscuro, Parent = pasta })
	Util.placa(placaLoja, "🛒 LOJA DE MELHORIAS", Enum.NormalId.Front)
	Util.placa(placaLoja, "🛒 LOJA DE MELHORIAS", Enum.NormalId.Back)
	local promptLoja = Instance.new("ProximityPrompt")
	promptLoja.ActionText = "Abrir Loja"
	promptLoja.ObjectText = "Melhorias"
	promptLoja.HoldDuration = 0
	promptLoja.MaxActivationDistance = 14
	promptLoja.RequiresLineOfSight = false
	promptLoja.Parent = balcao

	-- Decoração de Natal (terreno, oficina, muros enfeitados, postes, floresta...)
	DecoracaoPartida.construir(pasta, {
		raio = raio,
		meio = meio,
		alturaMuro = alturaMuro,
		larguraPortao = larguraPortao,
		zSul = zSul,
		mesaPos = mesaPos,
		lojaPos = lojaPos,
		portao = portao,
		cadeado = cadeado,
		placaPortao = placaPortao,
		placaMesa = placaMesa,
		placaLoja = placaLoja,
		toldo = toldo,
		colunas = colunas,
	})

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
