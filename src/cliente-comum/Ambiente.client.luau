-- ❄️ Efeitos de AMBIENTE de Natal. Rodam só no seu computador/celular (o servidor não anima nada):
--   • neve caindo em volta da câmera;
--   • pisca-pisca suave nas lâmpadas (ondas lentas, nada de piscar rápido);
--   • brilhos dourados na Árvore Gigante e nas estrelas;
--   • fumacinha saindo das chaminés;
--   • na Partida: as luzes do portão acendem forte quando alguém acha a chave.
-- O cenário marca as peças com "tags" (Config.TAGS_NATAL) e este script procura por elas.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Compartilhado"):WaitForChild("Config"))
local P = Config.PALETA
local TAGS = Config.TAGS_NATAL

-- Celular (tela de toque e sem teclado): menos partículas e menos animação
local celular = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local TEXTURA_FUMACA = "rbxasset://textures/particles/smoke_main.dds"
local TEXTURA_BRILHO = "rbxasset://textures/particles/sparkles_main.dds"

-- Chama "fn" para cada peça com a tag (as que já existem e as que aparecerem depois)
local function paraCada(tag: string, fn: (Instance) -> ())
	for _, obj in CollectionService:GetTagged(tag) do
		task.spawn(fn, obj)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
end

local function sequencia(a: number, b: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

------------------------------------------------------------------------
-- NEVE CAINDO: uma "nuvem" invisível que acompanha a câmera
------------------------------------------------------------------------
local nuvem = Instance.new("Part")
nuvem.Name = "NeveCaindo"
nuvem.Anchored = true
nuvem.CanCollide = false
nuvem.CanQuery = false
nuvem.CanTouch = false
nuvem.CastShadow = false
nuvem.Transparency = 1
nuvem.Size = Vector3.new(130, 1, 130)
nuvem.Parent = workspace

local neve = Instance.new("ParticleEmitter")
neve.Name = "Flocos"
neve.Texture = TEXTURA_FUMACA
neve.Rate = celular and 20 or 40
neve.Lifetime = NumberRange.new(9, 12)
neve.Speed = NumberRange.new(4, 6)
neve.EmissionDirection = Enum.NormalId.Bottom
neve.SpreadAngle = Vector2.new(12, 12)
neve.Acceleration = Vector3.new(0.8, -0.3, 0.5) -- um ventinho de leve
neve.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22, 0.08), NumberSequenceKeypoint.new(1, 0.18, 0.06) })
neve.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0.15), NumberSequenceKeypoint.new(0.85, 0.2), NumberSequenceKeypoint.new(1, 1) })
neve.Color = ColorSequence.new(Color3.new(1, 1, 1))
neve.LightEmission = 0.3
neve.Rotation = NumberRange.new(0, 360)
neve.RotSpeed = NumberRange.new(-40, 40)
neve.Parent = nuvem

RunService.RenderStepped:Connect(function()
	-- Pega a câmera na hora (o Roblox troca a câmera quando o personagem nasce)
	local camera = workspace.CurrentCamera
	if camera then
		nuvem.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 35, 0))
	end
end)

------------------------------------------------------------------------
-- PISCA-PISCA SUAVE: cada lâmpada "respira" devagar (2 a 4 s), em ondas
------------------------------------------------------------------------
paraCada(TAGS.lampada, function(obj)
	if not obj:IsA("BasePart") then
		return
	end
	local fase = obj:GetAttribute("Fase") or 0
	-- No celular, metade das lâmpadas fica acesa parada (menos trabalho)
	if celular and fase % 2 == 1 then
		return
	end
	local duracao = 2.2 + (fase % 3) * 0.6
	local info = TweenInfo.new(duracao, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, fase * 0.35)
	TweenService:Create(obj, info, {
		Transparency = 0.4,
		Color = obj.Color:Lerp(Color3.new(0, 0, 0), 0.2),
	}):Play()
end)

------------------------------------------------------------------------
-- BRILHOS DOURADOS (estrelas e Árvore Gigante)
------------------------------------------------------------------------
paraCada(TAGS.brilho, function(obj)
	if not obj:IsA("BasePart") then
		return
	end
	local suave = obj:GetAttribute("Suave") == true
	local e = Instance.new("ParticleEmitter")
	e.Name = "BrilhoDourado"
	e.Texture = TEXTURA_BRILHO
	e.Color = ColorSequence.new(P.dourado, P.luz)
	e.LightEmission = 1
	e.SpreadAngle = Vector2.new(180, 180)
	if suave then
		-- Faíscas bem discretas espalhadas pela copa
		e.Rate = celular and 2 or 4
		e.Lifetime = NumberRange.new(1.5, 2.5)
		e.Speed = NumberRange.new(0.2, 0.6)
		e.Size = sequencia(0.45, 0)
		e.Transparency = sequencia(0.2, 1)
	else
		-- Em volta da estrela
		e.Rate = celular and 3 or 6
		e.Lifetime = NumberRange.new(1, 1.8)
		e.Speed = NumberRange.new(1, 3)
		e.Size = sequencia(0.8, 0)
		e.Transparency = sequencia(0, 1)
	end
	e.Parent = obj
end)

------------------------------------------------------------------------
-- FUMAÇA NAS CHAMINÉS
------------------------------------------------------------------------
paraCada(TAGS.chamine, function(obj)
	if not obj:IsA("BasePart") then
		return
	end
	local e = Instance.new("ParticleEmitter")
	e.Name = "Fumaca"
	e.Texture = TEXTURA_FUMACA
	e.Rate = celular and 1.5 or 2.5
	e.Lifetime = NumberRange.new(5, 7)
	e.Speed = NumberRange.new(2.5, 4)
	e.EmissionDirection = Enum.NormalId.Top
	e.SpreadAngle = Vector2.new(12, 12)
	e.Acceleration = Vector3.new(1.2, 0.5, 0.4)
	e.Size = sequencia(1.2, 4.5)
	e.Transparency = sequencia(0.35, 1)
	e.Color = ColorSequence.new(Color3.fromRGB(222, 226, 236))
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-20, 20)
	e.LightEmission = 0.05
	e.Parent = obj
end)

------------------------------------------------------------------------
-- PORTÃO (Partida): quando alguém acha a chave, as luzes do portão pulsam forte
------------------------------------------------------------------------
local portaoAceso = false
local function acenderPortao()
	if portaoAceso then
		return
	end
	portaoAceso = true
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	for _, obj in CollectionService:GetTagged(TAGS.portao) do
		if obj:IsA("BasePart") then
			obj.Transparency = 0
			obj.Color = P.dourado:Lerp(Color3.new(1, 1, 1), 0.25)
			TweenService:Create(obj, info, { Transparency = 0.35, Color = P.dourado }):Play()
			local luz = obj:FindFirstChildOfClass("PointLight")
			if luz then
				luz.Color = P.dourado
				luz.Range = 20
				luz.Brightness = 2
				TweenService:Create(luz, info, { Brightness = 3.5 }):Play()
			end
		end
	end
end

local function conferirChave()
	if workspace:GetAttribute("DonoChave") then
		acenderPortao()
	end
end
workspace:GetAttributeChangedSignal("DonoChave"):Connect(conferirChave)
conferirChave()
