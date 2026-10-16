-- Salva e carrega o progresso dos jogadores (Estrelas, Ajudantes, Renascimentos, Recordes).
-- Usado no Lobby e na Partida.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Compartilhado.Config)

local Dados = {}

local store: DataStore? = nil
do
	local ok, resultado = pcall(function()
		return DataStoreService:GetDataStore("Jogadores_" .. Config.VERSAO_DADOS)
	end)
	if ok then
		store = resultado
	else
		warn("[Dados] DataStore indisponível (no Studio, ative 'Enable Studio Access to API Services'). O progresso não será salvo.")
	end
end

local sessoes: { [Player]: any } = {}
local naoSalvar: { [Player]: boolean } = {}

local function padrao()
	return {
		Estrelas = Config.ESTRELAS_INICIAIS,
		Inventario = {}, -- ex: { Elfo = 2, Rena = 1 }
		Equipados = {}, -- ex: { "Elfo", "Rena" }
		Renascimentos = 0,
		Fugas = 0,
		Recordes = {}, -- ex: { Solo = 754 } (segundos)
	}
end

local function completar(d)
	local base = padrao()
	for k, v in base do
		if d[k] == nil then
			d[k] = v
		end
	end
	return d
end

function Dados.atualizarAtributos(player: Player)
	local d = sessoes[player]
	if not d then
		return
	end
	player:SetAttribute("Estrelas", d.Estrelas)
	player:SetAttribute("Renascimentos", d.Renascimentos)
	player:SetAttribute("Fugas", d.Fugas)
	player:SetAttribute("Equipados", table.concat(d.Equipados, ","))
	player:SetAttribute("Inventario", HttpService:JSONEncode(d.Inventario))
	player:SetAttribute("Recordes", HttpService:JSONEncode(d.Recordes))
	player:SetAttribute("DadosProntos", true)
end

function Dados.carregar(player: Player)
	local chave = "Jogador_" .. player.UserId
	local dados = nil
	if store then
		for tentativa = 1, 3 do
			local ok, resultado = pcall(function()
				return (store :: DataStore):GetAsync(chave)
			end)
			if ok then
				dados = resultado
				break
			end
			warn("[Dados] Falha ao carregar " .. player.Name .. " (tentativa " .. tentativa .. "): " .. tostring(resultado))
			if tentativa == 3 then
				-- Não deixa salvar por cima, senão apagaria o progresso real do jogador
				naoSalvar[player] = true
			end
			task.wait(1.5)
		end
	end
	if not player.Parent then
		return nil
	end
	sessoes[player] = completar(dados or padrao())
	Dados.atualizarAtributos(player)
	return sessoes[player]
end

function Dados.get(player: Player)
	return sessoes[player]
end

-- Espera os dados do jogador ficarem prontos (até 15s)
function Dados.esperar(player: Player)
	local inicio = os.clock()
	while not sessoes[player] and player.Parent and os.clock() - inicio < 15 do
		task.wait(0.1)
	end
	return sessoes[player]
end

function Dados.salvar(player: Player)
	local d = sessoes[player]
	if not d or not store or naoSalvar[player] then
		return
	end
	local chave = "Jogador_" .. player.UserId
	for tentativa = 1, 3 do
		local ok, erro = pcall(function()
			(store :: DataStore):SetAsync(chave, d, { player.UserId })
		end)
		if ok then
			return
		end
		warn("[Dados] Falha ao salvar " .. player.Name .. " (tentativa " .. tentativa .. "): " .. tostring(erro))
		task.wait(1)
	end
end

function Dados.multiplicador(player: Player): number
	local d = sessoes[player]
	local renasc = d and d.Renascimentos or 0
	return 1 + renasc * Config.BONUS_POR_RENASCIMENTO
end

function Dados.iniciar()
	Players.PlayerAdded:Connect(function(p)
		Dados.carregar(p)
	end)
	for _, p in Players:GetPlayers() do
		task.spawn(Dados.carregar, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		Dados.salvar(p)
		sessoes[p] = nil
		naoSalvar[p] = nil
	end)
	game:BindToClose(function()
		local pendentes = 0
		for p in sessoes do
			pendentes += 1
			task.spawn(function()
				Dados.salvar(p)
				pendentes -= 1
			end)
		end
		local inicio = os.clock()
		while pendentes > 0 and os.clock() - inicio < 25 do
			task.wait(0.2)
		end
	end)
end

return Dados
