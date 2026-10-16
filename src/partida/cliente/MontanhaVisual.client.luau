-- 🎀 Deixa a MONTANHA DE PRESENTES bonita sem pesar o jogo.
-- O servidor cria só a caixa de cada presente (1 peça). Aqui, no seu computador/celular:
--   • os presentes da CAMADA DE FORA que estão PERTO da câmera ganham fita e laço;
--   • quando um presente some, os vizinhos que ficaram à mostra passam a poder ganhar fita;
--   • os presentes raros mais próximos (Diamante e Arco-íris) soltam um brilho leve.
-- Tudo é só visual: o clique continua acertando a caixa normalmente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Compartilhado"):WaitForChild("Config"))
local P = Config.PALETA

-- O servidor só cria a montanha quando o grupo chega
local montanha = workspace:WaitForChild("Montanha", math.huge) :: Folder

local celular = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
-- No máximo: fitas = 14% dos presentes, laços = 3% (no celular, menos)
local PARTE_FITAS = celular and 0.1 or 0.14
local PARTE_LACOS = celular and 0.02 or 0.03
local MAX_BRILHOS = celular and 3 or 6
local DISTANCIA_MAX = 95

local pastaVisual = Instance.new("Folder")
pastaVisual.Name = "MontanhaVisual"
pastaVisual.Parent = workspace

------------------------------------------------------------------------
-- Grade: os presentes ficam em camadas de 2,6 studs, deslocadas meio espaço
-- uma da outra. Com isso dá pra saber quem está "por fora" da montanha.
------------------------------------------------------------------------
type Info = { gx: number, gy: number, gz: number, exposto: boolean, topoLivre: boolean, raro: boolean }
local porChave: { [number]: BasePart } = {}
local infos: { [BasePart]: Info } = {}
local precisaRecalcular = true

local function chave(gx: number, gy: number, gz: number): number
	return (gy * 512 + (gx + 256)) * 512 + (gz + 256)
end

local function existe(gx: number, gy: number, gz: number): boolean
	return porChave[chave(gx, gy, gz)] ~= nil
end

local LADOS = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 } }
local DIAGONAIS = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }

local function calcular(info: Info)
	local exposto = false
	for _, d in LADOS do
		if not existe(info.gx + d[1], info.gy, info.gz + d[2]) then
			exposto = true
			break
		end
	end
	local cobertos = 0
	for _, d in DIAGONAIS do
		if existe(info.gx + d[1], info.gy + 1, info.gz + d[2]) then
			cobertos += 1
		end
	end
	info.exposto = exposto or cobertos < 4
	info.topoLivre = cobertos == 0
end

local function adicionar(obj: Instance)
	if not obj:IsA("BasePart") or infos[obj] then
		return
	end
	local p = obj.Position
	local info: Info = {
		gx = math.round(p.X / 1.3),
		gy = math.round((p.Y - 1.2) / 2.6),
		gz = math.round(p.Z / 1.3),
		exposto = true,
		topoLivre = true,
		raro = obj:GetAttribute("Raridade") == "Diamante" or obj:GetAttribute("Raridade") == "Arco-íris",
	}
	infos[obj] = info
	porChave[chave(info.gx, info.gy, info.gz)] = obj
	precisaRecalcular = true
end

------------------------------------------------------------------------
-- Fitas, laços e brilhos (reaproveitados: nada é criado e destruído toda hora)
------------------------------------------------------------------------
local fitaDe: { [BasePart]: BasePart } = {}
local lacoDe: { [BasePart]: { BasePart } } = {}
local brilhoDe: { [BasePart]: Attachment } = {}
local fitasLivres: { BasePart } = {}
local lacosLivres: { { BasePart } } = {}
local brilhosLivres: { Attachment } = {}

local function pecaVisual(): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function corDaFita(presente: BasePart): Color3
	return presente:GetAttribute("Raridade") == "Dourado" and P.vermelho or P.dourado
end

local function porFita(presente: BasePart)
	local fita = table.remove(fitasLivres) or pecaVisual()
	fita.Name = "Fita"
	local s = presente.Size
	fita.Size = Vector3.new(s.X + 0.08, s.Y + 0.08, s.Z * 0.22)
	fita.CFrame = presente.CFrame
	fita.Color = corDaFita(presente)
	fita.Reflectance = 0.1
	fita.Parent = pastaVisual
	fitaDe[presente] = fita
end

local function tirarFita(presente: BasePart)
	local fita = fitaDe[presente]
	if fita then
		fitaDe[presente] = nil
		fita.Parent = nil
		table.insert(fitasLivres, fita)
	end
end

local function porLaco(presente: BasePart)
	local par = table.remove(lacosLivres)
	if not par then
		par = {}
		for _ = 1, 2 do
			local orelha = pecaVisual()
			orelha.Name = "Orelha"
			local malha = Instance.new("SpecialMesh")
			malha.MeshType = Enum.MeshType.Sphere
			malha.Parent = orelha
			table.insert(par, orelha)
		end
	end
	local s = presente.Size
	for i, orelha in par do
		local lado = i == 1 and -1 or 1
		orelha.Size = Vector3.new(0.95, 0.45, 0.5)
		orelha.CFrame = presente.CFrame * CFrame.new(lado * 0.4, s.Y / 2 + 0.14, 0) * CFrame.Angles(0, 0, math.rad(-lado * 28))
		orelha.Color = corDaFita(presente)
		orelha.Parent = pastaVisual
	end
	lacoDe[presente] = par
