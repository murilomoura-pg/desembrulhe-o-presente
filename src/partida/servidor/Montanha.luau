-- Gera a MONTANHA DE PRESENTES e controla quem pega cada presente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Compartilhado.Config)
local Util = require(ReplicatedStorage.Compartilhado.Util)

local Montanha = {}

local TAMANHO = 2.4 -- tamanho de cada presente
local ESPACO = 2.6 -- distância entre presentes

local pasta: Folder? = nil
Montanha.total = 0
Montanha.restantes = 0

local ALTURA = 1.2 -- altura da montanha = raio x ALTURA

-- Todas as posições de um cone cheio, da camada de baixo para cima
local function posicoesCone(raio: number, rng: Random?): { Vector3 }
	local altura = raio * ALTURA
	local lista = {}
	local camada = 0
	while true do
		local y = camada * ESPACO + TAMANHO / 2
		if y > altura then
			break
		end
		local r = raio * (1 - y / altura)
		local passos = math.floor(r / ESPACO)
		-- deslocamento em camadas alternadas, parece mais "empilhado"
		local desloc = (camada % 2) * ESPACO / 2
		for ix = -passos, passos do
			for iz = -passos, passos do
				local x = ix * ESPACO + desloc
				local z = iz * ESPACO + desloc
				if x * x + z * z <= r * r then
					local jx = rng and rng:NextNumber(-0.15, 0.15) or 0
					local jz = rng and rng:NextNumber(-0.15, 0.15) or 0
					table.insert(lista, Vector3.new(x + jx, y, z + jz))
				end
			end
		end
		camada += 1
	end
	return lista
end

-- Menor raio em que cabem "quantidade" presentes
function Montanha.raioPara(quantidade: number): number
	local raio = 8
	while #posicoesCone(raio) < quantidade do
		raio *= 1.02
	end
	return raio
end

function Montanha.gerar(quantidade: number, raio: number)
	local rng = Random.new()
	local pos = posicoesCone(raio, rng)
	while #pos < quantidade do
		raio *= 1.02
		pos = posicoesCone(raio, rng)
	end

	local nova = Instance.new("Folder")
	nova.Name = "Montanha"
	for i = 1, quantidade do
		local p = pos[i]
		local rar = Util.sortear(Config.RARIDADES, rng)
		local cor = rar.cores[rng:NextInteger(1, #rar.cores)]
		local presente = Instance.new("Part")
		presente.Name = "Presente"
		presente.Anchored = true
		presente.CanTouch = false
		presente.Size = Vector3.one * TAMANHO
		presente.CFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(rng:NextNumber(-12, 12)), 0)
		presente.Color = cor
		presente.Material = rar.material
		presente.TopSurface = Enum.SurfaceType.Smooth
		presente.BottomSurface = Enum.SurfaceType.Smooth
		presente:SetAttribute("Raridade", rar.id)
		if rar.id ~= "Comum" then
			presente.Reflectance = 0.15
		end

		-- Laço (só visual; o clique passa direto para a caixa)
		local laco = Instance.new("Part")
		laco.Name = "Laco"
		laco.Anchored = true
		laco.CanCollide = false
		laco.CanQuery = false
		laco.CanTouch = false
		laco.CastShadow = false
		laco.Size = Vector3.new(TAMANHO + 0.08, TAMANHO + 0.08, TAMANHO * 0.22)
		laco.CFrame = presente.CFrame
		laco.Color = rar.id == "Dourado" and Color3.fromRGB(200, 30, 40) or Color3.fromRGB(255, 215, 80)
		laco.Material = Enum.Material.SmoothPlastic
		laco.Parent = presente

		if rar.id == "Arco-íris" or rar.id == "Diamante" then
			local brilho = Instance.new("Sparkles")
			brilho.SparkleColor = cor
			brilho.Parent = presente
		end
		presente.Parent = nova
	end
	nova.Parent = workspace -- coloca tudo de uma vez (mais rápido)
	pasta = nova
	Montanha.total = quantidade
	Montanha.restantes = quantidade
	workspace:SetAttribute("PresentesTotal", quantidade)
	workspace:SetAttribute("PresentesRestantes", quantidade)
	return raio
end

function Montanha.pasta(): Folder?
	return pasta
end

function Montanha.ehPresente(obj: any): boolean
	return typeof(obj) == "Instance" and pasta ~= nil and obj:IsA("BasePart") and obj.Parent == pasta
end

local function remover(presente: BasePart): string
	local rar = presente:GetAttribute("Raridade") or "Comum"
	presente:Destroy()
	Montanha.restantes -= 1
	workspace:SetAttribute("PresentesRestantes", Montanha.restantes)
	return rar
end

-- Pega o presente clicado + os vizinhos (até "quantidade"). Retorna a lista de raridades.
function Montanha.pegarPerto(presente: BasePart, quantidade: number): { string }
	local pegos = { remover(presente) }
	if quantidade <= 1 or not pasta then
		return pegos
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { pasta }
	local centro = presente.Position
	local vizinhos = workspace:GetPartBoundsInRadius(centro, ESPACO * 2.5, params)
	table.sort(vizinhos, function(a, b)
		return (a.Position - centro).Magnitude < (b.Position - centro).Magnitude
	end)
	for _, v in vizinhos do
		if #pegos >= quantidade then
			break
		end
		if v.Parent == pasta then
			table.insert(pegos, remover(v))
		end
	end
	return pegos
end

-- Usado pelos ajudantes: pega presentes perto de uma posição (ou qualquer um)
function Montanha.pegarParaAjudante(perto: Vector3?, quantidade: number): { string }
	local pegos = {}
	if not pasta or Montanha.restantes <= 0 then
		return pegos
	end
	local candidatos: { Instance } = {}
	if perto then
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { pasta }
		candidatos = workspace:GetPartBoundsInRadius(perto, 35, params)
	end
	if #candidatos < quantidade then
		candidatos = pasta:GetChildren()
	end
	-- Prefere os presentes de cima (a montanha vai "derretendo" de cima para baixo)
	table.sort(candidatos, function(a: any, b: any)
		return a.Position.Y > b.Position.Y
	end)
	for _, c in candidatos do
		if #pegos >= quantidade then
			break
		end
		if c.Parent == pasta then
			table.insert(pegos, remover(c :: BasePart))
		end
	end
	return pegos
end

return Montanha
