-- ✂️ As 4 BANCADAS DE DESEMBRULHAR (uma por jogador).
-- Este módulo constrói as bancadas, entrega uma para cada jogador que entra,
-- libera quando ele sai e mantém a placa atualizada ("Livre" ou nome + quantos presentes).
-- As regras de desembrulhar (moedas, chave...) continuam no Partida.server.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Natal = require(ServerStorage.Comum.Natal)

local Bancadas = {}

local P = Config.PALETA
local CINZA_LIVRE = Color3.fromRGB(92, 98, 112)

export type Bancada = {
	numero: number,
	modelo: Model,
	centro: Vector3, -- ponto no chão, no meio da bancada
	bandeja: BasePart, -- onde a pilha de presentes aparece (e onde fica o botão "Colocar presentes")
	prompt: ProximityPrompt,
	placa: BasePart,
	textoNome: TextLabel,
	textoEstoque: TextLabel,
	icone: BillboardGui,
	dono: Player?,
}

Bancadas.lista = {} :: { Bancada }

local function texto(pai: Instance, tamanho: UDim2, posicao: UDim2, cor: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = tamanho
	l.Position = posicao
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = cor
	l.TextStrokeTransparency = 0.2
	l.Parent = pai
	return l
end

-- Monta uma bancada. "cf" fica no chão, no meio dela, com a FRENTE (onde o jogador fica)
-- para cf.LookVector.
local function construirUma(pai: Instance, numero: number, cf: CFrame): Bancada
	local m = Instance.new("Model")
	m.Name = "Bancada_" .. numero
	m:SetAttribute("Numero", numero)
	m:SetAttribute("Dono", 0)
	m:SetAttribute("Estoque", 0)
	m.Parent = pai

	-- Mesa baixa de madeira (pernas + tampo), toalha vermelha e bandeja de metal
	for _, x in { -3.4, 3.4 } do
		for _, z in { -1.8, 1.8 } do
			Natal.solida(m, { Name = "Perna", Size = Vector3.new(0.6, 2.6, 0.6), CFrame = cf * CFrame.new(x, 1.3, z), Color = P.madeiraEscura, Material = Enum.Material.Wood })
		end
	end
	Natal.solida(m, { Name = "Tampo", Size = Vector3.new(8, 0.5, 4.5), CFrame = cf * CFrame.new(0, 2.85, 0), Color = P.madeiraClara, Material = Enum.Material.Wood })
	Natal.peca(m, { Name = "Toalha", Size = Vector3.new(8.2, 0.08, 4.7), CFrame = cf * CFrame.new(0, 3.13, 0), Color = P.vermelho, Material = Enum.Material.Fabric })
	Natal.peca(m, { Name = "ToalhaFrente", Size = Vector3.new(8.2, 1.4, 0.1), CFrame = cf * CFrame.new(0, 2.45, -2.36), Color = P.vermelho, Material = Enum.Material.Fabric })
	Natal.peca(m, { Name = "Barrado", Size = Vector3.new(8.2, 0.22, 0.14), CFrame = cf * CFrame.new(0, 1.8, -2.38), Color = P.dourado, Material = Enum.Material.Foil })
	local bandeja = Natal.solida(m, { Name = "Bandeja", Size = Vector3.new(5.2, 0.25, 3), CFrame = cf * CFrame.new(0, 3.3, 0.1), Color = Color3.fromRGB(190, 196, 206), Material = Enum.Material.Metal })
	bandeja.CastShadow = false

	-- Enfeites: rolo de papel listrado, tesoura e laços
	local rolo = (cf * CFrame.new(-3.3, 3.62, 1.2)).Position
	Natal.cilindro(m, rolo - cf.LookVector * 1.4, rolo + cf.LookVector * 1.4, 0.8, P.verdeClaro, { Name = "RoloPapel" })
	Natal.cilindro(m, rolo - cf.LookVector * 0.1, rolo + cf.LookVector * 0.1, 0.85, P.neve, { Name = "ListraRolo" })
	local t = cf * CFrame.new(3.2, 3.2, -1)
	for _, lado in { -1, 1 } do
		local lamina = t * CFrame.Angles(0, math.rad(lado * 18), 0)
		Natal.peca(m, { Name = "Lamina", Size = Vector3.new(0.2, 0.1, 1.8), CFrame = lamina * CFrame.new(0, 0, -0.7), Color = Color3.fromRGB(200, 210, 220), Material = Enum.Material.Metal })
		Natal.peca(m, { Name = "CaboTesoura", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.18, 0.7, 0.7), CFrame = lamina * CFrame.new(0, 0, 0.45) * CFrame.Angles(0, 0, math.rad(90)), Color = P.vermelho })
	end
	Natal.laco(m, cf * CFrame.new(3.3, 3.25, 1.3), 0.9, P.dourado)

	-- Placa com o nome do dono (e quantos presentes tem na bancada), em dois postes
	for _, x in { -3.6, 3.6 } do
		Natal.cilindro(m, (cf * CFrame.new(x, 3.1, 2.1)).Position, (cf * CFrame.new(x, 7.4, 2.1)).Position, 0.4, P.madeiraEscura, { Name = "PostePlaca", Material = Enum.Material.Wood })
	end
	local placa = Natal.peca(m, { Name = "Placa", Size = Vector3.new(7.4, 2.4, 0.3), CFrame = cf * CFrame.new(0, 6.3, 2.1), Color = CINZA_LIVRE })
	Natal.moldura(m, placa, { cor = P.madeiraEscura, espessura = 0.25, neve = true })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0.3
	gui.Parent = placa
	local textoNome = texto(gui, UDim2.fromScale(0.94, 0.58), UDim2.fromScale(0.03, 0.03), Color3.new(1, 1, 1))
	local textoEstoque = texto(gui, UDim2.fromScale(0.94, 0.36), UDim2.fromScale(0.03, 0.62), P.luz)

	-- Ícone flutuante "✂️ DESEMBRULHAR"
	local ancora = Natal.peca(m, { Name = "AncoraIcone", Size = Vector3.one, CFrame = cf * CFrame.new(0, 9.4, 0.6), Transparency = 1 })
	local icone = Instance.new("BillboardGui")
	icone.Name = "Icone"
	icone.Size = UDim2.fromScale(7, 1.8)
	icone.MaxDistance = 90
	icone.LightInfluence = 0
	icone.Parent = ancora
	local fundo = Instance.new("Frame")
	fundo.Size = UDim2.fromScale(1, 1)
	fundo.BackgroundColor3 = P.vermelhoEscuro
	fundo.BackgroundTransparency = 0.15
	fundo.Parent = icone
	local canto = Instance.new("UICorner")
	canto.CornerRadius = UDim.new(0.4, 0)
	canto.Parent = fundo
	local borda = Instance.new("UIStroke")
	borda.Color = P.dourado
	borda.Thickness = 2
	borda.Parent = fundo
	local rotulo = texto(fundo, UDim2.fromScale(0.92, 0.8), UDim2.fromScale(0.04, 0.1), Color3.new(1, 1, 1))
	rotulo.Text = "✂️ DESEMBRULHAR"

	-- Botão de colocar os presentes do saco na bancada (tecla E ou toque)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ColocarPresentes"
	prompt.ActionText = "Colocar presentes"
	prompt.ObjectText = "Bancada " .. numero
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.RAIO_BANCADA
	prompt.RequiresLineOfSight = false
	prompt.Parent = bandeja

	return {
		numero = numero,
		modelo = m,
		centro = cf.Position,
		bandeja = bandeja,
		prompt = prompt,
		placa = placa,
		textoNome = textoNome,
		textoEstoque = textoEstoque,
		icone = icone,
		dono = nil,
	}
