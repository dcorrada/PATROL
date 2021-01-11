function Patrol {
    param ($workdir, $scriptname)

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName PresentationFramework
    Import-Module -Name "$workdir\Modules\Forms.psm1"

    # get credentials
    $form_PWD = New-Object System.Windows.Forms.Form
    $form_PWD.Text = "LOGIN"
    $form_PWD.Size = "400,270"
    $form_PWD.StartPosition = 'CenterScreen'
    $form_PWD.Topmost = $true
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Size(10,20) 
    $label.Size = New-Object System.Drawing.Size(300,20) 
    $label.Text = "Insert your credentials"
    $form_PWD.Controls.Add($label)
    $usrlabel = New-Object System.Windows.Forms.Label
    $usrlabel.Location = New-Object System.Drawing.Size(10,50) 
    $usrlabel.Size = New-Object System.Drawing.Size(100,20) 
    $usrlabel.Text = "Username:"
    $form_PWD.Controls.Add($usrlabel)
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(130,50)
    $textBox.Size = New-Object System.Drawing.Size(150,20)
    $form_PWD.Add_Shown({$textBox.Select()})
    $form_PWD.Controls.Add($textBox)
    $pwdlabel = New-Object System.Windows.Forms.Label
    $pwdlabel.Location = New-Object System.Drawing.Size(10,80) 
    $pwdlabel.Size = New-Object System.Drawing.Size(100,20) 
    $pwdlabel.Text = "Password:"
    $form_PWD.Controls.Add($pwdlabel)
    $MaskedTextBox = New-Object System.Windows.Forms.MaskedTextBox
    $MaskedTextBox.PasswordChar = '*'
    $MaskedTextBox.Location = New-Object System.Drawing.Point(130,80)
    $MaskedTextBox.Size = New-Object System.Drawing.Size(150,20)
    $form_PWD.Add_Shown({$MaskedTextBox.Select()})
    $form_PWD.Controls.Add($MaskedTextBox)
    $CheckBox = New-Object System.Windows.Forms.CheckBox
    $CheckBox.Location = New-Object System.Drawing.Point(20,120)
    $CheckBox.Size = New-Object System.Drawing.Size(200,20)
    $CheckBox.Checked = $false
    $CheckBox.Text = "Domain Account"
    $form_PWD.Add_Shown({$CheckBox.Select()})
    $form_PWD.Controls.Add($CheckBox)
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = "100,160"
    $OKButton.Size = '100,30'
    $OKButton.Text = "Ok"
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form_PWD.AcceptButton = $OKButton
    $form_PWD.Controls.Add($OKButton)
    $result = $form_PWD.ShowDialog()

    # get domain name
    $thiscomputer = Get-WmiObject -Class Win32_ComputerSystem
    
    if ($CheckBox.Checked) {
        $fullname = $thiscomputer.Domain + '\' + $textBox.Text
    } else {
        $fullname = $textBox.Text
    }
    $usr = $textBox.Text
    $pwd = ConvertTo-SecureString $MaskedTextBox.Text -AsPlainText -Force
    $credit = New-Object System.Management.Automation.PSCredential($usr, $pwd)
    
    [reflection.assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement") > $null
    $principalContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new([System.DirectoryServices.AccountManagement.ContextType]'Machine',$env:COMPUTERNAME)
    if ($principalContext.ValidateCredentials($fullname,$MaskedTextBox.Text)) { # check credentials
        # load the module to cript/decript DB
        Import-Module -Name "$workdir\Modules\FileCryptography.psm1"

        Copy-Item -Path "$workdir\PatrolDB.csv.AES" -Destination "C:\Users\$env:USERNAME\Desktop\PatrolDB.csv.AES"
        $stringa = Get-Content "$workdir\crypto.key"
        $chiave = ConvertTo-SecureString $stringa -AsPlainText -Force
        Unprotect-File "C:\Users\$env:USERNAME\Desktop\PatrolDB.csv.AES" -Algorithm AES -Key $chiave -RemoveSource > $null

        $filecontent = Get-Content -Path "C:\Users\$env:USERNAME\Desktop\PatrolDB.csv"
        $allowed = @()
        foreach ($newline in $filecontent) {
            ($script, $utente) = $newline.Split(';')
            if ($script -eq $scriptname) {
                $allowed += $utente
            }
        }
        
        Remove-Item -Path "C:\Users\$env:USERNAME\Desktop\PatrolDB.csv"

        if ($allowed -contains 'everyone') { 
            Write-Host -ForegroundColor Cyan "Patrol disabled"
            $status = 'granted'
        } elseif ($allowed -contains $usr) {
            Write-Host -ForegroundColor Green "Patrol unlocked"
            $status = 'granted'
        } else {
            Write-Host -ForegroundColor Red "Patrol locked"
            $status = 'blocked'
        }        
       
    } else {
        [System.Windows.MessageBox]::Show("Password o username uncorrect",'ERROR','Ok','Error')
        Exit
    }

    # write access record
    net stop workstation /y > $null
    net start workstation > $null
    Start-Sleep 3
    New-PSDrive -Name Z -PSProvider FileSystem -Root $workdir -Credential $credit > $null

    $rec_data = Get-Date -UFormat "%d/%m/%Y-%H:%M"
    $new_record = @(
        $rec_data,
        $usr,
        $scriptname,
        $status
    )
    $new_string = [system.String]::Join(";", $new_record)
    $new_string | Out-File "Z:\ACCESSI_PATROL.csv" -Encoding ASCII -Append
    

    if ($status -eq 'blocked') {
        [System.Windows.MessageBox]::Show("User is not enabled to run this script",'WARNING','Ok','Error')
        Exit
    }

    Remove-PSDrive -Name Z

    return $credit
}
Export-ModuleMember -Function Patrol