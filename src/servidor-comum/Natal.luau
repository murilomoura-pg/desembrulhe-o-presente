-- 🎄 Kit de DECORAÇÃO DE NATAL.
-- Funções que montam enfeites (pinheiros, chalés, luzes, placas, bonecos de neve...)
-- a partir de uma posição. Usado pelo MapaLobby e pelo MapaPartida (só no servidor).
--
-- Tudo aqui é SÓ VISUAL:
--   • peças ancoradas, sem colisão (menos paredes de casas, troncos e cercas);
--   • CanQuery/CanTouch desligados, então nada atrapalha o clique nos presentes;
--   • peças pequenas não fazem sombra (fica mais leve no celular);
--   • cada enfeite vira um Model com nome claro.
-- Os efeitos animados (piscar, neve caindo, fumaça) são feitos no cliente
-- (Ambiente.client.luau), procurando as "tags" de Config.TAGS_NATAL.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Util = require(ReplicatedStorage.Compartilhado.Util)

local Natal = {}

local P = Config.PALETA
local TAGS = Config.TAGS_NATAL
Natal.P = P

local CIMA = Vector3.yAxis
local TAU = math.pi * 2

-- Sorteios com SEMENTE FIXA: o mapa sai igualzinho em todo servidor.
local rng = Random.new(1225)
function Natal.semente(n: number)
	rng = Random.new(n)
end
function Natal.sortear(a: number, b: number): number
	return rng:NextNumber(a, b)
end
-- Variação leve (±10%) para nada parecer copiado e colado
local function variar(valor: number, quanto: number?): number
	local q = quanto or 0.1
	return valor * rng:NextNumber(1 - q, 1 + q)
end

-- Cores das lâmpadas do pisca-pisca (vão se alternando)
local CORES_LAMPADAS = { P.vermelho, P.luz, Color3.fromRGB(90, 200, 120), P.azul, P.dourado }
local contadorLampadas = 0

------------------------------------------------------------------------
-- PEÇAS BÁSICAS
------------------------------------------------------------------------

-- Pasta "Decoracao" (ou outro nome) dentro de um lugar do mapa
function Natal.pasta(pai: Instance, nome: string?): Folder
	local f = Instance.new("Folder")
	f.Name = nome or "Decoracao"
	f.Parent = pai
	return f
end

function Natal.modelo(pai: Instance, nome: string): Model
	local m = Instance.new("Model")
	m.Name = nome
	m.Parent = pai
	return m
end

-- Peça de decoração. Aceita as mesmas propriedades do Util.peca, mais:
--   Classe = "WedgePart"/"CornerWedgePart"... (padrão "Part")
--   Malha = Enum.MeshType.Sphere (vira uma "bolha" do tamanho da peça)
function Natal.peca(pai: Instance, props: { [string]: any }): BasePart
	local p = Instance.new(props.Classe or "Part") :: BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	-- Formato primeiro (bola/cilindro), depois o resto
	if props.Shape then
		(p :: any).Shape = props.Shape
	end
	for k, v in props do
		if k ~= "Classe" and k ~= "Malha" and k ~= "Shape" then
			(p :: any)[k] = v
		end
	end
	if props.Malha then
		local m = Instance.new("SpecialMesh")
		m.MeshType = props.Malha
		m.Parent = p
	end
	p.Parent = pai
	return p
end

-- Enfeite "soldado" numa peça que se mexe (ex.: o Portão, que sobe na fuga).
-- Ele acompanha a peça sozinho, sem precisar de nenhum código extra.
function Natal.soldar(peca: BasePart, enfeite: BasePart)
	enfeite.Anchored = false
	enfeite.Massless = true
	enfeite.CanCollide = false
	local solda = Instance.new("WeldConstraint")
	solda.Part0 = peca
	solda.Part1 = enfeite
	solda.Parent = enfeite
end

-- Peça "sólida": bloqueia o jogador e faz sombra (paredes, troncos, cercas)
function Natal.solida(pai: Instance, props: { [string]: any }): BasePart
	local p = Natal.peca(pai, props)
	p.CanCollide = true
	p.CastShadow = true
	return p
end

function Natal.bola(pai: Instance, pos: Vector3, diametro: number, cor: Color3, props: { [string]: any }?): BasePart
	local t: { [string]: any } = { Name = "Bola", Shape = Enum.PartType.Ball, Size = Vector3.one * diametro, CFrame = CFrame.new(pos), Color = cor }
	for k, v in (props or {}) :: { [string]: any } do
		t[k] = v
	end
	return Natal.peca(pai, t)
end

-- "Bolha" achatada ou esticada (elipsoide): neve fofa, copas de árvore, laços
function Natal.elipse(pai: Instance, cf: CFrame, tamanho: Vector3, cor: Color3, props: { [string]: any }?): BasePart
	local t: { [string]: any } = { Name = "Bolha", Malha = Enum.MeshType.Sphere, Size = tamanho, CFrame = cf, Color = cor }
	for k, v in (props or {}) :: { [string]: any } do
		t[k] = v
	end
	return Natal.peca(pai, t)
end

-- Cilindro ligando dois pontos (troncos, fios, postes, rolos)
function Natal.cilindro(pai: Instance, a: Vector3, b: Vector3, diametro: number, cor: Color3, props: { [string]: any }?): BasePart
	local dir = b - a
	local meio = (a + b) / 2
	local up = math.abs(dir.Unit.Y) > 0.99 and Vector3.xAxis or CIMA
	local cf = CFrame.lookAt(meio, b, up) * CFrame.Angles(0, math.rad(90), 0)
	local t: { [string]: any } = { Name = "Cilindro", Shape = Enum.PartType.Cylinder, Size = Vector3.new(dir.Magnitude, diametro, diametro), CFrame = cf, Color = cor }
	for k, v in (props or {}) :: { [string]: any } do
		t[k] = v
	end
	return Natal.peca(pai, t)
end

-- Triângulo retângulo (uma WedgePart) com o ângulo reto no ponto B:
-- um lado vai na direção "dirA" (comprimento lenA) e o outro na "dirB" (lenB).
-- Com dois deles fazemos frontões de telhado, pontas de estrela, pingentes de gelo...
function Natal.triangulo(pai: Instance, B: Vector3, dirA: Vector3, lenA: number, dirB: Vector3, lenB: number, espessura: number, cor: Color3, props: { [string]: any }?): BasePart
	local zLocal = -dirA.Unit
	local yLocal = dirB.Unit
	local xLocal = yLocal:Cross(zLocal)
	local centro = B + dirA.Unit * (lenA / 2) + dirB.Unit * (lenB / 2)
	local t: { [string]: any } = {
		Name = "Triangulo",
		Classe = "WedgePart",
		Size = Vector3.new(espessura, lenB, lenA),
		CFrame = CFrame.fromMatrix(centro, xLocal, yLocal, zLocal),
		Color = cor,
	}
	for k, v in (props or {}) :: { [string]: any } do
		t[k] = v
	end
	return Natal.peca(pai, t)
end