end

-- Atualiza placa, ícone e botão de acordo com o dono e o estoque
local function atualizar(b: Bancada)
	local estoque = b.modelo:GetAttribute("Estoque") or 0
	if b.dono then
		b.placa.Color = Config.CORES_BANCADA[b.numero]
		b.textoNome.Text = b.dono.DisplayName
		b.textoEstoque.Text = "🎁 " .. estoque .. " na bancada"
		b.icone.Enabled = true
		b.prompt.Enabled = true
	else
		b.placa.Color = CINZA_LIVRE
		b.textoNome.Text = "Livre"
		b.textoEstoque.Text = ""
		b.icone.Enabled = false
		b.prompt.Enabled = false
	end
end

-- Cria as 4 bancadas. "posicoes" = pontos no chão; "frente" = para onde o jogador olha a bancada.
function Bancadas.construir(pai: Instance, posicoes: { Vector3 }, frente: Vector3)
	table.clear(Bancadas.lista)
	for i, pos in posicoes do
		local b = construirUma(pai, i, CFrame.lookAt(pos, pos + frente))
		atualizar(b)
		table.insert(Bancadas.lista, b)
	end
end

function Bancadas.de(player: Player): Bancada?
	for _, b in Bancadas.lista do
		if b.dono == player then
			return b
		end
	end
	return nil
end

-- Dá a primeira bancada livre para o jogador
function Bancadas.atribuir(player: Player): Bancada?
	local ja = Bancadas.de(player)
	if ja then
		return ja
	end
	for _, b in Bancadas.lista do
		if not b.dono then
			b.dono = player
			b.modelo:SetAttribute("Dono", player.UserId)
			b.modelo:SetAttribute("Estoque", 0)
			player:SetAttribute("Bancada", b.numero)
			atualizar(b)
			return b
		end
	end
	return nil
end

-- O jogador saiu: a bancada volta a ficar "Livre"
function Bancadas.liberar(player: Player)
	local b = Bancadas.de(player)
	if b then
		b.dono = nil
		b.modelo:SetAttribute("Dono", 0)
		b.modelo:SetAttribute("Estoque", 0)
		atualizar(b)
	end
end

function Bancadas.definirEstoque(b: Bancada, quantidade: number)
	if b.modelo:GetAttribute("Estoque") ~= quantidade then
		b.modelo:SetAttribute("Estoque", quantidade)
		atualizar(b)
	end
end

-- O jogador está perto da PRÓPRIA bancada? (folga um pouco maior que a do cliente)
function Bancadas.perto(b: Bancada, posicao: Vector3): boolean
	local d = Vector3.new(posicao.X - b.centro.X, 0, posicao.Z - b.centro.Z).Magnitude
	return d <= Config.RAIO_BANCADA + 3
end

return Bancadas
