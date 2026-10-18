-- 🕺 ANIMAÇÕES DOS PERSONAGENS (só visual: roda no seu computador/celular e não muda nada do jogo).
--
-- Os movimentos são feitos por CÓDIGO. A cada quadro, depois que o Roblox aplica as
-- animações normais (andar, pular, ficar parado...), este módulo gira um pouco as
-- articulações (cintura, pescoço, ombros e cotovelos) POR CIMA delas. No quadro seguinte
-- a pose volta a ser a do Roblox, então nada fica travado ou torto se o jogador andar,
-- pular, morrer ou sair no meio. Funciona em R15 e em R6 (o R6 não tem cotovelo).
--
-- Movimentos:
--   • contínuos (ficam ligados enquanto alguém chama "manter"): pegar, desembrulhar;
--   • espera: balanço leve de quem está parado numa sala do lobby (para na hora em que anda);
--   • gestos curtos: colocar, aceno, chegada, comemorar.
-- Também tem: cópia do presente voando até o personagem, "puff" de neve e girar o SEU
-- personagem devagar para um ponto (só quando ele está parado).
--
-- Se Config.ANIMACOES.IDS tiver o ID de uma animação publicada, esse movimento usa a
-- animação publicada no lugar do código.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Compartilhado"):WaitForChild("Config"))
local P = Config.PALETA
local IDS: { [string]: string } = Config.ANIMACOES.IDS
local DUR = Config.ANIMACOES.DURACOES

local Animacoes = {}

local player = Players.LocalPlayer
local celular = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local IDENT = CFrame.identity

-- Giro em graus no espaço do tronco: x = para a frente/trás, y = virar, z = para o lado
local function giro(x: number, y: number, z: number): CFrame
	return CFrame.fromEulerAnglesYXZ(math.rad(x), math.rad(y), math.rad(z))
end

