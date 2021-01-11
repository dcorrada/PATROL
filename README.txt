###############################################################################
DISCLAIMER: In order to use this tool all the scripts patched need to be executed
elevated with admin privileges. For the source scripts you can add these lines 
at the header of your own code (example for PowerShell scripts):

# elevate script execution with admin privileges
$currentUser = New-Object Security.Principal.WindowsPrincipal `
$([Security.Principal.WindowsIdentity]::GetCurrent())
$testadmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if ($testadmin -eq $false) {
    Start-Process powershell.exe -Verb RunAs `
    -ArgumentList ('-noprofile -file "{0}" -elevated' `
    -f ($myinvocation.MyCommand.Definition))
    exit $LASTEXITCODE
}

For the compiled scripts you can run them by right click > Run As Administrator
###############################################################################

1 - INSTALLATION
Launch the installation script INSTALL.ps1. Be sure that installation path is
accessible (in read/write mode) to all users that you want to allow the launch
of your own scripts.

2 - CONFIGURATION
Once PATROL is installed an encrypted DB will be created (PatrolDB.csv.AES).
In this file are stored pairs of values (username;scriptname) that will define
the individual grants for each script.
	
	A) Launch UpdateDB.exe script. After logged with your credentials, click
	on "Add record" option to add the scriptname and username to be granted

	B) Protect your script using PATROL access grants. Add, on the header of
	your script, the following code (PowerShell example):

		# run patrol agent
		$stdout = [installation_path]\Patrol.exe [script_name]
		$usr = $stdout[0]
		$pwd_clear = $stdout[1]
		$status = $stdout[2]
		$pwd = ConvertTo-SecureString $pwd_clear -AsPlainText -Force
		$login = New-Object System.Management.Automation.PSCredential($usr, $pwd)
		if ($status -ne "granted") {
			Write-Host -ForegroundColor RED "Access for $usr $status"
			Pause
			Exit
		} else {
			Write-Host -ForegroundColor GREEN "Access for $usr $status"
		}  

	The Patrol.exe function returns username and password credentials, followed
	by the status of access to the script (blocked or granted). You can recycle
	the credential info for further authentications (variable $login).

	C) To further protect your scripts it is suggested to compile them. In case
	of PowerShell scripts you can use a tool like PS2EXE available at:

	https://gallery.technet.microsoft.com/scriptcenter/PS2EXE-Convert-PowerShell-9e4e07f1

