-- 🎄 Decoração de Natal do LOBBY (só visual: não muda nada no jogo).
-- Monta: chão de neve com caminhos, chalés das salas, Fábrica de Ajudantes,
-- Árvore Gigante, molduras dos placares, postes, bonecos de neve e a floresta em volta.
-- As peças que funcionam (pisos, placares, máquina, spawn) são feitas no MapaLobby
-- e aqui a gente só "veste" elas, sem mudar posição, tamanho nem nome.

local ServerStorage = game:GetService("ServerStorage")

local Natal = require(ServerStorage.Comum.Natal)

local DecoracaoLobby = {}

local P = Natal.P
local CIMA = Vector3.yAxis
local TAU = math.pi * 2

-- Lugares importantes do lobby (iguais aos do MapaLobby)
local SPAWN = Vector3.new(0, 0, 20)
local ARVORE = Vector3.new(0, 0, 66)
local PLACAR = Vector3.new(40, 0, 50)
local VILA = Vector3.new(0, 0, 20) -- centro da vila (a floresta fica em volta)

-- Giro (em Y) para a frente (-Z) de um enfeite olhar de "de" para "para"
local function giroPara(de: Vector3, para: Vector3): number
	local d = para - de
	return math.atan2(-d.X, -d.Z)
end

------------------------------------------------------------------------
-- Áreas onde NÃO pode ter árvore (caminhos e coisas que o jogador usa)
------------------------------------------------------------------------
local RETANGULOS = {
	{ -76, 76, -86, -6 }, -- salas, casas, título e a rua da frente (xMin, xMax, zMin, zMax)
}
local CIRCULOS = {
	{ SPAWN, 22 },
	{ ARVORE, 32 },
	{ Vector3.new(-54, 0, 54), 34 }, -- máquina + fábrica
	{ PLACAR, 20 },
	{ Vector3.new(-18, 0, 33), 10 }, -- caminho até a máquina
	{ Vector3.new(20, 0, 35), 10 }, -- caminho até o placar
}
-- Montinhos de neve (x, z, raio): também ficam sem árvore em cima
local MONTINHOS = {
	{ -84, 18, 10 }, { 74, 12, 9 }, { -28, 98, 12 }, { 62, 96, 11 }, { 98, -46, 12 }, { -100, -48, 13 },
	{ -64, 112, 10 }, { 104, 78, 12 }, { -124, 34, 11 }, { 124, -6, 10 }, { 20, 128, 12 }, { -90, 82, 9 },
}
for _, m in MONTINHOS do
	table.insert(CIRCULOS, { Vector3.new(m[1], 0, m[2]), m[3] })
end

local function livre(p: Vector3, folga: number): boolean
	for _, r in RETANGULOS do
		if p.X > r[1] - folga and p.X < r[2] + folga and p.Z > r[3] - folga and p.Z < r[4] + folga then
			return false
		end
	end
	for _, c in CIRCULOS do
		if (Vector3.new(p.X, 0, p.Z) - c[1]).Magnitude < c[2] + folga then
			return false
		end
	end
	return true
end

------------------------------------------------------------------------
-- TERRENO: chão de neve, caminhos, montinhos e montanhas no horizonte
------------------------------------------------------------------------
local function terreno()
	Natal.prepararTerreno()
	Natal.chaoDeNeve(0, 20, 480, 480)

	-- Caminhos de neve batida
	Natal.caminho(Vector3.new(-80, 0, -17), Vector3.new(80, 0, -17), 12) -- rua em frente às salas
	Natal.praca(SPAWN, 14)
	Natal.caminho(Vector3.new(0, 0, 8), Vector3.new(0, 0, -12), 8)
	Natal.caminho(Vector3.new(0, 0, 30), Vector3.new(0, 0, 46), 8)
	Natal.praca(ARVORE, 22)
	Natal.caminho(Vector3.new(-8, 0, 26), Vector3.new(-31, 0, 41), 8)
	Natal.caminho(Vector3.new(8, 0, 26), Vector3.new(34, 0, 42), 8)
	Natal.praca(Vector3.new(-44, 0, 40), 10) -- frente da máquina

	-- Montinhos de neve (só onde ninguém precisa passar)
	for _, m in MONTINHOS do
		Natal.montinho(Vector3.new(m[1], 0, m[2]), m[3])
	end

	-- Montanhas nevadas em volta (fundo do cenário e limite natural do mapa)
	local pontos = {}
	for i = 0, 31 do
		local a = i * TAU / 32
		local r = 196 + Natal.sortear(-10, 12)
		table.insert(pontos, Vector3.new(math.cos(a) * r, 0, 20 + math.sin(a) * r))
	end
	Natal.montanhas(pontos, 30, 50)
