-- Ajudantes para montar a interface (botões, painéis, avisos) do jeito certo
-- para CELULAR e PC: tamanhos em escala, texto que se ajusta e cantos arredondados.
-- 🎄 Visual de Natal: painéis vermelho-escuros com borda dourada fina e sombra,
-- botões com degradê e "pulinho" ao passar o mouse/tocar, texto sempre com contorno.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Interface = {}

Interface.CORES = {
	fundo = Color3.fromRGB(16, 48, 34), -- verde-pinheiro bem escuro (etiquetas e cartões)
	painel = Color3.fromRGB(112, 22, 30), -- vermelho de Natal escuro (janelas)
	vermelho = Color3.fromRGB(198, 40, 40),
	verde = Color3.fromRGB(46, 160, 86),
	dourado = Color3.fromRGB(245, 199, 107),
	azul = Color3.fromRGB(52, 122, 196),
	cinza = Color3.fromRGB(105, 110, 125),
	branco = Color3.new(1, 1, 1),
	-- Novas (só visual)
	creme = Color3.fromRGB(255, 240, 210),
	contornoTexto = Color3.fromRGB(28, 14, 10),
	sombra = Color3.new(0, 0, 0),
}

-- Altura mínima confortável para o dedo no celular
local ALTURA_MIN_BOTAO = 44

function Interface.tela(nome: string): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = nome
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

function Interface.arredondar(obj: GuiObject, raio: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(raio or 0.2, 0)
	c.Parent = obj
end

function Interface.contorno(obj: GuiObject, cor: Color3?, espessura: number?)
	local s = Instance.new("UIStroke")
	s.Color = cor or Color3.new(0, 0, 0)
	s.Thickness = espessura or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
end

-- Degradê suave de cima (mais claro) para baixo (mais escuro). Funciona com qualquer cor de fundo.
local function degrade(obj: GuiObject, escuro: number?)
	local g = Instance.new("UIGradient")
	local e = escuro or 0.78
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(e, e, e))
	g.Rotation = 90
	g.Parent = obj
end

-- Deixa um quadro com cara de "janela de Natal": degradê, borda dourada fina e cantos redondos.
-- (os painéis já usam; os HUDs chamam nos quadros que eles mesmos montam)
function Interface.fundoNatal(quadro: GuiObject)
	degrade(quadro, 0.72)
	if not quadro:FindFirstChildOfClass("UIStroke") then
		Interface.contorno(quadro, Interface.CORES.dourado, 2)
	end
	if not quadro:FindFirstChildOfClass("UICorner") then
		Interface.arredondar(quadro, 0.06)
	end
end