-- Lâmpada de pisca-pisca (o cliente faz ela "respirar" devagar)
function Natal.lampada(pai: Instance, pos: Vector3, diametro: number?, cor: Color3?): BasePart
	contadorLampadas += 1
	local c = cor or CORES_LAMPADAS[(contadorLampadas % #CORES_LAMPADAS) + 1]
	local l = Natal.bola(pai, pos, diametro or 0.5, c, { Name = "Lampada", Material = Enum.Material.Neon })
	l:SetAttribute("Fase", contadorLampadas % 7)
	l:AddTag(TAGS.lampada)
	return l
end

-- Luz de verdade (PointLight). Usar pouco: no máximo ~40 por lugar.
function Natal.luz(pai: Instance, cor: Color3, alcance: number, brilho: number?): PointLight
	local l = Instance.new("PointLight")
	l.Color = cor
	l.Range = math.min(alcance, 20)
	l.Brightness = brilho or 1.2
	l.Shadows = false
	l.Parent = pai
	return l
end

-- Camada de neve fofa em cima de uma peça quadrada (muro, placa, cerca, poste)
function Natal.neveEmCima(pai: Instance, peca: BasePart, espessura: number?): BasePart
	local e = espessura or 0.9
	local s = peca.Size
	return Natal.elipse(pai, peca.CFrame * CFrame.new(0, s.Y / 2 + e * 0.2, 0), Vector3.new(s.X + 0.5, e, s.Z + 0.5), P.neve, { Name = "Neve", Material = Enum.Material.Snow })
end

-- Pingentes de gelo pendurados entre dois pontos
function Natal.pingentes(pai: Instance, a: Vector3, b: Vector3, quantidade: number, comprimento: number?)
	local lado = (b - a).Unit
	for i = 1, quantidade do
		local t = (i - 0.5) / quantidade
		local ponto = a:Lerp(b, t)
		Natal.triangulo(pai, ponto, -CIMA, variar(comprimento or 1.6, 0.4), lado, 0.35, 0.3, P.azul, {
			Name = "Pingente",
			Material = Enum.Material.Ice,
			Transparency = 0.15,
		})
	end
end

------------------------------------------------------------------------
-- LUZES, FITAS E BANDEIRINHAS
------------------------------------------------------------------------

-- Cordão de luzes entre dois pontos, com uma "barriguinha" no meio
function Natal.cordaoDeLuzes(pai: Instance, a: Vector3, b: Vector3, n: number, queda: number?): Model
	local m = Natal.modelo(pai, "CordaoDeLuzes")
	local q = queda or (a - b).Magnitude * 0.06
	local function ponto(t: number): Vector3
		return a:Lerp(b, t) - CIMA * (q * 4 * t * (1 - t))
	end
	-- Fio (poucos pedaços, para economizar peças)
	local pedacos = math.clamp(math.floor(n / 3), 2, 5)
	for i = 1, pedacos do
		local p1, p2 = ponto((i - 1) / pedacos), ponto(i / pedacos)
		Natal.cilindro(m, p1, p2, 0.12, P.metal, { Name = "Fio" })
	end
	for i = 1, n do
		Natal.lampada(m, ponto((i - 0.5) / n) - CIMA * 0.25, 0.5)
	end
	return m
end

-- Fileira de bandeirinhas (losangos pendurados) — usada com a cor de cada sala
function Natal.bandeirolas(pai: Instance, a: Vector3, b: Vector3, n: number, cor: Color3): Model
	local m = Natal.modelo(pai, "Bandeirolas")
	local lado = (b - a).Unit
	for i = 1, n do
		local t = (i - 0.5) / n
		local pos = a:Lerp(b, t) - CIMA * (0.9 + 0.5 * 4 * t * (1 - t))
		local corBandeira = i % 2 == 0 and P.neve or cor
		-- Quadrado girado 45° = losango com a ponta para baixo
		local cf = CFrame.fromMatrix(pos, lado, CIMA, lado:Cross(CIMA)) * CFrame.Angles(0, 0, math.rad(45))
		Natal.peca(m, { Name = "Bandeira", Size = Vector3.new(1.3, 1.3, 0.12), CFrame = cf, Color = corBandeira })
	end
	Natal.cilindro(m, a, b, 0.1, P.neve, { Name = "Corda" })
	return m
end

------------------------------------------------------------------------
-- ESTRELA, SINO, MEIA, LAÇO, ENGRENAGEM
------------------------------------------------------------------------

-- Estrela 3D de 5 pontas virada para "cf.LookVector"
function Natal.estrela(pai: Instance, cf: CFrame, tamanho: number, cor: Color3?): Model
	local m = Natal.modelo(pai, "Estrela")
	local c = cor or P.dourado
	local centro = cf.Position
	local cimaE, direita = cf.UpVector, cf.RightVector
	local r0 = tamanho * 0.2
	local L = tamanho * 0.5 - r0
	local W = (TAU * r0 / 5) * 1.15
	local D = tamanho * 0.18
	for i = 0, 4 do
		local a = i * TAU / 5
		local fora = cimaE * math.cos(a) + direita * math.sin(a)
		local lado = cimaE * -math.sin(a) + direita * math.cos(a)
		local base = centro + fora * r0 * 0.9
		Natal.triangulo(m, base, fora, L, lado, W / 2, D, c, { Name = "Ponta", Material = Enum.Material.Neon })
		Natal.triangulo(m, base, fora, L, -lado, W / 2, D, c, { Name = "Ponta", Material = Enum.Material.Neon })
	end
	local miolo = Natal.peca(m, {
		Name = "Miolo",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(D * 1.25, r0 * 2.3, r0 * 2.3),
		CFrame = CFrame.fromMatrix(centro, cf.LookVector, cimaE),
		Color = c,
		Material = Enum.Material.Neon,
	})
	m.PrimaryPart = miolo
	return m
end

-- Laço de presente: duas "orelhas" achatadas + nó
function Natal.laco(pai: Instance, cf: CFrame, tamanho: number, cor: Color3): Model
	local m = Natal.modelo(pai, "Laco")
	local s = tamanho
	for _, lado in { -1, 1 } do
		Natal.elipse(m, cf * CFrame.new(lado * s * 0.32, s * 0.12, 0) * CFrame.Angles(0, 0, math.rad(-lado * 28)), Vector3.new(s * 0.62, s * 0.34, s * 0.3), cor, { Name = "Orelha" })
	end
	Natal.bola(m, (cf * CFrame.new(0, s * 0.05, 0)).Position, s * 0.24, cor, { Name = "No" })
	return m
end

function Natal.sino(pai: Instance, cf: CFrame, tamanho: number): Model
	local m = Natal.modelo(pai, "Sino")
	local s = tamanho
	Natal.elipse(m, cf * CFrame.new(0, s * 0.15, 0), Vector3.new(s * 0.8, s, s * 0.8), P.dourado, { Name = "Corpo", Material = Enum.Material.Foil })
	Natal.peca(m, { Name = "Boca", Shape = Enum.PartType.Cylinder, Size = Vector3.new(s * 0.14, s * 0.95, s * 0.95), CFrame = cf * CFrame.new(0, -s * 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.dourado, Material = Enum.Material.Foil })
	Natal.bola(m, (cf * CFrame.new(0, -s * 0.42, 0)).Position, s * 0.22, P.madeiraEscura, { Name = "Badalo" })
	Natal.laco(m, cf * CFrame.new(0, s * 0.7, 0), s * 0.7, P.vermelho)
	return m
end

-- Meia de Natal pendurada (cf = topo da meia, virada para a frente)
function Natal.meia(pai: Instance, cf: CFrame, tamanho: number?): Model
	local m = Natal.modelo(pai, "Meia")
	local s = tamanho or 1
	Natal.peca(m, { Name = "Perna", Size = Vector3.new(1.1, 1.8, 0.5) * s, CFrame = cf * CFrame.new(0, -1.3 * s, 0), Color = P.vermelho })
	Natal.peca(m, { Name = "Pe", Size = Vector3.new(1.7, 0.9, 0.5) * s, CFrame = cf * CFrame.new(0.3 * s, -2.4 * s, 0), Color = P.vermelho })
	Natal.peca(m, { Name = "Barra", Size = Vector3.new(1.3, 0.6, 0.6) * s, CFrame = cf * CFrame.new(0, -0.3 * s, 0), Color = P.neve, Material = Enum.Material.Fabric })
	return m
end

-- Engrenagem dourada (cf virado para a frente da parede)
function Natal.engrenagem(pai: Instance, cf: CFrame, raio: number): Model
	local m = Natal.modelo(pai, "Engrenagem")
	local base = CFrame.fromMatrix(cf.Position, cf.LookVector, cf.UpVector)
	Natal.peca(m, { Name = "Disco", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, raio * 2, raio * 2), CFrame = base, Color = P.dourado, Material = Enum.Material.Foil })
	Natal.peca(m, { Name = "Eixo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, raio * 0.6, raio * 0.6), CFrame = base, Color = P.madeiraEscura })
	local dentes = 8
	for i = 1, dentes do
		local a = i * TAU / dentes
		local dir = cf.UpVector * math.cos(a) + cf.RightVector * math.sin(a)
		local pos = cf.Position + dir * (raio + 0.25)
		Natal.peca(m, { Name = "Dente", Size = Vector3.new(raio * 0.38, 0.7, 0.45), CFrame = CFrame.fromMatrix(pos, dir:Cross(cf.LookVector), dir), Color = P.dourado, Material = Enum.Material.Foil })
	end
	return m
end

------------------------------------------------------------------------
-- ÁRVORES
------------------------------------------------------------------------

type Camada = { y: number, raio: number, meiaAltura: number }

-- Raio da copa numa altura (para colocar luzes e bolas por cima das camadas)
local function raioCopa(camadas: { Camada }, y: number): number
	local r = 0
	for _, c in camadas do
		local d = (y - c.y) / c.meiaAltura
		if math.abs(d) < 1 then
			r = math.max(r, c.raio * math.sqrt(1 - d * d))
		end
	end
	return r
end

-- Pinheiro com copa em camadas fofas.
-- opcoes: neve (padrão sim), luzes, bolas, lacos, estrela (bolinha dourada no topo)
function Natal.pinheiro(pai: Instance, pos: Vector3, escala: number, opcoes: { [string]: any }?): Model
	local o = opcoes or {}
	local s = escala
	local m = Natal.modelo(pai, "Pinheiro")
	local giro = rng:NextNumber(0, TAU)
	Natal.solida(m, { Name = "Tronco", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.4 * s, 1.6 * s, 1.6 * s), CFrame = CFrame.new(pos + CIMA * 1.7 * s) * CFrame.Angles(0, 0, math.rad(90)), Color = P.madeira, Material = Enum.Material.Wood })
	local camadas: { Camada } = {}
	for i = 0, 3 do
		local largura = variar((12 - i * 2.7) * s, 0.06)
		local altura = largura * 0.62
		local y = (4.6 + i * 3.3) * s
		local desvio = Vector3.new(rng:NextNumber(-0.25, 0.25), 0, rng:NextNumber(-0.25, 0.25)) * s
		local centro = pos + CIMA * y + desvio
		local cor = P.verde:Lerp(P.verdeClaro, rng:NextNumber(0, 0.45))
		local copa = Natal.elipse(m, CFrame.new(centro) * CFrame.Angles(0, giro + i, 0), Vector3.new(largura, altura, largura), cor, { Name = "Copa" })
		copa.CastShadow = s >= 0.8
		table.insert(camadas, { y = y, raio = largura / 2, meiaAltura = altura / 2 })
		if o.neve ~= false then
			Natal.elipse(m, CFrame.new(centro + CIMA * altura * 0.24), Vector3.new(largura * 0.78, altura * 0.42, largura * 0.78), P.neve, { Name = "Neve", Material = Enum.Material.Snow })
		end
	end
	local topo = pos + CIMA * 16.4 * s
	if o.estrela then
		Natal.bola(m, topo, 1.3 * s, P.dourado, { Name = "Estrela", Material = Enum.Material.Neon })
	else
		Natal.elipse(m, CFrame.new(topo), Vector3.new(1.4, 2.4, 1.4) * s, o.neve ~= false and P.neve or P.verde, { Name = "Ponta" })
	end
	-- Enfeites espalhados por cima da copa
	local function pontoNaCopa(yMin: number, yMax: number, afastar: number): Vector3
		local y = rng:NextNumber(yMin, yMax) * s
		local a = rng:NextNumber(0, TAU)
		local r = raioCopa(camadas, y) * 0.97 + afastar
		return pos + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
	end
	if o.luzes then
		for i = 1, 8 do
			local y = (3 + i * 1.45) * s
			local a = i * 2.2 + giro
			local r = raioCopa(camadas, y) * 0.97 + 0.2
			Natal.lampada(m, pos + Vector3.new(math.cos(a) * r, y, math.sin(a) * r), 0.45 * math.max(1, s))
		end
	end
	if o.bolas then
		for i = 1, 6 do
			local cor = i % 2 == 0 and P.dourado or P.vermelho
			Natal.bola(m, pontoNaCopa(3, 13, 0.3), 0.75 * s, cor, { Name = "Enfeite", Material = i % 2 == 0 and Enum.Material.Foil or Enum.Material.SmoothPlastic, Reflectance = 0.15 })
		end
	end
	if o.lacos then
		for _ = 1, 2 do
			local p = pontoNaCopa(4, 11, 0.4)
			Natal.laco(m, CFrame.lookAt(p, Vector3.new(pos.X, p.Y, pos.Z)) * CFrame.Angles(0, math.pi, 0), 1.1 * s, P.vermelho)
		end
	end
	return m
end

-- A ÁRVORE GIGANTE do Lobby: ponto focal da praça
function Natal.arvoreGigante(pai: Instance, pos: Vector3, direcaoFrente: Vector3): Model
	local m = Natal.modelo(pai, "ArvoreGigante")
	local frente = (direcaoFrente * Vector3.new(1, 0, 1)).Unit
	-- Saia da árvore (tapete redondo) e tronco
	Natal.peca(m, { Name = "Saia", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 30, 30), CFrame = CFrame.new(pos + CIMA * 0.15) * CFrame.Angles(0, 0, math.rad(90)), Color = P.vermelhoEscuro, Material = Enum.Material.Fabric })
	Natal.peca(m, { Name = "BordaSaia", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 31.5, 31.5), CFrame = CFrame.new(pos + CIMA * 0.1) * CFrame.Angles(0, 0, math.rad(90)), Color = P.dourado })
	Natal.solida(m, { Name = "Tronco", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10, 4.5, 4.5), CFrame = CFrame.new(pos + CIMA * 5) * CFrame.Angles(0, 0, math.rad(90)), Color = P.madeira, Material = Enum.Material.Wood })

	-- Copa: 7 camadas, cada uma com "tufos" em volta para ficar irregular e volumosa
	local camadas: { Camada } = {}
	for i = 0, 6 do
		local f = i / 6
		local largura = 30 + (8 - 30) * f
		local altura = largura * 0.55 + 2
		local y = 11 + i * 5.6
		local centro = pos + CIMA * y
		local cor = P.verde:Lerp(P.verdeClaro, 0.15 + 0.2 * (i % 2))
		local copa = Natal.elipse(m, CFrame.new(centro), Vector3.new(largura, altura, largura), cor, { Name = "Copa" })
		copa.CastShadow = true
		for k = 0, 2 do
			local a = math.rad(i * 47 + k * 120)
			local off = Vector3.new(math.cos(a), 0, math.sin(a)) * largura * 0.27
			Natal.elipse(m, CFrame.new(centro + off - CIMA * altura * 0.08), Vector3.new(largura * 0.55, altura * 0.72, largura * 0.55), P.verde:Lerp(P.verdeClaro, rng:NextNumber(0, 0.5)), { Name = "Tufo" })
		end
		Natal.elipse(m, CFrame.new(centro + CIMA * altura * 0.25), Vector3.new(largura * 0.8, altura * 0.42, largura * 0.8), P.neve, { Name = "Neve", Material = Enum.Material.Snow })
		table.insert(camadas, { y = y, raio = largura / 2 * 1.06, meiaAltura = altura / 2 })
	end

	-- Cordão de luzes em espiral (5 voltas)
	local voltas, total = 5, 78
	for k = 0, total - 1 do
		local t = k / (total - 1)
		local y = 5 + t * 40
		local a = t * voltas * TAU
		local r = raioCopa(camadas, y) + 0.45
		Natal.lampada(m, pos + Vector3.new(math.cos(a) * r, y, math.sin(a) * r), 0.75)
	end
	-- Bolas vermelhas e douradas
	for i = 1, 34 do
		local y = rng:NextNumber(5, 42)
		local a = rng:NextNumber(0, TAU)
		local r = raioCopa(camadas, y) + 0.3
		local dourada = i % 2 == 0
		Natal.bola(m, pos + Vector3.new(math.cos(a) * r, y, math.sin(a) * r), rng:NextNumber(1.3, 2), dourada and P.dourado or P.vermelho, {
			Name = "Enfeite",
			Material = dourada and Enum.Material.Foil or Enum.Material.SmoothPlastic,
			Reflectance = 0.2,
		})
	end
	-- Laços vermelhos grandes
	for i = 1, 6 do
		local y = 8 + i * 5.5
		local a = i * 2.4
		local r = raioCopa(camadas, y) + 0.5
		local p = pos + Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
		Natal.laco(m, CFrame.lookAt(p, p + (p - Vector3.new(pos.X, p.Y, pos.Z))), 2.6, P.vermelho)
	end

	-- Estrela 3D no topo + luz e brilhos (o cliente solta faíscas douradas nela)
	local posEstrela = pos + CIMA * 52
	local estrela = Natal.estrela(m, CFrame.lookAt(posEstrela, posEstrela + frente), 8)
	local miolo = estrela.PrimaryPart :: BasePart
	miolo:AddTag(TAGS.brilho)
	Natal.luz(miolo, P.dourado, 18, 2)
	-- Área invisível em volta da copa: os brilhos dourados sutis saem daqui
	local area = Natal.peca(m, { Name = "AreaBrilho", Size = Vector3.new(22, 34, 22), CFrame = CFrame.new(pos + CIMA * 24), Transparency = 1 })
	area:AddTag(TAGS.brilho)
	area:SetAttribute("Suave", true)
	local luzInterna = Natal.peca(m, { Name = "LuzInterna", Size = Vector3.one, CFrame = CFrame.new(pos + CIMA * 16 + frente * 14), Transparency = 1 })
	Natal.luz(luzInterna, P.luz, 20, 1.3)

	-- Presentes na base
	for i = 1, 10 do
		local a = i * TAU / 10 + 0.3
		local r = rng:NextNumber(5.5, 10)
		local t = rng:NextNumber(2, 3.6)
		local cores = { P.vermelho, P.dourado, P.neve, P.verdeClaro, P.azul }
		Natal.presente(m, pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r), Vector3.new(t * variar(1, 0.15), t, t * variar(1, 0.15)), cores[i % #cores + 1], i % 2 == 0 and P.vermelho or P.dourado, a, i % 3 == 0)
	end
	return m
end

------------------------------------------------------------------------
-- ENFEITES DO CENÁRIO
------------------------------------------------------------------------

-- Presente decorativo (não é coletável). comLaco = orelhas em cima.
function Natal.presente(pai: Instance, pos: Vector3, tamanho: Vector3, cor: Color3, corFita: Color3, giro: number?, comLaco: boolean?): Model
	local m = Natal.modelo(pai, "PresenteDecorativo")
	local cf = CFrame.new(pos + CIMA * tamanho.Y / 2) * CFrame.Angles(0, giro or 0, 0)
	local caixa = Natal.peca(m, { Name = "Caixa", Size = tamanho, CFrame = cf, Color = cor })
	caixa.CastShadow = tamanho.Y > 2.5
	Natal.peca(m, { Name = "Fita", Size = Vector3.new(tamanho.X + 0.08, tamanho.Y + 0.08, tamanho.Z * 0.2), CFrame = cf, Color = corFita })
	Natal.peca(m, { Name = "Fita", Size = Vector3.new(tamanho.X * 0.2, tamanho.Y + 0.08, tamanho.Z + 0.08), CFrame = cf, Color = corFita })
	if comLaco then
		Natal.laco(m, cf * CFrame.new(0, tamanho.Y / 2, 0), math.min(tamanho.X, tamanho.Z) * 0.6, corFita)
	end
	return m
end

-- Montinho de presentes (para cantinhos e perto das construções)
function Natal.pilhaDePresentes(pai: Instance, pos: Vector3, quantidade: number)
	local cores = { P.vermelho, P.dourado, P.neve, P.verdeClaro, P.azul }
	for i = 1, quantidade do
		local a = rng:NextNumber(0, TAU)
		local r = rng:NextNumber(0, 2.6)
		local t = rng:NextNumber(1.4, 2.8)
		local cor = cores[rng:NextInteger(1, #cores)]
		Natal.presente(pai, pos + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r), Vector3.new(t, t * variar(0.9, 0.2), t), cor, cor == P.vermelho and P.dourado or P.vermelho, a, i == 1)
	end
end

-- Bengala doce listrada
function Natal.bengala(pai: Instance, pos: Vector3, escala: number, giro: number?): Model
	local m = Natal.modelo(pai, "Bengala")
	local s = escala
	local base = CFrame.new(pos) * CFrame.Angles(0, giro or 0, 0)
	local altura = 7 * s
	local partes = 6
	for i = 1, partes do
		local y0, y1 = (i - 1) * altura / partes, i * altura / partes
		Natal.cilindro(m, (base * CFrame.new(0, y0, 0)).Position, (base * CFrame.new(0, y1, 0)).Position, 0.75 * s, i % 2 == 0 and P.vermelho or P.neve, { Name = "Cabo" })
	end
	-- Curva de cima (meia-volta)
	local raio = 1.3 * s
	local centroCurva = base * CFrame.new(raio, altura, 0)
	local anterior = (base * CFrame.new(0, altura, 0)).Position
	for i = 1, 5 do
		local a = math.pi - i * math.pi / 5
		local p = (centroCurva * CFrame.new(math.cos(a) * raio, math.sin(a) * raio, 0)).Position
		Natal.cilindro(m, anterior, p, 0.75 * s, i % 2 == 0 and P.vermelho or P.neve, { Name = "Curva" })
		Natal.bola(m, p, 0.75 * s, i % 2 == 0 and P.vermelho or P.neve, { Name = "Junta" })
		anterior = p
	end
	return m
end

-- Boneco de neve genérico (cachecol vermelho, cartola e nariz de cenoura)
function Natal.bonecoDeNeve(pai: Instance, pos: Vector3, giro: number?, escala: number?): Model
	local m = Natal.modelo(pai, "BonecoDeNeve")
	local s = escala or 1
	local cf = CFrame.new(pos) * CFrame.Angles(0, giro or 0, 0)
	local function em(x: number, y: number, z: number): Vector3
		return (cf * CFrame.new(x * s, y * s, z * s)).Position
	end
	Natal.solida(m, { Name = "Base", Shape = Enum.PartType.Ball, Size = Vector3.one * 5 * s, CFrame = CFrame.new(em(0, 2.2, 0)), Color = P.neve, Material = Enum.Material.Snow })
	Natal.bola(m, em(0, 5.6, 0), 3.8 * s, P.neve, { Name = "Corpo", Material = Enum.Material.Snow, CastShadow = true })
	Natal.bola(m, em(0, 8.3, 0), 2.8 * s, P.neve, { Name = "Cabeca", Material = Enum.Material.Snow })
	for _, x in { -0.45, 0.45 } do
		Natal.bola(m, em(x, 8.7, -1.25), 0.35 * s, P.metal, { Name = "Olho" })
	end
	Natal.elipse(m, cf * CFrame.new(0, 8.2 * s, -1.75 * s), Vector3.new(0.35, 0.35, 1.3) * s, Color3.fromRGB(240, 130, 40), { Name = "Nariz" })
	for i = 0, 2 do
		Natal.bola(m, em(0, 6.6 - i * 0.9, -1.75 + i * 0.05), 0.4 * s, P.metal, { Name = "Botao" })
	end
	-- Cachecol
	Natal.peca(m, { Name = "Cachecol", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.7, 3.3, 3.3) * s, CFrame = cf * CFrame.new(0, 7.15 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.vermelho, Material = Enum.Material.Fabric })
	Natal.peca(m, { Name = "PontaCachecol", Size = Vector3.new(0.7, 2, 0.3) * s, CFrame = cf * CFrame.new(0.8 * s, 6.3 * s, -1.6 * s) * CFrame.Angles(0, 0, math.rad(-10)), Color = P.vermelho, Material = Enum.Material.Fabric })
	-- Cartola
	Natal.peca(m, { Name = "AbaChapeu", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, 3, 3) * s, CFrame = cf * CFrame.new(0, 9.55 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.metal })
	Natal.peca(m, { Name = "Chapeu", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.8, 2, 2) * s, CFrame = cf * CFrame.new(0, 10.5 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.metal })
	Natal.peca(m, { Name = "FitaChapeu", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 2.05, 2.05) * s, CFrame = cf * CFrame.new(0, 9.85 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = P.vermelho })
	-- Braços de galho
	for _, lado in { -1, 1 } do
		Natal.cilindro(m, em(lado * 1.6, 6, 0), em(lado * 3.6, 7.6, 0), 0.25 * s, P.madeira, { Name = "Braco" })
	end
	return m
end

-- Poste de luz com lanterna, laço vermelho e neve em cima
function Natal.poste(pai: Instance, pos: Vector3, comLuz: boolean?, altura: number?): Model
	local m = Natal.modelo(pai, "Poste")
	local h = altura or 12
	Natal.solida(m, { Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 1.8, 1.8), CFrame = CFrame.new(pos + CIMA * 0.6) * CFrame.Angles(0, 0, math.rad(90)), Color = P.metal, Material = Enum.Material.Metal })
	Natal.cilindro(m, pos, pos + CIMA * h, 0.6, P.metal, { Name = "Haste", Material = Enum.Material.Metal, CanCollide = true })
	local lanterna = Natal.peca(m, { Name = "Lanterna", Size = Vector3.new(1.5, 1.9, 1.5), CFrame = CFrame.new(pos + CIMA * (h + 1)), Color = P.luz, Material = Enum.Material.Neon })
	Natal.peca(m, { Name = "Moldura", Size = Vector3.new(1.9, 0.35, 1.9), CFrame = CFrame.new(pos + CIMA * (h + 0.05)), Color = P.metal, Material = Enum.Material.Metal })
	local tampa = Natal.peca(m, { Name = "Tampa", Size = Vector3.new(2.1, 0.45, 2.1), CFrame = CFrame.new(pos + CIMA * (h + 2.15)), Color = P.metal, Material = Enum.Material.Metal })
	Natal.neveEmCima(m, tampa, 0.6)
	Natal.laco(m, CFrame.new(pos + CIMA * (h - 1.6) - Vector3.zAxis * 0.35), 1.2, P.vermelho)
	if comLuz then
		Natal.luz(lanterna, P.luz, 20, 1.4)
	end
	return m
end

-- Lanterna pequena (para pendurar ou apoiar)
function Natal.lanterna(pai: Instance, pos: Vector3, comLuz: boolean?): Model
	local m = Natal.modelo(pai, "Lanterna")
	local vidro = Natal.peca(m, { Name = "Vidro", Size = Vector3.new(0.9, 1.2, 0.9), CFrame = CFrame.new(pos), Color = P.luz, Material = Enum.Material.Neon })
	Natal.peca(m, { Name = "Tampa", Size = Vector3.new(1.2, 0.3, 1.2), CFrame = CFrame.new(pos + CIMA * 0.75), Color = P.metal, Material = Enum.Material.Metal })
	Natal.peca(m, { Name = "Fundo", Size = Vector3.new(1.1, 0.2, 1.1), CFrame = CFrame.new(pos - CIMA * 0.7), Color = P.metal, Material = Enum.Material.Metal })
	if comLuz then
		Natal.luz(vidro, P.luz, 16, 1.2)
	end
	return m
end

-- Guirlanda redonda (cf virado para fora da parede)
function Natal.guirlanda(pai: Instance, cf: CFrame, tamanho: number): Model
	local m = Natal.modelo(pai, "Guirlanda")
	local r = tamanho / 2
	local tufos = 9
	for i = 1, tufos do
		local a = i * TAU / tufos
		local p = (cf * CFrame.new(math.cos(a) * r * 0.72, math.sin(a) * r * 0.72, 0)).Position
		Natal.bola(m, p, r * 0.62, i % 2 == 0 and P.verde or P.verdeClaro, { Name = "Folhas" })
	end
	for i = 1, 4 do
		local a = i * TAU / 4 + 0.4
		local p = (cf * CFrame.new(math.cos(a) * r * 0.85, math.sin(a) * r * 0.85, -r * 0.25)).Position
		Natal.bola(m, p, r * 0.2, P.vermelho, { Name = "Fruta" })
	end
	Natal.laco(m, cf * CFrame.new(0, -r * 0.8, -r * 0.2), r * 0.9, P.vermelho)
	return m
end

-- Cerca de madeira entre dois pontos (no chão), com neve em cima
function Natal.cerca(pai: Instance, a: Vector3, b: Vector3, altura: number?): Model
	local m = Natal.modelo(pai, "Cerca")
	local h = altura or 3.2
	local dir = b - a
	local n = math.max(1, math.floor(dir.Magnitude / 4))
	local cf = CFrame.lookAt((a + b) / 2, b)
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		local estaca = Natal.solida(m, { Name = "Estaca", Size = Vector3.new(0.6, h, 0.6), CFrame = CFrame.lookAt(p + CIMA * h / 2, p + CIMA * h / 2 + dir), Color = P.madeira, Material = Enum.Material.Wood })
		estaca.CastShadow = false
		Natal.bola(m, p + CIMA * (h + 0.1), 0.75, P.neve, { Name = "Neve", Material = Enum.Material.Snow })
	end
	for _, y in { h * 0.4, h * 0.82 } do
		local trilho = Natal.solida(m, { Name = "Trilho", Size = Vector3.new(0.25, 0.4, dir.Magnitude), CFrame = cf + CIMA * y, Color = P.madeiraClara, Material = Enum.Material.Wood })
		trilho.CastShadow = false
	end
	Natal.elipse(m, cf + CIMA * (h * 0.82 + 0.3), Vector3.new(0.6, 0.4, dir.Magnitude), P.neve, { Name = "NeveTrilho", Material = Enum.Material.Snow })
	return m
end

-- Trenó do Papai Noel (genérico), com saco de presentes
function Natal.treno(pai: Instance, cf: CFrame): Model
	local m = Natal.modelo(pai, "Treno")
	-- Esquis
	for _, x in { -1.9, 1.9 } do
		Natal.peca(m, { Name = "Esqui", Size = Vector3.new(0.35, 0.35, 9), CFrame = cf * CFrame.new(x, 0.25, 0), Color = P.dourado, Material = Enum.Material.Foil })
		Natal.peca(m, { Name = "Curva", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 2.2, 2.2), CFrame = cf * CFrame.new(x, 1.1, -4.6), Color = P.dourado, Material = Enum.Material.Foil })
		for _, z in { -2.5, 2.5 } do
			Natal.peca(m, { Name = "Apoio", Size = Vector3.new(0.3, 1.2, 0.3), CFrame = cf * CFrame.new(x, 1, z), Color = P.dourado })
		end
	end
	Natal.solida(m, { Name = "Corpo", Size = Vector3.new(4.4, 2.2, 7), CFrame = cf * CFrame.new(0, 2.6, 0.4), Color = P.vermelho })
	Natal.peca(m, { Name = "Encosto", Size = Vector3.new(4.4, 2.6, 0.8), CFrame = cf * CFrame.new(0, 4.6, 3.5) * CFrame.Angles(math.rad(-12), 0, 0), Color = P.vermelho })
	Natal.peca(m, { Name = "Frente", Size = Vector3.new(4.4, 1.6, 0.8), CFrame = cf * CFrame.new(0, 4, -2.9) * CFrame.Angles(math.rad(15), 0, 0), Color = P.vermelho })
	Natal.peca(m, { Name = "Friso", Size = Vector3.new(4.6, 0.3, 7.2), CFrame = cf * CFrame.new(0, 3.75, 0.4), Color = P.dourado, Material = Enum.Material.Foil })
	Natal.peca(m, { Name = "Assento", Size = Vector3.new(4, 0.5, 3), CFrame = cf * CFrame.new(0, 3.9, 1.6), Color = P.verde, Material = Enum.Material.Fabric })
	-- Saco de presentes
	Natal.elipse(m, cf * CFrame.new(0, 5.6, -0.6), Vector3.new(3.4, 3.6, 3.2), Color3.fromRGB(150, 110, 70), { Name = "Saco", Material = Enum.Material.Fabric })
	Natal.presente(m, (cf * CFrame.new(-0.9, 6.6, -0.8)).Position, Vector3.new(1.3, 1.3, 1.3), P.vermelho, P.dourado, 0.4)
	Natal.presente(m, (cf * CFrame.new(0.8, 6.8, -0.3)).Position, Vector3.new(1.1, 1.4, 1.1), P.verdeClaro, P.dourado, -0.3)
	return m
