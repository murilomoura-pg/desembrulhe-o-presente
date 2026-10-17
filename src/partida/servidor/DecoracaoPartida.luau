-- 🎄 Decoração de Natal da PARTIDA (só visual: não muda nada no jogo).
-- Layout parecido com o Peel THE Potato (Capítulo 1), no tema de Natal:
--   • montanha de presentes no centro, numa plataforma com anel dourado (feita no MapaPartida);
--   • setas de neve brilhante do spawn até a montanha e caminho de chapa de metal;
--   • atrás do spawn, a OFICINA DOS ELFOS: galpão de madeira com a frente aberta,
--     as 4 bancadas, a Máquina de Presentes (loja) e o cofre no fundo;
--   • caixotes de melhorias nas cercas de tela, perto do spawn;
--   • pinheiros e montanhas de neve do lado de fora.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Natal = require(ServerStorage.Comum.Natal)

local DecoracaoPartida = {}

local P = Natal.P
local TAGS = Config.TAGS_NATAL
local CIMA = Vector3.yAxis
local TAU = math.pi * 2

local function giroPara(de: Vector3, para: Vector3): number
	local d = para - de
	return math.atan2(-d.X, -d.Z)
end

local function terreno(L: { [string]: any })
	local W, R = L.metadePatio, L.raio
	local zMeio = (L.zNorte + L.zFundo) / 2
	Natal.prepararTerreno()
	Natal.chaoDeNeve(0, zMeio, W * 2 + 220, (L.zFundo - L.zNorte) + 220)
	Natal.anel(Vector3.zero, R + 6, R + 12)
	Natal.caminho(Vector3.new(-L.metadeGalpao + 3, 0, L.zFrente - 3), Vector3.new(L.metadeGalpao - 3, 0, L.zFrente - 3), 6)
	local alcance = math.sqrt(W * W + ((L.zFundo - L.zNorte) / 2) ^ 2) + 95
	local pontos = {}
	for i = 0, 21 do
		local a = i * TAU / 22 + 0.1
		local r = alcance + Natal.sortear(-8, 14)
		table.insert(pontos, Vector3.new(math.cos(a) * r, 0, zMeio + math.sin(a) * r))
	end
	Natal.montanhas(pontos, 60, 85)
end

local function caminhoESetas(dec: Instance, L: { [string]: any })
	local m = Natal.modelo(dec, "CaminhoDeMetal")
	local R = L.raio
	local z0, z1 = R + 6, L.zFrente
	Natal.peca(m, { Name = "Chapa", Size = Vector3.new(10, 0.2, z1 - z0), CFrame = CFrame.new(0, 0.1, (z0 + z1) / 2), Color = Color3.fromRGB(150, 156, 168), Material = Enum.Material.DiamondPlate })
	for _, x in { -5.2, 5.2 } do
		Natal.peca(m, { Name = "Beirada", Size = Vector3.new(0.5, 0.3, z1 - z0), CFrame = CFrame.new(x, 0.15, (z0 + z1) / 2), Color = P.metal, Material = Enum.Material.Metal })
	end
	-- Setas de neve brilhante apontando para a montanha (só visual)
	for _, z in { R + 24, R + 18, R + 12 } do
		local base = Vector3.new(0, 0.26, z)
		Natal.peca(m, { Name = "Seta", Size = Vector3.new(1, 0.08, 2.6), CFrame = CFrame.new(base + Vector3.zAxis * 1.3), Color = P.neve, Material = Enum.Material.Neon, Transparency = 0.15 })
		for _, lado in { -1, 1 } do
			Natal.triangulo(m, base, -Vector3.zAxis, 2, Vector3.xAxis * lado, 1.6, 0.08, P.neve, { Name = "Seta", Material = Enum.Material.Neon, Transparency = 0.15 })
		end
	end
end

