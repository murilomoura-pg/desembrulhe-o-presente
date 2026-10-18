-- 🕺 Animações da PARTIDA (só visual: não muda nada do jogo nem do servidor).
-- Liga os movimentos do módulo Animacoes ao que o servidor JÁ espalha para todo mundo
-- (atributos), então cada um vê também os outros jogadores se mexendo:
--   • o "Saco" de alguém aumentou → ele faz o gesto de pegar e os presentes que sumiram
--     perto dele voam até ele (no seu personagem o gesto já acontece no clique, no HudPartida);
--   • o "Estoque" de uma bancada aumentou → o dono faz o gesto de colocar;
--   • o "Estoque" diminuiu → o dono mexe os braços desembrulhando;
--   • alguém achou a chave, ou todos fugiram → comemora.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Compartilhado"):WaitForChild("Config"))
local Animacoes = require(script.Parent.Parent:WaitForChild("Comum"):WaitForChild("Animacoes"))

local player = Players.LocalPlayer

------------------------------------------------------------------------
-- Presentes que acabaram de sumir da montanha (para saber quem pegou o quê)
------------------------------------------------------------------------
local sumidos: { { presente: BasePart, quando: number, usado: boolean } } = {}

task.spawn(function()
	local montanha = workspace:WaitForChild("Montanha", math.huge)
	montanha.ChildRemoved:Connect(function(obj)
		if obj:IsA("BasePart") then
			table.insert(sumidos, { presente = obj, quando = os.clock(), usado = false })
			if #sumidos > 40 then
				table.remove(sumidos, 1)
			end
		end
	end)
end)

------------------------------------------------------------------------
-- Pegar presentes (todos os jogadores)
------------------------------------------------------------------------
local function observar(p: Player)
	local antes = p:GetAttribute("Saco") or 0
	p:GetAttributeChangedSignal("Saco"):Connect(function()
		local saco = p:GetAttribute("Saco") or 0
		local ganhou = saco - antes
		antes = saco
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if ganhou <= 0 or not root then
			return
		end
		-- Os presentes que sumiram agora há pouco perto dele são os que ele pegou
		-- (os mais recentes primeiro). Cada presente voa uma vez só.
		local agora = os.clock()
		local alvo: Vector3? = nil
		for i = #sumidos, 1, -1 do
			local s = sumidos[i]
			if ganhou <= 0 or agora - s.quando > 1 then
				break
			end
			if not s.usado and (s.presente.Position - root.Position).Magnitude <= Config.ALCANCE_COLETA + 12 then
				s.usado = true
				ganhou -= 1
				alvo = alvo or s.presente.Position
				Animacoes.voarPresente(s.presente, char)
			end
		end
		if p ~= player then
			Animacoes.pegar(char, alvo)
		end
	end)

	-- Achou a chave: comemora
	p:GetAttributeChangedSignal("TemChave"):Connect(function()
		if p:GetAttribute("TemChave") then
			Animacoes.gesto(p.Character, "comemorar")
		end
	end)
end

for _, p in Players:GetPlayers() do
	observar(p)
end
Players.PlayerAdded:Connect(observar)

-- Fugiram: todo mundo comemora
workspace:GetAttributeChangedSignal("TempoFinal"):Connect(function()
	if workspace:GetAttribute("TempoFinal") then
		for _, p in Players:GetPlayers() do
			Animacoes.gesto(p.Character, "comemorar")
		end
	end
end)

------------------------------------------------------------------------
-- Bancadas: colocar e desembrulhar (pelo número de presentes em cima de cada uma)
------------------------------------------------------------------------
local function observarBancada(modelo: Instance)
	local anterior = modelo:GetAttribute("Estoque") or 0
	modelo:GetAttributeChangedSignal("Estoque"):Connect(function()
		local estoque = modelo:GetAttribute("Estoque") or 0
		local dono = Players:GetPlayerByUserId(modelo:GetAttribute("Dono") or 0)
		local char = dono and dono.Character
		if char then
			if estoque > anterior then
				Animacoes.gesto(char, "colocar")
			elseif estoque < anterior and dono ~= player then
				-- (os SEUS braços já mexem pelo botão/tecla, no HudPartida)
				Animacoes.manter(char, "desembrulhar", 0.8)
			end
		end
		anterior = estoque
	end)
end

task.spawn(function()
	local mapa = workspace:WaitForChild("MapaPartida", math.huge)
	for i = 1, 4 do
		local modelo = mapa:WaitForChild("Bancada_" .. i, 30)
		if modelo then
			observarBancada(modelo)
		end
	end
end)
