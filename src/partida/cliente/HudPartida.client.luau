-- Interface da PARTIDA: moedas, saco, tempo, progresso da montanha, botão DESEMBRULHAR,
-- loja de melhorias, coleta por clique/toque e tela de fuga.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Compartilhado = ReplicatedStorage:WaitForChild("Compartilhado")
local Config = require(Compartilhado:WaitForChild("Config"))
local Util = require(Compartilhado:WaitForChild("Util"))
local Interface = require(Compartilhado:WaitForChild("Interface"))
local CORES = Interface.CORES

local player = Players.LocalPlayer

local remAviso = Util.remoto("Aviso") :: RemoteEvent
local remColetar = Util.remoto("Coletar") :: RemoteEvent
local remDesembrulhar = Util.remoto("Desembrulhar") :: RemoteEvent
local remDesembrulhou = Util.remoto("Desembrulhou") :: RemoteEvent
local remAbrirLoja = Util.remoto("AbrirLoja") :: RemoteEvent
local remComprar = Util.remoto("Comprar") :: RemoteFunction
local remFugiram = Util.remoto("Fugiram") :: RemoteEvent
local remContagem = Util.remoto("Contagem") :: RemoteEvent

local gui = Interface.tela("HudPartida")

------------------------------------------------------------------------
-- Sons (sons que já vêm no Roblox, não precisam de upload)
------------------------------------------------------------------------
local function som(id: string, volume: number): Sound
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.Parent = SoundService
	return s
end
local somPegar = som("rbxasset://sounds/clickfast.wav", 0.5)
local somMoeda = som("rbxasset://sounds/electronicpingshort.wav", 0.25)
local somChave = som("rbxasset://sounds/victory.wav", 0.8)

------------------------------------------------------------------------
-- Canto esquerdo: moedas, estrelas, saco
------------------------------------------------------------------------
local barra = Instance.new("Frame")
barra.BackgroundTransparency = 1
-- Fica abaixo da janela de chat do Roblox (que ocupa o canto de cima)
barra.Position = UDim2.fromScale(0.01, 0.36)
barra.Size = UDim2.fromScale(0.26, 0.21)
barra.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0.04, 0)
layout.Parent = barra

local function etiqueta(): TextLabel
	local l = Interface.texto(barra, { Size = UDim2.fromScale(1, 0.3), BackgroundTransparency = 0.15, BackgroundColor3 = CORES.fundo, TextXAlignment = Enum.TextXAlignment.Left })
	Interface.arredondar(l, 0.3)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingTop = UDim.new(0.1, 0)
	pad.PaddingBottom = UDim.new(0.1, 0)
	pad.Parent = l
	return l
end
local lblMoedas = etiqueta()
local lblEstrelas = etiqueta()
local lblSaco = etiqueta()

local function atualizarBarra()
	lblMoedas.Text = "💰 " .. Util.numero(player:GetAttribute("Moedas") or 0)
	lblEstrelas.Text = "⭐ " .. Util.numero(player:GetAttribute("Estrelas") or 0)
	local saco, max = player:GetAttribute("Saco") or 0, player:GetAttribute("SacoMax") or 10
	lblSaco.Text = string.format("🎒 %d/%d", saco, max)
	lblSaco.TextColor3 = saco >= max and Color3.fromRGB(255, 110, 110) or CORES.branco
end
for _, nome in { "Moedas", "Estrelas", "Saco", "SacoMax" } do
	player:GetAttributeChangedSignal(nome):Connect(atualizarBarra)
end
atualizarBarra()

------------------------------------------------------------------------
-- Topo: tempo e progresso da montanha
------------------------------------------------------------------------
local topo = Instance.new("Frame")
topo.AnchorPoint = Vector2.new(0.5, 0)
topo.Position = UDim2.fromScale(0.5, 0.02)
topo.Size = UDim2.fromScale(0.34, 0.12)
topo.BackgroundColor3 = CORES.fundo
topo.BackgroundTransparency = 0.15
Interface.arredondar(topo, 0.2)
Interface.fundoNatal(topo)
topo.Parent = gui
local lblTempo = Interface.texto(topo, { Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0, 0.04), Text = "00:00" })
local fundoBarra = Instance.new("Frame")
fundoBarra.Position = UDim2.fromScale(0.06, 0.6)
fundoBarra.Size = UDim2.fromScale(0.88, 0.28)
fundoBarra.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Interface.arredondar(fundoBarra, 0.5)
fundoBarra.Parent = topo
local preenchimento = Instance.new("Frame")
preenchimento.Size = UDim2.fromScale(0, 1)
preenchimento.BackgroundColor3 = CORES.verde
Interface.arredondar(preenchimento, 0.5)
preenchimento.Parent = fundoBarra
local lblProgresso = Interface.texto(fundoBarra, { Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 2 })

