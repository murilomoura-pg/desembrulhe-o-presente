-- Script principal da PARTIDA.
-- Fluxo: espera o grupo chegar → monta a montanha → contagem → pegar/desembrulhar/comprar
-- → alguém acha a CHAVE → abre o Portão → todos fogem → tempo vai pro ranking → volta pro lobby.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Util = require(ReplicatedStorage.Compartilhado.Util)
local Dados = require(ServerStorage.Comum.Dados)
local Ranking = require(ServerStorage.Comum.Ranking)
local Montanha = require(script.Parent.Montanha)
local MapaPartida = require(script.Parent.MapaPartida)

local remAviso = Util.remoto("Aviso") :: RemoteEvent
local remColetar = Util.remoto("Coletar") :: RemoteEvent
local remDesembrulhar = Util.remoto("Desembrulhar") :: RemoteEvent
local remDesembrulhou = Util.remoto("Desembrulhou") :: RemoteEvent
local remAbrirLoja = Util.remoto("AbrirLoja") :: RemoteEvent
local remComprar = Util.remoto("Comprar", "RemoteFunction") :: RemoteFunction
local remFugiram = Util.remoto("Fugiram") :: RemoteEvent
local remContagem = Util.remoto("Contagem") :: RemoteEvent

Dados.iniciar()

local function avisarTodos(texto: string)
	remAviso:FireAllClients(texto)
end

------------------------------------------------------------------------
-- Estado de cada jogador na partida (zera toda partida)
------------------------------------------------------------------------
type Estado = {
	moedas: number,
	niveis: { [string]: number },
	saco: { [string]: number }, -- quantidade por raridade
	sacoTotal: number,
	segurando: boolean,
	acumulado: number,
	ultimoClique: number,
	timersAjudantes: { number },
	resumo: { moedas: number, raros: { string }, estrelas: number }, -- para mandar ao cliente
}

local estados: { [Player]: Estado } = {}

local function valorMelhoria(estado: Estado, id: string): number
	local m = Config.melhoriaPorId(id)
	return m.niveis[estado.niveis[id] or 1]
end

local function atualizarAtributos(player: Player)
	local e = estados[player]
	if not e then
		return
	end
	player:SetAttribute("Moedas", math.floor(e.moedas))
	player:SetAttribute("Saco", e.sacoTotal)
	player:SetAttribute("SacoMax", valorMelhoria(e, "Saco"))
	for _, m in Config.MELHORIAS do
		player:SetAttribute("Nivel_" .. m.id, e.niveis[m.id] or 1)
	end
	local ls = player:FindFirstChild("leaderstats")
	local moedas = ls and ls:FindFirstChild("Moedas") :: IntValue?
	if moedas then
		moedas.Value = math.floor(e.moedas)
	end
end

local function aplicarVelocidade(player: Player)
	local e = estados[player]
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if e and hum then
		hum.WalkSpeed = valorMelhoria(e, "Velocidade")
	end
end

local function bonusAjudantes(player: Player): number
	local d = Dados.get(player)
	local bonus = 0
	if d then
		for _, id in d.Equipados do
			local a = Config.ajudantePorId(id)
			if a then
				bonus += a.bonusValor
			end
		end
	end
	return bonus
end

local function valorDe(player: Player, raridade: string): number
	local e = estados[player]
	local rar = Config.raridadePorId(raridade)
	return rar.valor * valorMelhoria(e, "Valor") * Dados.multiplicador(player) * (1 + bonusAjudantes(player))
end

------------------------------------------------------------------------
-- Espera o grupo e monta a partida
------------------------------------------------------------------------
local modo = Config.MODOS[1]
local idsEsperados: { number } = {}
local iniciou = false
local inicioServidor = 0
local terminou = false
local mapa: any = nil

-- Chave
local chave = {
	encontrada = false,
	dono = nil :: Player?,
	fracao = Random.new():NextNumber(Config.CHAVE_MIN, Config.CHAVE_MAX),
}
local desembrulhados = 0
local perdidos = 0 -- presentes que sumiram com quem saiu do jogo

local function lerTeleportData(player: Player)
	local jd = player:GetJoinData()
	local td = jd and jd.TeleportData
	if type(td) == "table" and type(td.modo) == "string" then
		modo = Config.modoPorNome(td.modo)
		if type(td.ids) == "table" then
			idsEsperados = td.ids
		end
		return true
	end
	return false
