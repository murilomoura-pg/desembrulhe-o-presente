# 🎁 Desembrulhe o Presente

Jogo de Roblox: uma montanha gigante de presentes e **uma única chave** escondida dentro de um deles.
Desembrulhe, compre melhorias, ache a chave, abra o portão e fuja o mais rápido que conseguir!

## Como o jogo funciona

| Parte | O que acontece |
|---|---|
| **Lobby** | Vila de Natal com 4 salas (chalés): **Solo, Dupla, Trio e Quarteto**. Quando a sala enche, o grupo vai para uma partida só dele. Tem os placares de fuga mais rápida, o placar de Renascimentos e a Máquina de Ajudantes. |
| **Partida** | Pátio da Oficina do Papai Noel (layout parecido com o Peel THE Potato). Clique/toque nos presentes da montanha para pegar, leve até a **sua Bancada** na Oficina dos Elfos, aperte **E** para colocar os presentes nela e segure **DESEMBRULHAR** (ou F, ou arraste o mouse/dedo por cima dos presentes). Moedas compram melhorias na **Loja** (Máquina de Presentes ou caixotes). A chave aparece quando a montanha está quase no fim e abre o **cofre** no fundo da oficina. |
| **Ajudantes** | Pets que desembrulham sozinhos. Custam 40 ⭐ na máquina do lobby. Até 3 equipados. |
| **Renascimento** | Cada fuga dá +1 Renascimento = +50% de moedas para sempre. |

## Estrutura dos arquivos

```
src/
  compartilhado/     → código usado no servidor e no cliente (Config, Util, Interface)
  servidor-comum/    → salvar dados, ranking e o kit de decoração de Natal (Natal.luau)
  cliente-comum/     → ajudantes seguindo os jogadores + efeitos de ambiente (neve, pisca-pisca...)
  lobby/servidor     → mapa do lobby, salas, teleporte, placares, máquina + DecoracaoLobby
  lobby/cliente      → interface do lobby
  partida/servidor   → montanha, mapa, regras da partida, chave, fuga + DecoracaoPartida
  partida/cliente    → interface da partida (loja, botão, tempo...) + laços da montanha
lobby.project.json   → monta o lugar "Lobby"
partida.project.json → monta o lugar "Partida"
```

👉 **Quer mudar preços, tamanho da montanha, chances dos pets?** Tudo fica em `src/compartilhado/Config.luau`.

## Gerar os arquivos do Roblox Studio

