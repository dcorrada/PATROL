<#
Name......: INSTALL.ps1
Version...: 21.1.1
Author....: Dario CORRADA

This script will install PATROL
#>

# setting execution policy
$ErrorActionPreference= 'SilentlyContinue'
Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy Bypass -Force
$ErrorActionPreference= 'Inquire'

# graphical stuff
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
$workdir = Get-Location
Import-Module -Name "$workdir\Modules\Forms.psm1"

# create temporary directory and move temp files in it
$tmppath = "C:\Users\$env:UserName\Desktop\PATROLTEMP"
if (!(Test-Path $tmppath)) {
   New-Item -ItemType directory -Path $tmppath > $null
}
Copy-Item "$workdir\Modules" -Recurse -Destination $tmppath > $null
Copy-Item "$workdir\Patrol.ps1" -Destination $tmppath > $null
Copy-Item "$workdir\UpdateDB.ps1" -Destination $tmppath > $null

# ask for installation path
$forminst = New-Object System.Windows.Forms.Form
$forminst.Text = "DESTPATH"
$forminst.Size = "350,200"
$forminst.StartPosition = 'CenterScreen'
$forminst.Topmost = $true
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Size(10,20) 
$label.Size = New-Object System.Drawing.Size(300,40) 
$label.Text = "Insert the installation path (be sure such path is accessible`nby all users that you want to use your scripts)"
$forminst.Controls.Add($label)
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,70)
$textBox.Size = New-Object System.Drawing.Size(300,20)
$textBox.Text = "C:\Users\$env:UserName\Desktop\PATROL"
$forminst.Add_Shown({$textBox.Select()})
$forminst.Controls.Add($textBox)
$CheckBox = New-Object System.Windows.Forms.CheckBox
$CheckBox.Location = New-Object System.Drawing.Point(10,90)
$CheckBox.Size = New-Object System.Drawing.Size(200,20)
$CheckBox.Checked = $true
$CheckBox.Text = "Create Directory"
$forminst.Add_Shown({$CheckBox.Select()})
$forminst.Controls.Add($CheckBox)
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = "100,120"
$OKButton.Size = '100,30'
$OKButton.Text = "Ok"
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$forminst.AcceptButton = $OKButton
$forminst.Controls.Add($OKButton)
$result = $forminst.ShowDialog()
$destpath = $textBox.Text

# creating crypto key
Import-Module -Name "$workdir\Modules\FileCryptography.psm1"
$cryptokey = New-CryptographyKey -Algorithm AES -AsPlainText

# updating scripts
$filelist = ('Patrol.ps1', 'UpdateDB.ps1')
foreach ($infile in $filelist) {
    $fullname = $tmppath + '\' + $infile
    ((Get-Content -path $fullname -Raw) -replace 'patrolinstallpath',$destpath) | Set-Content -Path $fullname
    ((Get-Content -path $fullname -Raw) -replace 'patrolcryptokey',$cryptokey) | Set-Content -Path $fullname
}

# compiling scripts
$filelist = ('Patrol.ps1', 'UpdateDB.ps1')
$cmd = "$workdir\PS2EXE\ps2exe.ps1"
foreach ($infile in $filelist) {
    $infile = $tmppath + '\' + $infile
    $infile -match "\\([a-zA-Z_\-\.\s0-9]+)\.ps1$" > $null
    $filename = $matches[1]
    $outfile = $tmppath + '\' + $filename + '.exe'
    & $cmd -inputFile $infile -outputFile $outfile -verbose
}

# Creating encrypted DB
$whoami = $env:USERNAME
"SCRIPT;USER" | Out-File "$tmppath\PatrolDB.csv" -Encoding ASCII -Append
"UpdateDB;$whoami" | Out-File "$tmppath\PatrolDB.csv" -Encoding ASCII -Append
$securekey = ConvertTo-SecureString $cryptokey -AsPlainText -Force
Protect-File "$tmppath\PatrolDB.csv" -Algorithm AES -Key $securekey

# Creating access register
"DATA;USERNAME;SCRIPT;STATUS" | Out-File "$tmppath\ACCESSI_PATROL.csv" -Encoding ASCII -Append

# Copying to installation path
if (!(Test-Path $destpath)) {
   New-Item -ItemType directory -Path $destpath > $null
}
Copy-Item "$tmppath\Modules" -Recurse -Destination $destpath > $null
Copy-Item "$tmppath\Patrol.exe" -Destination $destpath > $null
Copy-Item "$tmppath\UpdateDB.exe" -Destination $destpath > $null
Copy-Item "$tmppath\PatrolDB.csv.AES" -Destination $destpath > $null
Copy-Item "$tmppath\ACCESSI_PATROL.csv" -Destination $destpath > $null

# remove temporary directory
Remove-Item $tmppath -Recurse -Force

# pop up ending message
[System.Windows.MessageBox]::Show("UpdateDB script granted for $whoami",'PATROL','Ok','Info') > $null