end

local function criarEstado(player: Player)
	local e: Estado = {
		moedas = 0,
		niveis = {},
		saco = {},
		sacoTotal = 0,
		segurando = false,
		acumulado = 0,
		ultimoClique = 0,
		timersAjudantes = {},
		resumo = { moedas = 0, raros = {}, estrelas = 0 },
	}
	for _, m in Config.MELHORIAS do
		e.niveis[m.id] = 1
	end
	estados[player] = e

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local moedas = Instance.new("IntValue")
	moedas.Name = "Moedas"
	moedas.Parent = ls
	ls.Parent = player

	atualizarAtributos(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		aplicarVelocidade(player)
	end)
	aplicarVelocidade(player)
end

local primeiroJogador = false
Players.PlayerAdded:Connect(function(player)
	if not primeiroJogador then
		primeiroJogador = true
		lerTeleportData(player)
	end
	criarEstado(player)
end)

-- Espera o primeiro jogador chegar
while not primeiroJogador do
	task.wait(0.1)
end

-- Monta a montanha e o mapa do tamanho do modo
local raio = Montanha.gerar(modo.presentes, Montanha.raioPara(modo.presentes))
mapa = MapaPartida.construir(raio)
workspace:SetAttribute("Modo", modo.nome)

-- Leva quem já está no jogo para o spawn novo
for _, p in Players:GetPlayers() do
	if p.Character then
		p:LoadCharacter()
	end
end

-- Espera o grupo inteiro (no máximo 20 segundos)
do
	local inicio = os.clock()
	local function todosChegaram()
		if #idsEsperados == 0 then
			return true
		end
		for _, id in idsEsperados do
			if not Players:GetPlayerByUserId(id) then
				return false
			end
		end
		return true
	end
	while not todosChegaram() and os.clock() - inicio < 20 do
		task.wait(0.5)
	end
	task.wait(2)
end

-- Contagem 3, 2, 1
for i = 3, 1, -1 do
	remContagem:FireAllClients(tostring(i))
	task.wait(1)
end
remContagem:FireAllClients("DESEMBRULHEM! 🎁")
inicioServidor = workspace:GetServerTimeNow()
workspace:SetAttribute("Inicio", inicioServidor)
iniciou = true

------------------------------------------------------------------------
-- A CHAVE
------------------------------------------------------------------------
local function darChave(player: Player)
	if chave.encontrada then
		return
	end
	chave.encontrada = true
	chave.dono = player
	player:SetAttribute("TemChave", true)
	workspace:SetAttribute("DonoChave", player.DisplayName)
	mapa.promptPortao.Enabled = true
	mapa.destaquePortao.Enabled = true
	avisarTodos("🔑 " .. player.DisplayName .. " ACHOU A CHAVE! Corram para o PORTÃO!")

	-- Chave brilhando em cima do jogador
	local char = player.Character
	local cabeca = char and char:FindFirstChild("Head")
	if cabeca then
		local bb = Instance.new("BillboardGui")
		bb.Name = "IconeChave"
		bb.Size = UDim2.fromScale(3, 3)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true
		bb.Parent = cabeca
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.TextScaled = true
		l.Text = "🔑"
		l.Parent = bb
	end
end

local function totalNosSacos(): number
	local t = 0
	for _, e in estados do
		t += e.sacoTotal
	end
	return t
end

