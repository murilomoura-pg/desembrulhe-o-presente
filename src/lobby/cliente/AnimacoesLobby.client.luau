-- 🕺 Animações do LOBBY (só visual: não muda nada das salas nem do servidor).
-- Usa o atributo "Sala" que o servidor já coloca em cada jogador, então cada um vê
-- também os outros se mexendo (Solo, Dupla, Trio e Quarteto funcionam igual):
--   • entrou numa sala → acena ("entrei!"); o SEU personagem, quando para,
--     gira devagar para o centro da sala (ou para a placa, se já estiver no centro);
--   • esperando na sala → pose de espera discreta, que para na hora em que ele anda;
--   • o jogo tirou alguém da sala (sala cheia, botão SAIR, teleporte que não deu certo)
--     → "puff" de neve onde ele estava e onde chegou + gesto de chegada.
-- Ninguém é movido por este script: quem anda é o próprio jogador.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Animacoes = require(script.Parent.Parent:WaitForChild("Comum"):WaitForChild("Animacoes"))

local player = Players.LocalPlayer

-- Em qual sala o jogador está. O lobby das Entradas (tela CRIAR GRUPO) usa o atributo
-- "Entrada" e as pastas "Entrada_<número>": os dois jeitos funcionam aqui.
local function salaDe(p: Player): any
	return p:GetAttribute("Sala") or p:GetAttribute("Entrada")
end

-- Ponto para o seu personagem olhar ao entrar: o centro da sala (ou a placa, se ele já estiver no centro)
local function pontoParaOlhar(valor: any, root: BasePart): Vector3?
	local mapa = workspace:FindFirstChild("MapaLobby")
	local sala = mapa and (mapa:FindFirstChild("Sala_" .. tostring(valor)) or mapa:FindFirstChild("Entrada_" .. tostring(valor)))
	local piso = sala and sala:FindFirstChild("Piso") :: BasePart?
	if not sala or not piso then
		return nil
	end
	local placa = sala:FindFirstChild("PlacaNome") :: BasePart?
	local noCentro = Vector3.new(root.Position.X - piso.Position.X, 0, root.Position.Z - piso.Position.Z).Magnitude < 4
	if noCentro and placa then
		return placa.Position
	end
	return piso.Position
end

local function observar(p: Player)
	local antes = salaDe(p)
	if antes then
		Animacoes.espera(p.Character, true)
	end
	local function mudou()
		local sala = salaDe(p)
		local char = p.Character
		if sala and not antes and char then
			Animacoes.gesto(char, "aceno")
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if p == player and root then
				local ponto = pontoParaOlhar(sala, root)
				if ponto then
					Animacoes.virarPara(char, ponto)
				end
			end
		end
		Animacoes.espera(char, sala ~= nil)
		antes = sala
	end
	p:GetAttributeChangedSignal("Sala"):Connect(mudou)
	p:GetAttributeChangedSignal("Entrada"):Connect(mudou)
end

for _, p in Players:GetPlayers() do
	observar(p)
end
Players.PlayerAdded:Connect(observar)

------------------------------------------------------------------------
-- O jogo tirou alguém da sala: o servidor coloca o personagem em outro lugar na hora.
-- Aqui só percebemos o "salto" (ninguém anda tanto num quadro) e disfarçamos com neve.
------------------------------------------------------------------------
local SALTO = 6 -- studs num quadro só
local ultimo: { [Player]: { char: Model, pos: Vector3 } } = {}

RunService.Heartbeat:Connect(function()
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not char or not root then
			ultimo[p] = nil
			continue
		end
		local u = ultimo[p]
		local pos = root.Position
		if u and u.char == char then
			if (pos - u.pos).Magnitude > SALTO then
				Animacoes.puff(u.pos)
				Animacoes.puff(pos)
				Animacoes.gesto(char, "chegada")
			end
			u.pos = pos
		else
			ultimo[p] = { char = char, pos = pos }
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	ultimo[p] = nil
end)
