-- Constrói o mapa do Lobby (vila de Natal com as 4 salas, placares e a máquina de ajudantes).
-- Tudo é criado por código quando o servidor liga.
-- Aqui ficam só as peças que FUNCIONAM no jogo (pisos das salas, placares, máquina, spawn).
-- Os enfeites (chalés, árvore gigante, floresta, neve...) ficam em DecoracaoLobby.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Util = require(ReplicatedStorage.Compartilhado.Util)
local Natal = require(ServerStorage.Comum.Natal)
local DecoracaoLobby = require(script.Parent.DecoracaoLobby)

local MapaLobby = {}

local P = Config.PALETA
local PLACAR_ESCURO = Color3.fromRGB(24, 30, 44)
-- Gira 180° para a "frente" da placa ficar virada para quem está na praça
local VIRAR = CFrame.Angles(0, math.pi, 0)

-- Presente gigante (a Máquina de Ajudantes)
local function caixaPresente(pasta: Instance, pos: Vector3, tamanho: Vector3, cor: Color3, corLaco: Color3)
	local caixa = Util.peca({ Name = "Caixa", Size = tamanho, Position = pos + Vector3.new(0, tamanho.Y / 2, 0), Color = cor, Parent = pasta })
	Util.peca({ Name = "Laco1", Size = Vector3.new(tamanho.X + 0.1, tamanho.Y + 0.1, tamanho.Z * 0.18), Position = caixa.Position, Color = corLaco, Material = Enum.Material.Foil, CanCollide = false, Parent = pasta })
	Util.peca({ Name = "Laco2", Size = Vector3.new(tamanho.X * 0.18, tamanho.Y + 0.1, tamanho.Z + 0.1), Position = caixa.Position, Color = corLaco, Material = Enum.Material.Foil, CanCollide = false, Parent = pasta })
	return caixa
end