end

local function tirarLaco(presente: BasePart)
	local par = lacoDe[presente]
	if par then
		lacoDe[presente] = nil
		for _, orelha in par do
			orelha.Parent = nil
		end
		table.insert(lacosLivres, par)
	end
end

local function porBrilho(presente: BasePart)
	local a = table.remove(brilhosLivres)
	if not a then
		a = Instance.new("Attachment")
		a.Name = "BrilhoRaro"
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Rate = 4
		e.Lifetime = NumberRange.new(0.7, 1.3)
		e.Speed = NumberRange.new(0.6, 1.6)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new(0.1)
		e.LightEmission = 1
		e.Parent = a
		a.Parent = workspace.Terrain
	end
	a.CFrame = CFrame.new(presente.Position + Vector3.yAxis * 0.6)
	local e = a:FindFirstChildOfClass("ParticleEmitter")
	if e then
		e.Color = ColorSequence.new(presente.Color:Lerp(Color3.new(1, 1, 1), 0.35))
		e.Enabled = true
	end
	brilhoDe[presente] = a
end

local function tirarBrilho(presente: BasePart)
	local a = brilhoDe[presente]
	if a then
		brilhoDe[presente] = nil
		local e = a:FindFirstChildOfClass("ParticleEmitter")
		if e then
			e.Enabled = false
		end
		table.insert(brilhosLivres, a)
	end
end

------------------------------------------------------------------------
-- Quando um presente é pego, os vizinhos ficam à mostra
------------------------------------------------------------------------
local function remover(obj: Instance)
	local presente = obj :: BasePart
	local info = infos[presente]
	tirarFita(presente)
	tirarLaco(presente)
	tirarBrilho(presente)
	if not info then
		return
	end
	infos[presente] = nil
	porChave[chave(info.gx, info.gy, info.gz)] = nil
	-- Vizinhos do lado e de baixo agora aparecem
	for _, d in LADOS do
		local v = porChave[chave(info.gx + d[1], info.gy, info.gz + d[2])]
		if v and infos[v] then
			infos[v].exposto = true
		end
	end
	for _, d in DIAGONAIS do
		local v = porChave[chave(info.gx + d[1], info.gy - 1, info.gz + d[2])]
		if v and infos[v] then
			calcular(infos[v])
		end
	end
end

for _, filho in montanha:GetChildren() do
	adicionar(filho)
end
montanha.ChildAdded:Connect(adicionar)
montanha.ChildRemoved:Connect(remover)

------------------------------------------------------------------------
-- A cada pouquinho: escolhe quem ganha fita/laço/brilho (os mais perto da câmera)
------------------------------------------------------------------------
type Candidato = { presente: BasePart, d: number }

local function atualizar()
	if precisaRecalcular then
		precisaRecalcular = false
		for _, info in infos do
			calcular(info)
		end
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local olho = camera.CFrame.Position
	local total = workspace:GetAttribute("PresentesTotal") or 0
	if total <= 0 then
		return
	end
	local maxFitas = math.floor(total * PARTE_FITAS)
	local maxLacos = math.floor(total * PARTE_LACOS)

	local candidatos: { Candidato } = {}
	local raros: { Candidato } = {}
	for presente, info in infos do
		if info.exposto then
			local d = (presente.Position - olho).Magnitude
			if d < DISTANCIA_MAX then
				table.insert(candidatos, { presente = presente, d = d })
				if info.raro then
					table.insert(raros, { presente = presente, d = d })
				end
			end
		end
	end
	table.sort(candidatos, function(a, b)
		return a.d < b.d
	end)
	table.sort(raros, function(a, b)
		return a.d < b.d
	end)

	local querFita: { [BasePart]: boolean } = {}
	local querLaco: { [BasePart]: boolean } = {}
	local lacos = 0
	for i = 1, math.min(#candidatos, maxFitas) do
		local presente = candidatos[i].presente
		querFita[presente] = true
		if lacos < maxLacos and infos[presente].topoLivre then
			querLaco[presente] = true
			lacos += 1
		end
	end
	local querBrilho: { [BasePart]: boolean } = {}
	for i = 1, math.min(#raros, MAX_BRILHOS) do
		querBrilho[raros[i].presente] = true
	end

	-- Tira de quem não precisa mais e põe em quem precisa
	for presente in fitaDe do
		if not querFita[presente] then
			tirarFita(presente)
		end
	end
	for presente in lacoDe do
		if not querLaco[presente] then
			tirarLaco(presente)
		end
	end
	for presente in brilhoDe do
		if not querBrilho[presente] then
			tirarBrilho(presente)
		end
	end
	for presente in querFita do
		if not fitaDe[presente] then
			porFita(presente)
		end
	end
	for presente in querLaco do
		if not lacoDe[presente] then
			porLaco(presente)
		end
	end
	for presente in querBrilho do
		if not brilhoDe[presente] then
			porBrilho(presente)
		end
	end
end

while true do
	atualizar()
	task.wait(0.4)
end
