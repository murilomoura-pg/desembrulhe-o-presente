-- Interface do LOBBY: Estrelas, Renascimentos, menu de Ajudantes, status da sala e avisos.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Compartilhado = ReplicatedStorage:WaitForChild("Compartilhado")
local Config = require(Compartilhado:WaitForChild("Config"))
local Util = require(Compartilhado:WaitForChild("Util"))
local Interface = require(Compartilhado:WaitForChild("Interface"))
local CORES = Interface.CORES

local player = Players.LocalPlayer

local remAviso = Util.remoto("Aviso") :: RemoteEvent
local remSairSala = Util.remoto("SairDaSala") :: RemoteEvent
local remResultadoGiro = Util.remoto("ResultadoGiro") :: RemoteEvent
local remEquipar = Util.remoto("EquiparAjudante") :: RemoteFunction
local remUltimaFuga = Util.remoto("UltimaFuga") :: RemoteEvent

local gui = Interface.tela("HudLobby")

------------------------------------------------------------------------
-- Barra de cima: Estrelas e Renascimentos
------------------------------------------------------------------------
local barra = Instance.new("Frame")
barra.BackgroundTransparency = 1
-- Fica abaixo da janela de chat do Roblox (que ocupa o canto de cima)
barra.Position = UDim2.fromScale(0.01, 0.36)
barra.Size = UDim2.fromScale(0.3, 0.14)
barra.Parent = gui
local layoutBarra = Instance.new("UIListLayout")
layoutBarra.Padding = UDim.new(0.06, 0)
layoutBarra.Parent = barra

local function etiqueta(cor: Color3): TextLabel
	local f = Interface.texto(barra, { Size = UDim2.fromScale(1, 0.45), BackgroundTransparency = 0.15, BackgroundColor3 = cor, TextXAlignment = Enum.TextXAlignment.Left })
	Interface.arredondar(f, 0.3)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingTop = UDim.new(0.1, 0)
	pad.PaddingBottom = UDim.new(0.1, 0)
	pad.Parent = f
	return f
end
local lblEstrelas = etiqueta(CORES.fundo)
local lblRenasc = etiqueta(CORES.fundo)

local function atualizarBarra()
	lblEstrelas.Text = "⭐ " .. Util.numero(player:GetAttribute("Estrelas") or 0) .. " Estrelas"
	local r = player:GetAttribute("Renascimentos") or 0
	lblRenasc.Text = string.format("🔁 %d Renasc. (+%d%% moedas)", r, r * Config.BONUS_POR_RENASCIMENTO * 100)
end
player:GetAttributeChangedSignal("Estrelas"):Connect(atualizarBarra)
player:GetAttributeChangedSignal("Renascimentos"):Connect(atualizarBarra)
atualizarBarra()

------------------------------------------------------------------------
-- Status da sala + botão SAIR
------------------------------------------------------------------------
local caixaSala = Instance.new("Frame")
caixaSala.AnchorPoint = Vector2.new(0.5, 1)
caixaSala.Position = UDim2.fromScale(0.5, 0.97)
caixaSala.Size = UDim2.fromScale(0.5, 0.11)
caixaSala.BackgroundColor3 = CORES.fundo
caixaSala.BackgroundTransparency = 0.1
caixaSala.Visible = false
Interface.arredondar(caixaSala, 0.3)
Interface.fundoNatal(caixaSala)
caixaSala.Parent = gui
local lblSala = Interface.texto(caixaSala, { Size = UDim2.fromScale(0.68, 0.8), Position = UDim2.fromScale(0.03, 0.1) })
local btnSair = Interface.botao(caixaSala, "SAIR", CORES.vermelho, { Size = UDim2.fromScale(0.25, 0.8), Position = UDim2.fromScale(0.72, 0.1) })
btnSair.Activated:Connect(function()
	remSairSala:FireServer()
end)

local function atualizarSala()
	local sala = player:GetAttribute("Sala")
	caixaSala.Visible = sala ~= nil
	if sala then
		lblSala.Text = "Sala " .. sala .. ": " .. (player:GetAttribute("SalaTexto") or "")
	end
end
player:GetAttributeChangedSignal("Sala"):Connect(atualizarSala)
player:GetAttributeChangedSignal("SalaTexto"):Connect(atualizarSala)