-- Retorna as referências que os outros scripts precisam
function MapaLobby.construir()
	Natal.semente(2512)
	Natal.iluminacao()

	local pasta = Instance.new("Folder")
	pasta.Name = "MapaLobby"

	-- O chão agora é TERRENO de neve (feito no DecoracaoLobby), sempre na altura 0.

	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, 20)
	spawn.Color = P.vermelho
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.Parent = pasta

	-- Título (placa grande no alto, atrás das casas, para não ficar escondida pelos telhados)
	local titulo = Util.peca({ Name = "Titulo", Size = Vector3.new(70, 14, 2), CFrame = CFrame.new(0, 61, -78) * VIRAR, Color = P.vermelho, Parent = pasta })
	local textoTitulo = Util.placa(titulo, "🎁 DESEMBRULHE O PRESENTE 🎁", Enum.NormalId.Front, Color3.new(1, 1, 1))
	-- Placa enorme: menos pixels por stud deixa as letras grandes (o texto tem tamanho máximo)
	local guiTitulo = textoTitulo.Parent :: SurfaceGui
	guiTitulo.PixelsPerStud = 12

	-- Salas (cada uma vira um chalé de madeira aberto na frente)
	local salas = {}
	local infoDecoracao = {}
	local espacamento = 34
	local inicioX = -espacamento * (#Config.MODOS - 1) / 2
	for i, modo in Config.MODOS do
		local x = inicioX + (i - 1) * espacamento
		local z = -40
		local salaPasta = Instance.new("Folder")
		salaPasta.Name = "Sala_" .. modo.nome
		salaPasta.Parent = pasta

		local piso = Util.peca({ Name = "Piso", Size = Vector3.new(24, 1, 24), Position = Vector3.new(x, 0.5, z), Color = modo.cor, Material = Enum.Material.Neon, Transparency = 0.25, Parent = salaPasta })
		-- Paredes de madeira (a frente fica aberta)
		Util.peca({ Name = "ParedeFundo", Size = Vector3.new(26, 32, 2), Position = Vector3.new(x, 16, z - 13), Color = P.madeira, Material = Enum.Material.WoodPlanks, Parent = salaPasta })
		Util.peca({ Name = "ParedeEsq", Size = Vector3.new(2, 12, 26), Position = Vector3.new(x - 13, 6, z), Color = P.madeira, Material = Enum.Material.WoodPlanks, Parent = salaPasta })
		Util.peca({ Name = "ParedeDir", Size = Vector3.new(2, 12, 26), Position = Vector3.new(x + 13, 6, z), Color = P.madeira, Material = Enum.Material.WoodPlanks, Parent = salaPasta })
		-- Faixa na cor da sala no topo das paredes laterais
		Util.peca({ Name = "FaixaEsq", Size = Vector3.new(2.4, 1, 26.4), Position = Vector3.new(x - 13, 12.5, z), Color = modo.cor, Material = Enum.Material.Neon, Parent = salaPasta })
		Util.peca({ Name = "FaixaDir", Size = Vector3.new(2.4, 1, 26.4), Position = Vector3.new(x + 13, 12.5, z), Color = modo.cor, Material = Enum.Material.Neon, Parent = salaPasta })

		-- Placa de madeira com o nome da sala
		local placaNome = Util.peca({ Name = "PlacaNome", Size = Vector3.new(22, 5, 0.5), CFrame = CFrame.new(x, 4.5, z - 11.8) * VIRAR, Color = P.madeiraEscura, Material = Enum.Material.WoodPlanks, Parent = salaPasta })
		local icones = string.rep("👤", modo.jogadores)
		Util.placa(placaNome, modo.nome:upper() .. "  " .. icones, Enum.NormalId.Front, P.luz)

		-- Placar do recorde desse modo (fica na parede do fundo, em cima)
		local placar = Util.peca({ Name = "Placar", Size = Vector3.new(22, 18, 0.5), CFrame = CFrame.new(x, 21, z - 11.8) * VIRAR, Color = PLACAR_ESCURO, Parent = salaPasta })

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
		table.insert(infoDecoracao, { x = x, z = z, modo = modo, placar = placar, placaNome = placaNome })
	end

	-- Máquina de Ajudantes (um presente gigante na porta da Fábrica de Ajudantes)
	local maquina = caixaPresente(pasta, Vector3.new(-40, 0, 45), Vector3.new(12, 10, 12), P.vermelho, P.dourado)
	maquina.Name = "MaquinaAjudantes"
	local placaMaq = Util.peca({ Name = "PlacaMaquina", Size = Vector3.new(18, 4, 0.5), Position = Vector3.new(-40, 15, 45), Color = P.madeira, Material = Enum.Material.WoodPlanks, Parent = pasta })
	Util.placa(placaMaq, "✨ MÁQUINA DE AJUDANTES ✨", Enum.NormalId.Front, P.luz)
	Util.placa(placaMaq, "✨ MÁQUINA DE AJUDANTES ✨", Enum.NormalId.Back, P.luz)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Girar (" .. Config.CUSTO_GIRO .. " ⭐)"
	prompt.ObjectText = "Máquina de Ajudantes"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = maquina

	-- Placar de Renascimentos
	local placarRenasc = Util.peca({ Name = "PlacarRenascimentos", Size = Vector3.new(22, 20, 0.5), CFrame = CFrame.new(40, 12, 50), Color = PLACAR_ESCURO, Parent = pasta })
	Util.peca({ Name = "PostePlacar", Size = Vector3.new(1, 2, 1), Position = Vector3.new(40, 1, 50), Color = P.dourado, Parent = pasta })

	-- Decoração de Natal (terreno, chalés, árvore gigante, fábrica, floresta...)
	DecoracaoLobby.construir(pasta, {
		salas = infoDecoracao,
		maquina = maquina,
		placaMaquina = placaMaq,
		placarRenascimentos = placarRenasc,
		titulo = titulo,
		spawn = spawn,
	})

	pasta.Parent = workspace -- coloca tudo de uma vez (mais rápido)

	return {
		salas = salas,
		promptMaquina = prompt,
		placarRenascimentos = placarRenasc,
		spawn = spawn,
	}
end

return MapaLobby
