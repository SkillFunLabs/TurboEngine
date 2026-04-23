# Turbo Engine – GUI minúscula (PT/EN)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# Seletor de idioma
$langForm = New-Object System.Windows.Forms.Form
$langForm.Text = "Language"
$langForm.Size = New-Object System.Drawing.Size(240,130)
$langForm.StartPosition = "CenterScreen"
$langForm.FormBorderStyle = "FixedDialog"
$langForm.MaximizeBox = $false
$langForm.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = "Language / Idioma:"
$lbl.ForeColor = [System.Drawing.Color]::White
$lbl.Location = New-Object System.Drawing.Point(40,20)
$lbl.Size = New-Object System.Drawing.Size(160,25)
$langForm.Controls.Add($lbl)

$btnPt = New-Object System.Windows.Forms.Button; $btnPt.Text = "Português"; $btnPt.Size = New-Object System.Drawing.Size(80,30); $btnPt.Location = New-Object System.Drawing.Point(30,60); $langForm.Controls.Add($btnPt)
$btnEn = New-Object System.Windows.Forms.Button; $btnEn.Text = "English"; $btnEn.Size = New-Object System.Drawing.Size(80,30); $btnEn.Location = New-Object System.Drawing.Point(130,60); $langForm.Controls.Add($btnEn)

$global:lang = $null
$btnPt.Add_Click({ $global:lang = 'PT'; $langForm.Close() })
$btnEn.Add_Click({ $global:lang = 'EN'; $langForm.Close() })
$langForm.ShowDialog() | Out-Null
if ($null -eq $global:lang) { exit }

$txt = if ($global:lang -eq 'PT') { @{ On='LIGAR'; Off='DESLIGAR'; StatusOn='Ligado'; StatusOff='Desligado'; Title='Turbo Engine' } } 
       else { @{ On='START'; Off='STOP'; StatusOn='Turbo ON'; StatusOff='Turbo OFF'; Title='Turbo Engine' } }

# Janela principal
$form = New-Object System.Windows.Forms.Form
$form.Text = $txt.Title
$form.Size = New-Object System.Drawing.Size(260,150)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedToolWindow"
$form.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
$form.TopMost = $true

$btnOn = New-Object System.Windows.Forms.Button
$btnOn.Text = $txt.On; $btnOn.Size = New-Object System.Drawing.Size(90,30); $btnOn.Location = New-Object System.Drawing.Point(15,20); $btnOn.BackColor = [System.Drawing.Color]::DarkGreen; $btnOn.ForeColor = [System.Drawing.Color]::White; $btnOn.FlatStyle = 'Flat'
$form.Controls.Add($btnOn)

$btnOff = New-Object System.Windows.Forms.Button
$btnOff.Text = $txt.Off; $btnOff.Size = New-Object System.Drawing.Size(90,30); $btnOff.Location = New-Object System.Drawing.Point(130,20); $btnOff.BackColor = [System.Drawing.Color]::DarkRed; $btnOff.ForeColor = [System.Drawing.Color]::White; $btnOff.FlatStyle = 'Flat'
$form.Controls.Add($btnOff)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Estado: $($txt.StatusOff)"; $lblStatus.ForeColor = [System.Drawing.Color]::Gray; $lblStatus.Location = New-Object System.Drawing.Point(15,70); $lblStatus.Size = New-Object System.Drawing.Size(220,20); $lblStatus.TextAlign = "MiddleCenter"
$form.Controls.Add($lblStatus)

# Motor
$script:timer = $null
$script:isRunning = $false

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class FgWindow {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);
}
"@ -ErrorAction SilentlyContinue

function Turbo-Cycle {
    try {
        $hwnd = [FgWindow]::GetForegroundWindow()
        $pidFg = 0
        [FgWindow]::GetWindowThreadProcessId($hwnd, [ref]$pidFg) | Out-Null
        if ($pidFg -ne 0) {
            $proc = Get-Process -Id $pidFg -ErrorAction SilentlyContinue
            if ($proc -and $proc.PriorityClass -eq "Normal" -and $proc.ProcessName -notmatch "^(explorer|svchost|csrss|dwm|System)$") {
                $proc.PriorityClass = "AboveNormal"
            }
        }
    } catch {}
}

$btnOn.Add_Click({
    if (-not $script:isRunning) {
        $script:timer = New-Object System.Windows.Forms.Timer
        $script:timer.Interval = 800
        $script:timer.Add_Tick({ Turbo-Cycle })
        $script:timer.Start()
        $script:isRunning = $true
        $lblStatus.Text = "Estado: $($txt.StatusOn)"
        $lblStatus.ForeColor = [System.Drawing.Color]::Lime
    }
})

$btnOff.Add_Click({
    if ($script:isRunning) {
        $script:timer.Stop()
        $script:timer.Dispose()
        $script:timer = $null
        $script:isRunning = $false
        $lblStatus.Text = "Estado: $($txt.StatusOff)"
        $lblStatus.ForeColor = [System.Drawing.Color]::Gray
    }
})

$form.ShowDialog() | Out-Null