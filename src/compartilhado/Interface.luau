-- Ajudantes para montar a interface (botões, painéis, avisos) do jeito certo
-- para CELULAR e PC: tamanhos em escala, texto que se ajusta e cantos arredondados.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Interface = {}

Interface.CORES = {
	fundo = Color3.fromRGB(30, 24, 48),
	painel = Color3.fromRGB(45, 36, 70),
	vermelho = Color3.fromRGB(215, 45, 55),
	verde = Color3.fromRGB(45, 170, 85),
	dourado = Color3.fromRGB(255, 200, 50),
	azul = Color3.fromRGB(60, 130, 230),
	cinza = Color3.fromRGB(110, 110, 130),
	branco = Color3.new(1, 1, 1),
}

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

function Interface.texto(pai: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Interface.CORES.branco
	l.TextStrokeTransparency = 0.4
	for k, v in props do
		(l :: any)[k] = v
	end
	l.Parent = pai
	return l
end

function Interface.botao(pai: Instance, texto: string, cor: Color3, props: { [string]: any }?): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = cor
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.TextColor3 = Interface.CORES.branco
	b.TextStrokeTransparency = 0.5
	b.Text = texto
	for k, v in (props or {}) :: { [string]: any } do
		(b :: any)[k] = v
	end
	Interface.arredondar(b, 0.25)
	Interface.contorno(b, Color3.new(0, 0, 0), 2.5)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.PaddingLeft = UDim.new(0.06, 0)
	pad.PaddingRight = UDim.new(0.06, 0)
	pad.Parent = b
	b.Parent = pai
	return b
end

-- Painel centralizado com título e botão de fechar
function Interface.painel(pai: Instance, titulo: string, tamanho: UDim2): (Frame, Frame)
	local p = Instance.new("Frame")
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Position = UDim2.fromScale(0.5, 0.5)
	p.Size = tamanho
	p.BackgroundColor3 = Interface.CORES.painel
	p.Visible = false
	Interface.arredondar(p, 0.05)
	Interface.contorno(p, Interface.CORES.dourado, 3)
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize = Vector2.new(720, 560)
	limite.Parent = p
	p.Parent = pai

	Interface.texto(p, { Size = UDim2.fromScale(0.8, 0.12), Position = UDim2.fromScale(0.1, 0.02), Text = titulo, TextColor3 = Interface.CORES.dourado })
	-- O X fica na esquerda: na direita ele ficava escondido atrás da lista de jogadores do Roblox
	local fechar = Interface.botao(p, "X", Interface.CORES.vermelho, { Size = UDim2.fromScale(0.1, 0.1), Position = UDim2.fromScale(0.02, 0.02), SizeConstraint = Enum.SizeConstraint.RelativeYY })
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
	conteudo.AutomaticCanvasSize = Enum.AutomaticSize.Y
	conteudo.CanvasSize = UDim2.new()
	conteudo.Parent = p
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