end

-- Placa de madeira com texto, moldura e neve. Retorna a tábua (o texto fica na frente, -Z do cf).
function Natal.placaDeMadeira(pai: Instance, cf: CFrame, texto: string, largura: number, altura: number, comPostes: boolean?): BasePart
	local m = Natal.modelo(pai, "PlacaDeMadeira")
	local tabua = Natal.peca(m, { Name = "Tabua", Size = Vector3.new(largura, altura, 0.5), CFrame = cf, Color = P.madeira, Material = Enum.Material.WoodPlanks })
	tabua.CastShadow = true
	Util.placa(tabua, texto, Enum.NormalId.Front, P.luz)
	Natal.moldura(m, tabua, { neve = true })
	if comPostes then
		-- Dois postes do chão até o alto da placa, por trás dela
		for _, lado in { -1, 1 } do
			local topo = (cf * CFrame.new(lado * (largura / 2 - 0.6), altura / 2 - 0.3, 0.6)).Position
			Natal.cilindro(m, Vector3.new(topo.X, 0, topo.Z), topo, 0.8, P.madeiraEscura, { Name = "Poste", Material = Enum.Material.Wood, CanCollide = true })
		end
	end
	return tabua
end

-- Moldura de madeira em volta de uma peça plana (placas e placares).
-- opcoes: cor, espessura, neve (neve em cima), luzes (quantas lâmpadas em cima), cantos (bolinhas douradas)
function Natal.moldura(pai: Instance, peca: BasePart, opcoes: { [string]: any }?): Model
	local o = opcoes or {}
	local m = Natal.modelo(pai, "Moldura")
	local s = peca.Size
	local e = o.espessura or math.clamp(math.min(s.X, s.Y) * 0.08, 0.35, 1.1)
	local cor = o.cor or P.madeiraEscura
	local fundo = s.Z + 0.5
	local material = o.material or Enum.Material.Wood
	local cf = peca.CFrame
	for _, lado in { -1, 1 } do
		Natal.peca(m, { Name = "Barra", Size = Vector3.new(s.X + e * 2, e, fundo), CFrame = cf * CFrame.new(0, lado * (s.Y + e) / 2, 0), Color = cor, Material = material })
		Natal.peca(m, { Name = "Barra", Size = Vector3.new(e, s.Y, fundo), CFrame = cf * CFrame.new(lado * (s.X + e) / 2, 0, 0), Color = cor, Material = material })
	end
	if o.cantos then
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				Natal.bola(m, (cf * CFrame.new(x * (s.X + e) / 2, y * (s.Y + e) / 2, 0)).Position, e * 1.5, P.dourado, { Name = "Canto", Material = Enum.Material.Foil })
			end
		end
	end
	local topo = cf * CFrame.new(0, s.Y / 2 + e, 0)
	if o.neve then
		Natal.elipse(m, topo * CFrame.new(0, e * 0.25, 0), Vector3.new(s.X + e * 2.6, e * 1.5 + 0.3, fundo + 0.7), P.neve, { Name = "Neve", Material = Enum.Material.Snow })
	end
	if o.luzes and o.luzes > 0 then
		-- Lâmpadas na beirada de baixo da neve, viradas para a frente
		local frente = cf.LookVector * (fundo / 2 + 0.25)
		local a = (topo * CFrame.new(-s.X / 2, -e * 0.3, 0)).Position + frente
		local b = (topo * CFrame.new(s.X / 2, -e * 0.3, 0)).Position + frente
		local n = o.luzes
		for i = 1, n do
			Natal.lampada(m, a:Lerp(b, (i - 0.5) / n), 0.55)
		end
	end
	return m
