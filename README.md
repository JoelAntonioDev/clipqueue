# ClipQueue

Fila de clipboard para **Windows 10/11**. Copia vários textos seguidos com `Ctrl+C`, e cada `Ctrl+V` cola o próximo da fila e remove-o. Um menu transparente permite escolher qual será o próximo a colar.

Ideal para copiar vários comandos (de um chat, documentação, etc.) e colá-los um a um no terminal de um servidor ou no editor.

## Funcionalidades

- **Acumula** todos os textos copiados com `Ctrl+C` (imagens e ficheiros são ignorados).
- **Cola em ordem**: por defeito, o mais antigo primeiro (FIFO). Configurável para o mais recente primeiro (LIFO).
- **Remove da fila** cada item colado com `Ctrl+V`.
- **Menu flutuante e transparente** no canto superior direito, para escolher o próximo item.
- **Undo**: repõe itens removidos na posição original.
- Não interfere com o `Ctrl+V` normal quando a fila está vazia ou quando o clipboard tem imagens ou ficheiros.

## Requisitos

- Windows 10 ou 11
- [AutoHotkey v2](https://www.autohotkey.com/)

## Instalação

1. Instala o AutoHotkey v2, por uma destas vias:
   - PowerShell: `winget install AutoHotkey.AutoHotkey`
   - Download em https://www.autohotkey.com/
2. Descarrega o `clipqueue.ahk`, por uma destas vias:
   - Clonar o repositório: `git clone https://github.com/JoelAntonioDev/clipqueue.git`
   - Ou abrir o ficheiro `clipqueue.ahk` neste repositório → **Download raw file**.
3. Guarda-o numa pasta fixa, por exemplo `C:\Tools\clipqueue\`.
4. Faz **duplo clique** no `clipqueue.ahk`. Aparece um ícone **H** na bandeja do sistema e o aviso "ClipQueue activo".

### Arrancar automaticamente com o Windows

1. Prime `Win + R`, escreve `shell:startup` e carrega em Enter.
2. Nessa pasta, cria um atalho para o `clipqueue.ahk` (botão direito → *Novo* → *Atalho*).

## Como usar

1. Copia vários textos com `Ctrl+C`. Cada cópia mostra um aviso, por exemplo "Copiado (3 na fila)".
2. Vai ao terminal ou editor e carrega em `Ctrl+V`. É colado o primeiro item, que sai da fila.
3. Volta a carregar em `Ctrl+V` para colar o seguinte, e assim por diante.
4. Para colar um item fora de ordem, **segura `Ctrl` sozinho durante 1 segundo**. O menu abre; escolhe o item; o próximo `Ctrl+V` cola esse item.

## Atalhos

| Atalho | Acção |
|---|---|
| `Ctrl+C` | Copia e adiciona à fila |
| `Ctrl+V` | Cola o item actual e remove-o da fila |
| Segurar `Ctrl` sozinho 1 s | Abre o menu |
| `Ctrl+Alt+V` | Abre o menu imediatamente |
| `Ctrl+Alt+Z` | Undo: repõe o último item removido (pode repetir-se) |
| `Ctrl+Alt+X` | Limpa a fila (reversível com `Ctrl+Alt+Z`) |
| `Ctrl+Alt+P` | Pausa ou retoma a captura |

**Dentro do menu**

| Tecla | Acção |
|---|---|
| `↑` `↓` + `Enter` | Escolher item |
| `1`–`9` | Escolher directamente pelo número |
| Duplo clique | Escolher item |
| `Delete` | Remover o item seleccionado |
| `Esc` ou clicar fora | Fechar |

O ícone na bandeja tem também: abrir menu, pausar, limpar, **Recarregar** e **Sair**.

## Configuração

Edita o topo do `clipqueue.ahk` e depois usa **Recarregar** no ícone da bandeja:

```ahk
HOLD_KEYS     := ["LControl", "RControl"]  ; tecla(s) a segurar para abrir o menu
HOLD_SECONDS  := 1        ; segundos a segurar
MAX_ITEMS     := 50       ; tamanho máximo da fila
PASTE_ORDER   := "fifo"   ; "fifo" = mais antigo primeiro | "lifo" = mais recente primeiro
MENU_OPACITY  := 225      ; 0 (invisível) a 255 (opaco)
EXCLUDED_APPS := []       ; ex.: ["explorer.exe"] -> Ctrl+V normal nestas apps
```

## Notas e limitações

- **Ctrl segurado**: o menu só abre se nenhuma outra tecla ou clique acontecer enquanto o Ctrl está premido. Por isso, `Ctrl+C`, `Ctrl+clique` ou `Ctrl+Alt+…` não o abrem. O Ctrl nunca é bloqueado nem re-enviado pelo script, logo não fica "preso".
- **Apps como Administrador**: se o terminal correr como Administrador, o ClipQueue também tem de correr como Administrador (botão direito → *Executar como administrador*). Caso contrário, o Windows bloqueia o `Ctrl+V`.
- **Colar com o botão direito** (PuTTY, alguns terminais): ao escolher um item no menu, ele também fica no clipboard e o botão direito cola-o. Só o `Ctrl+V` é que o remove da fila.
- **`Ctrl+Shift+V`** não é interceptado.
- A fila vive em memória: é perdida ao fechar ou recarregar o script.

## Licença

[MIT](LICENSE)