------------------------------------------------------------------------
-- Menu de Ajudantes
------------------------------------------------------------------------
local painel, conteudo = Interface.painel(gui, "🐾 SEUS AJUDANTES", UDim2.fromScale(0.7, 0.75))
local grade = Instance.new("UIGridLayout")
grade.CellPadding = UDim2.fromOffset(8, 8)
grade.SortOrder = Enum.SortOrder.LayoutOrder
grade.Parent = conteudo
-- Tamanho dos cartões em pixels, calculado pela largura da janela (funciona em celular e PC)
local function ajustarCartoes()
	local largura = conteudo.AbsoluteSize.X - 12
	local w = math.floor((largura - 16) / 3)
	grade.CellSize = UDim2.fromOffset(w, math.floor(w / 0.85))
end
conteudo:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajustarCartoes)
ajustarCartoes()

local function redesenharMenu()
	for _, filho in conteudo:GetChildren() do
		if filho:IsA("Frame") then
			filho:Destroy()
		end
	end
	local inv = {}
	pcall(function()
		inv = HttpService:JSONDecode(player:GetAttribute("Inventario") or "{}")
	end)
	local equipados = {}
	for id in string.gmatch(player:GetAttribute("Equipados") or "", "[^,]+") do
		equipados[id] = (equipados[id] or 0) + 1
	end

	local algum = false
	for ordem, info in Config.AJUDANTES do
		local qtd = inv[info.id] or 0
		if qtd <= 0 then
			continue
		end
		algum = true
		local cartao = Instance.new("Frame")
		cartao.BackgroundColor3 = CORES.fundo
		cartao.LayoutOrder = ordem
		Interface.arredondar(cartao, 0.1)
		Interface.contorno(cartao, Config.CORES_RARIDADE_AJUDANTE[info.raridade], 3)
		cartao.Parent = conteudo
		Interface.texto(cartao, { Size = UDim2.fromScale(1, 0.36), Position = UDim2.fromScale(0, 0.02), Text = info.emoji })
		Interface.texto(cartao, { Size = UDim2.fromScale(0.92, 0.13), Position = UDim2.fromScale(0.04, 0.38), Text = info.nome .. " x" .. qtd })
		Interface.texto(cartao, { Size = UDim2.fromScale(0.92, 0.1), Position = UDim2.fromScale(0.04, 0.51), Text = info.raridade, TextColor3 = Config.CORES_RARIDADE_AJUDANTE[info.raridade] })
		local desc = string.format("Abre %d a cada %.1fs", info.coleta, info.intervalo)
		if info.bonusValor > 0 then
			desc ..= string.format(" • +%d%% moedas", info.bonusValor * 100)
		end
		Interface.texto(cartao, { Size = UDim2.fromScale(0.92, 0.1), Position = UDim2.fromScale(0.04, 0.62), Text = desc, TextColor3 = Color3.fromRGB(210, 210, 230) })
		local nEquip = equipados[info.id] or 0
		local podeEquipar = nEquip < qtd
		local linha = Instance.new("Frame")
		linha.BackgroundTransparency = 1
		linha.Size = UDim2.fromScale(0.92, 0.2)
		linha.Position = UDim2.fromScale(0.04, 0.76)
		linha.Parent = cartao
		local btnEq = Interface.botao(linha, podeEquipar and "Equipar" or "Equipado", podeEquipar and CORES.verde or CORES.cinza, { Size = UDim2.fromScale(nEquip > 0 and 0.48 or 1, 1) })
		btnEq.Activated:Connect(function()
			if not podeEquipar then
				return
			end
			local ok, msg = remEquipar:InvokeServer(info.id, true)
			if not ok and msg then
				Interface.aviso(msg, CORES.vermelho)
			end
		end)
		if nEquip > 0 then
			local btnTirar = Interface.botao(linha, "Tirar", CORES.vermelho, { Size = UDim2.fromScale(0.48, 1), Position = UDim2.fromScale(0.52, 0) })
			btnTirar.Activated:Connect(function()
				remEquipar:InvokeServer(info.id, false)
			end)
		end
	end
	if not algum then
		local vazio = Instance.new("Frame")
		vazio.BackgroundTransparency = 1
		vazio.Parent = conteudo
		Interface.texto(vazio, { Size = UDim2.fromScale(1, 1), Text = "Nenhum ainda! Vá até a Máquina de Ajudantes 🎁" })
	end
