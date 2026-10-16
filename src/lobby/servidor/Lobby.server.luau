-- Script principal do LOBBY.
-- Cuida das salas (Solo/Dupla/Trio/Quarteto), do teleporte para a partida,
-- dos placares de recorde e da Máquina de Ajudantes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Util = require(ReplicatedStorage.Compartilhado.Util)
local Dados = require(ServerStorage.Comum.Dados)
local Ranking = require(ServerStorage.Comum.Ranking)
local MapaLobby = require(script.Parent.MapaLobby)

local remAviso = Util.remoto("Aviso") :: RemoteEvent
local remSairSala = Util.remoto("SairDaSala") :: RemoteEvent
local remResultadoGiro = Util.remoto("ResultadoGiro") :: RemoteEvent
local remEquipar = Util.remoto("EquiparAjudante", "RemoteFunction") :: RemoteFunction
local remUltimaFuga = Util.remoto("UltimaFuga") :: RemoteEvent

Dados.iniciar()
local mapa = MapaLobby.construir()

local function avisar(player: Player, texto: string)
	remAviso:FireClient(player, texto)
end

------------------------------------------------------------------------
-- Placar de líderes (leaderstats) e mensagem de "você fugiu em X"
------------------------------------------------------------------------
local function criarLeaderstats(player: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local fugas = Instance.new("IntValue")
	fugas.Name = "Fugas"
	fugas.Parent = ls
	local renasc = Instance.new("IntValue")
	renasc.Name = "Renasc."
	renasc.Parent = ls
	ls.Parent = player
	local function atualizar()
		fugas.Value = player:GetAttribute("Fugas") or 0
		renasc.Value = player:GetAttribute("Renascimentos") or 0
	end
	player:GetAttributeChangedSignal("Fugas"):Connect(atualizar)
	player:GetAttributeChangedSignal("Renascimentos"):Connect(atualizar)
	atualizar()
end

Players.PlayerAdded:Connect(function(player)
	criarLeaderstats(player)
	-- Se veio de uma partida, mostra o resultado
	local joinData = player:GetJoinData()
	local td = joinData and joinData.TeleportData
	if type(td) == "table" and td.tempo then
		task.delay(3, function()
			if player.Parent then
				remUltimaFuga:FireClient(player, td)
			end
		end)
	end
end)

------------------------------------------------------------------------
-- SALAS
------------------------------------------------------------------------
type Sala = {
	modo: any,
	piso: BasePart,
	status: TextLabel,
	saida: Vector3,
	jogadores: { Player },
	contagem: number?,
	teleportando: boolean,
}

local salas: { Sala } = {}
for _, s in mapa.salas do
	table.insert(salas, {
		modo = s.modo,
		piso = s.piso,
		status = s.status,
		saida = s.saida,
		jogadores = {},
		contagem = nil,
		teleportando = false,
	})
end

local function dentroDoPiso(piso: BasePart, pos: Vector3): boolean
	local rel = piso.CFrame:PointToObjectSpace(pos)
	return math.abs(rel.X) <= piso.Size.X / 2 and math.abs(rel.Z) <= piso.Size.Z / 2 and rel.Y < 14 and rel.Y > -3
end

local function tirarDaSala(player: Player, sala: Sala)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.CFrame = CFrame.new(sala.saida + Vector3.new(math.random(-4, 4), 0, 0))
	end
end

local function atualizarStatus(sala: Sala)
	local n = #sala.jogadores
	local max = sala.modo.jogadores
	if sala.teleportando then
		sala.status.Text = "🚀 Indo para a fábrica..."
	elseif sala.contagem then
		sala.status.Text = string.format("%d/%d  •  Começando em %d", n, max, math.ceil(sala.contagem))
	elseif n > 0 then
		sala.status.Text = string.format("%d/%d  •  Esperando jogadores", n, max)
	else
		sala.status.Text = string.format("%d/%d", n, max)
	end
	for _, p in sala.jogadores do
		p:SetAttribute("SalaTexto", sala.status.Text)
	end
end

local function teleportar(sala: Sala)
	local grupo = table.clone(sala.jogadores)
	sala.teleportando = true
	atualizarStatus(sala)

	if Config.PARTIDA_PLACE_ID == 0 or RunService:IsStudio() then
		for _, p in grupo do
			avisar(p, "⚠️ O teleporte só funciona com o jogo publicado e o PARTIDA_PLACE_ID configurado.")
			tirarDaSala(p, sala)
		end
		task.wait(1)
		sala.teleportando = false
		return
	end

	-- Salva antes de sair do servidor
	for _, p in grupo do
		Dados.salvar(p)
	end

	local ids = {}
	for _, p in grupo do
		table.insert(ids, p.UserId)
	end

	local ok, erro = pcall(function()
		local codigo = TeleportService:ReserveServer(Config.PARTIDA_PLACE_ID)
		local opcoes = Instance.new("TeleportOptions")
		opcoes.ReservedServerAccessCode = codigo
		opcoes:SetTeleportData({ modo = sala.modo.nome, ids = ids })
		TeleportService:TeleportAsync(Config.PARTIDA_PLACE_ID, grupo, opcoes)
	end)
	if not ok then
		warn("[Lobby] Falha no teleporte: " .. tostring(erro))
		for _, p in grupo do
			avisar(p, "Não deu pra entrar na partida agora. Tente de novo!")
			tirarDaSala(p, sala)
		end
	end
	task.wait(8)
	sala.teleportando = false
end

TeleportService.TeleportInitFailed:Connect(function(player, _resultado, mensagem)
	warn("[Lobby] Teleporte falhou para " .. player.Name .. ": " .. tostring(mensagem))
	avisar(player, "O teleporte falhou. Entre na sala de novo!")
end)

remSairSala.OnServerEvent:Connect(function(player)
	for _, sala in salas do
		if table.find(sala.jogadores, player) then
			tirarDaSala(player, sala)
		end
	end
end)

-- Loop das salas: confere quem está em cima de cada piso
task.spawn(function()
	local passo = 0.25
	while true do
		task.wait(passo)
		for _, sala in salas do
			if sala.teleportando then
				continue
			end
			local agora: { Player } = {}
			for _, p in Players:GetPlayers() do
				local char = p.Character
				local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if root and hum and hum.Health > 0 and dentroDoPiso(sala.piso, root.Position) then
					table.insert(agora, p)
				end
			end
			-- Mantém a ordem de chegada; quem chegou com a sala cheia é empurrado pra fora
			local novaLista: { Player } = {}
			for _, p in sala.jogadores do
				if table.find(agora, p) then
					table.insert(novaLista, p)
				end
			end
			for _, p in agora do
				if not table.find(novaLista, p) then
					if #novaLista < sala.modo.jogadores then
						table.insert(novaLista, p)
					else
						avisar(p, "Essa sala está cheia!")
						tirarDaSala(p, sala)
					end
				end
			end
			-- Quem saiu da sala perde o texto de status
			for _, p in sala.jogadores do
				if not table.find(novaLista, p) and p.Parent then
					p:SetAttribute("SalaTexto", nil)
					p:SetAttribute("Sala", nil)
				end
			end
			for _, p in novaLista do
				p:SetAttribute("Sala", sala.modo.nome)
			end
			sala.jogadores = novaLista

			if #sala.jogadores >= sala.modo.jogadores then
				sala.contagem = (sala.contagem or Config.CONTAGEM_SALA) - passo
				if sala.contagem <= 0 then
					sala.contagem = nil
					task.spawn(teleportar, sala)
				end
			else
				sala.contagem = nil
			end
			atualizarStatus(sala)
		end
	end
end)

------------------------------------------------------------------------
-- PLACARES
------------------------------------------------------------------------
local cacheNomes: { [number]: string } = {}
local function nomeDe(userId: number): string
	if cacheNomes[userId] then
		return cacheNomes[userId]
	end
	local ok, nome = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	cacheNomes[userId] = ok and nome or ("Jogador " .. userId)
	return cacheNomes[userId]
end

local function montarPlacar(peca: BasePart, titulo: string, linhas: { string })
	local antigo = peca:FindFirstChild("PlacarGui")
	if antigo then
		antigo:Destroy()
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PlacarGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = peca
	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.Padding = UDim.new(0.01, 0)
	lista.Parent = gui
	local function linha(texto: string, ordem: number, altura: number, cor: Color3)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, altura)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = cor
		l.TextStrokeTransparency = 0.5
		l.Text = texto
		l.LayoutOrder = ordem
		l.Parent = gui
	end
	linha(titulo, 0, 0.13, Color3.fromRGB(255, 210, 60))
	if #linhas == 0 then
		linha("Ninguém ainda... seja o primeiro!", 1, 0.07, Color3.fromRGB(200, 200, 220))
	end
	for i, texto in linhas do
		local cor = i == 1 and Color3.fromRGB(255, 215, 0) or i == 2 and Color3.fromRGB(220, 220, 230) or i == 3 and Color3.fromRGB(230, 150, 80) or Color3.new(1, 1, 1)
		linha(texto, i, 0.075, cor)
	end