end

------------------------------------------------------------------------
-- CHALÉ DE CADA SALA
------------------------------------------------------------------------
-- A parede do fundo vira a frente de uma casa de madeira, com telhado nevado
-- (bem acima do placar, para não esconder nada). A cor da sala aparece só nos
-- detalhes: faixa, moldura da placa e bandeirinhas.
local function chaleDaSala(dec: Instance, s: { [string]: any })
	local m = Natal.modelo(dec, "Chale_" .. s.modo.nome)
	local x, z = s.x, s.z
	local zFrente = z - 12 -- frente da parede do fundo
	local zTras = z - 28 -- fundo da casa
	local cor = s.modo.cor

	-- Corpo da casa atrás da parede do fundo
	Natal.solida(m, { Name = "Casa", Size = Vector3.new(26, 32, 14), CFrame = CFrame.new(x, 16, z - 21), Color = P.madeira, Material = Enum.Material.WoodPlanks })
	Natal.solida(m, { Name = "Fundacao", Size = Vector3.new(26.8, 1.6, 14.8), CFrame = CFrame.new(x, 0.8, z - 21), Color = P.pedra, Material = Enum.Material.Cobblestone })
	for _, lado in { -1, 1 } do
		Natal.peca(m, { Name = "BasePedra", Size = Vector3.new(2.6, 1.8, 26.6), CFrame = CFrame.new(x + lado * 13, 0.9, z), Color = P.pedra, Material = Enum.Material.Cobblestone })
		-- Toras nos cantos
		Natal.cilindro(m, Vector3.new(x + lado * 13.3, 0, zFrente - 0.6), Vector3.new(x + lado * 13.3, 32.5, zFrente - 0.6), 1.6, P.madeiraClara, { Name = "Tora", Material = Enum.Material.Wood })
		Natal.cilindro(m, Vector3.new(x + lado * 13, 0, zTras), Vector3.new(x + lado * 13, 32.5, zTras), 1.6, P.madeiraClara, { Name = "Tora", Material = Enum.Material.Wood })
		-- Janelas acesas nas laterais da casa (aparecem entre um chalé e outro)
		local pj = Vector3.new(x + lado * 13.25, 21, z - 21)
		Natal.janela(m, CFrame.lookAt(pj, pj + Vector3.xAxis * lado))

		-- Paredes laterais da sala: neve em cima, poste na entrada com guirlanda
		Natal.elipse(m, CFrame.new(x + lado * 13, 13.35, z), Vector3.new(2.9, 1.3, 27), P.neve, { Name = "NeveMuro", Material = Enum.Material.Snow })
		local baseposte = Vector3.new(x + lado * 13, 0, z + 13.4)
		Natal.cilindro(m, baseposte, baseposte + CIMA * 13.6, 2.6, P.madeiraClara, { Name = "PosteEntrada", Material = Enum.Material.Wood, CanCollide = true })
		Natal.bola(m, baseposte + CIMA * 14.3, 1.6, P.dourado, { Name = "Pinaculo", Material = Enum.Material.Foil })
		local pg = baseposte + Vector3.new(0, 8.2, 1.5)
		Natal.guirlanda(m, CFrame.lookAt(pg, pg + Vector3.zAxis), 3.4)
		-- Bandeirinhas na cor da sala (por dentro) e pisca-pisca (por fora)
		Natal.bandeirolas(m, Vector3.new(x + lado * 11.85, 11.7, z + 12), Vector3.new(x + lado * 11.85, 11.7, z - 11), 8, cor)
		Natal.cordaoDeLuzes(m, Vector3.new(x + lado * 14.25, 12.2, z + 12.5), Vector3.new(x + lado * 14.25, 12.2, z - 12), 9, 0.5)
	end

	-- Telhado nevado (a frente do telhado fica virada para a praça)
	local topo = CFrame.new(x, 32, z - 20) * CFrame.Angles(0, math.pi, 0)
	Natal.telhado(m, topo, 26, 16, 7.8, 1.5, { luzesFrente = 8 })
	-- Janela redonda acesa no frontão
	local pr = Vector3.new(x, 35.2, zFrente + 0.2)
	local virado = CFrame.fromMatrix(pr, Vector3.zAxis, CIMA)
	Natal.peca(m, { Name = "AroJanela", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 3.6, 3.6), CFrame = virado, Color = P.madeiraEscura })
	Natal.peca(m, { Name = "JanelaRedonda", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 2.8, 2.8), CFrame = virado * CFrame.new(0.1, 0, 0), Color = P.luz, Material = Enum.Material.Neon })

	-- Lanterna acesa entre a placa do nome e o placar (ilumina o piso e o placar)
	Natal.lanterna(m, Vector3.new(x, 9.5, zFrente + 0.8), true)

	-- Molduras: placar com neve e luzinhas; placa do nome com a cor da sala
	Natal.moldura(m, s.placar, { neve = true, luzes = 7, cantos = true })
	Natal.moldura(m, s.placaNome, { cor = cor, material = Enum.Material.Neon, espessura = 0.45 })