-- 0 → 1 com começo e fim macios
local function suave(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function onda(t: number, porSegundo: number): number
	return math.sin(t * porSegundo * 2 * math.pi)
end

------------------------------------------------------------------------
-- Articulações do personagem
------------------------------------------------------------------------
-- { nome no R15, peça do R15, nome no R6, peça do R6 }
local JUNTAS = {
	cintura = { "Waist", "UpperTorso", "RootJoint", "HumanoidRootPart" },
	pescoco = { "Neck", "Head", "Neck", "Torso" },
	ombroD = { "RightShoulder", "RightUpperArm", "Right Shoulder", "Torso" },
	ombroE = { "LeftShoulder", "LeftUpperArm", "Left Shoulder", "Torso" },
	cotoveloD = { "RightElbow", "RightLowerArm" },
	cotoveloE = { "LeftElbow", "LeftLowerArm" },
}

type Junta = {
	obj: Instance, -- Motor6D (ou AnimationConstraint, nos personagens com as articulações novas do Roblox)
	giro: CFrame, -- como a articulação está virada em relação ao tronco
	desgiro: CFrame,
	fator: number, -- quanto do movimento ela faz (a cintura do R6 leva as pernas junto, então mexe menos)
	base: CFrame?, -- pose do Roblox antes do nosso giro (para devolver no quadro seguinte)
}

local function acharJuntas(char: Model, hum: Humanoid): { [string]: Junta }
	local r6 = hum.RigType == Enum.HumanoidRigType.R6
	local juntas: { [string]: Junta } = {}
	for nome, onde in JUNTAS do
		local nomeJunta, nomePeca = onde[1], onde[2]
		if r6 then
			nomeJunta, nomePeca = onde[3], onde[4]
		end
		local peca = nomePeca and char:FindFirstChild(nomePeca)
		local obj = peca and peca:FindFirstChild(nomeJunta)
		local rot: CFrame? = nil
		if obj and obj:IsA("Motor6D") then
			rot = obj.C0.Rotation
		elseif obj and obj:IsA("AnimationConstraint") and obj.Attachment0 then
			rot = obj.Attachment0.CFrame.Rotation
		end
		if obj and rot then
			juntas[nome] = { obj = obj, giro = rot, desgiro = rot:Inverse(), fator = (r6 and nome == "cintura") and 0.5 or 1, base = nil }
		end
	end
	return juntas
end

local function lerPose(j: Junta): CFrame
	return (j.obj :: any).Transform
end

local function escreverPose(j: Junta, cf: CFrame)
	(j.obj :: any).Transform = cf
end

------------------------------------------------------------------------
-- Estado de cada personagem que está se mexendo
------------------------------------------------------------------------
type Camada = {
	inicio: number, -- quando começou (ou recomeçou do zero)
	ate: number, -- até quando o movimento continua ligado
	peso: number, -- 0 = sem efeito, 1 = movimento inteiro
	alvo: Vector3?, -- para onde olhar (pegar)
	trilha: AnimationTrack?, -- animação publicada (quando tem ID no Config)
	porId: boolean,
}

type Estado = {
	char: Model,
	hum: Humanoid,
	root: BasePart,
	juntas: { [string]: Junta },
	camadas: { [string]: Camada },
	espera: boolean,
	virar: { ponto: Vector3, ate: number }?,
	trilhas: { [string]: AnimationTrack },
}

local estados: { [Model]: Estado } = {}

local function estadoDe(char: Model?): Estado?
	if not char or not char.Parent then
		return nil
	end
	local existente = estados[char]
	if existente then
		return existente
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil
	end
	local juntas = acharJuntas(char, hum)
	if next(juntas) == nil then
		return nil -- personagem ainda carregando (tenta de novo no próximo movimento)
	end
	local e: Estado = { char = char, hum = hum, root = root, juntas = juntas, camadas = {}, espera = false, virar = nil, trilhas = {} }
	estados[char] = e
	return e
end

-- Animação publicada (Config.ANIMACOES.IDS). Retorna true quando o movimento é dela.
-- Só o dono toca a animação no próprio personagem: o Roblox já mostra ela para todo mundo.
local function trilha(e: Estado, nome: string): (boolean, AnimationTrack?)
	local id = IDS[string.upper(nome)]
	if not id or id == "" then
		return false, nil
	end
	if e.char ~= player.Character then
		return true, nil
	end
	local t = e.trilhas[nome]
	if not t then
		local animator = e.hum:FindFirstChildOfClass("Animator")
		if not animator then
			return true, nil
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, nova = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if not ok or not nova then
			return true, nil
		end
		t = nova
		e.trilhas[nome] = nova
	end
	return true, t
end

------------------------------------------------------------------------
-- Os movimentos. Cada "pose" diz quanto girar cada articulação (em graus) no
-- momento t (segundos desde o começo); p vai de 0 a 1 nos gestos curtos.
------------------------------------------------------------------------
type Rots = { [string]: CFrame }
type Movimento = {
	duracao: number?, -- gestos curtos
	subir: number, -- contínuos: segundos para entrar...
	descer: number, -- ...e para sair
	pose: (e: Estado, c: Camada, t: number, p: number) -> Rots,
}

-- Para onde fica um ponto em relação ao personagem: virar e altura, em graus
local function direcao(e: Estado, alvo: Vector3?): (number, number)
	if not alvo then
		return 0, 0
	end
	local rel = e.root.CFrame:PointToObjectSpace(alvo)
	local virar = math.deg(math.atan2(-rel.X, -rel.Z))
	local altura = math.deg(math.atan2(rel.Y - 1, Vector2.new(rel.X, rel.Z).Magnitude))
	return math.clamp(virar, -50, 50), math.clamp(altura, -50, 60)
end

local MOVIMENTOS: { [string]: Movimento } = {
	-- Pegar: vira o tronco e o rosto para o presente, estica os braços e inclina um pouco.
	-- Segurando o clique, os braços continuam "puxando" num ritmo suave (sem recomeçar).
	pegar = {
		subir = DUR.PEGAR * 0.25,
		descer = DUR.PEGAR * 0.45,
		pose = function(e, c, t)
			local virar, altura = direcao(e, c.alvo)
			local puxando = math.clamp((c.ate - c.inicio - 0.3) / 0.3, 0, 1) * onda(t, 2.2)
			local braco = math.clamp(62 + altura * 0.7, 25, 115) + 10 * puxando
			local abaixar = math.max(0, -altura) * 0.3
			return {
				cintura = giro(-(8 + abaixar), virar * 0.55, 0),
				pescoco = giro(altura * 0.4, virar * 0.45, 0),
				ombroD = giro(braco, 0, -12),
				ombroE = giro(braco, 0, 12),
				cotoveloD = giro(22 - 12 * puxando, 0, 0),
				cotoveloE = giro(22 - 12 * puxando, 0, 0),
			}
		end,
	},
	-- Desembrulhar: braços na frente, mãos afastando e juntando (rasgando o papel)
	desembrulhar = {
		subir = 0.15,
		descer = 0.25,
		pose = function(_e, _c, t)
			local s = onda(t, 2.6)
			return {
				cintura = giro(-10, 0, 0),
				pescoco = giro(-18, 0, 0),
				ombroD = giro(46 + 9 * s, 0, -16 + 8 * s),
				ombroE = giro(46 - 9 * s, 0, 16 - 8 * s),
				cotoveloD = giro(50 - 12 * s, 0, 0),
				cotoveloE = giro(50 + 12 * s, 0, 0),
			}
		end,
	},
	-- Espera na sala: balança devagar e mexe os ombros de leve
	espera = {
		subir = 0.6,
		descer = 0.12,
		pose = function(_e, _c, t)
			local s = onda(t, 0.45)
			local ombro = math.max(0, onda(t, 0.9))
			return {
				cintura = giro(0, 3 * s, 2.5 * s),
				pescoco = giro(0, -5 * onda(t, 0.22), -2 * s),
				ombroD = giro(3 * s, 0, 5 + 3 * ombro),
				ombroE = giro(-3 * s, 0, -5 - 3 * ombro),
			}
		end,
	},
	-- Colocar na bancada: inclina, leva os braços para a frente e para baixo e volta
	colocar = {
		duracao = DUR.COLOCAR,
		subir = 0,
		descer = 0,
		pose = function(_e, _c, _t, p)
			local a = math.sin(math.pi * p)
			return {
				cintura = giro(-16 * a, 0, 0),
				pescoco = giro(-12 * a, 0, 0),
				ombroD = giro(58 * a, 0, -8 * a),
				ombroE = giro(58 * a, 0, 8 * a),
				cotoveloD = giro(30 * a, 0, 0),
				cotoveloE = giro(30 * a, 0, 0),
			}
		end,
	},
	-- "Entrei!": levanta a mão direita e acena
	aceno = {
		duracao = DUR.ACENO,
		subir = 0,
		descer = 0,
		pose = function(_e, _c, _t, p)
			local a = suave(p / 0.3) * (1 - suave((p - 0.7) / 0.3))
			local w = math.sin(p * math.pi * 3)
			return {
				cintura = giro(0, 0, 4 * a),
				pescoco = giro(6 * a, 0, 0),
				ombroD = giro(10 * a, 0, (135 + 8 * w) * a),
				cotoveloD = giro(10 * a, 0, 22 * w * a),
			}
		end,
	},
	-- Chegada (o jogo tirou você da sala): pequena "aterrissagem" com os braços abertos
	chegada = {
		duracao = DUR.CHEGADA,
		subir = 0,
		descer = 0,
		pose = function(_e, _c, _t, p)
			local a = math.sin(math.pi * p)
			return {
				cintura = giro(-12 * a, 0, 0),
				pescoco = giro(-6 * a, 0, 0),
				ombroD = giro(15 * a, 0, 42 * a),
				ombroE = giro(15 * a, 0, -42 * a),
			}
		end,
	},
	-- Comemorar (achou a chave / fugiu): os dois braços para cima
	comemorar = {
		duracao = DUR.COMEMORAR,
		subir = 0,
		descer = 0,
		pose = function(_e, _c, _t, p)
			local a = suave(p / 0.25) * (1 - suave((p - 0.75) / 0.25))
			local b = math.abs(math.sin(p * math.pi * 2))
			return {
				cintura = giro(6 * a, 0, 0),
				pescoco = giro(12 * a, 0, 0),
				ombroD = giro(15 * a, 0, (150 - 15 * b) * a),
				ombroE = giro(15 * a, 0, -(150 - 15 * b) * a),
				cotoveloD = giro(15 * b * a, 0, 0),
				cotoveloE = giro(15 * b * a, 0, 0),
			}
		end,
	},
}

------------------------------------------------------------------------
-- Como os outros scripts usam
------------------------------------------------------------------------

-- Liga um movimento contínuo ("pegar" ou "desembrulhar") ou o mantém ligado por mais
-- alguns segundos. Chamar de novo NÃO recomeça o movimento: ele só continua.
function Animacoes.manter(char: Model?, nome: string, segundos: number?, alvo: Vector3?)
	local mov = MOVIMENTOS[nome]
	local e = estadoDe(char)
	if not e or not mov or mov.duracao then
		return
	end
	local agora = os.clock()
	local c = e.camadas[nome]
	if not c then
		c = { inicio = agora, ate = agora, peso = 0, alvo = nil, trilha = nil, porId = false }
		e.camadas[nome] = c
	elseif c.peso <= 0 then
		c.inicio = agora
	end
	c.ate = math.max(c.ate, agora + (segundos or 0.15))
	c.alvo = alvo or c.alvo
	local porId, t = trilha(e, nome)
	c.porId = porId
	if t then
		c.trilha = t
		if not t.IsPlaying then
			t:Play(0.1)
		end
	end
end

-- Gesto de pegar presente (olhando para "alvo", se tiver)
function Animacoes.pegar(char: Model?, alvo: Vector3?)
	Animacoes.manter(char, "pegar", DUR.PEGAR * 0.3, alvo)
end

-- Gesto curto: "colocar", "aceno", "chegada" ou "comemorar"
function Animacoes.gesto(char: Model?, nome: string)
	local mov = MOVIMENTOS[nome]
	local e = estadoDe(char)
	if not e or not mov or not mov.duracao then
		return
	end
	local porId, t = trilha(e, nome)
	if porId then
		if t then
			t:Play(0.1)
		end
		return
	end
	local agora = os.clock()
	e.camadas[nome] = { inicio = agora, ate = agora + mov.duracao, peso = 1, alvo = nil, trilha = nil, porId = false }
end

-- Pose de espera (lobby): fica ligada enquanto "ligar" for true e o personagem estiver parado
function Animacoes.espera(char: Model?, ligar: boolean)
	local e = if ligar then estadoDe(char) else (char and estados[char])
	if e then
		e.espera = ligar
	end
end

-- Gira o SEU personagem devagar para um ponto. Espera ele parar (até 2,5 s);
-- se continuar andando, desiste. Só gira: nunca muda a posição.
function Animacoes.virarPara(char: Model?, ponto: Vector3)
	if not char or char ~= player.Character then
		return
	end
	local e = estadoDe(char)
	if e then
		e.virar = { ponto = ponto, ate = os.clock() + 2.5 }
	end
end

------------------------------------------------------------------------
-- Cópia do presente voando até o personagem (só no seu computador/celular)
------------------------------------------------------------------------
type Voo = {
	caixa: BasePart,
	fita: BasePart,
	tamanho: Vector3,
	tamanhoFita: Vector3,
	de: CFrame,
	fim: Vector3,
	inicio: number,
	char: Model?,
}
local voos: { Voo } = {}
local voaram: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local MAX_VOOS = celular and 14 or 28

local pastaEfeitos: Folder? = nil
local function efeitos(): Folder
	local pasta = pastaEfeitos
	if not pasta or not pasta.Parent then
		pasta = Instance.new("Folder")
		pasta.Name = "EfeitosAnimacao"
		pasta.Parent = workspace
		pastaEfeitos = pasta
	end
	return pasta :: Folder
end

local function pecaVisual(): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- Cria uma cópia (só visual) do presente que pula, gira, encolhe e voa até "char".
-- O presente de verdade não é tocado. Cada presente voa uma vez só.
function Animacoes.voarPresente(presente: BasePart, char: Model?)
	if voaram[presente] or #voos >= MAX_VOOS then
		return
	end
	voaram[presente] = true
	local caixa = pecaVisual()
	caixa.Name = "CopiaPresente"
	caixa.Size = presente.Size
	caixa.CFrame = presente.CFrame
	caixa.Color = presente.Color
	caixa.Material = presente.Material
	caixa.Reflectance = presente.Reflectance
	local fita = pecaVisual()
	fita.Name = "Fita"
	fita.Size = presente.Size * Vector3.new(1.04, 1.04, 0.24)
	fita.CFrame = presente.CFrame
	fita.Color = presente:GetAttribute("Raridade") == "Dourado" and P.vermelho or P.dourado
	fita.Material = Enum.Material.SmoothPlastic
	fita.Parent = caixa
	caixa.Parent = efeitos()
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	table.insert(voos, {
		caixa = caixa,
		fita = fita,
		tamanho = caixa.Size,
		tamanhoFita = fita.Size,
		de = presente.CFrame,
		fim = root and root.Position or presente.Position,
		inicio = os.clock(),
		char = char,
	})
end

------------------------------------------------------------------------
-- "Puff" de neve (por exemplo, onde o jogador saiu e onde chegou)
------------------------------------------------------------------------
function Animacoes.puff(pos: Vector3)
	local a = Instance.new("Attachment")
	a.Name = "PuffNeve"
	a.Position = pos - Vector3.new(0, 1.5, 0)
	a.Parent = workspace.Terrain
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.45, 0.8)
	e.Speed = NumberRange.new(5, 9)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 6
	e.Acceleration = Vector3.new(0, 2, 0)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 2.6) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
	e.Color = ColorSequence.new(P.neve)
	e.LightEmission = 0.2
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.Parent = a
	e:Emit(celular and 10 or 18)
	task.delay(1, function()
		a:Destroy()
	end)