RunService.Heartbeat:Connect(function()
	local inicio = workspace:GetAttribute("Inicio")
	local final = workspace:GetAttribute("TempoFinal")
	if final then
		lblTempo.Text = "⏱️ " .. Util.tempo(final)
	elseif inicio then
		lblTempo.Text = "⏱️ " .. Util.tempo(workspace:GetServerTimeNow() - inicio)
	else
		lblTempo.Text = "Esperando o grupo..."
	end
	local total = workspace:GetAttribute("PresentesTotal") or 0
	local feitos = workspace:GetAttribute("Desembrulhados") or 0
	if total > 0 then
		local f = math.clamp(feitos / total, 0, 1)
		preenchimento.Size = UDim2.fromScale(f, 1)
		local dono = workspace:GetAttribute("DonoChave")
		lblProgresso.Text = dono and ("🔑 com " .. dono .. "!") or string.format("🎁 %d%% desembrulhado", math.floor(f * 100))
	end
end)

------------------------------------------------------------------------
-- Botão DESEMBRULHAR (aparece perto da mesa). Segure para desembrulhar.
-- No PC também dá pra segurar a tecla F.
------------------------------------------------------------------------
local mesa: BasePart? = nil
task.spawn(function()
	local mapa = workspace:WaitForChild("MapaPartida")
	mesa = mapa:WaitForChild("MesaDesembrulhar") :: BasePart
end)

local btnDesembrulhar = Interface.botao(gui, "✂️ DESEMBRULHAR", CORES.verde, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.fromScale(0.97, 0.72),
	Size = UDim2.fromScale(0.24, 0.16),
	Visible = false,
})
local limite = Instance.new("UISizeConstraint")
limite.MinSize = Vector2.new(150, 60)
limite.Parent = btnDesembrulhar
Interface.texto(btnDesembrulhar, { Size = UDim2.fromScale(1, 0.35), Position = UDim2.fromScale(0, 1.05), Text = "segure (PC: tecla F)", TextColor3 = Color3.fromRGB(220, 255, 220) })

local segurandoBotao = false
local segurandoTecla = false
local enviado = false
local function atualizarSegurando()
	local agora = (segurandoBotao or segurandoTecla) and btnDesembrulhar.Visible
	if agora ~= enviado then
		enviado = agora
		remDesembrulhar:FireServer(agora)
		btnDesembrulhar.BackgroundColor3 = agora and Color3.fromRGB(30, 120, 60) or CORES.verde
	end
end
btnDesembrulhar.MouseButton1Down:Connect(function()
	segurandoBotao = true
	atualizarSegurando()
end)
btnDesembrulhar.MouseButton1Up:Connect(function()
	segurandoBotao = false
	atualizarSegurando()
end)
btnDesembrulhar.MouseLeave:Connect(function()
	segurandoBotao = false
	atualizarSegurando()
end)
UserInputService.InputBegan:Connect(function(input, processado)
	if not processado and input.KeyCode == Enum.KeyCode.F then
		segurandoTecla = true
		atualizarSegurando()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F then
		segurandoTecla = false
		atualizarSegurando()
	end
end)

-- Dica de "saco cheio" com seta para a mesa
local lblDicaSaco = Interface.texto(gui, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.86),
	Size = UDim2.fromScale(0.5, 0.06),
	Text = "🎒 Saco cheio! Vá para a ✂️ Mesa de Desembrulhar",
	TextColor3 = Color3.fromRGB(255, 220, 120),
	Visible = false,
})

RunService.Heartbeat:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local perto = false
	if root and mesa then
		local a = Vector3.new(root.Position.X, 0, root.Position.Z)
		local b = Vector3.new(mesa.Position.X, 0, mesa.Position.Z)
		perto = (a - b).Magnitude <= Config.RAIO_MESA
	end
	btnDesembrulhar.Visible = perto and not workspace:GetAttribute("TempoFinal")
	atualizarSegurando()
	local saco, max = player:GetAttribute("Saco") or 0, player:GetAttribute("SacoMax") or 10
	lblDicaSaco.Visible = saco >= max and not perto
end)

------------------------------------------------------------------------
-- Pegar presentes: clique (PC) ou toque (celular). Segurando continua pegando.
------------------------------------------------------------------------
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include

local pressionando: InputObject? = nil
local function tentarColetar(posTela: Vector2)
	local montanha = workspace:FindFirstChild("Montanha")
	if not montanha then
		return
	end
	params.FilterDescendantsInstances = { montanha }
	-- ScreenPointToRay desconta a barra do topo do Roblox (a posição do clique vem sem ela)
	-- Pega a câmera na hora (o Roblox troca a câmera quando o personagem nasce)
	local raio = workspace.CurrentCamera:ScreenPointToRay(posTela.X, posTela.Y)
	local hit = workspace:Raycast(raio.Origin, raio.Direction * 300, params)
	if hit and hit.Instance.Parent == montanha then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and (root.Position - hit.Instance.Position).Magnitude <= Config.ALCANCE_COLETA then
			remColetar:FireServer(hit.Instance)
			somPegar:Play()
		end
	end
