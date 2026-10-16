-- Funções pequenas usadas no servidor e no cliente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Util = {}

-- 1234567 -> "1,23M"
function Util.numero(n: number): string
	n = math.floor(n)
	if n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

-- 754 -> "12:34"
function Util.tempo(segundos: number): string
	segundos = math.max(0, segundos)
	local h = math.floor(segundos / 3600)
	local m = math.floor((segundos % 3600) / 60)
	local s = math.floor(segundos % 60)
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%02d:%02d", m, s)
end

-- Pega (ou cria, no servidor) um RemoteEvent/RemoteFunction pelo nome.
function Util.remoto(nome: string, classe: string?): Instance
	local pasta = ReplicatedStorage:FindFirstChild("Remotos")
	if RunService:IsServer() then
		if not pasta then
			pasta = Instance.new("Folder")
			pasta.Name = "Remotos"
			pasta.Parent = ReplicatedStorage
		end
		local r = pasta:FindFirstChild(nome)
		if not r then
			r = Instance.new(classe or "RemoteEvent")
			r.Name = nome
			r.Parent = pasta
		end
		return r
	end
	pasta = ReplicatedStorage:WaitForChild("Remotos")
	return pasta:WaitForChild(nome)
end

-- Sorteio por peso: lista de itens com campo "chance"
function Util.sortear(lista: { any }, rng: Random?): any
	local r = (rng or Random.new()):NextNumber()
	local acumulado = 0
	for _, item in lista do
		acumulado += item.chance
		if r <= acumulado then
			return item
		end
	end
	return lista[1]
end

-- Cria uma peça de forma rápida
function Util.peca(props: { [string]: any }): BasePart
	local classe = props.Classe or "Part"
	local p = Instance.new(classe)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "Classe" and k ~= "Parent" then
			(p :: any)[k] = v
		end
	end
	if props.Parent then
		p.Parent = props.Parent
	end
	return p
end

-- Placa de texto numa face de uma peça
function Util.placa(peca: BasePart, texto: string, face: Enum.NormalId?, corTexto: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = peca
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = corTexto or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = texto
	label.Parent = gui
	return label
end

return Util