-- Confere se está na hora da chave aparecer (chamado sempre que um presente é desembrulhado)
local function conferirChave(quem: Player?)
	if chave.encontrada or terminou then
		return
	end
	local efetivo = Montanha.total - perdidos
	local acabou = Montanha.restantes <= 0 and totalNosSacos() <= 0
	if desembrulhados >= efetivo * chave.fracao or acabou then
		local alvo = quem
		if not alvo or not alvo.Parent then
			local lista = Players:GetPlayers()
			alvo = lista[math.random(1, math.max(1, #lista))]
		end
		if alvo then
			darChave(alvo)
		end
	end
end

------------------------------------------------------------------------
-- Desembrulhar um presente (usado pelo jogador na mesa e pelos ajudantes)
------------------------------------------------------------------------
local function desembrulhar(player: Player, raridade: string)
	local e = estados[player]
	if not e then
		return
	end
	local valor = valorDe(player, raridade)
	e.moedas += valor
	e.resumo.moedas += valor
	if raridade ~= "Comum" then
		table.insert(e.resumo.raros, raridade)
	end
	if math.random() < Config.CHANCE_ESTRELA then
		local d = Dados.get(player)
		if d then
			d.Estrelas += 1
			player:SetAttribute("Estrelas", d.Estrelas)
			e.resumo.estrelas += 1
		end
	end
	desembrulhados += 1
	workspace:SetAttribute("Desembrulhados", desembrulhados)
	conferirChave(player)
end

local function tirarDoSaco(e: Estado): string?
	if e.sacoTotal <= 0 then
		return nil
	end
	-- Sorteia proporcional ao que tem no saco
	local r = math.random(1, e.sacoTotal)
	for rar, qtd in e.saco do
		if r <= qtd then
			e.saco[rar] = qtd - 1
			e.sacoTotal -= 1
			return rar
		end
		r -= qtd
	end
	return nil
end

------------------------------------------------------------------------
-- Remotos
------------------------------------------------------------------------
remColetar.OnServerEvent:Connect(function(player, presente)
	local e = estados[player]
	if not e or not iniciou or terminou then
		return
	end
	if os.clock() - e.ultimoClique < 0.12 then
		return
	end
	if not Montanha.ehPresente(presente) then
		return
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - presente.Position).Magnitude > Config.ALCANCE_COLETA + 4 then
		return
	end
	local max = valorMelhoria(e, "Saco")
	local espaco = max - e.sacoTotal
	if espaco <= 0 then
		remAviso:FireClient(player, "🎒 Saco cheio! Leve até a Mesa de Desembrulhar.")
		e.ultimoClique = os.clock() + 0.5
		return
	end
	e.ultimoClique = os.clock()
	local qtd = math.min(espaco, valorMelhoria(e, "Maos"))
	local pegos = Montanha.pegarPerto(presente, qtd)
	for _, rar in pegos do
		e.saco[rar] = (e.saco[rar] or 0) + 1
		e.sacoTotal += 1
	end
	atualizarAtributos(player)
end)

remDesembrulhar.OnServerEvent:Connect(function(player, segurando)
	local e = estados[player]
	if e then
		e.segurando = segurando == true
		if not e.segurando then
			e.acumulado = 0
		end
	end
end)

mapa.promptLoja.Triggered:Connect(function(player)
	remAbrirLoja:FireClient(player)
end)

remComprar.OnServerInvoke = function(player: Player, id: any)
	local e = estados[player]
	if not e or terminou or type(id) ~= "string" then
		return false
	end
	local m = Config.melhoriaPorId(id)
	if not m then
		return false
	end
	local nivel = e.niveis[id] or 1
	if nivel >= #m.niveis then
		return false, "Já está no máximo!"
	end
	local preco = m.custos[nivel + 1]
	if e.moedas < preco then
		return false, "Moedas insuficientes!"
	end
	e.moedas -= preco
	e.niveis[id] = nivel + 1
	atualizarAtributos(player)
	if id == "Velocidade" then
		aplicarVelocidade(player)
	end
	return true
end

------------------------------------------------------------------------
-- Loop principal: mesa de desembrulhar + ajudantes
------------------------------------------------------------------------
local tempoEnvio = 0
RunService.Heartbeat:Connect(function(dt)
	if not iniciou or terminou then
		return
	end
	for player, e in estados do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

		-- Desembrulhar na mesa
		if e.segurando and root and e.sacoTotal > 0 then
			local distancia = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(mapa.mesaPos.X, 0, mapa.mesaPos.Z)).Magnitude
			if distancia <= Config.RAIO_MESA + 2 then
				e.acumulado += valorMelhoria(e, "Tesoura") * dt
				local mudou = false
				while e.acumulado >= 1 and e.sacoTotal > 0 do
					e.acumulado -= 1
					local rar = tirarDoSaco(e)
					if rar then
						desembrulhar(player, rar)
						mudou = true
					end
				end
				if mudou then
					atualizarAtributos(player)
				end
			end
		end

		-- Ajudantes trabalhando sozinhos
		local d = Dados.get(player)
		if d and Montanha.restantes > 0 then
			for i, id in d.Equipados do
				local a = Config.ajudantePorId(id)
				if a then
					e.timersAjudantes[i] = (e.timersAjudantes[i] or 0) + dt
					if e.timersAjudantes[i] >= a.intervalo then
						e.timersAjudantes[i] = 0
						local pegos = Montanha.pegarParaAjudante(root and root.Position, a.coleta)
						for _, rar in pegos do
							desembrulhar(player, rar)
						end
						if #pegos > 0 then
							atualizarAtributos(player)
						end
					end
				end
			end
		end
	end

	-- Manda o resumo do que cada um ganhou (no máximo ~7x por segundo)
	tempoEnvio += dt
	if tempoEnvio >= 0.15 then
		tempoEnvio = 0
		for player, e in estados do
			if e.resumo.moedas > 0 then
				remDesembrulhou:FireClient(player, e.resumo)
				e.resumo = { moedas = 0, raros = {}, estrelas = 0 }
			end
		end
	end
end)

------------------------------------------------------------------------
-- FUGA!
------------------------------------------------------------------------
local function fugir()
	if terminou then
		return
	end
	terminou = true
	local tempo = workspace:GetServerTimeNow() - inicioServidor
	workspace:SetAttribute("TempoFinal", tempo)

	-- Abre o portão
	mapa.promptPortao.Enabled = false
	mapa.cadeado:Destroy()
	TweenService:Create(mapa.portao, TweenInfo.new(2.5, Enum.EasingStyle.Quad), {
		CFrame = mapa.portao.CFrame + Vector3.new(0, mapa.portao.Size.Y + 2, 0),
	}):Play()

	local resultados = {}
	for _, player in Players:GetPlayers() do
		local d = Dados.get(player)
		local recorde = false
		if d then
			d.Fugas += 1
			d.Renascimentos += 1
			d.Estrelas += Config.ESTRELAS_POR_FUGA
			local anterior = d.Recordes[modo.nome]
			if not anterior or tempo < anterior then
				d.Recordes[modo.nome] = math.floor(tempo)
				recorde = true
			end
			Dados.atualizarAtributos(player)
			task.spawn(Ranking.gravarTempo, player.UserId, modo.nome, tempo)
			task.spawn(Ranking.gravarRenascimentos, player.UserId, d.Renascimentos)
			task.spawn(Dados.salvar, player)
		end
		resultados[player] = { tempo = tempo, modo = modo.nome, recorde = recorde }
		remFugiram:FireClient(player, {
			tempo = tempo,
			modo = modo.nome,
			recorde = recorde,
			estrelas = Config.ESTRELAS_POR_FUGA,
			renascimentos = d and d.Renascimentos or 0,
			bonus = (d and d.Renascimentos or 0) * Config.BONUS_POR_RENASCIMENTO,
		})
	end

	task.wait(10)

	-- Volta todo mundo para o lobby
	if RunService:IsStudio() or Config.LOBBY_PLACE_ID == 0 then
		avisarTodos("(No Studio não tem teleporte. No jogo publicado vocês voltariam ao lobby agora.)")
		return
	end
	for player, resultado in resultados do
		if player.Parent then
			task.spawn(function()
				local opcoes = Instance.new("TeleportOptions")
				opcoes:SetTeleportData(resultado)
				local ok, erro = pcall(function()
					TeleportService:TeleportAsync(Config.LOBBY_PLACE_ID, { player }, opcoes)
				end)
				if not ok then
					warn("[Partida] Falha ao voltar ao lobby: " .. tostring(erro))
					player:Kick("Vocês fugiram! Entre de novo no jogo para continuar. 🎁")
				end
			end)
		end
	end
end

mapa.promptPortao.Triggered:Connect(function(player)
	if not chave.encontrada then
		return
	end
	if player ~= chave.dono then
		remAviso:FireClient(player, "Só quem tem a 🔑 pode abrir! (" .. (chave.dono and chave.dono.DisplayName or "?") .. ")")
		return
	end
	fugir()
end)

------------------------------------------------------------------------
-- Alguém saiu no meio da partida
------------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	local e = estados[player]
	if e then
		perdidos += e.sacoTotal
	end
	estados[player] = nil
	if chave.encontrada and chave.dono == player and not terminou then
		-- passa a chave para outro jogador
		chave.encontrada = false
		chave.dono = nil
		local lista = Players:GetPlayers()
		for _, p in lista do
			if p ~= player then
				darChave(p)
				break
			end
		end
	else
		conferirChave(nil)
	end
end)