Usamos o [Rojo](https://rojo.space), que transforma estas pastas em arquivos que o Studio abre:

```bash
rojo build lobby.project.json -o build/Lobby.rbxl
rojo build partida.project.json -o build/Partida.rbxl
```

## Publicar (passo a passo)

1. Abra **Lobby.rbxl** no Roblox Studio → **Arquivo › Publicar no Roblox** → crie um jogo novo chamado *Desembrulhe o Presente*.
2. No Studio, abra **Visualizar › Gerenciador de Ativos** → **Places** → botão direito → **Adicionar novo lugar**.
3. Abra **Partida.rbxl** → **Arquivo › Publicar no Roblox como...** → escolha o mesmo jogo → escolha o lugar novo.
4. Pegue os dois IDs (o número que aparece no link de cada lugar) e coloque em `Config.luau`:
   `LOBBY_PLACE_ID` e `PARTIDA_PLACE_ID`. Gere os arquivos de novo e publique os dois.
5. Nas **Configurações do jogo**:
   - **Segurança** → ligue *Enable Studio Access to API Services* (para salvar progresso).
   - No lugar **Partida**, coloque o **máximo de jogadores = 4**.

## Testar no Studio

- **Partida**: aperte *Play*. Ela começa no modo Solo automaticamente.
- **Lobby**: dá pra andar, girar ajudantes e entrar nas salas. O **teleporte** só funciona no jogo publicado.

## 🎄 Visual de Natal

O jogo tem cara de **vila de Natal**. Isso é **só aparência**: as regras, os preços e os dados salvos são os mesmos de antes.

| Onde | O que tem |
|---|---|
| **Lobby** | Chão de neve de verdade (Terrain) com caminhos de neve batida e montanhas em volta. Cada sala é um **chalé de madeira** com telhado nevado, guirlandas, pisca-pisca e bandeirinhas na cor da sala. No centro da praça fica a **Árvore Gigante**, com estrela 3D lapidada e grupinhos de presentes no pé. A máquina fica na porta da **Fábrica de Ajudantes**, que tem chaminé com fumaça. Os placares ganharam moldura de madeira com neve, e uma floresta de pinheiros em grupos (maiores perto das montanhas) cerca tudo. |
| **Partida** | Pátio com neve e cercas de tela, montanha numa plataforma com anel dourado e setas no chão. Atrás do spawn fica a **Oficina dos Elfos** (galpão aberto) com as 4 bancadas, a Máquina de Presentes (loja) e o **cofre redondo** (portão de fuga), cujas luzes pulsam quando alguém acha a chave. Caixotes com as melhorias ficam perto do spawn e uma estrela dourada brilha sobre a montanha. |
| **Efeitos** | Neve caindo, pisca-pisca suave, brilhos dourados e fumaça. Tudo roda **no cliente** (fica leve para o servidor) e é mais econômico no celular. |
| **Interface** | Painéis vermelhos com borda dourada e sombra, botões com animação e altura mínima de 44 px (bom para o dedo). |

Arquivos do visual:
- `Config.luau` → `Config.PALETA` (as cores de Natal) e `Config.TAGS_NATAL`.
- `servidor-comum/Natal.luau` → o "kit" de enfeites: `pinheiro`, `arvoreGigante`, `chale`, `telhado`, `guirlanda`, `cordaoDeLuzes`, `bonecoDeNeve`, `poste`, `placaDeMadeira`, `moldura` e outros, além da iluminação e do terreno.
- `lobby/servidor/DecoracaoLobby.luau` e `partida/servidor/DecoracaoPartida.luau` → onde cada enfeite fica.
- `cliente-comum/Ambiente.client.luau` → neve caindo, pisca-pisca, brilhos, fumaça e luzes do portão.
- `partida/cliente/MontanhaVisual.client.luau` → laços da montanha. O servidor cria só a caixa de cada presente (1 peça). O cliente põe fita e laço nos presentes **de fora** e **perto da câmera**, com limite de no máximo +20% de peças.

👉 **Quer mudar uma cor de Natal?** Mude em `Config.PALETA`. Para tirar ou mover um enfeite, procure o nome dele em `DecoracaoLobby.luau` ou `DecoracaoPartida.luau`.

**Iluminação:** a tecnologia de luz **Future** já vem configurada nos arquivos `.project.json` (não dá para trocar por script). Se o Studio perguntar sobre a migração de iluminação, pode aceitar.

### 🌲 Pinheiros

Todos os pinheiros (a Árvore Gigante, os da rua, os dos bosques, a floresta e os da Partida) saem do **mesmo gerador** em `Natal.luau`. A copa é feita de **andares de galhos**: cada andar é uma "saia" de cunhas em volta do tronco, com a ponta para fora e um pouco caída. Os andares ficam menores para cima e girados entre si, então a borda fica serrilhada como a de um pinheiro de verdade. A neve fica em cima das pontas de alguns galhos (sorteados), e cada árvore tem o próprio sorteio: sai sempre igual em todo servidor.

`Natal.pinheiro(pasta, posição, escala, opções)`: escala 1 = uns 22 de altura. Opções principais:

| Opção | O que faz |
|---|---|
| `estilo = "tradicional"` | bolas vermelhas e douradas, pisca-pisca colorido |
| `estilo = "nevado"` | mais neve, bolas brancas e prata, luzes branco-quentes |
| `estilo = "dourado"` | bolas douradas e brancas, luzes quentes |
| `estilo = "natural"` | só neve (floresta) |
| `estrela = true` | estrela 3D no topo (`frente` diz para onde ela olha) |
| `montinho = true`, `presentes = 1 ou 2` | neve e presentes no pé da árvore |
| `distante = 0 a 1` | verde mais escuro e azulado (árvores perto das montanhas) |

As opções antigas (`luzes`, `bolas`, `lacos`, `estrela`, `neve`) continuam funcionando. Peças por árvore: floresta até ~18, decoradas ~60, Árvore Gigante ~350. A folhagem não tem colisão e tem `CanQuery` desligado (a câmera passa por ela sem pular); só o tronco é sólido.

## ✂️ Bancadas de desembrulhar

Cada jogador da partida recebe **uma bancada** (são 4, uma por jogador; no Solo as outras ficam "Livre").

1. Pegue presentes na montanha (o saco aparece embaixo à esquerda, ex.: `🎒 7/10`).
2. Vá até a **sua bancada** (a placa mostra seu nome e a sua cor) e aperte **E** (ou toque no botão): tudo o que está no saco vai para cima da bancada.
3. Segure **✂️ DESEMBRULHAR** (ou a tecla **F**, ou segure o mouse/dedo passando por cima dos presentes da bancada). Cada presente aberto vira moedas, na velocidade da melhoria **Tesoura**.

Só o dono usa a própria bancada (o servidor confere o dono e a distância). Se alguém sai da partida, a bancada volta a ficar "Livre". Arquivos: `partida/servidor/Bancadas.luau` (bancadas e donos), `Partida.server.luau` (regras) e `partida/cliente/BancadasVisual.client.luau` (pilha de presentes e papel picado).

## 🕺 Animações dos personagens

Isso é **só aparência**: as regras, a velocidade de coleta e o servidor continuam iguais. Os movimentos são feitos **por código** (não precisam ser publicados no Roblox) e funcionam em **R15 e R6**. Cada jogador vê também os outros se mexendo, porque as animações usam os atributos que o servidor já manda para todo mundo (`Saco`, `Estoque` da bancada, `TemChave`, `Sala`).

| Onde | O que acontece |
|---|---|
| **Partida** | Ao pegar um presente, o personagem vira para ele e estica os braços (segurando o clique, o movimento continua suave, sem recomeçar). Uma **cópia** do presente pula, gira, encolhe e voa até o personagem, e o contador 🎒 dá um pulinho. Na bancada: gesto de **colocar** (E) e braços **desembrulhando** enquanto segura. Achou a chave ou fugiu: **comemora**. |
| **Lobby** | Entrou numa sala: **aceno**. Parado, o seu personagem **gira devagar** para o centro da sala e fica numa **pose de espera** discreta, que para na hora em que você anda. Quando o jogo tira alguém da sala (cheia, botão SAIR ou teleporte), aparece um **puff de neve** onde ele estava e onde chegou. |

Arquivos:
- `cliente-comum/Animacoes.luau` → todos os movimentos (pegar, desembrulhar, espera, colocar, aceno, chegada, comemorar), a cópia do presente voando e o puff de neve.
- `partida/cliente/AnimacoesPartida.client.luau` e `lobby/cliente/AnimacoesLobby.client.luau` → ligam os movimentos ao que acontece no jogo.
- `partida/cliente/HudPartida.client.luau` → poucas linhas marcadas com "Só visual" (gesto e cópia no clique, pulinho do 🎒, braços ao desembrulhar).
- `Config.luau` → `Config.ANIMACOES` (durações e IDs opcionais).

👉 **Quer usar uma animação feita no Animation Editor?** Publique-a na conta dona do jogo (Animation Editor → **...** → **Publicar no Roblox**), copie o ID e cole em `Config.ANIMACOES.IDS` (ex.: `PEGAR = "rbxassetid://123..."`). Com o ID vazio (`""`), o jogo usa o movimento feito por código.