end

------------------------------------------------------------------------
-- FÁBRICA DE AJUDANTES DO PAPAI NOEL (atrás da máquina)
------------------------------------------------------------------------
local function fabrica(dec: Instance, maquina: BasePart, placaMaquina: BasePart)
	local m = Natal.modelo(dec, "FabricaDeAjudantes")
	local chaoMaquina = Vector3.new(maquina.Position.X, 0, maquina.Position.Z)
	local dir = (chaoMaquina - SPAWN).Unit
	local pos = chaoMaquina + dir * 24
	local cf = CFrame.lookAt(pos, chaoMaquina)
	local _, info = Natal.chale(m, cf, 30, 20, 18, { nome = "Fabrica", porta = true, chamine = true, luzesFrente = 9, inclinacao = 0.7 })

	-- Placa no frontão
	Natal.placaDeMadeira(m, cf * CFrame.new(0, 22.4, -10.7), "🎅 FÁBRICA DE AJUDANTES", 14, 3.2)
	-- Engrenagens douradas na fachada
	for _, e in { { -10, 15.2, 1.6 }, { 10, 15.2, 1.6 }, { -6.6, 13.4, 1 }, { 6.6, 13.4, 1 } } do
		local p = (cf * CFrame.new(e[1], e[2], -10.35)).Position
		Natal.engrenagem(m, CFrame.lookAt(p, p + cf.LookVector), e[3])
	end
	-- Esteira saindo da porta e levando presentes até a máquina
	local esteira = cf * CFrame.new(0, 0, -13.4)
	Natal.solida(m, { Name = "Esteira", Size = Vector3.new(4, 0.5, 6.6), CFrame = esteira * CFrame.new(0, 2.3, 0), Color = P.metal, Material = Enum.Material.Metal })
	for _, lado in { -1, 1 } do
		Natal.peca(m, { Name = "LateralEsteira", Size = Vector3.new(0.4, 1.3, 6.6), CFrame = esteira * CFrame.new(lado * 2.2, 2, 0), Color = P.madeiraClara, Material = Enum.Material.Wood })
		Natal.peca(m, { Name = "PeEsteira", Size = Vector3.new(0.5, 1.8, 0.5), CFrame = esteira * CFrame.new(lado * 1.6, 0.9, 0), Color = P.metal, Material = Enum.Material.Metal })
	end
	Natal.presente(m, (esteira * CFrame.new(0, 2.55, 1.6)).Position, Vector3.new(1.5, 1.4, 1.5), P.verdeClaro, P.dourado, 0.2)
	Natal.presente(m, (esteira * CFrame.new(0.2, 2.55, -1.6)).Position, Vector3.new(1.3, 1.5, 1.3), P.azul, P.vermelho, -0.4)
	-- Lanterna acesa na porta, presentes e bengalas
	Natal.lanterna(m, (cf * CFrame.new(3.4, 6.6, -11)).Position, true)
	Natal.lanterna(m, (cf * CFrame.new(-3.4, 6.6, -11)).Position, false)
	Natal.pilhaDePresentes(m, (cf * CFrame.new(12.5, 0, -13.5)).Position, 4)
	for _, lado in { -1, 1 } do
		local p = (cf * CFrame.new(lado * 16.5, 0, -12)).Position
		Natal.bengala(m, p, 1.1, giroPara(p, SPAWN))
	end
	-- Placa da máquina: moldura, neve, luzinhas e dois postes
	Natal.moldura(m, placaMaquina, { neve = true, cantos = true, luzes = 6 })
	for _, lado in { -1, 1 } do
		local topo = placaMaquina.Position + Vector3.new(lado * 9.7, 1.8, 0)
		Natal.cilindro(m, Vector3.new(topo.X, 0, topo.Z), topo, 0.8, P.madeiraEscura, { Name = "PostePlaca", Material = Enum.Material.Wood })
	end
	return info