end

UserInputService.InputBegan:Connect(function(input, processado)
	if processado then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		pressionando = input
		tentarColetar(Vector2.new(input.Position.X, input.Position.Y))
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input == pressionando or input.UserInputType == Enum.UserInputType.MouseButton1 then
		pressionando = nil
	end
end)
task.spawn(function()
	while true do
		task.wait(0.15)
		local p = pressionando
		if p then
			tentarColetar(Vector2.new(p.Position.X, p.Position.Y))
		end
	end
end)

------------------------------------------------------------------------
-- Ganhos ao desembrulhar ("+12 💰" subindo)
------------------------------------------------------------------------
local NOMES_RAROS = { ["Dourado"] = "🟡 DOURADO", ["Diamante"] = "💎 DIAMANTE", ["Arco-íris"] = "🌈 ARCO-ÍRIS" }
remDesembrulhou.OnClientEvent:Connect(function(resumo)
	somMoeda:Play()
	local l = Interface.texto(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5 + math.random(-10, 10) / 100, 0.55),
		Size = UDim2.fromScale(0.2, 0.06),
		Text = "+" .. Util.numero(resumo.moedas) .. " 💰",
		TextColor3 = CORES.dourado,
	})
	task.spawn(function()
		for i = 1, 20 do
			l.Position += UDim2.fromScale(0, -0.008)
			l.TextTransparency = i / 20
			l.TextStrokeTransparency = 0.4 + i / 33
			task.wait(0.03)
		end
		l:Destroy()
	end)
	for _, rar in resumo.raros do
		if rar ~= "Dourado" then
			Interface.aviso("✨ Presente " .. (NOMES_RAROS[rar] or rar) .. "!", CORES.dourado)
		end
	end
	if resumo.estrelas > 0 then
		Interface.aviso("⭐ Você achou " .. resumo.estrelas .. " Estrela!", CORES.dourado)
	end
	Interface.pular(lblMoedas)
end)

------------------------------------------------------------------------
-- LOJA
------------------------------------------------------------------------
local painelLoja, conteudoLoja = Interface.painel(gui, "🛒 LOJA DE MELHORIAS", UDim2.fromScale(0.62, 0.78))
local lista = Instance.new("UIListLayout")
lista.Padding = UDim.new(0, 8)
lista.SortOrder = Enum.SortOrder.LayoutOrder
lista.Parent = conteudoLoja

local linhasLoja = {}
for ordem, m in Config.MELHORIAS do
	local linha = Instance.new("Frame")
	linha.Size = UDim2.new(1, -12, 0, 70)
	linha.BackgroundColor3 = CORES.fundo
	linha.LayoutOrder = ordem
	Interface.arredondar(linha, 0.2)
	linha.Parent = conteudoLoja
	local nome = Interface.texto(linha, { Size = UDim2.fromScale(0.6, 0.5), Position = UDim2.fromScale(0.03, 0.05), TextXAlignment = Enum.TextXAlignment.Left })
	local desc = Interface.texto(linha, { Size = UDim2.fromScale(0.6, 0.35), Position = UDim2.fromScale(0.03, 0.58), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(200, 200, 220) })
	local btn = Interface.botao(linha, "", CORES.verde, { Size = UDim2.fromScale(0.33, 0.8), Position = UDim2.fromScale(0.65, 0.1) })
	btn.Activated:Connect(function()
		local ok, msg = remComprar:InvokeServer(m.id)
		if ok then
			Interface.pular(linha)
		elseif msg then
			Interface.aviso(msg, Color3.fromRGB(255, 120, 120))
		end
	end)
	linhasLoja[m.id] = { nome = nome, desc = desc, btn = btn, m = m }
end

local function formatarNivel(m, valor: number): string
	if m.id == "Valor" then
		return "x" .. valor
	elseif m.id == "Tesoura" then
		return valor .. "/s"
	end
	return tostring(valor)
end

local function atualizarLoja()
	local moedas = player:GetAttribute("Moedas") or 0
	for id, l in linhasLoja do
		local m = l.m
		local nivel = player:GetAttribute("Nivel_" .. id) or 1
		local atual = m.niveis[nivel]
		local proximo = m.niveis[nivel + 1]
		l.nome.Text = string.format("%s  (%s)", m.nome, formatarNivel(m, atual))
		if proximo then
			local preco = m.custos[nivel + 1]
			l.desc.Text = m.desc .. " → " .. formatarNivel(m, proximo)
			l.btn.Text = "💰 " .. Util.numero(preco)
			l.btn.BackgroundColor3 = moedas >= preco and CORES.verde or CORES.cinza
		else
			l.desc.Text = m.desc
			l.btn.Text = "MÁXIMO"
			l.btn.BackgroundColor3 = CORES.dourado
		end
	end
