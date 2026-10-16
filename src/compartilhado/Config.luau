-- Configurações do jogo "Desembrulhe o Presente".
-- Quase todo número de balanceamento está aqui: mude aqui e o jogo inteiro muda.

local Config = {}

-- ⚠️ Depois de publicar os dois lugares no Roblox, coloque os IDs aqui.
-- (O ID aparece no link do jogo: roblox.com/games/ESTE_NUMERO/...)
Config.LOBBY_PLACE_ID = 0
Config.PARTIDA_PLACE_ID = 0

Config.VERSAO_DADOS = "v1" -- trocar zera o progresso de todo mundo (cuidado!)

-- Modos (salas do lobby). "presentes" = tamanho da montanha.
Config.MODOS = {
	{ nome = "Solo", jogadores = 1, presentes = 1500, cor = Color3.fromRGB(80, 200, 120) },
	{ nome = "Dupla", jogadores = 2, presentes = 2400, cor = Color3.fromRGB(80, 160, 255) },
	{ nome = "Trio", jogadores = 3, presentes = 3200, cor = Color3.fromRGB(190, 110, 255) },
	{ nome = "Quarteto", jogadores = 4, presentes = 4000, cor = Color3.fromRGB(255, 120, 80) },
}

function Config.modoPorNome(nome: string)
	for _, modo in Config.MODOS do
		if modo.nome == nome then
			return modo
		end
	end
	return Config.MODOS[1]
end

-- Tempo de contagem nas salas quando a sala enche (segundos)
Config.CONTAGEM_SALA = 5

-- Raridades dos presentes. "chance" soma 1.
Config.RARIDADES = {
	{
		id = "Comum",
		chance = 0.90,
		valor = 1,
		cores = {
			Color3.fromRGB(220, 50, 50),
			Color3.fromRGB(40, 170, 80),
			Color3.fromRGB(50, 110, 220),
			Color3.fromRGB(150, 70, 200),
		},
		material = Enum.Material.SmoothPlastic,
	},
	{ id = "Dourado", chance = 0.07, valor = 8, cores = { Color3.fromRGB(255, 200, 40) }, material = Enum.Material.Foil },
	{ id = "Diamante", chance = 0.025, valor = 30, cores = { Color3.fromRGB(120, 230, 255) }, material = Enum.Material.Glass },
	{ id = "Arco-íris", chance = 0.005, valor = 120, cores = { Color3.fromRGB(255, 90, 200) }, material = Enum.Material.Neon },
}

function Config.raridadePorId(id: string)
	for _, r in Config.RARIDADES do
		if r.id == id then
			return r
		end
	end
	return Config.RARIDADES[1]
end

-- Chance de vir uma Estrela ao desembrulhar um presente
Config.CHANCE_ESTRELA = 0.012
Config.ESTRELAS_POR_FUGA = 30
Config.ESTRELAS_INICIAIS = 40

-- A chave aparece quando essa fração da montanha já foi desembrulhada (sorteada entre min e max)
Config.CHAVE_MIN = 0.90
Config.CHAVE_MAX = 0.985

-- Distâncias (em studs)
Config.ALCANCE_COLETA = 24
Config.RAIO_MESA = 14

-- Renascimento: cada fuga dá +1, e cada um dá +50% de moedas para sempre
Config.BONUS_POR_RENASCIMENTO = 0.5

-- Melhorias compradas com moedas dentro da partida (zeram a cada partida)
-- niveis[1] é o valor inicial (grátis). custos[i] é o preço para chegar no nível i.
Config.MELHORIAS = {
	{ id = "Saco", nome = "🎒 Saco Maior", desc = "Carrega mais presentes", niveis = { 10, 25, 50, 125, 250, 450 }, custos = { 0, 15, 60, 200, 600, 1500 } },
	{ id = "Tesoura", nome = "✂️ Tesoura", desc = "Desembrulha mais rápido (por segundo)", niveis = { 2, 4, 7, 12, 20, 32 }, custos = { 0, 20, 80, 250, 700, 1800 } },
	{ id = "Maos", nome = "🧤 Luvas", desc = "Pega mais presentes por clique", niveis = { 1, 2, 3, 5, 8 }, custos = { 0, 25, 100, 350, 900 } },
	{ id = "Velocidade", nome = "👟 Botas", desc = "Corre mais rápido", niveis = { 16, 20, 24, 28, 32 }, custos = { 0, 30, 120, 400, 1000 } },
	{ id = "Valor", nome = "💰 Laço de Ouro", desc = "Presentes valem mais", niveis = { 1, 1.5, 2, 3, 5 }, custos = { 0, 50, 250, 800, 2000 } },
}

function Config.melhoriaPorId(id: string)
	for _, m in Config.MELHORIAS do
		if m.id == id then
			return m
		end
	end
	return nil