end

------------------------------------------------------------------------
-- PRAÇA DA ÁRVORE GIGANTE
------------------------------------------------------------------------
local function pracaDaArvore(dec: Instance)
	local m = Natal.modelo(dec, "PracaDaArvore")
	Natal.arvoreGigante(m, ARVORE, (SPAWN - ARVORE) * Vector3.new(1, 0, 1))

	-- Cerca baixa em volta (aberta do lado do spawn)
	local raio = 22
	for k = 0, 7 do
		local a0, a1 = k * TAU / 8 + TAU / 16, (k + 1) * TAU / 8 + TAU / 16
		local meio = (a0 + a1) / 2
		-- O spawn fica no -Z: deixa esse lado aberto
		if math.sin(meio) > -0.6 then
			local pA = ARVORE + Vector3.new(math.cos(a0) * raio, 0, math.sin(a0) * raio)
			local pB = ARVORE + Vector3.new(math.cos(a1) * raio, 0, math.sin(a1) * raio)
			Natal.cerca(m, pA, pB, 3)
		end
	end
	-- Bengalas na entrada e postes acesos
	for _, lado in { -1, 1 } do
		local p = ARVORE + Vector3.new(lado * 8, 0, -21)
		Natal.bengala(m, p, 1.2, giroPara(p, SPAWN))
		Natal.poste(m, ARVORE + Vector3.new(lado * 25, 0, -18), true)
		Natal.poste(m, ARVORE + Vector3.new(lado * 26, 0, 18), true)
	end
	-- Trenó com presentes e boneco de neve
	local pTreno = ARVORE + Vector3.new(13, 0, 8)
	Natal.treno(m, CFrame.new(pTreno) * CFrame.Angles(0, giroPara(pTreno, SPAWN), 0))
	local pBoneco = ARVORE + Vector3.new(-13, 0, 8)
	Natal.bonecoDeNeve(m, pBoneco, giroPara(pBoneco, SPAWN))
end