end

-- Janela com luz quente, moldura, cruz e neve no parapeito.
-- cf fica no centro da janela, com -Z apontando para FORA da parede.
function Natal.janela(pai: Instance, cf: CFrame, largura: number?, altura: number?): Model
	local m = Natal.modelo(pai, "Janela")
	local w, h = largura or 2.8, altura or 3.4
	Natal.peca(m, { Name = "Moldura", Size = Vector3.new(w + 0.8, h + 0.8, 0.35), CFrame = cf, Color = P.madeiraEscura, Material = Enum.Material.Wood })
	Natal.peca(m, { Name = "Vidro", Size = Vector3.new(w, h, 0.2), CFrame = cf * CFrame.new(0, 0, -0.15), Color = P.luz, Material = Enum.Material.Neon, Transparency = 0.05 })
	Natal.peca(m, { Name = "Cruz", Size = Vector3.new(0.22, h, 0.3), CFrame = cf * CFrame.new(0, 0, -0.25), Color = P.madeiraEscura })
	Natal.peca(m, { Name = "Cruz", Size = Vector3.new(w, 0.22, 0.3), CFrame = cf * CFrame.new(0, 0, -0.25), Color = P.madeiraEscura })
	Natal.elipse(m, cf * CFrame.new(0, -h / 2 - 0.35, -0.35), Vector3.new(w + 1.1, 0.55, 0.9), P.neve, { Name = "NeveParapeito", Material = Enum.Material.Snow })
	return m
