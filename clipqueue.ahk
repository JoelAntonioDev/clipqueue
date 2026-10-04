#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsBuffer True
Persistent

; ================== CONFIGURAÇÃO ==================
HOLD_KEYS     := ["LControl", "RControl"]  ; segurar Ctrl (esq. ou dir.) sozinho abre o menu
HOLD_SECONDS  := 1        ; segundos a segurar
MAX_ITEMS     := 50       ; tamanho máximo da fila
PASTE_ORDER   := "fifo"   ; "fifo" = cola o mais antigo primeiro | "lifo" = o mais recente
MENU_OPACITY  := 225      ; 0 (invisível) a 255 (opaco)
EXCLUDED_APPS := []       ; ex.: ["explorer.exe"] -> Ctrl+V normal nestas apps

; ================== ESTADO ==================
global Queue := []           ; textos na fila
global Selected := 0         ; índice escolhido no menu (0 = automático)
global Removed := []         ; pilha de undo: {text, idx}
global SuppressUntil := 0    ; ignora alterações feitas pelo próprio script
global Paused := false
global PrevWin := 0
global MenuGui := 0, MenuList := 0

BuildMenu()
SetupTray()
OnClipboardChange(ClipChanged)

; Segurar Ctrl: "~" deixa o Ctrl passar normalmente (nada é bloqueado nem re-enviado)
InstallMouseHook()   ; para detectar Ctrl+clique e não abrir o menu nesse caso
for k in HOLD_KEYS
    Hotkey "~" k, HoldHandler, "B0"   ; B0: ignora o auto-repeat do Ctrl

; Teclas numéricas dentro do menu
HotIf MenuActive
Loop 9 {
    Hotkey "" A_Index, PickNumber
    Hotkey "Numpad" A_Index, PickNumber
}
HotIf

Notify("ClipQueue activo")

; ================== CAPTURA (Ctrl+C) ==================
ClipChanged(type) {
    global
    if (Paused || type != 1 || A_TickCount < SuppressUntil)
        return
    txt := A_Clipboard
    if (txt = "")
        return
    if (Queue.Length && Queue[Queue.Length] == txt)
        return
    Queue.Push(txt)
    while (Queue.Length > MAX_ITEMS) {
        Queue.RemoveAt(1)
        if (Selected = 1)
            Selected := 0
        else if (Selected > 1)
            Selected--
    }
    Notify("Copiado  (" Queue.Length " na fila)")
    if MenuActive()
        RefreshMenu()
}

; ================== COLAR (Ctrl+V) ==================
#HotIf PasteActive()
$^v:: {
    global
    idx := CurrentIndex()
    txt := Queue[idx]
    SetClip(txt)
    Send "^v"
    Sleep 150                      ; dá tempo à app para ler o clipboard
    RemoveItem(idx)
    Selected := 0
    Notify("Colado  (" Queue.Length " restantes)")
}
#HotIf

PasteActive(*) {
    global
    if (Paused || Queue.Length = 0 || MenuActive())
        return false
    if !DllCall("IsClipboardFormatAvailable", "UInt", 13)   ; clipboard tem imagem/ficheiros
        return false
    try {
        exe := WinGetProcessName("A")
        for app in EXCLUDED_APPS
            if (StrLower(app) = StrLower(exe))
                return false
    }
    return true
}

; ================== ATALHOS GLOBAIS ==================
^!v:: ShowMenu()            ; Ctrl+Alt+V  abre o menu sem esperar
^!z:: UndoRemove()          ; Ctrl+Alt+Z  repõe o último removido
^!x:: ClearQueue()          ; Ctrl+Alt+X  limpa a fila (reversível com undo)
^!p:: TogglePause()         ; Ctrl+Alt+P  pausa/retoma a captura

; ================== SEGURAR TECLA ==================
HoldHandler(hk) {
    global
    key := SubStr(hk, 2)                      ; "~LControl" -> "LControl"
    if KeyWait(key, "T" HOLD_SECONDS)         ; soltou antes do tempo
        return
    if (A_PriorKey != key)                    ; usaste Ctrl+C, Ctrl+clique, etc. -> não abre
        return
    ShowMenu()
    KeyWait key
}

; ================== MENU ==================
BuildMenu() {
    global
    MenuGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "ClipQueue")
    MenuGui.BackColor := "1E1E1E"
    MenuGui.MarginX := 10, MenuGui.MarginY := 8
    MenuGui.SetFont("s9 c9A9A9A", "Segoe UI")
    MenuGui.AddText("w560", "ClipQueue  ·  ↑↓ ou 1-9 escolher  ·  Enter confirmar  ·  Del remover  ·  Esc fechar")
    MenuGui.SetFont("s10 cE6E6E6", "Consolas")
    MenuList := MenuGui.AddListBox("w560 r12 Background2D2D2D cE6E6E6")
    MenuList.OnEvent("DoubleClick", (*) => ConfirmChoice())
    MenuGui.OnEvent("Escape", (*) => HideMenu())
}

