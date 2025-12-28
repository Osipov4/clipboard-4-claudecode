#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; 剪贴板图片守护进程
; 功能：检测剪贴板中的图片，保存到指定目录，并将路径复制到剪贴板
; ============================================================

; 配置
global ImageSavePath := "F:\workspace\image"
global IsProcessing := false
global LastSaveTime := 0

; 确保保存目录存在
if !DirExist(ImageSavePath)
    DirCreate(ImageSavePath)

; 加载 GDI+
global pToken := 0
hGdiPlus := DllCall("LoadLibrary", "Str", "gdiplus.dll", "Ptr")
si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
NumPut("UInt", 1, si, 0)
DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken, "Ptr", si, "Ptr", 0)

; 注册剪贴板变化监听
OnClipboardChange(ClipboardChanged)

; 退出时清理
OnExit(ExitFunc)

; 托盘菜单
A_TrayMenu.Delete()
A_TrayMenu.Add("打开图片目录", (*) => Run(ImageSavePath))
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())
A_IconTip := "剪贴板图片守护进程"

; 启动提示
TrayTip("剪贴板图片守护进程", "已启动，监控剪贴板中的图片...")

ExitFunc(*) {
    global pToken
    if pToken
        DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
}

; 主函数：处理剪贴板变化
ClipboardChanged(DataType) {
    global IsProcessing, LastSaveTime

    ; 避免重入和频繁触发
    if IsProcessing
        return

    currentTime := A_TickCount
    if (currentTime - LastSaveTime < 500)
        return

    ; DataType: 0=空, 1=文本/文件, 2=其他格式(如图片)
    if (DataType != 2)
        return

    ; 检查是否有位图格式
    CF_BITMAP := 2
    CF_DIB := 8
    if !DllCall("IsClipboardFormatAvailable", "UInt", CF_BITMAP)
        && !DllCall("IsClipboardFormatAvailable", "UInt", CF_DIB)
        return

    IsProcessing := true

    try {
        ; 生成文件名（使用时间戳+毫秒）
        timestamp := FormatTime(, "yyyyMMdd_HHmmss")
        ms := Mod(A_TickCount, 1000)
        fileName := "clip_" . timestamp . "_" . ms . ".jpg"
        filePath := ImageSavePath . "\" . fileName

        ; 保存图片
        if SaveBitmapFromClipboard(filePath) {
            LastSaveTime := A_TickCount
            ; 延迟设置剪贴板路径
            SetTimer(SetClipPath.Bind(filePath), -150)
            TrayTip("图片已保存", fileName)
        }
    }

    IsProcessing := false
}

; 设置剪贴板路径
SetClipPath(filePath) {
    ; 临时移除监听
    OnClipboardChange(ClipboardChanged, 0)

    ; 清空并设置文本
    A_Clipboard := ""
    Sleep(50)
    A_Clipboard := filePath

    ; 等待剪贴板准备好
    if !ClipWait(2, 0) {
        TrayTip("错误", "设置剪贴板失败")
    }

    ; 延迟恢复监听
    SetTimer(EnableClipboardMonitor, -300)
}

EnableClipboardMonitor() {
    OnClipboardChange(ClipboardChanged)
}

; 从剪贴板保存位图为 PNG
SaveBitmapFromClipboard(filePath) {
    global pToken

    if !pToken
        return false

    ; 打开剪贴板
    if !DllCall("OpenClipboard", "Ptr", A_ScriptHwnd)
        return false

    pBitmap := 0
    result := false

    try {
        ; 优先使用 CF_BITMAP
        CF_BITMAP := 2
        hBitmap := DllCall("GetClipboardData", "UInt", CF_BITMAP, "Ptr")

        if hBitmap {
            ; 从 HBITMAP 创建 GDI+ Bitmap
            status := DllCall("gdiplus\GdipCreateBitmapFromHBITMAP"
                , "Ptr", hBitmap
                , "Ptr", 0
                , "Ptr*", &pBitmap)

            if (status = 0 && pBitmap) {
                ; 获取 JPEG 编码器 CLSID
                ; JPEG CLSID: {557CF401-1A04-11D3-9A73-0000F81EF32E}
                CLSID := Buffer(16)
                NumPut("UInt", 0x557CF401, CLSID, 0)
                NumPut("UShort", 0x1A04, CLSID, 4)
                NumPut("UShort", 0x11D3, CLSID, 6)
                NumPut("UChar", 0x9A, CLSID, 8)
                NumPut("UChar", 0x73, CLSID, 9)
                NumPut("UChar", 0x00, CLSID, 10)
                NumPut("UChar", 0x00, CLSID, 11)
                NumPut("UChar", 0xF8, CLSID, 12)
                NumPut("UChar", 0x1E, CLSID, 13)
                NumPut("UChar", 0xF3, CLSID, 14)
                NumPut("UChar", 0x2E, CLSID, 15)

                ; 保存图片
                status := DllCall("gdiplus\GdipSaveImageToFile"
                    , "Ptr", pBitmap
                    , "WStr", filePath
                    , "Ptr", CLSID
                    , "Ptr", 0)

                result := (status = 0)

                ; 释放位图
                DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
            }
        }
    }

    DllCall("CloseClipboard")
    return result
}