end

local function atualizarPlacares()
	for i, sala in salas do
		local peca = mapa.salas[i].placar
		local top = Ranking.top(Ranking.nomeTempo(sala.modo.nome), true, 10)
		local linhas = {}
		for pos, item in top do
			table.insert(linhas, string.format("%d. %s — %s", pos, nomeDe(item.userId), Util.tempo(item.valor)))
		end
		montarPlacar(peca, "🏆 FUGA MAIS RÁPIDA", linhas)
	end
	local top = Ranking.top(Ranking.NOME_RENASCIMENTOS, false, 10)
	local linhas = {}
	for pos, item in top do
		table.insert(linhas, string.format("%d. %s — %d", pos, nomeDe(item.userId), item.valor))
	end
	montarPlacar(mapa.placarRenascimentos, "🔁 MAIS RENASCIMENTOS", linhas)
end

task.spawn(function()
	while true do
		atualizarPlacares()
		task.wait(60)
	end
end)

------------------------------------------------------------------------
-- MÁQUINA DE AJUDANTES
------------------------------------------------------------------------
local ultimoGiro: { [Player]: number } = {}

mapa.promptMaquina.Triggered:Connect(function(player)
	if os.clock() - (ultimoGiro[player] or 0) < 1 then
		return
	end
	ultimoGiro[player] = os.clock()
	local d = Dados.get(player)
	if not d then
		return
	end
	if d.Estrelas < Config.CUSTO_GIRO then
		avisar(player, string.format("Você precisa de %d ⭐ (tem %d). Ache estrelas dentro dos presentes!", Config.CUSTO_GIRO, d.Estrelas))
		return
	end
	d.Estrelas -= Config.CUSTO_GIRO
	local ajudante = Util.sortear(Config.AJUDANTES)
	d.Inventario[ajudante.id] = (d.Inventario[ajudante.id] or 0) + 1
	-- Equipa sozinho se tiver espaço
	local equipouSozinho = false
	if #d.Equipados < Config.MAX_EQUIPADOS then
		table.insert(d.Equipados, ajudante.id)
		equipouSozinho = true
	end
	Dados.atualizarAtributos(player)
	remResultadoGiro:FireClient(player, ajudante.id, equipouSozinho)
end)

-- Equipar / desequipar pelo menu
remEquipar.OnServerInvoke = function(player: Player, id: any, equipar: any)
	local d = Dados.get(player)
	if not d or type(id) ~= "string" or not Config.ajudantePorId(id) then
		return false
	end
	if equipar then
		local tenho = d.Inventario[id] or 0
		local equipadosDesse = 0
		for _, e in d.Equipados do
			if e == id then
				equipadosDesse += 1
			end
		end
		if equipadosDesse >= tenho then
			return false, "Você não tem mais desse ajudante."
		end
		if #d.Equipados >= Config.MAX_EQUIPADOS then
			return false, "Máximo de " .. Config.MAX_EQUIPADOS .. " ajudantes equipados."
		end
		table.insert(d.Equipados, id)
	else
		local idx = table.find(d.Equipados, id)
		if idx then
			table.remove(d.Equipados, idx)
		end
	end
	Dados.atualizarAtributos(player)
	return true
end

Players.PlayerRemoving:Connect(function(p)
	ultimoGiro[p] = nil
end)