-- OFICINA DOS ELFOS (galpão aberto na frente)
local function oficina(dec: Instance, L: { [string]: any })
	local m = Natal.modelo(dec, "OficinaDosElfos")
	local G, H = L.metadeGalpao, L.alturaGalpao
	local zF, zB = L.zFrente, L.zFundo
	local zMeio = (zF + zB) / 2
	local fundo = zB - zF

	Natal.peca(m, { Name = "Piso", Size = Vector3.new(G * 2, 0.3, fundo), CFrame = CFrame.new(0, 0.15, zMeio), Color = P.madeiraClara, Material = Enum.Material.WoodPlanks, CanCollide = true })
	for _, lado in { -1, 1 } do
		Natal.solida(m, { Name = "ParedeLateral", Size = Vector3.new(1.5, H, fundo + 0.75), CFrame = CFrame.new(lado * (G + 0.75), H / 2, zMeio + 0.375), Color = P.madeira, Material = Enum.Material.WoodPlanks })
	end
	-- Parede do fundo com a abertura do cofre (atrás da porta redonda)
	local xA, xB, hA = L.xPortao - 4.5, L.xPortao + 4.5, 11
	local esqLarg = xA - (-G - 1.5)
	Natal.solida(m, { Name = "ParedeFundo", Size = Vector3.new(esqLarg, H, 1.5), CFrame = CFrame.new(-G - 1.5 + esqLarg / 2, H / 2, zB), Color = P.madeira, Material = Enum.Material.WoodPlanks })
	local dirLarg = (G + 1.5) - xB
	Natal.solida(m, { Name = "ParedeFundo", Size = Vector3.new(dirLarg, H, 1.5), CFrame = CFrame.new(xB + dirLarg / 2, H / 2, zB), Color = P.madeira, Material = Enum.Material.WoodPlanks })
	Natal.solida(m, { Name = "ParedeFundo", Size = Vector3.new(xB - xA, H - hA, 1.5), CFrame = CFrame.new(L.xPortao, hA + (H - hA) / 2, zB), Color = P.madeira, Material = Enum.Material.WoodPlanks })

	-- Telhado nevado e viga da frente
	Natal.telhado(m, CFrame.new(0, H, zF + 15.25), G * 2 + 1.5, fundo + 1, (G + 0.75) * 0.32, 1.6, { luzesFrente = 14 })
	Natal.solida(m, { Name = "VigaFrente", Size = Vector3.new(G * 2 + 1.5, 1.6, 1.4), CFrame = CFrame.new(0, H - 0.8, zF + 0.2), Color = P.madeiraEscura, Material = Enum.Material.Wood })
	for _, lado in { -1, 1 } do
		local base = Vector3.new(lado * (G + 0.4), 0, zF + 0.3)
		Natal.cilindro(m, base, base + CIMA * (H + 0.6), 1.9, P.madeiraClara, { Name = "Tora", Material = Enum.Material.Wood, CanCollide = true })
		local pg = base + Vector3.new(-lado * 0.2, 13.5, -1.2)
		Natal.guirlanda(m, CFrame.lookAt(pg, pg - Vector3.zAxis), 3.4)
	end
	Natal.cordaoDeLuzes(m, Vector3.new(-G + 1, H - 1.7, zF - 0.6), Vector3.new(G - 1, H - 1.7, zF - 0.6), 22, 1.2)
	Natal.placaDeMadeira(m, CFrame.new(0, H + 4.2, zF - 0.15), "🧝 OFICINA DOS ELFOS", 24, 3.6)

	-- Vigas por dentro e lâmpadas quentes penduradas
	for _, dz in { 9, 17, 25 } do
		Natal.peca(m, { Name = "Viga", Size = Vector3.new(G * 2, 0.9, 0.9), CFrame = CFrame.new(0, H - 1.8, zF + dz), Color = P.madeiraEscura, Material = Enum.Material.Wood })
	end
	for _, x in { -15, 0, 15 } do
		local p = Vector3.new(x, 15, zF + 9)
		Natal.cilindro(m, p + CIMA * 0.8, Vector3.new(x, H - 2.25, zF + 9), 0.12, P.metal, { Name = "Fio" })
		Natal.lanterna(m, p, true)
	end

	-- Janelas acesas no fundo e estante com presentes
	for _, x in { -22, -4 } do
		local pj = Vector3.new(x, 13, zB - 0.95)
		Natal.janela(m, CFrame.lookAt(pj, pj - Vector3.zAxis), 5, 4.5)
	end
	local zEstante = zB - 0.75 - 1.2
	for _, y in { 3.6, 7.2 } do
		Natal.peca(m, { Name = "Prateleira", Size = Vector3.new(26, 0.4, 2.2), CFrame = CFrame.new(-19, y, zEstante), Color = P.madeiraEscura, Material = Enum.Material.Wood })
	end
	for _, x in { -32, -19, -6 } do
		Natal.peca(m, { Name = "LadoEstante", Size = Vector3.new(0.5, 8, 2.2), CFrame = CFrame.new(x, 4, zEstante), Color = P.madeiraEscura, Material = Enum.Material.Wood })
	end
	local cores = { P.vermelho, P.verdeClaro, P.dourado, P.azul, P.neve }
	for i = 1, 10 do
		local x = -30.5 + ((i - 1) % 5) * 5.6
		local y = i <= 5 and 3.8 or 7.4
		local t = Natal.sortear(1.3, 2)
		Natal.presente(m, Vector3.new(x, y, zEstante), Vector3.new(t, t, t), cores[i % #cores + 1], i % 2 == 0 and P.dourado or P.vermelho, Natal.sortear(-0.3, 0.3), i % 3 == 0)
	end
end

-- MÁQUINA DE PRESENTES (a loja), no meio das bancadas
local function maquina(dec: Instance, L: { [string]: any })
	local m = Natal.modelo(dec, "MaquinaDePresentes")
	local loja: BasePart = L.loja
	local base = loja.Position - CIMA * loja.Size.Y / 2
	local corpo = Natal.solida(m, { Name = "Corpo", Size = Vector3.new(6, 5.4, 4), CFrame = CFrame.new(base + Vector3.new(0, 6.7, 0.2)), Color = P.vermelhoEscuro })
	for _, y in { -2.55, 2.55 } do
		Natal.peca(m, { Name = "Friso", Size = Vector3.new(6.2, 0.35, 4.2), CFrame = corpo.CFrame * CFrame.new(0, y, 0), Color = P.dourado, Material = Enum.Material.Foil })
	end
	local tela = Natal.peca(m, { Name = "Telinha", Size = Vector3.new(4.2, 2.6, 0.15), CFrame = corpo.CFrame * CFrame.new(0, 0.4, -2.05), Color = P.azul, Material = Enum.Material.Neon })
	Natal.peca(m, { Name = "MolduraTela", Size = Vector3.new(4.8, 3.2, 0.12), CFrame = corpo.CFrame * CFrame.new(0, 0.4, -2.0), Color = P.metal, Material = Enum.Material.Metal })
	Natal.luz(tela, P.azul, 12, 0.8)
	Natal.cilindro(m, corpo.Position + CIMA * 2.7, corpo.Position + CIMA * 4.4, 2.6, Color3.fromRGB(190, 196, 206), { Name = "Funil", Material = Enum.Material.Metal })
	Natal.presente(m, corpo.Position + CIMA * 4.4, Vector3.new(1.6, 1.4, 1.6), P.verdeClaro, P.dourado, 0.3, true)
	for _, lado in { -1, 1 } do
		local p = corpo.Position + Vector3.new(lado * 3.15, 0.5, 0)
		Natal.engrenagem(m, CFrame.lookAt(p, p + Vector3.xAxis * lado), 1.3)
	end
	Natal.placaDeMadeira(m, CFrame.new(base + Vector3.new(0, 12.6, 0.2)), "🛒 LOJA DE MELHORIAS", 9.5, 2)
end

-- COFRE DO PAPAI NOEL (portão de fuga)
local function cofre(dec: Instance, L: { [string]: any })
	local m = Natal.modelo(dec, "CofreDecoracao")
	local porta: BasePart = L.portao
	local cadeado: BasePart = L.cadeado
	local c = porta.Position
	local r = L.diametroPorta / 2
	local frente = -Vector3.zAxis
	-- Parafusos e barras NA porta (soldados: giram junto quando o cofre abre)
	for i = 0, 9 do
		local a = i * TAU / 10
		local p = c + Vector3.new(math.cos(a) * (r - 0.9), math.sin(a) * (r - 0.9), 0) + frente * 0.65
		Natal.soldar(porta, Natal.bola(m, p, 0.7, P.metal, { Name = "Parafuso", Material = Enum.Material.Metal }))
	end
	for _, tamanho in { Vector3.new(r * 1.6, 0.6, 0.2), Vector3.new(0.6, r * 1.6, 0.2) } do
		Natal.soldar(porta, Natal.peca(m, { Name = "BarraCofre", Size = tamanho, CFrame = CFrame.new(c + frente * 0.65), Color = P.dourado, Material = Enum.Material.Foil }))
	end
	-- Volante do cofre DENTRO do Cadeado (some junto com ele na fuga)
	local v = cadeado.Position + frente * 0.45
	for i = 0, 3 do
		local a = i * TAU / 4 + math.rad(45)
		local ponta = v + Vector3.new(math.cos(a), math.sin(a), 0) * 3.2
		Natal.cilindro(cadeado, v, ponta, 0.45, P.dourado, { Name = "Raio", Material = Enum.Material.Foil })
		Natal.bola(cadeado, ponta, 0.9, P.dourado, { Name = "Pegador", Material = Enum.Material.Foil })
	end
	Natal.bola(cadeado, v + frente * 0.2, 1.4, P.vermelho, { Name = "Miolo" })
	-- Luzinhas em volta da porta e lanternas (acendem forte quando acham a chave)
	local zParede = L.zFundo - 0.75 - 0.15
	for i = 0, 15 do
		local a = i * TAU / 16
		local p = Vector3.new(c.X + math.cos(a) * (r + 0.7), c.Y + math.sin(a) * (r + 0.7), zParede)
		if p.Y > 0.5 and p.X < L.metadeGalpao - 0.5 then
			Natal.bola(m, p, 0.55, P.dourado, { Name = "LuzCofre", Material = Enum.Material.Neon, Transparency = 0.35 }):AddTag(TAGS.portao)
		end
	end
	for _, x in { c.X - r - 1.8, L.metadeGalpao - 0.9 } do
		local lanterna = Natal.peca(m, { Name = "LanternaCofre", Size = Vector3.new(1.2, 1.8, 1.2), CFrame = CFrame.new(x, 9.5, zParede - 0.8), Color = P.luz, Material = Enum.Material.Neon })
		lanterna:AddTag(TAGS.portao)
		Natal.luz(lanterna, P.luz, 14, 1)
	end
	Natal.moldura(m, L.placaPortao, { neve = true, cantos = true })
end

-- CAIXOTES DE MELHORIAS (com fita e laço, como presentes)
local function caixotes(dec: Instance, L: { [string]: any })
	local m = Natal.modelo(dec, "CaixotesDecoracao")
	for _, c in L.caixotes do
		local caixa: BasePart = c.caixa
		Natal.peca(m, { Name = "Fita", Size = Vector3.new(3.7, 3.7, 0.6), CFrame = caixa.CFrame, Color = P.vermelho, Material = Enum.Material.Fabric })
		Natal.peca(m, { Name = "Fita", Size = Vector3.new(0.6, 3.7, 3.7), CFrame = caixa.CFrame, Color = P.vermelho, Material = Enum.Material.Fabric })
		Natal.laco(m, caixa.CFrame * CFrame.new(0, 1.85, 0), 1.7, P.vermelho)
	end
end

-- CERCAS DE TELA EM VOLTA DO PÁTIO
local function cercas(dec: Instance, L: { [string]: any })
	local m = Natal.modelo(dec, "Cercas")
	local W, G = L.metadePatio, L.metadeGalpao
	Natal.cercaDeTela(m, Vector3.new(-W, 0, L.zNorte), Vector3.new(W, 0, L.zNorte))
	for _, lado in { -1, 1 } do
		Natal.cercaDeTela(m, Vector3.new(lado * W, 0, L.zNorte), Vector3.new(lado * W, 0, L.zCintura))
		Natal.cercaDeTela(m, Vector3.new(lado * W, 0, L.zCintura), Vector3.new(lado * G, 0, L.zCintura))
		Natal.cercaDeTela(m, Vector3.new(lado * G, 0, L.zCintura), Vector3.new(lado * G, 0, L.zFrente))
	end
end

-- EM VOLTA DA MONTANHA: postes, cordões de luz e a estrela no alto
local function emVoltaDaMontanha(dec: Instance, L: { [string]: any })
	local m = Natal.modelo(dec, "EmVoltaDaMontanha")
	local R = L.raio
	local pontos = {}
	for i = 0, 7 do
		local a = math.rad(i * 45 + 22.5)
		local p = Vector3.new(math.cos(a) * (R + 11), 0, math.sin(a) * (R + 11))
		table.insert(pontos, p)
		Natal.poste(m, p, true)
	end
	for i, p in pontos do
		Natal.cordaoDeLuzes(m, p + CIMA * 12.4, pontos[i % #pontos + 1] + CIMA * 12.4, 8, 2)
	end
	local alto = R * 1.2 + 12
	local pos = Vector3.new(0, alto, 0)
	local estrela = Natal.estrela(m, CFrame.lookAt(pos, Vector3.new(0, alto, L.zSpawn)), 10)
	local miolo = estrela.PrimaryPart :: BasePart
	miolo:AddTag(TAGS.brilho)
	Natal.luz(miolo, P.dourado, 20, 2)
end

-- CANTOS DO PÁTIO E FLORESTA DO LADO DE FORA
local function cantos(dec: Instance, L: { [string]: any })
	local m = Natal.modelo(dec, "Cantos")
	local W = L.metadePatio
	for _, lado in { -1, 1 } do
		Natal.pinheiro(m, Vector3.new(lado * (W - 7), 0, L.zNorte + 7), 1.1, { luzes = true, bolas = true, lacos = true, estrela = true })
	end
	local pt = Vector3.new(-(W - 6), 0, L.zCintura - 7)
	Natal.treno(m, CFrame.new(pt) * CFrame.Angles(0, giroPara(pt, Vector3.zero), 0))
	local pb = Vector3.new(W - 5, 0, L.zCintura - 6)
	Natal.bonecoDeNeve(m, pb, giroPara(pb, Vector3.new(0, 0, L.zSpawn)))
end

local function floresta(dec: Instance, L: { [string]: any })
	local m = Natal.modelo(dec, "FlorestaDeFora")
	local W, G = L.metadePatio, L.metadeGalpao
	local function dentro(p: Vector3, folga: number): boolean
		local naMontanha = math.abs(p.X) <= W + folga and p.Z >= L.zNorte - folga and p.Z <= L.zCintura + folga
		local naOficina = math.abs(p.X) <= G + folga and p.Z >= L.zCintura - folga and p.Z <= L.zFundo + folga
		return naMontanha or naOficina
	end
	local colocadas: { Vector3 } = {}
	local feitas, tentativas = 0, 0
	while feitas < 30 and tentativas < 500 do
		tentativas += 1
		local p = Vector3.new(Natal.sortear(-W - 70, W + 70), 0, Natal.sortear(L.zNorte - 70, L.zFundo + 50))
		local livre = not dentro(p, 16)
		for _, q in colocadas do
			if (q - p).Magnitude < 15 then
				livre = false
				break
			end
		end
		if livre then
			table.insert(colocadas, p)
			feitas += 1
			Natal.pinheiro(m, p, Natal.sortear(1.6, 2.4), {})
		end
	end
end

function DecoracaoPartida.construir(pasta: Instance, L: { [string]: any })
	local dec = Natal.pasta(pasta, "Decoracao")
	terreno(L)
	caminhoESetas(dec, L)
	oficina(dec, L)
	maquina(dec, L)
	cofre(dec, L)
	caixotes(dec, L)
	cercas(dec, L)
	emVoltaDaMontanha(dec, L)
	cantos(dec, L)
	floresta(dec, L)
end

return DecoracaoPartida