------------------------------------------------------------------------
-- PLACAR DE RENASCIMENTOS E TÍTULO
------------------------------------------------------------------------
local function placarRenascimentos(dec: Instance, placar: BasePart)
	local m = Natal.modelo(dec, "PlacarRenascimentosDecoracao")
	Natal.moldura(m, placar, { neve = true, cantos = true, luzes = 8 })
	-- Fundo de madeira atrás (o lado de trás fica bonito para quem vem da árvore)
	Natal.peca(m, { Name = "Costas", Size = Vector3.new(22, 20, 0.3), CFrame = placar.CFrame * CFrame.new(0, 0, 0.42), Color = P.madeira, Material = Enum.Material.WoodPlanks })
	for _, lado in { -1, 1 } do
		Natal.solida(m, { Name = "Pe", Size = Vector3.new(1.4, 2, 1.4), CFrame = CFrame.new(placar.Position.X + lado * 9, 1, placar.Position.Z), Color = P.madeiraEscura, Material = Enum.Material.Wood })
	end
	-- (do lado esquerdo já tem o poste da praça da árvore)
	Natal.poste(m, PLACAR + Vector3.new(14.5, 0, -1), true)
	Natal.pilhaDePresentes(m, PLACAR + Vector3.new(13, 0, -6), 3)
end

local function titulo(dec: Instance, placa: BasePart)
	local m = Natal.modelo(dec, "TituloDecoracao")
	Natal.moldura(m, placa, { neve = true, cantos = true, luzes = 16, espessura = 1.2, cor = P.madeira })
	for _, lado in { -1, 1 } do
		local x = placa.Position.X + lado * 30
		local z = placa.Position.Z - 1.6
		Natal.cilindro(m, Vector3.new(x, 0, z), Vector3.new(x, placa.Position.Y + 2, z), 2.6, P.madeiraClara, { Name = "Mastro", Material = Enum.Material.Wood, CanCollide = true })
		local pe = Vector3.new(placa.Position.X + lado * 39.5, placa.Position.Y, placa.Position.Z + 0.6)
		Natal.estrela(m, CFrame.lookAt(pe, pe + Vector3.zAxis), 6)
	end
end

------------------------------------------------------------------------
-- RUA DAS SALAS, SPAWN E ENFEITES SOLTOS
------------------------------------------------------------------------
local function ruaEEnfeites(dec: Instance)
	local m = Natal.modelo(dec, "Rua")
	-- Postes acesos na beira da rua (sem ficar na frente de nenhuma sala)
	for _, x in { -72, -40, -10, 10, 40, 72 } do
		Natal.poste(m, Vector3.new(x, 0, -8), true)
	end
	-- Pinheirinhos decorados entre os chalés (pequenos) e pinheiros médios nas pontas
	-- da rua. As estrelas olham para a rua; os presentes ficam só nos das pontas.
	for _, x in { -34, 0, 34 } do
		Natal.pinheiro(m, Vector3.new(x, 0, -34), 0.55, { estilo = if x == 0 then "dourado" else "nevado", estrela = true, montinho = true })
	end
	for _, x in { -72, 72 } do
		Natal.pinheiro(m, Vector3.new(x, 0, -38), 1, { estilo = "tradicional", estrela = true, montinho = true, presentes = if x < 0 then 2 else 1 })
	end
	-- Bengalas no começo da rua e perto do spawn
	for _, lado in { -1, 1 } do
		local p = Vector3.new(lado * 6.5, 0, 6)
		Natal.bengala(m, p, 1, giroPara(p, SPAWN))
	end
	-- Bonecos de neve
	for _, p in { Vector3.new(-24, 0, 26), Vector3.new(56, 0, 18), Vector3.new(-60, 0, 10) } do
		Natal.bonecoDeNeve(m, p, giroPara(p, SPAWN))
	end
	-- Presentes perto dos bosques
	Natal.pilhaDePresentes(m, Vector3.new(-92, 0, 52), 3)
	Natal.pilhaDePresentes(m, Vector3.new(90, 0, 40), 3)
	Natal.pilhaDePresentes(m, Vector3.new(-44, 0, 104), 3)
end