end

------------------------------------------------------------------------
-- CONSTRUÇÕES
------------------------------------------------------------------------

-- Telhado de duas águas com neve, frontões e pingentes.
-- cfTopo = centro do topo das paredes (frente = -Z). A cumeeira corre de frente para trás.
-- opcoes: cor, pingentes (sim/não), luzesFrente (lâmpadas em cada lado da frente)
function Natal.telhado(pai: Instance, cfTopo: CFrame, largura: number, profundidade: number, alturaCumeeira: number, beiral: number?, opcoes: { [string]: any }?): Model
	local o = opcoes or {}
	local m = Natal.modelo(pai, "Telhado")
	local b = beiral or 1.5
	local metade = largura / 2
	local alcance = metade + b
	local angulo = math.atan2(alturaCumeeira, metade)
	local comprimento = alcance / math.cos(angulo)
	local fundo = profundidade + b * 2
	local t = 0.9
	local yBeiral = -b * math.tan(angulo)
	local cor = o.cor or P.vermelhoEscuro
	for _, lado in { -1, 1 } do
		local normal = Vector3.new(lado * math.sin(angulo), math.cos(angulo), 0)
		local centro = Vector3.new(lado * alcance / 2, alturaCumeeira - alcance * math.tan(angulo) / 2, 0)
		local giro = CFrame.Angles(0, 0, -lado * angulo)
		local placa = Natal.peca(m, { Name = "Telha", Size = Vector3.new(comprimento + 0.4, t, fundo), CFrame = cfTopo * CFrame.new(centro + normal * t / 2) * giro, Color = cor })
		placa.CastShadow = true
		placa.CanCollide = true
		Natal.peca(m, { Name = "NeveTelhado", Size = Vector3.new(comprimento * 0.97, 0.7, fundo - 0.2), CFrame = cfTopo * CFrame.new(centro + normal * (t + 0.3)) * giro, Color = P.neve, Material = Enum.Material.Snow })
		-- Rolinho de neve na beirada (deixa a borda arredondada)
		local beirada = cfTopo * CFrame.new(lado * (alcance - 0.3), yBeiral + t + 0.2, 0)
		Natal.elipse(m, beirada, Vector3.new(1.3, 1.1, fundo + 0.2), P.neve, { Name = "NeveBeirada", Material = Enum.Material.Snow })
		if o.pingentes ~= false then
			local a = (cfTopo * CFrame.new(lado * alcance, yBeiral - 0.1, -fundo / 2 + 0.6)).Position
			local z = (cfTopo * CFrame.new(lado * alcance, yBeiral - 0.1, fundo / 2 - 0.6)).Position
			Natal.pingentes(m, a, z, math.clamp(math.floor(fundo / 3), 3, 9), 1.6)
		end
		-- Frontões (os triângulos de parede na frente e atrás)
		for _, frente in { -1, 1 } do
			local B = (cfTopo * CFrame.new(0, 0, frente * (profundidade / 2 - 0.5))).Position
			Natal.triangulo(m, B, cfTopo.RightVector * lado, metade, cfTopo.UpVector, alturaCumeeira, 1, o.corFrontao or P.madeira, { Name = "Frontao", Material = Enum.Material.WoodPlanks, CastShadow = true })
		end
		if o.luzesFrente and o.luzesFrente > 0 then
			local alto = (cfTopo * CFrame.new(0, alturaCumeeira + t + 0.2, -fundo / 2 - 0.2)).Position
			local baixo = (cfTopo * CFrame.new(lado * (alcance - 0.4), yBeiral + t + 0.2, -fundo / 2 - 0.2)).Position
			for i = 1, o.luzesFrente do
				Natal.lampada(m, alto:Lerp(baixo, (i - 0.5) / o.luzesFrente) - CIMA * 0.15, 0.55)
			end
		end
	end
	Natal.elipse(m, cfTopo * CFrame.new(0, alturaCumeeira + t + 0.35, 0), Vector3.new(1.8, 1.3, fundo + 0.3), P.neve, { Name = "NeveCumeeira", Material = Enum.Material.Snow })
	return m