end
player:GetAttributeChangedSignal("Moedas"):Connect(atualizarLoja)
for _, m in Config.MELHORIAS do
	player:GetAttributeChangedSignal("Nivel_" .. m.id):Connect(atualizarLoja)
end
atualizarLoja()

remAbrirLoja.OnClientEvent:Connect(function()
	atualizarLoja()
	painelLoja.Visible = true
	Interface.pular(painelLoja)
end)

-- Fecha a loja se o jogador se afastar
task.spawn(function()
	while true do
		task.wait(0.5)
		if painelLoja.Visible then
			local mapa = workspace:FindFirstChild("MapaPartida")
			local loja = mapa and mapa:FindFirstChild("Loja") :: BasePart?
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if loja and root and (loja.Position - root.Position).Magnitude > 30 then
				painelLoja.Visible = false
			end
		end
	end
end)

------------------------------------------------------------------------
-- Contagem inicial, avisos, chave e fuga
------------------------------------------------------------------------
local lblGrande = Interface.texto(gui, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.4),
	Size = UDim2.fromScale(0.6, 0.18),
	Text = "",
	TextColor3 = CORES.dourado,
	TextStrokeTransparency = 0,
	Visible = false,
})

remContagem.OnClientEvent:Connect(function(texto: string)
	lblGrande.Text = texto
	lblGrande.Visible = true
	Interface.pular(lblGrande)
	if #texto > 2 then
		task.delay(1.5, function()
			lblGrande.Visible = false
		end)
	end
end)

remAviso.OnClientEvent:Connect(function(texto: string)
	Interface.aviso(texto)
	if string.find(texto, "ACHOU A CHAVE") then
		somChave:Play()
	end
end)

player:GetAttributeChangedSignal("TemChave"):Connect(function()
	if player:GetAttribute("TemChave") then
		lblGrande.Text = "🔑 VOCÊ ACHOU A CHAVE! Abra o PORTÃO!"
		lblGrande.Visible = true
		Interface.pular(lblGrande)
		task.delay(4, function()
			lblGrande.Visible = false
		end)
	end
end)

remFugiram.OnClientEvent:Connect(function(r)
	local painel = Instance.new("Frame")
	painel.AnchorPoint = Vector2.new(0.5, 0.5)
	painel.Position = UDim2.fromScale(0.5, 0.5)
	painel.Size = UDim2.fromScale(0.5, 0.55)
	painel.BackgroundColor3 = CORES.painel
	Interface.arredondar(painel, 0.06)
	Interface.contorno(painel, CORES.dourado, 4)
	Interface.fundoNatal(painel)
	local lim = Instance.new("UISizeConstraint")
	lim.MinSize = Vector2.new(300, 220)
	lim.Parent = painel
	painel.Parent = gui
	Interface.texto(painel, { Size = UDim2.fromScale(0.9, 0.2), Position = UDim2.fromScale(0.05, 0.04), Text = "🎉 VOCÊS FUGIRAM! 🎉", TextColor3 = CORES.dourado })
	Interface.texto(painel, { Size = UDim2.fromScale(0.9, 0.14), Position = UDim2.fromScale(0.05, 0.26), Text = "⏱️ Tempo: " .. Util.tempo(r.tempo) .. "  (" .. r.modo .. ")" })
	if r.recorde then
		Interface.texto(painel, { Size = UDim2.fromScale(0.9, 0.1), Position = UDim2.fromScale(0.05, 0.41), Text = "🏆 NOVO RECORDE PESSOAL!", TextColor3 = CORES.dourado })
	end
	Interface.texto(painel, { Size = UDim2.fromScale(0.9, 0.1), Position = UDim2.fromScale(0.05, 0.54), Text = "+" .. r.estrelas .. " ⭐ Estrelas" })
	Interface.texto(painel, { Size = UDim2.fromScale(0.9, 0.1), Position = UDim2.fromScale(0.05, 0.66), Text = string.format("🔁 Renascimento %d  (+%d%% moedas)", r.renascimentos, r.bonus * 100), TextColor3 = Color3.fromRGB(150, 220, 255) })
	Interface.texto(painel, { Size = UDim2.fromScale(0.9, 0.09), Position = UDim2.fromScale(0.05, 0.84), Text = "Voltando para o lobby...", TextColor3 = Color3.fromRGB(200, 200, 220) })
	Interface.pular(painel)
	somChave:Play()
end)
