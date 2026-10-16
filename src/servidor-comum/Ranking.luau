-- Ranking global: fuga mais rápida (um por modo) e mais Renascimentos.
-- A Partida grava, o Lobby lê e mostra nos placares.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Compartilhado.Config)

local Ranking = {}

local function store(nome: string): OrderedDataStore?
	local ok, resultado = pcall(function()
		return DataStoreService:GetOrderedDataStore(nome .. "_" .. Config.VERSAO_DADOS)
	end)
	return ok and resultado or nil
end

function Ranking.nomeTempo(modo: string): string
	return "FugaRapida_" .. modo
end

Ranking.NOME_RENASCIMENTOS = "Renascimentos"

-- Grava o tempo só se for melhor (menor) que o anterior do jogador
function Ranking.gravarTempo(userId: number, modo: string, segundos: number)
	local s = store(Ranking.nomeTempo(modo))
	if not s then
		return
	end
	local valor = math.max(1, math.floor(segundos))
	pcall(function()
		(s :: OrderedDataStore):UpdateAsync(tostring(userId), function(antigo)
			if antigo == nil or valor < antigo then
				return valor
			end
			return nil -- não muda
		end)
	end)
end

function Ranking.gravarRenascimentos(userId: number, total: number)
	local s = store(Ranking.NOME_RENASCIMENTOS)
	if not s then
		return
	end
	pcall(function()
		(s :: OrderedDataStore):SetAsync(tostring(userId), total)
	end)
end

-- Retorna lista { {userId, valor}, ... }
function Ranking.top(nome: string, crescente: boolean, quantidade: number)
	local s = store(nome)
	if not s then
		return {}
	end
	local ok, pagina = pcall(function()
		return (s :: OrderedDataStore):GetSortedAsync(crescente, quantidade)
	end)
	if not ok then
		return {}
	end
	local lista = {}
	for _, item in pagina:GetCurrentPage() do
		table.insert(lista, { userId = tonumber(item.key), valor = item.value })
	end
	return lista
end

return Ranking
