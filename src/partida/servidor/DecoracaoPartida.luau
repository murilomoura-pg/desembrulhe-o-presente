-- 🎄 Decoração de Natal da PARTIDA (só visual: não muda nada no jogo).
-- O pátio vira a OFICINA DO PAPAI NOEL: fachada da oficina atrás do spawn, muros de
-- pedra e madeira com luzes e guirlandas, portão de oficina, bancada de elfo na mesa,
-- barraquinha natalina na loja, postes em volta da montanha, estrela dourada no alto
-- e floresta + montanhas nevadas do lado de fora.
-- As peças que funcionam são feitas no MapaPartida; aqui elas só ganham enfeites.

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

------------------------------------------------------------------------
-- TERRENO
------------------------------------------------------------------------
local function terreno(info: { [string]: any })
	local M, raio = info.meio, info.raio
	Natal.prepararTerreno()
	Natal.chaoDeNeve(0, 0, M * 2 + 200, M * 2 + 200)
	-- Caminhos de neve batida: anel em volta da montanha e ligações
	Natal.anel(Vector3.zero, raio + 15, raio + 28)
	Natal.caminho(Vector3.new(0, 0, info.zSul), Vector3.new(0, 0, raio + 22), 12)
	Natal.caminho(Vector3.new(info.mesaPos.X, 0, info.zSul - 4), Vector3.new(info.lojaPos.X, 0, info.zSul - 4), 8)
	Natal.caminho(Vector3.new(0, 0, -(raio + 22)), Vector3.new(0, 0, -M + 2), 12)
	-- Lá fora: caminho saindo pelo portão
	Natal.caminho(Vector3.new(0, 0, -M - 4), Vector3.new(0, 0, -M - 60), 12)

	-- Montanhas nevadas bem grandes lá fora (aparecem por cima dos muros)
	local pontos = {}
	for i = 0, 19 do
		local a = i * TAU / 20 + 0.1
		local r = M + 125 + Natal.sortear(-10, 15)
		table.insert(pontos, Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
	end
	Natal.montanhas(pontos, 70, 95)
end

------------------------------------------------------------------------
-- MUROS: pedra embaixo, madeira em cima, toras, luzes e guirlandas
------------------------------------------------------------------------
-- Um trecho reto de muro visto de dentro do pátio.
-- a, b = pontas do trecho no chão, colado na face de dentro; dentro = direção do pátio
local function enfeitarMuro(dec: Instance, a: Vector3, b: Vector3, dentro: Vector3, altura: number, comGuirlanda: (number) -> boolean, pularX: number?)
	local m = Natal.modelo(dec, "MuroEnfeitado")
	local dir = b - a
	local comprimento = dir.Magnitude
	local lado = dir.Unit
	local cf = CFrame.fromMatrix((a + b) / 2, lado, CIMA, -dentro)
	-- Tábuas de madeira na parte de cima e um friso separando da pedra
	Natal.peca(m, { Name = "Tabuas", Size = Vector3.new(comprimento, altura - 9.5, 0.4), CFrame = cf * CFrame.new(0, 9.5 + (altura - 9.5) / 2, -0.2), Color = P.madeira, Material = Enum.Material.WoodPlanks })
	Natal.peca(m, { Name = "Friso", Size = Vector3.new(comprimento, 0.7, 0.9), CFrame = cf * CFrame.new(0, 9.5, -0.45), Color = P.madeiraEscura, Material = Enum.Material.Wood })
	Natal.elipse(m, cf * CFrame.new(0, altura + 1.9, 2), Vector3.new(comprimento + 1, 1.4, 5.6), P.neve, { Name = "NeveMuro", Material = Enum.Material.Snow })
	-- Toras a cada ~19 studs, com luzes entre elas
	local n = math.max(1, math.floor(comprimento / 19))
	local anterior: Vector3? = nil
	for i = 0, n do
		local p = a + lado * (comprimento * i / n) + dentro * 0.7
		local pular = pularX and math.abs(p.X) < pularX
		if not pular then
			Natal.cilindro(m, p, p + CIMA * (altura + 1.2), 1.5, P.madeiraClara, { Name = "Tora", Material = Enum.Material.Wood })
			Natal.bola(m, p + CIMA * (altura + 1.6), 1.5, P.neve, { Name = "NeveTora", Material = Enum.Material.Snow })
			if comGuirlanda(i) then
				local pg = p + CIMA * 17 + dentro * 0.9
				Natal.guirlanda(m, CFrame.lookAt(pg, pg + dentro), 3)
			elseif i % 2 == 1 then
				Natal.laco(m, CFrame.lookAt(p + CIMA * 17 + dentro * 0.9, p + CIMA * 17 + dentro * 5), 1.6, P.vermelho)
			end
			if anterior and i % 2 == 1 then
				Natal.cordaoDeLuzes(m, anterior + CIMA * 21.5 + dentro * 0.6, p + CIMA * 21.5 + dentro * 0.6, 6, 1.4)
			end
			anterior = p
		else
			anterior = nil
		end
	end
end

local function muros(dec: Instance, info: { [string]: any })
	local M, h = info.meio, info.alturaMuro
	local d = M - 2 -- face de dentro dos muros
	local g = info.larguraPortao / 2
	local nenhuma = function(_i: number)
		return false
	end
	-- Sul (atrás do spawn): o meio fica para a fachada da oficina
	enfeitarMuro(dec, Vector3.new(-d, 0, d), Vector3.new(d, 0, d), -Vector3.zAxis, h, function(i)
		return i == 1 or i == 7
	end, 33)
	-- Leste e oeste
	enfeitarMuro(dec, Vector3.new(d, 0, d - 2), Vector3.new(d, 0, -d + 2), -Vector3.xAxis, h, function(i)
		return i == 2 or i == 6
	end)
	enfeitarMuro(dec, Vector3.new(-d, 0, -d + 2), Vector3.new(-d, 0, d - 2), Vector3.xAxis, h, function(i)
		return i == 2 or i == 6
	end)
	-- Norte (dos dois lados do portão)
	enfeitarMuro(dec, Vector3.new(-d, 0, -d), Vector3.new(-g - 7, 0, -d), Vector3.zAxis, h, nenhuma)
	enfeitarMuro(dec, Vector3.new(g + 7, 0, -d), Vector3.new(d, 0, -d), Vector3.zAxis, h, nenhuma)
end

------------------------------------------------------------------------
-- FACHADA DA OFICINA DO PAPAI NOEL (atrás do spawn)
------------------------------------------------------------------------
local function oficina(dec: Instance, info: { [string]: any })
	local M = info.meio
	local pos = Vector3.new(0, 0, M - 5)
	local cf = CFrame.lookAt(pos, Vector3.new(0, 0, 0))
	local m, _ = Natal.chale(dec, cf, 60, 6, 28, { nome = "OficinaDoPapaiNoel", janelas = false, chamine = true, luzesFrente = 12, inclinacao = 0.4 })
	-- Placa grande no frontão
	Natal.placaDeMadeira(m, cf * CFrame.new(0, 31, -3.45), "🎅 OFICINA DO PAPAI NOEL", 30, 5)
	-- Portão grande (enfeite) com faixas douradas e guirlanda
	local porta = cf * CFrame.new(0, 7, -3.2)
	Natal.peca(m, { Name = "BatentePorta", Size = Vector3.new(11.6, 14.4, 0.4), CFrame = porta, Color = P.madeiraEscura, Material = Enum.Material.Wood })
	for _, lado in { -1, 1 } do
		Natal.peca(m, { Name = "Folha", Size = Vector3.new(4.9, 13.2, 0.4), CFrame = porta * CFrame.new(lado * 2.6, -0.4, -0.2), Color = P.vermelho, Material = Enum.Material.Wood })
		Natal.bola(m, (porta * CFrame.new(lado * 0.8, -1, -0.55)).Position, 0.6, P.dourado, { Name = "Macaneta", Material = Enum.Material.Foil })
	end
	for _, y in { -4, 3 } do
		Natal.peca(m, { Name = "FaixaPorta", Size = Vector3.new(10.2, 0.5, 0.2), CFrame = porta * CFrame.new(0, y, -0.5), Color = P.dourado, Material = Enum.Material.Foil })
	end
	Natal.guirlanda(m, CFrame.lookAt((porta * CFrame.new(0, 9.4, -0.5)).Position, (porta * CFrame.new(0, 9.4, -5)).Position), 4)
	-- Janelas acesas em dois andares
	for _, x in { -23, -12.5, 12.5, 23 } do
		for _, y in { 8.5, 19 } do
			local p = cf * CFrame.new(x, y, -3.2)
			Natal.janela(m, CFrame.lookAt(p.Position, p.Position + cf.LookVector), 3.2, 4)
		end
	end
	-- Meias penduradas embaixo das janelas de cima
	for _, x in { -17.75, 17.75 } do
		local p = cf * CFrame.new(x, 17, -3.5)
		Natal.meia(m, CFrame.lookAt(p.Position, p.Position + cf.LookVector))
	end
	-- Lanternas na porta (uma acesa)
	Natal.lanterna(m, (cf * CFrame.new(-7.4, 8, -3.9)).Position, true)
	Natal.lanterna(m, (cf * CFrame.new(7.4, 8, -3.9)).Position, false)
end

------------------------------------------------------------------------
-- PORTÃO: pilares de pedra, moldura que acende e cadeado bem visível
------------------------------------------------------------------------
local function portao(dec: Instance, info: { [string]: any })
	local m = Natal.modelo(dec, "PortaoDecoracao")
	local M = info.meio
	local g = info.larguraPortao / 2
	local h = info.alturaMuro
	local zDentro = -M + 2

	-- Pilares de pedra dos dois lados, com lanternas que acendem forte quando a chave aparece
	for _, lado in { -1, 1 } do
		local x = lado * (g + 3)
		local pilar = Natal.solida(m, { Name = "Pilar", Size = Vector3.new(6, h + 6, 7), CFrame = CFrame.new(x, (h + 6) / 2, -M), Color = P.pedra, Material = Enum.Material.Cobblestone })
		local capitel = Natal.peca(m, { Name = "Capitel", Size = Vector3.new(7.2, 1.4, 8.2), CFrame = pilar.CFrame * CFrame.new(0, (h + 6) / 2 + 0.7, 0), Color = P.pedra, Material = Enum.Material.Slate })
		Natal.neveEmCima(m, capitel, 1.2)
		Natal.bola(m, capitel.Position + CIMA * 2.2, 2.4, P.dourado, { Name = "Esfera", Material = Enum.Material.Foil })
		local lanterna = Natal.peca(m, { Name = "LanternaPortao", Size = Vector3.new(1.6, 2.2, 1.6), CFrame = CFrame.new(x, 17, zDentro + 2.6), Color = P.luz, Material = Enum.Material.Neon })
		lanterna:AddTag(TAGS.portao)
		Natal.luz(lanterna, P.luz, 16, 1)
		Natal.peca(m, { Name = "Suporte", Size = Vector3.new(0.4, 0.4, 2), CFrame = CFrame.new(x, 18.2, zDentro + 1.6), Color = P.metal, Material = Enum.Material.Metal })
		-- Pinheiro decorado e bengala do lado de dentro
		Natal.pinheiro(m, Vector3.new(lado * (g + 14), 0, zDentro + 9), 1.1, { luzes = true, bolas = true, lacos = true, estrela = true })
		local pb = Vector3.new(lado * (g + 4.5), 0, zDentro + 6)
		Natal.bengala(m, pb, 1.2, giroPara(pb, Vector3.zero))
	end
	-- Moldura dourada em volta da abertura (acende quando acham a chave)
	for _, dados in {
		{ Vector3.new(0.6, h - 4, 0.4), Vector3.new(-g - 0.3, (h - 4) / 2, zDentro + 1.7) },
		{ Vector3.new(0.6, h - 4, 0.4), Vector3.new(g + 0.3, (h - 4) / 2, zDentro + 1.7) },
		{ Vector3.new(info.larguraPortao + 1.2, 0.6, 0.4), Vector3.new(0, h - 4 + 0.3, zDentro + 0.25) },
	} do
		local friso = Natal.peca(m, { Name = "FrisoPortao", Size = dados[1], CFrame = CFrame.new(dados[2]), Color = P.dourado, Material = Enum.Material.Neon, Transparency = 0.35 })
		friso:AddTag(TAGS.portao)
	end
	-- Placa da saída com moldura e neve
	Natal.moldura(m, info.placaPortao, { neve = true, cantos = true })

	-- Faixas de ferro dourado NO portão (soldadas: sobem junto quando ele abre)
	local p: BasePart = info.portao
	local frente = p.Size.Z / 2 + 0.15
	for _, y in { -7, 0, 7 } do
		local faixa = Natal.peca(m, { Name = "FaixaPortao", Size = Vector3.new(p.Size.X - 0.4, 1, 0.3), CFrame = p.CFrame * CFrame.new(0, y, frente), Color = P.dourado, Material = Enum.Material.Foil })
		Natal.soldar(p, faixa)
	end
	local meioPortao = Natal.peca(m, { Name = "EmendaPortao", Size = Vector3.new(0.5, p.Size.Y - 0.4, 0.3), CFrame = p.CFrame * CFrame.new(0, 0, frente), Color = P.madeiraEscura, Material = Enum.Material.Wood })
	Natal.soldar(p, meioPortao)

	-- Cadeado: alça e buraco da fechadura (ficam DENTRO do cadeado, então somem com ele na fuga)
	local c: BasePart = info.cadeado
	local topo = c.CFrame * CFrame.new(0, c.Size.Y / 2, 0)
	for _, lado in { -1, 1 } do
		Natal.cilindro(c, (topo * CFrame.new(lado * 1.2, 0, 0)).Position, (topo * CFrame.new(lado * 1.2, 2.2, 0)).Position, 0.7, P.dourado, { Name = "Alca", Material = Enum.Material.Foil })
		Natal.bola(c, (topo * CFrame.new(lado * 1.2, 2.2, 0)).Position, 0.7, P.dourado, { Name = "Alca", Material = Enum.Material.Foil })
	end
	Natal.cilindro(c, (topo * CFrame.new(-1.2, 2.2, 0)).Position, (topo * CFrame.new(1.2, 2.2, 0)).Position, 0.7, P.dourado, { Name = "Alca", Material = Enum.Material.Foil })
	local face = c.CFrame * CFrame.new(0, 0.3, c.Size.Z / 2 + 0.05)
	Natal.bola(c, (face * CFrame.new(0, 0.4, 0)).Position, 0.8, P.metal, { Name = "Fechadura" })
	Natal.peca(c, { Name = "Fechadura", Size = Vector3.new(0.35, 1.1, 0.15), CFrame = face * CFrame.new(0, -0.25, 0), Color = P.metal })
end

------------------------------------------------------------------------
-- MESA DE DESEMBRULHAR: bancada de elfo
------------------------------------------------------------------------
local function bancada(dec: Instance, info: { [string]: any })
	local m = Natal.modelo(dec, "BancadaDeElfo")
	local base = info.mesaPos
	local topo = base.Y + 3.9
	-- Saia de tecido vermelho na frente e atrás da mesa
	for _, z in { -3.62, 3.62 } do
		Natal.peca(m, { Name = "Toalha", Size = Vector3.new(16.3, 2.4, 0.15), CFrame = CFrame.new(base + Vector3.new(0, 2.4, z)), Color = P.vermelho, Material = Enum.Material.Fabric })
		Natal.peca(m, { Name = "BarraToalha", Size = Vector3.new(16.3, 0.35, 0.2), CFrame = CFrame.new(base + Vector3.new(0, 1.25, z)), Color = P.dourado, Material = Enum.Material.Foil })
	end
	-- Rolos de papel de presente
	for i, d in { { -4.5, -2, P.vermelho }, { -0.5, -2.3, P.verdeClaro } } do
		local c = base + Vector3.new(d[1], topo + 0.45, d[2])
		Natal.cilindro(m, c - Vector3.xAxis * 2.5, c + Vector3.xAxis * 2.5, 0.9, d[3], { Name = "RoloPapel" })
		for _, x in { -1.2, 1.2 } do
			Natal.cilindro(m, c + Vector3.xAxis * (x - 0.1), c + Vector3.xAxis * (x + 0.1), 0.95, i == 1 and P.neve or P.dourado, { Name = "ListraRolo" })
		end
	end
	-- Tesoura aberta
	local t = CFrame.new(base + Vector3.new(4.6, topo + 0.1, 1.2))
	for _, lado in { -1, 1 } do
		local lamina = t * CFrame.Angles(0, math.rad(lado * 18), 0)
		Natal.peca(m, { Name = "Lamina", Size = Vector3.new(0.25, 0.12, 2.8), CFrame = lamina * CFrame.new(0, 0, -1.2), Color = Color3.fromRGB(200, 210, 220), Material = Enum.Material.Metal })
		Natal.peca(m, { Name = "Cabo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 1, 1), CFrame = lamina * CFrame.new(0, 0, 0.7) * CFrame.Angles(0, 0, math.rad(90)), Color = P.vermelho })
	end
	-- Carretéis de fita
	for i, d in { { -6.6, 1.8 }, { -5.1, 2.4 } } do
		local c = base + Vector3.new(d[1], topo, d[2])
		Natal.cilindro(m, c, c + CIMA * 0.6, 1.2, i == 1 and P.dourado or P.vermelho, { Name = "Carretel" })
	end
	-- Presentes sendo embrulhados
	Natal.presente(m, base + Vector3.new(0.6, topo, 1.2), Vector3.new(1.8, 1.4, 1.8), P.azul, P.vermelho, 0.3, true)
	Natal.presente(m, base + Vector3.new(2.6, topo, -1.8), Vector3.new(1.3, 1.6, 1.3), P.vermelho, P.dourado, -0.2)

	-- Estante de elfo do lado de fora (oeste), com rolos coloridos
	local e = CFrame.lookAt(base + Vector3.new(-11.5, 0, 0), base + Vector3.new(0, 0, 0))
	Natal.solida(m, { Name = "FundoEstante", Size = Vector3.new(9, 10, 0.6), CFrame = e * CFrame.new(0, 5, 0.9), Color = P.madeira, Material = Enum.Material.WoodPlanks })
	for _, x in { -4.6, 4.6 } do
		Natal.peca(m, { Name = "LadoEstante", Size = Vector3.new(0.6, 10.4, 2.4), CFrame = e * CFrame.new(x, 5.2, 0), Color = P.madeiraEscura, Material = Enum.Material.Wood })
	end
	local cores = { P.vermelho, P.verdeClaro, P.dourado, P.azul, P.neve }
	for nivel, y in { 2.4, 5.4, 8.4 } do
		Natal.peca(m, { Name = "Prateleira", Size = Vector3.new(9, 0.4, 2.4), CFrame = e * CFrame.new(0, y, 0), Color = P.madeiraEscura, Material = Enum.Material.Wood })
		for k = 1, 3 do
			local c = (e * CFrame.new(-3 + (k - 1) * 3, y + 0.65, -0.1)).Position
			Natal.cilindro(m, c - e.LookVector * 1, c + e.LookVector * 1, 0.9, cores[(nivel + k) % #cores + 1], { Name = "RoloEstante" })
		end
	end
	local tampo = Natal.peca(m, { Name = "TopoEstante", Size = Vector3.new(9.8, 0.5, 2.8), CFrame = e * CFrame.new(0, 10.6, 0), Color = P.madeiraEscura, Material = Enum.Material.Wood })
	Natal.neveEmCima(m, tampo, 0.7)

	-- Placa da mesa: moldura de madeira com cantos dourados e neve; dois postes
	-- (o verde aceso fica só no tampo e no círculo da mesa, que é o que importa)
	Natal.moldura(m, info.placaMesa, { neve = true, cantos = true, espessura = 0.45 })
	for _, lado in { -1, 1 } do
		local topoPoste = info.placaMesa.Position + Vector3.new(lado * 8.5, 1.6, 0)
		Natal.cilindro(m, Vector3.new(topoPoste.X, 0, topoPoste.Z), topoPoste, 0.7, P.madeiraEscura, { Name = "PostePlaca", Material = Enum.Material.Wood })
	end
end

------------------------------------------------------------------------
-- LOJA: barraquinha de mercado natalino
------------------------------------------------------------------------
local function barraquinha(dec: Instance, info: { [string]: any })
	local m = Natal.modelo(dec, "Barraquinha")
	local base = info.lojaPos
	local toldo: BasePart = info.toldo
	-- Toldo listrado vermelho e branco, com babado na beirada
	for _, x in { -6, -2, 2, 6 } do
		Natal.peca(m, { Name = "Listra", Size = Vector3.new(2, 0.64, toldo.Size.Z + 0.02), CFrame = toldo.CFrame * CFrame.new(x, 0, 0), Color = P.neve, Material = Enum.Material.Fabric })
	end
	for i = 0, 7 do
		local x = -7 + i * 2
		local p = toldo.CFrame * CFrame.new(x, -0.25, toldo.Size.Z / 2)
		Natal.elipse(m, p, Vector3.new(2, 0.9, 0.5), i % 2 == 0 and P.vermelho or P.neve, { Name = "Babado", Material = Enum.Material.Fabric })
	end
	-- Colunas listradas como bengala doce
	for _, coluna in info.colunas do
		for k = 0, 3 do
			local y = -4 + k * 2.6
			Natal.peca(m, { Name = "ListraColuna", Size = Vector3.new(0.9, 0.55, 0.9), CFrame = coluna.CFrame * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(25)), Color = P.vermelho })
		end
		Natal.bola(m, coluna.Position + CIMA * 5.8, 1.1, P.dourado, { Name = "Pinaculo", Material = Enum.Material.Foil })
	end
	-- Lanternas penduradas no toldo (uma acesa)
	for i, x in { -6.5, 6.5 } do
		local p = (toldo.CFrame * CFrame.new(x, -1.6, toldo.Size.Z / 2 - 0.8)).Position
		Natal.lanterna(m, p, i == 1)
	end
	-- Mercadorias no balcão (lembram as melhorias da loja)
	local topo = base.Y + 4.4
	Natal.elipse(m, CFrame.new(base + Vector3.new(-5, topo + 0.8, 0.5)), Vector3.new(1.8, 1.7, 1.6), Color3.fromRGB(150, 110, 70), { Name = "Saco", Material = Enum.Material.Fabric })
	for _, x in { -2.4, -1.4 } do
		Natal.peca(m, { Name = "Bota", Size = Vector3.new(0.7, 1.3, 0.7), CFrame = CFrame.new(base + Vector3.new(x, topo + 0.65, 0.2)), Color = P.vermelho })
		Natal.peca(m, { Name = "PeBota", Size = Vector3.new(0.7, 0.5, 1.2), CFrame = CFrame.new(base + Vector3.new(x, topo + 0.25, 0.45)), Color = P.vermelho })
		Natal.peca(m, { Name = "BarraBota", Size = Vector3.new(0.8, 0.3, 0.8), CFrame = CFrame.new(base + Vector3.new(x, topo + 1.35, 0.2)), Color = P.neve, Material = Enum.Material.Fabric })
	end
	for k = 0, 2 do
		local c = base + Vector3.new(1.6 + k * 0.2, topo + k * 0.32, 0.6)
		Natal.cilindro(m, c, c + CIMA * 0.3, 1.1, P.dourado, { Name = "Moedas", Material = Enum.Material.Foil })
	end
	Natal.presente(m, base + Vector3.new(4.6, topo, 0.2), Vector3.new(1.5, 1.5, 1.5), P.verdeClaro, P.dourado, 0.3, true)
	Natal.elipse(m, CFrame.new(base + Vector3.new(3, topo + 0.3, -0.9)), Vector3.new(1.2, 0.6, 0.9), P.verde, { Name = "Luva" })
	-- Placa da loja com moldura dourada
	Natal.moldura(m, info.placaLoja, { cor = P.dourado, material = Enum.Material.Foil, espessura = 0.35, neve = true })
	-- Pinheirinho decorado ao lado
	Natal.pinheiro(m, base + Vector3.new(11.5, 0, -1), 0.55, { luzes = true, bolas = true, estrela = true })
end

------------------------------------------------------------------------
-- MONTANHA: postes em volta, luzes entre eles e uma estrela dourada no alto
------------------------------------------------------------------------
local function emVoltaDaMontanha(dec: Instance, info: { [string]: any })
	local m = Natal.modelo(dec, "EmVoltaDaMontanha")
	local raio = info.raio
	local pontos = {}
	for i = 0, 7 do
		local a = math.rad(i * 45 + 22.5)
		local p = Vector3.new(math.cos(a) * (raio + 22), 0, math.sin(a) * (raio + 22))
		table.insert(pontos, p)
		Natal.poste(m, p, true)
	end
	for i, p in pontos do
		local q = pontos[i % #pontos + 1]
		Natal.cordaoDeLuzes(m, p + CIMA * 12.4, q + CIMA * 12.4, 9, 2.2)
	end
	-- Estrela gigante flutuando acima do topo da montanha, virada para o spawn
	local alto = raio * 1.2 + 12
	local pos = Vector3.new(0, alto, 0)
	local estrela = Natal.estrela(m, CFrame.lookAt(pos, Vector3.new(0, alto, info.zSul)), 10)
	local miolo = estrela.PrimaryPart :: BasePart
	miolo:AddTag(TAGS.brilho)
	Natal.luz(miolo, P.dourado, 20, 2)
end

------------------------------------------------------------------------
-- CANTOS DO PÁTIO
------------------------------------------------------------------------
local function cantos(dec: Instance, info: { [string]: any })
	local m = Natal.modelo(dec, "Cantos")
	local M = info.meio
	local c = M - 13
	-- Norte: pinheiros grandes decorados
	for _, x in { -c, c } do
		Natal.pinheiro(m, Vector3.new(x, 0, -c), 1.35, { luzes = true, bolas = true, lacos = true, estrela = true })
	end
	-- Sudoeste: trenó com presentes
	local pt = Vector3.new(-c + 2, 0, c - 6)
	Natal.treno(m, CFrame.new(pt) * CFrame.Angles(0, giroPara(pt, Vector3.zero), 0))
	Natal.pilhaDePresentes(m, Vector3.new(-c + 9, 0, c - 1), 4)
	-- Sudeste: boneco de neve e pinheiro
	local pb = Vector3.new(c - 4, 0, c - 8)
	Natal.bonecoDeNeve(m, pb, giroPara(pb, Vector3.zero))
	Natal.pinheiro(m, Vector3.new(c + 2, 0, c - 1), 1.1, { luzes = true, bolas = true })
	-- Meio das laterais: presentes empilhados perto do muro
	Natal.pilhaDePresentes(m, Vector3.new(-c - 4, 0, 0), 4)
	Natal.pilhaDePresentes(m, Vector3.new(c + 4, 0, 0), 4)
end

------------------------------------------------------------------------
-- FLORESTA DO LADO DE FORA (só as copas aparecem por cima dos muros)
------------------------------------------------------------------------
local function florestaDeFora(dec: Instance, info: { [string]: any })
	local m = Natal.modelo(dec, "FlorestaDeFora")
	local M = info.meio
	local feitas = 0
	local colocadas: { Vector3 } = {}
	local tentativas = 0
	while feitas < 28 and tentativas < 300 do
		tentativas += 1
		local ladoMuro = Natal.sortear(0, 4)
		local ao = Natal.sortear(-M - 30, M + 30)
		local fora = M + Natal.sortear(20, 46)
		local p: Vector3
		if ladoMuro < 1 then
			p = Vector3.new(ao, 0, fora)
		elseif ladoMuro < 2 then
			p = Vector3.new(ao, 0, -fora)
		elseif ladoMuro < 3 then
			p = Vector3.new(fora, 0, ao)
		else
			p = Vector3.new(-fora, 0, ao)
		end
		-- Deixa livre a vista pelo portão
		local livre = not (p.Z < -M and math.abs(p.X) < 24)
		for _, q in colocadas do
			if (q - p).Magnitude < 16 then
				livre = false
				break
			end
		end
		if livre then
			table.insert(colocadas, p)
			feitas += 1
			Natal.pinheiro(m, p, Natal.sortear(2, 2.5), {})
		end
	end
end

------------------------------------------------------------------------
function DecoracaoPartida.construir(pasta: Instance, info: { [string]: any })
	local dec = Natal.pasta(pasta, "Decoracao")
	terreno(info)
	muros(dec, info)
	oficina(dec, info)
	portao(dec, info)
	bancada(dec, info)
	barraquinha(dec, info)
	emVoltaDaMontanha(dec, info)
	cantos(dec, info)
	florestaDeFora(dec, info)
end

return DecoracaoPartida