end

-- Chalé de madeira fechado (corpo + fundação + toras nos cantos + telhado nevado).
-- cf = centro no chão, com a FRENTE para cf.LookVector.
-- opcoes: janelas (padrão sim), porta, chamine, janelaRedonda, luzesFrente, corTelhado, inclinacao
function Natal.chale(pai: Instance, cf: CFrame, largura: number, profundidade: number, altura: number, opcoes: { [string]: any }?): (Model, { [string]: any })
	local o = opcoes or {}
	local m = Natal.modelo(pai, o.nome or "Chale")
	local info: { [string]: any } = {}
	Natal.solida(m, { Name = "Paredes", Size = Vector3.new(largura, altura, profundidade), CFrame = cf * CFrame.new(0, altura / 2, 0), Color = P.madeira, Material = Enum.Material.WoodPlanks })
	Natal.solida(m, { Name = "Fundacao", Size = Vector3.new(largura + 0.8, 1.6, profundidade + 0.8), CFrame = cf * CFrame.new(0, 0.8, 0), Color = P.pedra, Material = Enum.Material.Cobblestone })
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			local base = (cf * CFrame.new(x * largura / 2, 0, z * profundidade / 2)).Position
			Natal.cilindro(m, base, base + CIMA * altura, 1.4, P.madeiraClara, { Name = "Tora", Material = Enum.Material.Wood })
		end
	end
	local hCumeeira = largura / 2 * (o.inclinacao or 0.62)
	Natal.telhado(m, cf * CFrame.new(0, altura, 0), largura, profundidade, hCumeeira, 1.6, { cor = o.corTelhado, luzesFrente = o.luzesFrente })
	info.cumeeira = (cf * CFrame.new(0, altura + hCumeeira, 0)).Position

	-- Janelas nas laterais e na frente (com -Z do cf da janela apontando para fora)
	if o.janelas ~= false then
		local yJanela = math.min(altura * 0.55, altura - 3)
		local nLado = math.max(1, math.floor(profundidade / 9))
		for _, lado in { -1, 1 } do
			for i = 1, nLado do
				local z = -profundidade / 2 + profundidade * (i - 0.5) / nLado
				local p = cf * CFrame.new(lado * (largura / 2 + 0.2), yJanela, z)
				Natal.janela(m, CFrame.lookAt(p.Position, p.Position + cf.RightVector * lado))
			end
		end
		local nFrente = math.max(1, math.floor(largura / 10))
		for i = 1, nFrente do
			local x = -largura / 2 + largura * (i - 0.5) / nFrente
			if not (o.porta and math.abs(x) < 4) then
				local p = cf * CFrame.new(x, yJanela, -profundidade / 2 - 0.2)
				Natal.janela(m, CFrame.lookAt(p.Position, p.Position + cf.LookVector))
			end
		end
	end
	if o.janelaRedonda then
		local p = cf * CFrame.new(0, altura + hCumeeira * 0.42, -profundidade / 2 - 0.15)
		local virado = CFrame.fromMatrix(p.Position, cf.LookVector, cf.UpVector)
		Natal.peca(m, { Name = "AroJanela", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 3.4, 3.4), CFrame = virado, Color = P.madeiraEscura })
		Natal.peca(m, { Name = "JanelaRedonda", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 2.6, 2.6), CFrame = virado * CFrame.new(0.1, 0, 0), Color = P.luz, Material = Enum.Material.Neon })
	end
	if o.porta then
		local p = cf * CFrame.new(0, 3.6, -profundidade / 2 - 0.25)
		Natal.peca(m, { Name = "Porta", Size = Vector3.new(4.4, 7.2, 0.4), CFrame = p, Color = P.vermelho, Material = Enum.Material.Wood })
		Natal.peca(m, { Name = "Batente", Size = Vector3.new(5.4, 7.8, 0.3), CFrame = p * CFrame.new(0, 0.3, 0.1), Color = P.madeiraEscura })
		Natal.bola(m, (p * CFrame.new(1.5, -0.3, -0.3)).Position, 0.45, P.dourado, { Name = "Macaneta", Material = Enum.Material.Foil })
		Natal.guirlanda(m, CFrame.lookAt((p * CFrame.new(0, 1.6, -0.35)).Position, (p * CFrame.new(0, 1.6, -5)).Position), 2.4)
		info.porta = p
	end
	if o.chamine then
		local base = cf * CFrame.new(largura * 0.24, altura, profundidade * 0.15)
		local alturaChamine = hCumeeira + 4
		local corpo = Natal.solida(m, { Name = "Chamine", Size = Vector3.new(2.6, alturaChamine, 2.6), CFrame = base * CFrame.new(0, alturaChamine / 2, 0), Color = P.pedra, Material = Enum.Material.Cobblestone })
		local boca = Natal.peca(m, { Name = "BocaChamine", Size = Vector3.new(3.2, 0.7, 3.2), CFrame = corpo.CFrame * CFrame.new(0, alturaChamine / 2 + 0.35, 0), Color = P.metal })
		local saida = Natal.peca(m, { Name = "Fumaca", Size = Vector3.new(1.6, 0.5, 1.6), CFrame = boca.CFrame * CFrame.new(0, 0.7, 0), Transparency = 1 })
		saida:AddTag(TAGS.chamine)
		info.chamine = saida
	end
	return m, info