------------------------------------------------------------------------
-- FLORESTA E BOSQUES
------------------------------------------------------------------------
local function floresta(dec: Instance)
	local m = Natal.modelo(dec, "Floresta")
	local colocadas: { Vector3 } = {}
	local function cabe(p: Vector3, distancia: number): boolean
		for _, q in colocadas do
			if (q - p).Magnitude < distancia then
				return false
			end
		end
		return true
	end

	-- Bosques no meio do caminho: nos 4 mais perto da vila, um pinheiro médio decorado
	-- (com estrela olhando para a vila); o resto só com neve. Estilos em pares, um de cada lado.
	local bosques = { { -98, -6 }, { 98, -4 }, { -80, 92 }, { 86, 96 }, { -34, 118 }, { 38, 122 } }
	local estilos = { "dourado", "dourado", "nevado", "nevado" }
	for i, b in bosques do
		local centro = Vector3.new(b[1], 0, b[2])
		for k = 1, 3 do
			local a = k * TAU / 3 + i
			local p = centro + Vector3.new(math.cos(a), 0, math.sin(a)) * Natal.sortear(5, 9)
			if livre(p, 6) and cabe(p, 9) then
				table.insert(colocadas, p)
				if k == 1 and estilos[i] then
					Natal.pinheiro(m, p, Natal.sortear(0.95, 1.1), { estilo = estilos[i], estrela = true, frente = VILA - p, montinho = true })
				else
					Natal.pinheiro(m, p, Natal.sortear(0.8, 1.35), { estilo = "natural" })
				end
			end
		end
	end

	-- As montanhas são terreno: árvore só onde o chão ainda é plano
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local function chaoPlano(p: Vector3): boolean
		local r = workspace:Raycast(Vector3.new(p.X, 120, p.Z), Vector3.new(0, -240, 0), params)
		return r == nil or r.Position.Y < 1.5
	end

	-- Floresta em GRUPOS de 3 a 5 pinheiros (só com neve), com clareiras entre eles.
	-- Quanto mais perto das montanhas, maiores e um pouco mais azulados (profundidade).
	local grupos: { Vector3 } = {}
	local tentativas = 0
	while #grupos < 10 and tentativas < 400 do
		tentativas += 1
		local a = Natal.sortear(0, TAU)
		local r = Natal.sortear(112, 146)
		local centro = VILA + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local separado = true
		for _, g in grupos do
			if (g - centro).Magnitude < 40 then
				separado = false
				break
			end
		end
		if separado and livre(centro, 6) then
			table.insert(grupos, centro)
			local fundo = math.clamp((r - 112) / 34, 0, 1)
			local quantos = math.floor(Natal.sortear(3, 5.99))
			local giro = Natal.sortear(0, TAU)
			for k = 1, quantos do
				local p = centro
				if k > 1 then
					local ak = giro + k * TAU / (quantos - 1) + Natal.sortear(-0.4, 0.4)
					p = centro + Vector3.new(math.cos(ak), 0, math.sin(ak)) * Natal.sortear(7, 12)
				end
				if livre(p, 5) and cabe(p, 7.5) and chaoPlano(p) then
					table.insert(colocadas, p)
					-- O primeiro de cada grupo é o maior
					local escala = Natal.sortear(1, 1.35) * (1 + fundo * 0.45) * (if k == 1 then 1.25 else 1)
					Natal.pinheiro(m, p, escala, { estilo = "natural", distante = fundo })
				end
			end
		end
	end
	-- Pinheiros bem grandes no pé das montanhas: dão profundidade ao fundo
	for i = 0, 7 do
		local a = i * TAU / 8 + Natal.sortear(-0.2, 0.2)
		local r = Natal.sortear(150, 160)
		local p = VILA + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		if livre(p, 8) and cabe(p, 14) and chaoPlano(p) then
			table.insert(colocadas, p)
			Natal.pinheiro(m, p, Natal.sortear(2.1, 2.7), { estilo = "natural", distante = 1 })
		end
	end
end

------------------------------------------------------------------------
function DecoracaoLobby.construir(pasta: Instance, info: { [string]: any })
	local dec = Natal.pasta(pasta, "Decoracao")
	terreno()
	for _, s in info.salas do
		chaleDaSala(dec, s)
	end
	fabrica(dec, info.maquina, info.placaMaquina)
	pracaDaArvore(dec)
	placarRenascimentos(dec, info.placarRenascimentos)
	titulo(dec, info.titulo)
	ruaEEnfeites(dec)
	floresta(dec)
end

return DecoracaoLobby