ShowMenu() {
    global
    if !MenuActive()
        PrevWin := WinExist("A")
    RefreshMenu()
    MenuGui.Show("Hide AutoSize")
    MenuGui.GetPos(, , &w, &h)
    MonitorGetWorkArea(MonitorGetPrimary(), &L, &T, &R, &B)
    MenuGui.Show("x" (R - w - 16) " y" (T + 16))
    WinSetTransparent(MENU_OPACITY, MenuGui.Hwnd)
    MenuList.Focus()
    SetTimer(AutoHide, 250)
}

HideMenu() {
    global
    SetTimer(AutoHide, 0)
    MenuGui.Hide()
    if (PrevWin && WinExist(PrevWin))
        WinActivate(PrevWin)
}

AutoHide() {   ; fecha se clicares fora
    global
    if !MenuActive() {
        SetTimer(AutoHide, 0)
        MenuGui.Hide()
    }
}

MenuActive(*) {
    global
    return MenuGui && WinActive("ahk_id " MenuGui.Hwnd)
}

RefreshMenu() {
    global
    MenuList.Delete()
    if !Queue.Length {
        MenuList.Add(["   (fila vazia)"])
        return
    }
    cur := CurrentIndex()
    items := []
    for i, t in Queue {
        mark := (i = cur) ? "▶ " : "  "
        num := (i <= 9) ? i "." : "  "
        items.Push(mark Format("{:-3}", num) " " Preview(t))
    }
    MenuList.Add(items)
    MenuList.Choose(cur)
}

ConfirmChoice() {
    global
    i := MenuList.Value
    if (i >= 1 && i <= Queue.Length) {
        Selected := i
        SetClip(Queue[i])   ; também fica no clipboard (útil para colar com botão direito)
        HideMenu()
        Notify("Próximo Ctrl+V:  " Preview(Queue[i]))
    } else {
        HideMenu()
    }
}

PickNumber(hk) {
    global
    n := Integer(SubStr(hk, -1))
    if (n <= Queue.Length) {
        MenuList.Choose(n)
        ConfirmChoice()
    }
}

#HotIf MenuActive()
Enter:: ConfirmChoice()
NumpadEnter:: ConfirmChoice()
Delete:: {
    global
    i := MenuList.Value
    if (i >= 1 && i <= Queue.Length) {
        RemoveItem(i)
        RefreshMenu()
        if Queue.Length
            MenuList.Choose(Min(i, Queue.Length))
    }
}
#HotIf

; ================== FILA ==================
CurrentIndex() {
    global
    if !Queue.Length
        return 0
    if (Selected >= 1 && Selected <= Queue.Length)
        return Selected
    return (PASTE_ORDER = "lifo") ? Queue.Length : 1
}

RemoveItem(idx) {
    global
    if (idx < 1 || idx > Queue.Length)
        return
    Removed.Push({text: Queue[idx], idx: idx})
    if (Removed.Length > 100)
        Removed.RemoveAt(1)
    Queue.RemoveAt(idx)
    if (Selected = idx)
        Selected := 0
    else if (Selected > idx)
        Selected--
}

UndoRemove() {
    global
    if !Removed.Length {
        Notify("Nada para repor")
        return
    }
    r := Removed.Pop()
    pos := Min(r.idx, Queue.Length + 1)
    Queue.InsertAt(pos, r.text)
    if (Selected >= pos)
        Selected++
    Notify("Reposto na posição " pos "  (" Queue.Length " na fila)")
    if MenuActive()
        RefreshMenu()
}

ClearQueue() {
    global
    i := Queue.Length
    while (i >= 1) {
        RemoveItem(i)
        i--
    }
    Selected := 0
    Notify("Fila limpa (Ctrl+Alt+Z repõe)")
    if MenuActive()
        RefreshMenu()
}

TogglePause() {
    global
    Paused := !Paused
    Notify(Paused ? "Captura PAUSADA" : "Captura RETOMADA")
}

; ================== UTILITÁRIOS ==================
SetClip(txt) {
    global
    SuppressUntil := A_TickCount + 600
    A_Clipboard := ""
    A_Clipboard := txt
    ClipWait 1
}

Preview(t) {
    lines := StrSplit(Trim(t, " `t`r`n"), "`n", "`r")
    p := RegExReplace(lines[1], "\s+", " ")
    if (StrLen(p) > 60)
        p := SubStr(p, 1, 57) "..."
    if (lines.Length > 1)
        p .= "   [+" (lines.Length - 1) " linhas]"
    return p
}

Notify(msg) {
    ToolTip msg
    SetTimer(() => ToolTip(), -1500)
}

SetupTray() {
    A_IconTip := "ClipQueue"
    tray := A_TrayMenu
    tray.Delete()
    tray.Add("Abrir menu  (Ctrl+Alt+V)", (*) => ShowMenu())
    tray.Add("Pausar/Retomar  (Ctrl+Alt+P)", (*) => TogglePause())
    tray.Add("Limpar fila  (Ctrl+Alt+X)", (*) => ClearQueue())
    tray.Add()
    tray.Add("Recarregar", (*) => Reload())
    tray.Add("Sair", (*) => ExitApp())
}
