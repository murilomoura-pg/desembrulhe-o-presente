# 🎁 Desembrulhe o Presente

Jogo de Roblox: uma montanha gigante de presentes e **uma única chave** escondida dentro de um deles.
Desembrulhe, compre melhorias, ache a chave, abra o portão e fuja o mais rápido que conseguir!

## Como o jogo funciona

| Parte | O que acontece |
|---|---|
| **Lobby** | Praça de neve com 4 salas: **Solo, Dupla, Trio e Quarteto**. Quando a sala enche, o grupo vai para uma partida só dele. Tem os placares de fuga mais rápida, o placar de Renascimentos e a Máquina de Ajudantes. |
| **Partida** | Pátio da Fábrica do Papai Noel. Clique/toque nos presentes para pegar, leve até a **Mesa de Desembrulhar** e segure o botão. Moedas compram melhorias na **Loja**. A chave aparece quando a montanha está quase no fim. |
| **Ajudantes** | Pets que desembrulham sozinhos. Custam 40 ⭐ na máquina do lobby. Até 3 equipados. |
| **Renascimento** | Cada fuga dá +1 Renascimento = +50% de moedas para sempre. |

## Estrutura dos arquivos

```
src/
  compartilhado/     → código usado no servidor e no cliente (Config, Util, Interface)
  servidor-comum/    → salvar dados e ranking (usado no Lobby e na Partida)
  cliente-comum/     → ajudantes seguindo os jogadores
  lobby/servidor     → mapa do lobby, salas, teleporte, placares, máquina
  lobby/cliente      → interface do lobby
  partida/servidor   → montanha, mapa, regras da partida, chave, fuga
  partida/cliente    → interface da partida (loja, botão, tempo...)
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