end

------------------------------------------------------------------------
-- Loops
------------------------------------------------------------------------

-- Gira o seu personagem um pouquinho por quadro (só se estiver parado no chão)
local function atualizarVirar(e: Estado, dt: number, agora: number)
	local v = e.virar
	if not v then
		return
	end
	-- Shift-lock / primeira pessoa: quem manda na direção é a câmera
	if agora > v.ate or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		e.virar = nil
		return
	end
	if e.hum.MoveDirection.Magnitude > 0.05 or e.hum.FloorMaterial == Enum.Material.Air then
		return
	end
	local pos = e.root.Position
	local dir = (v.ponto - pos) * Vector3.new(1, 0, 1)
	if dir.Magnitude < 0.5 then
		e.virar = nil
		return
	end
	local olhar = e.root.CFrame.LookVector
	local atual = math.atan2(-olhar.X, -olhar.Z)
	local alvo = math.atan2(-dir.X, -dir.Z)
	local diferenca = (alvo - atual + math.pi) % (2 * math.pi) - math.pi
	if math.abs(diferenca) < 0.03 then
		e.virar = nil
		return
	end
	e.root.CFrame = CFrame.new(pos) * CFrame.Angles(0, atual + diferenca * math.min(1, dt * 9), 0)
end

local function somar(rots: Rots, pose: Rots, peso: number)
	for nome, cf in pose do
		if peso < 1 then
			cf = IDENT:Lerp(cf, peso)
		end
		local atual = rots[nome]
		rots[nome] = if atual then atual * cf else cf
	end