end

------------------------------------------------------------------------
-- TERRENO DE NEVE (Terrain)
------------------------------------------------------------------------
-- O chão fica sempre na altura 0 (de y = -4 até 0), igual ao chão antigo.
-- Os blocos são alinhados de 4 em 4 studs (o tamanho do "voxel" do terreno),
-- assim o chão das áreas de jogo fica perfeitamente plano.

local function alinhar(v: number): number
	return math.floor(v / 4 + 0.5) * 4
end

function Natal.prepararTerreno()
	local t = workspace.Terrain
	t:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(236, 243, 252))
	t:SetMaterialColor(Enum.Material.Glacier, P.neveBatida)
	t:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(104, 112, 128))
	t.WaterWaveSize = 0
	t.Decoration = false
end

-- Chão de neve retangular, centro em (x, z)
function Natal.chaoDeNeve(x: number, z: number, tamX: number, tamZ: number)
	workspace.Terrain:FillBlock(CFrame.new(alinhar(x), -2, alinhar(z)), Vector3.new(alinhar(tamX), 4, alinhar(tamZ)), Enum.Material.Snow)
end

-- Caminho de neve batida de A até B (só troca o "material" do chão, sem mudar a altura)
function Natal.caminho(a: Vector3, b: Vector3, largura: number)
	local passos = math.max(1, math.ceil((b - a).Magnitude / 2))
	local lado = alinhar(math.max(4, largura))
	local feitos = {}
	for i = 0, passos do
		local p = a:Lerp(b, i / passos)
		local cx, cz = alinhar(p.X), alinhar(p.Z)
		local chave = cx .. "," .. cz
		if not feitos[chave] then
			feitos[chave] = true
			workspace.Terrain:FillBlock(CFrame.new(cx, -2, cz), Vector3.new(lado, 4, lado), Enum.Material.Glacier)
		end
	end
