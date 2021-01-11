<#
Name......: Compile.ps1
Version...: 19.05.1
Author....:  CORRADA

This script is an interface to compile your scripts
#>

# header
$ErrorActionPreference= 'Inquire'
$WarningPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

# setting installation path
$workdir = 'patrolinstallpath'

# select ps1 file
[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms')
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = "C:\Users\$env:USERNAME\Desktop"
$OpenFileDialog.filter = 'PowerShell script (*.ps1)| *.ps1'
$OpenFileDialog.ShowDialog() | Out-Null
$ps1file = $OpenFileDialog.filename
$ps1file -match "\\([a-zA-Z_\-\.\s0-9]+)\.ps1$" > $null
$filename = $matches[1]

# select output compiled file
[System.Reflection.Assembly]::LoadWithPartialName(�System.windows.forms�)
$OpenFileDialog = New-Object System.Windows.Forms.SaveFileDialog
$OpenFileDialog.initialDirectory = "C:\Users\$env:USERNAME\Desktop"
$OpenFileDialog.filter = �Executable (*.exe)| *.exe�
$OpenFileDialog.filename = $filename
$OpenFileDialog.ShowDialog() | Out-Null
$exefile = $OpenFileDialog.filename

$cmd = $workdir + "\PS2EXE\ps2exe.ps1"
& $cmd -inputFile $ps1file -outputFile $exefile -verbose