end

-- 1) ANTES das animações do Roblox: devolve a pose que existia antes do nosso giro.
--    Assim o nosso giro nunca se acumula de um quadro para o outro.
RunService.PreAnimation:Connect(function()
	for _, e in estados do
		for _, j in e.juntas do
			local base = j.base
			if base then
				j.base = nil
				escreverPose(j, base)
			end
		end
	end
end)

-- 2) DEPOIS das animações do Roblox: soma o nosso giro por cima.
RunService.PreSimulation:Connect(function(dt)
	local agora = os.clock()
	for char, e in estados do
		if not char.Parent or not e.root.Parent or e.hum.Health <= 0 then
			estados[char] = nil
			continue
		end
		-- O avatar foi trocado (articulações novas): procura de novo
		for _, j in e.juntas do
			if not j.obj.Parent then
				e.juntas = acharJuntas(char, e.hum)
				break
			end
		end
		atualizarVirar(e, dt, agora)

		-- Espera: continua ligada só enquanto o personagem está parado no chão
		if e.espera then
			local v = e.root.AssemblyLinearVelocity
			if Vector2.new(v.X, v.Z).Magnitude < 1.5 and e.hum.FloorMaterial ~= Enum.Material.Air then
				Animacoes.manter(char, "espera", 0.05)
			end
		end

		local rots: Rots = {}
		for nome, c in e.camadas do
			local mov = MOVIMENTOS[nome]
			local t = agora - c.inicio
			if mov.duracao then
				local p = t / mov.duracao
				if p >= 1 then
					e.camadas[nome] = nil
				else
					somar(rots, mov.pose(e, c, t, p), 1)
				end
				continue
			end
			if agora < c.ate then
				c.peso = if mov.subir > 0 then math.min(1, c.peso + dt / mov.subir) else 1
			else
				c.peso = if mov.descer > 0 then math.max(0, c.peso - dt / mov.descer) else 0
			end
			if c.peso <= 0 then
				if c.trilha then
					c.trilha:Stop(0.2)
				end
				e.camadas[nome] = nil
			elseif not c.porId then
				somar(rots, mov.pose(e, c, t, 0), suave(c.peso))
			end
		end

		for nome, j in e.juntas do
			local r = rots[nome]
			if r then
				if j.fator ~= 1 then
					r = IDENT:Lerp(r, j.fator)
				end
				local base = lerPose(j)
				j.base = base
				escreverPose(j, j.desgiro * r * j.giro * base)
			end
		end

		-- Nada mais para fazer: para de acompanhar (a pose já é só a do Roblox)
		if next(e.camadas) == nil and not e.espera and not e.virar then
			estados[char] = nil
		end
	end
end)

-- Presentes voando: pulinho para cima, gira, encolhe e chega no personagem
RunService.RenderStepped:Connect(function()
	if #voos == 0 then
		return
	end
	local agora = os.clock()
	for i = #voos, 1, -1 do
		local v = voos[i]
		local p = (agora - v.inicio) / DUR.VOO_PRESENTE
		if p >= 1 then
			v.caixa:Destroy()
			table.remove(voos, i)
			continue
		end
		local root = v.char and v.char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			v.fim = root.Position + Vector3.new(0, 0.5, 0)
		end
		local pos = v.de.Position:Lerp(v.fim, p * p) + Vector3.yAxis * (2.2 * math.sin(math.pi * math.min(1, p * 1.4)))
		local escala = if p < 0.2 then 1 + 0.75 * p else 1.15 - 0.95 * (p - 0.2) / 0.8
		local cf = CFrame.new(pos) * v.de.Rotation * CFrame.Angles(0.7 * p, 3.5 * p, 0)
		v.caixa.Size = v.tamanho * escala
		v.caixa.CFrame = cf
		v.fita.Size = v.tamanhoFita * escala
		v.fita.CFrame = cf
	end
end)

return Animacoes