end
player:GetAttributeChangedSignal("Inventario"):Connect(redesenharMenu)
player:GetAttributeChangedSignal("Equipados"):Connect(redesenharMenu)
redesenharMenu()

local btnAjudantes = Interface.botao(gui, "🐾 Ajudantes", CORES.azul, {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromScale(0.01, 0.6),
	Size = UDim2.fromScale(0.16, 0.09),
})
local limiteBtn = Instance.new("UISizeConstraint")
limiteBtn.MinSize = Vector2.new(110, 40)
limiteBtn.Parent = btnAjudantes
btnAjudantes.Activated:Connect(function()
	painel.Visible = not painel.Visible
end)

------------------------------------------------------------------------
-- Resultado do giro da máquina
------------------------------------------------------------------------
local janelaGiro = Instance.new("Frame")
janelaGiro.AnchorPoint = Vector2.new(0.5, 0.5)
janelaGiro.Position = UDim2.fromScale(0.5, 0.45)
janelaGiro.Size = UDim2.fromScale(0.35, 0.45)
janelaGiro.BackgroundColor3 = CORES.painel
janelaGiro.Visible = false
Interface.arredondar(janelaGiro, 0.08)
local contornoGiro = Instance.new("UIStroke")
contornoGiro.Thickness = 4
contornoGiro.Parent = janelaGiro
local proporcaoGiro = Instance.new("UIAspectRatioConstraint")
proporcaoGiro.AspectRatio = 0.9
proporcaoGiro.Parent = janelaGiro
Interface.fundoNatal(janelaGiro)
janelaGiro.Parent = gui
local lblGiroEmoji = Interface.texto(janelaGiro, { Size = UDim2.fromScale(1, 0.45), Position = UDim2.fromScale(0, 0.05) })
local lblGiroNome = Interface.texto(janelaGiro, { Size = UDim2.fromScale(0.9, 0.15), Position = UDim2.fromScale(0.05, 0.52) })
local lblGiroRar = Interface.texto(janelaGiro, { Size = UDim2.fromScale(0.9, 0.1), Position = UDim2.fromScale(0.05, 0.68) })
local btnGiroOk = Interface.botao(janelaGiro, "LEGAL!", CORES.verde, { Size = UDim2.fromScale(0.6, 0.14), Position = UDim2.fromScale(0.2, 0.82) })
btnGiroOk.Activated:Connect(function()
	janelaGiro.Visible = false
end)

remResultadoGiro.OnClientEvent:Connect(function(id: string, equipouSozinho: boolean)
	local info = Config.ajudantePorId(id)
	if not info then
		return
	end
	janelaGiro.Visible = true
	btnGiroOk.Visible = false
	-- Animação: troca os emojis rapidinho antes de mostrar o resultado
	for i = 1, 14 do
		local aleatorio = Config.AJUDANTES[math.random(1, #Config.AJUDANTES)]
		lblGiroEmoji.Text = aleatorio.emoji
		lblGiroNome.Text = "..."
		lblGiroRar.Text = ""
		contornoGiro.Color = Config.CORES_RARIDADE_AJUDANTE[aleatorio.raridade]
		task.wait(0.05 + i * 0.012)
	end
	local cor = Config.CORES_RARIDADE_AJUDANTE[info.raridade]
	lblGiroEmoji.Text = info.emoji
	lblGiroNome.Text = info.nome
	lblGiroRar.Text = info.raridade .. (equipouSozinho and " • Equipado!" or "")
	lblGiroRar.TextColor3 = cor
	contornoGiro.Color = cor
	btnGiroOk.Visible = true
	Interface.pular(janelaGiro)
end)

------------------------------------------------------------------------
-- Avisos e resultado da última fuga
------------------------------------------------------------------------
remAviso.OnClientEvent:Connect(function(texto: string)
	Interface.aviso(texto)
end)

remUltimaFuga.OnClientEvent:Connect(function(dados)
	local texto = string.format("🏃 Você fugiu em %s no modo %s!", Util.tempo(dados.tempo or 0), tostring(dados.modo or "?"))
	Interface.aviso(texto, CORES.dourado)
	if dados.recorde then
		Interface.aviso("🏆 NOVO RECORDE PESSOAL!", CORES.dourado)
	end
end)

-- Dica para quem acabou de chegar
task.delay(2, function()
	Interface.aviso("Entre numa sala (Solo, Dupla, Trio ou Quarteto) para jogar! 🎁")
end)