end

-- Ajudantes (pets). Ficam salvos para sempre.
-- coleta = presentes desembrulhados por vez, intervalo = segundos entre cada vez
-- bonusValor = +% nas moedas do dono
Config.CUSTO_GIRO = 40
Config.MAX_EQUIPADOS = 3
Config.AJUDANTES = {
	{ id = "Elfo", nome = "Elfo Ajudante", emoji = "🧝", chance = 0.45, coleta = 1, intervalo = 3, bonusValor = 0, cor = Color3.fromRGB(60, 180, 80), raridade = "Comum" },
	{ id = "Pinguim", nome = "Pinguim", emoji = "🐧", chance = 0.25, coleta = 2, intervalo = 3, bonusValor = 0, cor = Color3.fromRGB(40, 40, 60), raridade = "Incomum" },
	{ id = "Rena", nome = "Rena", emoji = "🦌", chance = 0.15, coleta = 3, intervalo = 2.5, bonusValor = 0, cor = Color3.fromRGB(150, 90, 40), raridade = "Raro" },
	{ id = "Boneco", nome = "Boneco de Neve", emoji = "⛄", chance = 0.10, coleta = 1, intervalo = 3, bonusValor = 0.25, cor = Color3.fromRGB(240, 240, 255), raridade = "Épico" },
	{ id = "Urso", nome = "Urso Polar", emoji = "🐻‍❄️", chance = 0.045, coleta = 5, intervalo = 2, bonusValor = 0, cor = Color3.fromRGB(230, 240, 250), raridade = "Lendário" },
	{ id = "Noel", nome = "Papai Noel", emoji = "🎅", chance = 0.005, coleta = 8, intervalo = 1.5, bonusValor = 0.5, cor = Color3.fromRGB(220, 30, 30), raridade = "Mítico" },
}

function Config.ajudantePorId(id: string)
	for _, a in Config.AJUDANTES do
		if a.id == id then
			return a
		end
	end
	return nil
end

Config.CORES_RARIDADE_AJUDANTE = {
	["Comum"] = Color3.fromRGB(200, 200, 200),
	["Incomum"] = Color3.fromRGB(90, 220, 110),
	["Raro"] = Color3.fromRGB(80, 160, 255),
	["Épico"] = Color3.fromRGB(190, 100, 255),
	["Lendário"] = Color3.fromRGB(255, 190, 40),
	["Mítico"] = Color3.fromRGB(255, 70, 90),
}

------------------------------------------------------------------------
-- 🎄 VISUAL DE NATAL (só aparência: nada aqui muda as regras do jogo)
------------------------------------------------------------------------

-- Paleta de cores usada no cenário e na interface.
-- Proporção pensada: muita neve e tons neutros, depois verde e madeira,
-- um pouco de vermelho e só um toque de dourado. As cores fortes ficam
-- para o que é interativo (salas, mesa, loja, portão, máquina).
Config.PALETA = {
	vermelho = Color3.fromRGB(198, 40, 40), -- #C62828 destaques, telhados, laços
	verde = Color3.fromRGB(22, 91, 51), -- #165B33 árvores, guirlandas
	neve = Color3.fromRGB(245, 249, 255), -- #F5F9FF neve, chão
	dourado = Color3.fromRGB(245, 199, 107), -- #F5C76B brilhos, estrelas, molduras
	azul = Color3.fromRGB(168, 216, 234), -- #A8D8EA gelo, sombras frias, detalhes
	madeira = Color3.fromRGB(101, 67, 46), -- #65432E casas, cercas, placas
	luz = Color3.fromRGB(255, 228, 163), -- #FFE4A3 janelas, lâmpadas

	-- Tons de apoio (variações das cores acima, para dar profundidade)
	vermelhoEscuro = Color3.fromRGB(122, 22, 28),
	verdeClaro = Color3.fromRGB(38, 122, 68),
	madeiraClara = Color3.fromRGB(150, 104, 70),
	madeiraEscura = Color3.fromRGB(64, 42, 30),
	pedra = Color3.fromRGB(122, 130, 146),
	metal = Color3.fromRGB(46, 50, 60),
	neveBatida = Color3.fromRGB(206, 222, 238), -- caminhos de neve pisada
}

-- Nomes das "etiquetas" (tags) que o cenário coloca nas peças para os efeitos
-- do cliente acharem: lâmpadas que piscam, chaminés com fumaça, brilhos dourados
-- e as luzes do portão que acendem quando alguém acha a chave.
Config.TAGS_NATAL = {
	lampada = "NatalLampada",
	chamine = "NatalChamine",
	brilho = "NatalBrilho",
	portao = "NatalPortao",
}

return Config