end

-- Praça redonda de neve batida
function Natal.praca(centro: Vector3, raio: number)
	local r = math.floor(raio / 4)
	for ix = -r, r do
		for iz = -r, r do
			if ix * ix + iz * iz <= r * r then
				workspace.Terrain:FillBlock(CFrame.new(alinhar(centro.X) + ix * 4, -2, alinhar(centro.Z) + iz * 4), Vector3.new(4, 4, 4), Enum.Material.Glacier)
			end
		end
	end
end

-- Anel de neve batida (caminho em volta de algo redondo, como a montanha)
function Natal.anel(centro: Vector3, raioInterno: number, raioExterno: number)
	local r = math.ceil(raioExterno / 4)
	for ix = -r, r do
		for iz = -r, r do
			local d = math.sqrt(ix * ix + iz * iz) * 4
			if d >= raioInterno and d <= raioExterno then
				workspace.Terrain:FillBlock(CFrame.new(alinhar(centro.X) + ix * 4, -2, alinhar(centro.Z) + iz * 4), Vector3.new(4, 4, 4), Enum.Material.Glacier)
			end
		end
	end
end

-- Montinho de neve (só uma "tampinha" aparece acima do chão)
function Natal.montinho(pos: Vector3, raio: number, altura: number?)
	local h = altura or raio * 0.45
	workspace.Terrain:FillBall(Vector3.new(pos.X, h - raio, pos.Z), raio, Enum.Material.Snow)
end

-- Montanhas nevadas em volta do mapa (fundo do cenário e limite natural)
-- "pontos" = lista de posições no chão onde ficam os picos
function Natal.montanhas(pontos: { Vector3 }, raioMin: number, raioMax: number)
	for i, p in pontos do
		local r = rng:NextNumber(raioMin, raioMax)
		local centro = Vector3.new(p.X, -r * 0.3, p.Z)
		workspace.Terrain:FillBall(centro, r, Enum.Material.Snow)
		-- Um pouco de pedra aparecendo nas encostas de algumas montanhas
		if i % 3 == 0 then
			workspace.Terrain:FillBall(centro + Vector3.new(r * 0.35, r * 0.25, 0), r * 0.42, Enum.Material.Rock)
			workspace.Terrain:FillBall(centro + Vector3.new(r * 0.3, r * 0.42, 0), r * 0.3, Enum.Material.Snow)
		end
	end
end

------------------------------------------------------------------------
-- ILUMINAÇÃO DE FIM DE TARDE NATALINO
------------------------------------------------------------------------
-- Céu frio e azulado + luzes quentes nas casas e árvores.
-- Obs.: Lighting.Technology (Future) não pode ser mudado por script; ele vem
-- do .project.json (veja o README).

local function efeito(classe: string, nome: string): Instance
	local antigo = Lighting:FindFirstChild(nome)
	if antigo then
		antigo:Destroy()
	end
	-- Tira efeitos padrão do mesmo tipo para não somar com os nossos
	for _, filho in Lighting:GetChildren() do
		if filho.ClassName == classe then
			filho:Destroy()
		end
	end
	local e = Instance.new(classe)
	e.Name = nome
	e.Parent = Lighting
	return e
end

function Natal.iluminacao()
	Lighting.ClockTime = 17.2
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(90, 95, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 150, 185)
	Lighting.ExposureCompensation = 0.1
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.35
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GeographicLatitude = 41

	local atm = efeito("Atmosphere", "NatalAtmosfera") :: Atmosphere
	atm.Density = 0.28
	atm.Offset = 0.1
	atm.Color = Color3.fromRGB(199, 214, 255)
	atm.Decay = Color3.fromRGB(106, 112, 150)
	atm.Glare = 0.2
	atm.Haze = 1.2

	local bloom = efeito("BloomEffect", "NatalBrilho") :: BloomEffect
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 1.6

	local cor = efeito("ColorCorrectionEffect", "NatalCor") :: ColorCorrectionEffect
	cor.Saturation = 0.08
	cor.Contrast = 0.06
	cor.TintColor = Color3.fromRGB(255, 248, 240)

	local sol = efeito("SunRaysEffect", "NatalRaios") :: SunRaysEffect
	sol.Intensity = 0.05
	sol.Spread = 0.6
end

return Natal