function Interface.texto(pai: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Interface.CORES.branco
	l.TextStrokeColor3 = Interface.CORES.contornoTexto
	l.TextStrokeTransparency = 0.3
	for k, v in props do
		(l :: any)[k] = v
	end
	-- Etiqueta com fundo (moedas, estrelas...): degradê e borda dourada fininha
	if l.BackgroundTransparency < 1 then
		degrade(l, 0.7)
		local s = Instance.new("UIStroke")
		s.Color = Interface.CORES.dourado
		s.Thickness = 1.5
		s.Transparency = 0.25
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = l
	end
	l.Parent = pai
	return l
end

-- Animação de escala dos botões (passar o mouse, apertar, soltar)
local INFO_RAPIDO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local INFO_VOLTA = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function animarBotao(b: TextButton)
	local escala = Instance.new("UIScale")
	escala.Name = "EscalaBotao"
	escala.Parent = b
	local dentro = false
	b.MouseEnter:Connect(function()
		dentro = true
		TweenService:Create(escala, INFO_RAPIDO, { Scale = 1.06 }):Play()
	end)
	b.MouseLeave:Connect(function()
		dentro = false
		TweenService:Create(escala, INFO_RAPIDO, { Scale = 1 }):Play()
	end)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(escala, INFO_RAPIDO, { Scale = 0.95 }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		TweenService:Create(escala, INFO_VOLTA, { Scale = dentro and 1.06 or 1 }):Play()
	end)
end

function Interface.botao(pai: Instance, texto: string, cor: Color3, props: { [string]: any }?): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = cor
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.TextColor3 = Interface.CORES.branco
	b.TextStrokeColor3 = Interface.CORES.contornoTexto
	b.TextStrokeTransparency = 0.35
	b.Text = texto
	for k, v in (props or {}) :: { [string]: any } do
		(b :: any)[k] = v
	end
	Interface.arredondar(b, 0.25)
	Interface.contorno(b, Color3.fromRGB(35, 18, 12), 2.5)
	degrade(b)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.PaddingLeft = UDim.new(0.06, 0)
	pad.PaddingRight = UDim.new(0.06, 0)
	pad.Parent = b
	animarBotao(b)
	b.Parent = pai
	-- Tamanho mínimo para o dedo (44 px). Espera um instante porque alguns HUDs
	-- colocam o próprio limite logo depois de criar o botão; aí só ajustamos o dele.
	task.defer(function()
		if not b.Parent then
			return -- o botão já foi apagado (ex.: o menu foi redesenhado)
		end
		local limite = b:FindFirstChildOfClass("UISizeConstraint")
		if limite then
			if limite.MinSize.Y < ALTURA_MIN_BOTAO then
				limite.MinSize = Vector2.new(limite.MinSize.X, ALTURA_MIN_BOTAO)
			end
		else
			limite = Instance.new("UISizeConstraint")
			limite.MinSize = Vector2.new(ALTURA_MIN_BOTAO, ALTURA_MIN_BOTAO)
			limite.Parent = b
		end
	end)
	return b
end

-- Painel centralizado com título e botão de fechar
function Interface.painel(pai: Instance, titulo: string, tamanho: UDim2): (Frame, Frame)
	-- "p" é só a caixa por fora (os HUDs mostram/escondem ela); o desenho fica dentro
	local p = Instance.new("Frame")
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Position = UDim2.fromScale(0.5, 0.5)
	p.Size = tamanho
	p.BackgroundTransparency = 1
	p.Visible = false
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize = Vector2.new(720, 560)
	limite.Parent = p
	p.Parent = pai

	-- Sombra suave (um quadro escuro um pouco para baixo, atrás de tudo)
	local sombra = Instance.new("Frame")
	sombra.Name = "Sombra"
	sombra.Size = UDim2.fromScale(1, 1)
	sombra.Position = UDim2.fromOffset(0, 7)
	sombra.BackgroundColor3 = Interface.CORES.sombra
	sombra.BackgroundTransparency = 0.55
	sombra.ZIndex = 0
	Interface.arredondar(sombra, 0.05)
	sombra.Parent = p

	-- Fundo vermelho com degradê e borda dourada (e uma segunda borda fininha por dentro)
	local fundo = Instance.new("Frame")
	fundo.Name = "Fundo"
	fundo.Size = UDim2.fromScale(1, 1)
	fundo.BackgroundColor3 = Interface.CORES.painel
	fundo.ZIndex = 1
	Interface.arredondar(fundo, 0.05)
	Interface.contorno(fundo, Interface.CORES.dourado, 2.5)
	degrade(fundo, 0.7)
	fundo.Parent = p
	local bordaInterna = Instance.new("Frame")
	bordaInterna.Name = "BordaInterna"
	bordaInterna.AnchorPoint = Vector2.new(0.5, 0.5)
	bordaInterna.Position = UDim2.fromScale(0.5, 0.5)
	bordaInterna.Size = UDim2.new(1, -12, 1, -12)
	bordaInterna.BackgroundTransparency = 1
	Interface.arredondar(bordaInterna, 0.045)
	local s = Instance.new("UIStroke")
	s.Color = Interface.CORES.dourado
	s.Thickness = 1
	s.Transparency = 0.6
	s.Parent = bordaInterna
	bordaInterna.Parent = fundo

	-- Título com um floquinho de cada lado e uma linha dourada embaixo
	Interface.texto(p, { Size = UDim2.fromScale(0.7, 0.12), Position = UDim2.fromScale(0.15, 0.02), Text = titulo, TextColor3 = Interface.CORES.dourado, ZIndex = 2 })
	for _, x in { 0.1, 0.86 } do
		Interface.texto(p, { Size = UDim2.fromScale(0.04, 0.07), Position = UDim2.fromScale(x, 0.045), Text = "❄", TextColor3 = Interface.CORES.creme, TextTransparency = 0.15, ZIndex = 2 })
	end
	local linha = Instance.new("Frame")
	linha.Name = "Linha"
	linha.AnchorPoint = Vector2.new(0.5, 0)
	linha.Position = UDim2.fromScale(0.5, 0.145)
	linha.Size = UDim2.new(0.8, 0, 0, 2)
	linha.BackgroundColor3 = Interface.CORES.dourado
	linha.BackgroundTransparency = 0.35
	linha.BorderSizePixel = 0
	linha.ZIndex = 2
	linha.Parent = p

	-- O X fica na esquerda: na direita ele ficava escondido atrás da lista de jogadores do Roblox
	local fechar = Interface.botao(p, "X", Interface.CORES.vermelho, { Size = UDim2.fromScale(0.1, 0.1), Position = UDim2.fromScale(0.02, 0.02), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 2 })
	fechar.Activated:Connect(function()
		p.Visible = false
	end)

	local conteudo = Instance.new("ScrollingFrame")
	conteudo.Name = "Conteudo"
	conteudo.Position = UDim2.fromScale(0.04, 0.16)
	conteudo.Size = UDim2.fromScale(0.92, 0.8)
	conteudo.BackgroundTransparency = 1
	conteudo.BorderSizePixel = 0
	conteudo.ScrollBarThickness = 8
	conteudo.ScrollBarImageColor3 = Interface.CORES.dourado
	conteudo.AutomaticCanvasSize = Enum.AutomaticSize.Y
	conteudo.CanvasSize = UDim2.new()
	conteudo.ZIndex = 2
	conteudo.Parent = p
	-- Em telas pequenas o X (mínimo 44 px) fica mais alto que o título:
	-- então a lista começa logo abaixo dele, para nada ficar por baixo do botão.
	local function ajustarConteudo()
		local altura = p.AbsoluteSize.Y
		if altura <= 0 then
			return
		end
		local topo = math.max(altura * 0.16, altura * 0.02 + math.max(altura * 0.1, ALTURA_MIN_BOTAO) + 6)
		conteudo.Position = UDim2.new(0.04, 0, 0, topo)
		conteudo.Size = UDim2.new(0.92, 0, 1, -topo - altura * 0.04)
	end
	p:GetPropertyChangedSignal("AbsoluteSize"):Connect(ajustarConteudo)
	ajustarConteudo()
	return p, conteudo :: any
end

-- Aviso que aparece no topo e some sozinho
local filaAvisos: Frame? = nil
function Interface.aviso(texto: string, cor: Color3?)
	if not filaAvisos or not filaAvisos.Parent then
		local gui = Interface.tela("Avisos")
		gui.DisplayOrder = 50
		local f = Instance.new("Frame")
		f.BackgroundTransparency = 1
		f.AnchorPoint = Vector2.new(0.5, 0)
		f.Position = UDim2.fromScale(0.5, 0.14)
		f.Size = UDim2.fromScale(0.7, 0.3)
		f.Parent = gui
		local lista = Instance.new("UIListLayout")
		lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
		lista.Padding = UDim.new(0.02, 0)
		lista.Parent = f
		filaAvisos = f
	end
	local l = Interface.texto(filaAvisos :: Frame, {
		Size = UDim2.fromScale(1, 0.22),
		Text = texto,
		TextColor3 = cor or Interface.CORES.branco,
		TextStrokeTransparency = 0,
	})
	task.delay(3.5, function()
		local t = TweenService:Create(l, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 })
		t:Play()
		t.Completed:Wait()
		l:Destroy()
	end)
end

-- Efeito de "pulinho" num elemento
function Interface.pular(obj: GuiObject)
	local escala = obj:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	escala.Parent = obj
	escala.Scale = 1.15
	TweenService:Create(escala, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

return Interface
