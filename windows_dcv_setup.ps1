# Define the parameter at the very beginning
param(
    [switch]$Debug
)

# Global variable to store the debug mode state
$Global:IsDebug = $Debug.IsPresent

# Define helper function to show debug messages only if debug mode is enabled
function Show-DebugMessage {
    param (
        [string]$Message,
        [string]$Title = "Debug"
    )

    if ($Global:IsDebug) {
        [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
}

# Ensure the script is running with administrative privileges
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not ($principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Please run this script as an Administrator.", "Insufficient Permissions", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# Load necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define helper function for single input dialogs
function Show-InputBox {
    param (
        [string]$Message,
        [string]$Title = "Input Required"
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(400, 150)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Message
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $form.Controls.Add($label)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Size = New-Object System.Drawing.Size(360, 20)
    $textbox.Location = New-Object System.Drawing.Point(10, 50)
    $form.Controls.Add($textbox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(220, 80)
    $okButton.Add_Click({ $form.DialogResult = "OK"; $form.Close() })
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(300, 80)
    $cancelButton.Add_Click({ $form.DialogResult = "Cancel"; $form.Close() })
    $form.Controls.Add($cancelButton)

    $result = $form.ShowDialog()
    if ($result -eq "OK") {
        return $textbox.Text
    } else {
        return $null
    }
}

# Define helper function for multiple inputs (used in Broker Configuration)
function Show-MultiInputDialog {
    param (
        [string]$Title = "Input Required",
        [string]$Label1Text = "",
        [string]$Label2Text = "",
        [string]$Label3Text = ""
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(600, 350)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    # Label and TextBox for Broker Certificate Path
    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = $Label1Text
    $label1.AutoSize = $true
    $label1.Location = New-Object System.Drawing.Point(10, 20)
    $form.Controls.Add($label1)

    $textbox1 = New-Object System.Windows.Forms.TextBox
    $textbox1.Size = New-Object System.Drawing.Size(560, 20)
    $textbox1.Location = New-Object System.Drawing.Point(10, 50)
    $form.Controls.Add($textbox1)

    # Label and TextBox for Broker Hostname
    $label2 = New-Object System.Windows.Forms.Label
    $label2.Text = $Label2Text
    $label2.AutoSize = $true
    $label2.Location = New-Object System.Drawing.Point(10, 90)
    $form.Controls.Add($label2)

    $textbox2 = New-Object System.Windows.Forms.TextBox
    $textbox2.Size = New-Object System.Drawing.Size(560, 20)
    $textbox2.Location = New-Object System.Drawing.Point(10, 120)
    $form.Controls.Add($textbox2)

    # Label and TextBox for Broker Port
    $label3 = New-Object System.Windows.Forms.Label
    $label3.Text = $Label3Text
    $label3.AutoSize = $true
    $label3.Location = New-Object System.Drawing.Point(10, 160)
    $form.Controls.Add($label3)

    $textbox3 = New-Object System.Windows.Forms.TextBox
    $textbox3.Size = New-Object System.Drawing.Size(560, 20)
    $textbox3.Location = New-Object System.Drawing.Point(10, 190)
    $form.Controls.Add($textbox3)

    # OK Button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Location = New-Object System.Drawing.Point(370, 270)
    $okButton.Add_Click({ $form.DialogResult = "OK"; $form.Close() })
    $form.Controls.Add($okButton)

    # Cancel Button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
    $cancelButton.Location = New-Object System.Drawing.Point(480, 270)
    $cancelButton.Add_Click({ $form.DialogResult = "Cancel"; $form.Close() })
    $form.Controls.Add($cancelButton)

    $result = $form.ShowDialog()
    if ($result -eq "OK") {
        return @{
            Input1 = $textbox1.Text
            Input2 = $textbox2.Text
            Input3 = $textbox3.Text
        }
    } else {
        return $null
    }
}

# Define helper function to ensure registry path exists
function Ensure-RegistryPath {
    param (
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        try {
            New-Item -Path $Path -Force | Out-Null
            Show-DebugMessage -Message "Created registry path: $Path"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to create registry path: $Path. Error: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            throw "Failed to create registry path: $Path. Error: $_"
        }
    } else {
        Show-DebugMessage -Message "Registry path exists: $Path"
    }
}

# Define the technical service name for DCV Server
$serviceName = "dcvserver"

# Define the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "DCV Registry Manager by ni-sp.com"
$form.Size = New-Object System.Drawing.Size(850, 430) # Increased width and height to accommodate more buttons
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.TopMost = $true

# Define button properties
$buttonWidth = 250
$buttonHeight = 40
$buttonMargin = 20
$columns = 3
# Adding new buttons
$buttonTexts = @(
    "Enable Dynamic console session",
    "Disable Dynamic console session",
    "Enable QUIC/UDP mode",
    "Disable QUIC/UDP mode",
    "Add default domain name",
    "Remove default domain name",
    "Configure NICE DCV Broker",
    "Clean NICE DCV Broker config",
    "Enable Delay DCV Server boot start",
    "Disable Delay DCV Server boot start",
    "Restart DCV Server",
    "Enable DCV Server debug mode",
    "Disable DCV Server debug mode",
    "Open DCV Server log directory",
    "Set mouse wheel sensitivity",
    "Set max-head-resolution",
    "Set web-client-max-head-resolution",
    "Set enable-yuv444-encoding"
)

# Initialize button array
$buttons = @()

# Calculate number of rows based on columns
$rows = [math]::Ceiling($buttonTexts.Count / $columns) # For 18 buttons and 3 columns, $rows = 6

# Create and position buttons in three columns
for ($i = 0; $i -lt $buttonTexts.Count; $i++) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)

    # Determine column and row
    $column = [math]::Floor($i / $rows)
    $row = $i % $rows

    # Calculate X and Y positions
    $x = $buttonMargin + ($column * ($buttonWidth + $buttonMargin))
    $y = $buttonMargin + ($row * ($buttonHeight + $buttonMargin))

    # Assign location
    $btn.Location = New-Object System.Drawing.Point -ArgumentList $x, $y
    $btn.Text = $buttonTexts[$i]
    $btn.Name = "Button$i"
    $form.Controls.Add($btn)
    $buttons += $btn
}

# Define helper function to show warning message
function Show-Warning {
    [System.Windows.Forms.MessageBox]::Show("Please restart the DCV Server service for changes to take effect.", "Action Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
}

# ----------------------- Existing Button Handlers -----------------------

# Button 1: Enable Dynamic console session
$buttons[0].Add_Click({
    Show-DebugMessage -Message "Enable Dynamic console session button clicked."
    $owner = Show-InputBox -Message "Please enter the owner name for the automatic console session:" -Title "Enable Dynamic Console Session"
    if ([string]::IsNullOrWhiteSpace($owner)) {
        [System.Windows.Forms.MessageBox]::Show("Operation cancelled or invalid input.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }

    try {
        $basePath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\session-management"

        Show-DebugMessage -Message "Ensuring registry path: $basePath"
        # Ensure the base registry key exists
        Ensure-RegistryPath -Path $basePath

        # Set max-concurrent-clients DWORD to 1
        New-ItemProperty -Path $basePath -Name "max-concurrent-clients" -Value 1 -PropertyType DWord -Force | Out-Null
        Show-DebugMessage -Message "Set 'max-concurrent-clients' to 1."

        # Set create-session DWORD to 1
        New-ItemProperty -Path $basePath -Name "create-session" -Value 1 -PropertyType DWord -Force | Out-Null
        Show-DebugMessage -Message "Set 'create-session' to 1."

        # Create automatic-console-session key if it doesn't exist
        $autoConsolePath = "$basePath\automatic-console-session"
        Show-DebugMessage -Message "Ensuring registry path: $autoConsolePath"
        Ensure-RegistryPath -Path $autoConsolePath

        # Set owner string
        New-ItemProperty -Path $autoConsolePath -Name "owner" -Value $owner -PropertyType String -Force | Out-Null
        Show-DebugMessage -Message "Set 'owner' to '$owner'."

        # Set disconnect-on-lock DWORD to 1
        $connectivityPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\connectivity"
        Show-DebugMessage -Message "Ensuring registry path: $connectivityPath"
        Ensure-RegistryPath -Path $connectivityPath
        New-ItemProperty -Path $connectivityPath -Name "disconnect-on-lock" -Value 1 -PropertyType DWord -Force | Out-Null
        Show-DebugMessage -Message "Set 'disconnect-on-lock' to 1."

        # Set os-auto-lock DWORD to 1
        $securityPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\security"
        Show-DebugMessage -Message "Ensuring registry path: $securityPath"
        Ensure-RegistryPath -Path $securityPath
        New-ItemProperty -Path $securityPath -Name "os-auto-lock" -Value 1 -PropertyType DWord -Force | Out-Null
        Show-DebugMessage -Message "Set 'os-auto-lock' to 1."

        # Ensure the directory for default.perm exists
        $permPath = "C:\Program Files\NICE\DCV\Server\conf\default.perm"
        $permDir = Split-Path -Path $permPath
        if (-not (Test-Path $permDir)) {
            New-Item -Path $permDir -ItemType Directory -Force | Out-Null
            Show-DebugMessage -Message "Created directory: $permDir"
        } else {
            Show-DebugMessage -Message "Directory exists: $permDir"
        }

        # Rewrite the default.perm file
        $permContent = @"
; In /etc/dcv/default.perm in the permissions section we apply the following setting to allow all users
; Permissions can be adjusted for the respective purposes, builtin enables all permissions

[permissions]
%any% allow builtin
"@
        Set-Content -Path $permPath -Value $permContent -Force
        Show-DebugMessage -Message "Rewrote default.perm file at $permPath."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 2: Disable Dynamic console session
$buttons[1].Add_Click({
    Show-DebugMessage -Message "Disable Dynamic console session button clicked."
    try {
        $basePath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\session-management"

        if (Test-Path $basePath) {
            Remove-ItemProperty -Path $basePath -Name "max-concurrent-clients" -ErrorAction SilentlyContinue
            Show-DebugMessage -Message "Removed 'max-concurrent-clients' from $basePath."
            Remove-ItemProperty -Path $basePath -Name "create-session" -ErrorAction SilentlyContinue
            Show-DebugMessage -Message "Removed 'create-session' from $basePath."
        } else {
            Show-DebugMessage -Message "Registry path does not exist: $basePath"
        }

        $autoConsolePath = "$basePath\automatic-console-session"
        if (Test-Path $autoConsolePath) {
            Remove-ItemProperty -Path $autoConsolePath -Name "owner" -ErrorAction SilentlyContinue
            Show-DebugMessage -Message "Removed 'owner' from $autoConsolePath."
            Remove-Item -Path $autoConsolePath -Force -ErrorAction SilentlyContinue
            Show-DebugMessage -Message "Removed registry key: $autoConsolePath."
        } else {
            Show-DebugMessage -Message "Registry path does not exist: $autoConsolePath"
        }

        $connectivityPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\connectivity"
        if (Test-Path $connectivityPath) {
            Remove-ItemProperty -Path $connectivityPath -Name "disconnect-on-lock" -ErrorAction SilentlyContinue
            Show-DebugMessage -Message "Removed 'disconnect-on-lock' from $connectivityPath."
        } else {
            Show-DebugMessage -Message "Registry path does not exist: $connectivityPath"
        }

        $securityPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\security"
        if (Test-Path $securityPath) {
            Remove-ItemProperty -Path $securityPath -Name "os-auto-lock" -ErrorAction SilentlyContinue
            Show-DebugMessage -Message "Removed 'os-auto-lock' from $securityPath."
        } else {
            Show-DebugMessage -Message "Registry path does not exist: $securityPath"
        }

        # Rewrite the default.perm file
        $permPath = "C:\Program Files\NICE\DCV\Server\conf\default.perm"
        if (-not (Test-Path $permPath)) {
            $permDir = Split-Path -Path $permPath
            if (-not (Test-Path $permDir)) {
                New-Item -Path $permDir -ItemType Directory -Force | Out-Null
                Show-DebugMessage -Message "Created directory: $permDir"
            }
        }
        $permContent = @"
; In /etc/dcv/default.perm in the permissions section we apply the following setting to allow all users
; Permissions can be adjusted for the respective purposes, builtin enables all permissions

[permissions]
; %any% allow builtin
"@
        Set-Content -Path $permPath -Value $permContent -Force
        Show-DebugMessage -Message "Rewrote default.perm file at $permPath."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 3: Enable QUIC/UDP mode
$buttons[2].Add_Click({
    Show-DebugMessage -Message "Enable QUIC/UDP mode button clicked."
    try {
        $connectivityPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\connectivity"

        Show-DebugMessage -Message "Ensuring registry path: $connectivityPath"
        # Ensure the connectivity registry path exists
        Ensure-RegistryPath -Path $connectivityPath

        # Set enable-quic-frontend DWORD to 1
        New-ItemProperty -Path $connectivityPath -Name "enable-quic-frontend" -Value 1 -PropertyType DWord -Force | Out-Null
        Show-DebugMessage -Message "Set 'enable-quic-frontend' to 1."

        # Set enable-datagrams-display string to "always-off"
        New-ItemProperty -Path $connectivityPath -Name "enable-datagrams-display" -Value "always-off" -PropertyType String -Force | Out-Null
        Show-DebugMessage -Message "Set 'enable-datagrams-display' to 'always-off'."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 4: Disable QUIC/UDP mode
$buttons[3].Add_Click({
    Show-DebugMessage -Message "Disable QUIC/UDP mode button clicked."
    try {
        $connectivityPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\connectivity"

        Show-DebugMessage -Message "Ensuring registry path: $connectivityPath"
        # Ensure the connectivity registry path exists
        Ensure-RegistryPath -Path $connectivityPath

        # Set enable-quic-frontend DWORD to 0
        Set-ItemProperty -Path $connectivityPath -Name "enable-quic-frontend" -Value 0 -Force | Out-Null
        Show-DebugMessage -Message "Set 'enable-quic-frontend' to 0 in $connectivityPath."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 5: Add default domain name
$buttons[4].Add_Click({
    Show-DebugMessage -Message "Add default domain name button clicked."
    $domainName = Show-InputBox -Message "Please enter the Windows Domain Name:" -Title "Add Default Domain Name"
    if ([string]::IsNullOrWhiteSpace($domainName)) {
        [System.Windows.Forms.MessageBox]::Show("Operation cancelled or invalid input.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }

    try {
        $policyPath = "Registry::HKEY_USERS\S-1-5-18\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

        Show-DebugMessage -Message "Ensuring registry path: $policyPath"
        # Ensure the policy registry path exists
        Ensure-RegistryPath -Path $policyPath

        # Set or create DefaultDomainName as a String
        New-ItemProperty -Path $policyPath -Name "DefaultDomainName" -Value $domainName -PropertyType String -Force | Out-Null
        Show-DebugMessage -Message "Set 'DefaultDomainName' to '$domainName'."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 6: Remove default domain name
$buttons[5].Add_Click({
    Show-DebugMessage -Message "Remove default domain name button clicked."
    try {
        $policyPath = "Registry::HKEY_USERS\S-1-5-18\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

        if (Test-Path $policyPath) {
            Remove-ItemProperty -Path $policyPath -Name "DefaultDomainName" -ErrorAction SilentlyContinue
            Show-DebugMessage -Message "Removed 'DefaultDomainName' from $policyPath."
        } else {
            Show-DebugMessage -Message "Registry path does not exist: $policyPath"
        }

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 7: Configure NICE DCV Broker
$buttons[6].Add_Click({
    Show-DebugMessage -Message "Configure NICE DCV Broker button clicked."
    while ($true) {
        $inputs = Show-MultiInputDialog -Title "Configure NICE DCV Broker" -Label1Text "Broker Certificate Path:" `
                                       -Label2Text "Broker Hostname (IP or DNS):" -Label3Text "Broker Port (1024-65535):"
        if ($inputs -eq $null) {
            return
        }

        $certPath = $inputs.Input1.Trim()
        $brokerHostname = $inputs.Input2.Trim()
        $brokerPort = $inputs.Input3.Trim()

        Show-DebugMessage -Message "Inputs received: CertPath='$certPath', Hostname='$brokerHostname', Port='$brokerPort'"

        # Validate certificate path
        if (-not (Test-Path $certPath)) {
            [System.Windows.Forms.MessageBox]::Show("Certificate file does not exist. Please enter a valid path.", "Invalid Input", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            continue
        }

        # Validate broker port
        if (-not ($brokerPort -match '^\d+$') -or [int]$brokerPort -lt 1024 -or [int]$brokerPort -gt 65535) {
            [System.Windows.Forms.MessageBox]::Show("Broker port must be a valid number between 1024 and 65535.", "Invalid Input", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            continue
        }

        # If all validations pass, proceed
        break
    }

    try {
        $securityPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\security"

        Show-DebugMessage -Message "Ensuring registry path: $securityPath"
        # Ensure the security registry path exists
        Ensure-RegistryPath -Path $securityPath

        # Set ca-file string
        New-ItemProperty -Path $securityPath -Name "ca-file" -Value $certPath -PropertyType String -Force | Out-Null
        Show-DebugMessage -Message "Set 'ca-file' to '$certPath'."

        # Construct auth-token-verifier string with corrected variable interpolation
        $authTokenVerifier = "https://${brokerHostname}:${brokerPort}/agent/validate-authentication-token"
        New-ItemProperty -Path $securityPath -Name "auth-token-verifier" -Value $authTokenVerifier -PropertyType String -Force | Out-Null
        Show-DebugMessage -Message "Set 'auth-token-verifier' to '$authTokenVerifier'."

        # Set no-tls-strict DWORD to 1
        New-ItemProperty -Path $securityPath -Name "no-tls-strict" -Value 1 -PropertyType DWord -Force | Out-Null
        Show-DebugMessage -Message "Set 'no-tls-strict' to 1."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 8: Clean NICE DCV Broker config
$buttons[7].Add_Click({
    Show-DebugMessage -Message "Clean NICE DCV Broker config button clicked."
    try {
        $securityPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\security"

        if (Test-Path $securityPath) {
            Remove-ItemProperty -Path $securityPath -Name "ca-file" -ErrorAction SilentlyContinue
            Show-DebugMessage -Message "Removed 'ca-file' from $securityPath."
            Remove-ItemProperty -Path $securityPath -Name "auth-token-verifier" -ErrorAction SilentlyContinue
            Show-DebugMessage -Message "Removed 'auth-token-verifier' from $securityPath."
            Remove-ItemProperty -Path $securityPath -Name "no-tls-strict" -ErrorAction SilentlyContinue
            Show-DebugMessage -Message "Removed 'no-tls-strict' from $securityPath."
        } else {
            Show-DebugMessage -Message "Registry path does not exist: $securityPath"
        }

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 9: Enable Delay DCV Server boot start
$buttons[8].Add_Click({
    Show-DebugMessage -Message "Enable Delay DCV Server boot start button clicked."
    try {
        $serviceRegPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$serviceName"

        # Verify that the service exists
        if (-not (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show("Service '$serviceName' does not exist.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        Show-DebugMessage -Message "Ensuring registry path: $serviceRegPath"
        Ensure-RegistryPath -Path $serviceRegPath

        # Set Start to 2 (Automatic)
        Set-ItemProperty -Path $serviceRegPath -Name "Start" -Value 2 -Force
        Show-DebugMessage -Message "Set 'Start' to 2 (Automatic) for DCV Server."

        # Set DelayedAutoStart to 1 (Automatic Delayed Start)
        Set-ItemProperty -Path $serviceRegPath -Name "DelayedAutoStart" -Value 1 -Force
        Show-DebugMessage -Message "Set 'DelayedAutoStart' to 1 for DCV Server."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred while enabling delayed start: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 10: Disable Delay DCV Server boot start
$buttons[9].Add_Click({
    Show-DebugMessage -Message "Disable Delay DCV Server boot start button clicked."
    try {
        $serviceRegPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$serviceName"

        # Verify that the service exists
        if (-not (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show("Service '$serviceName' does not exist.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        Show-DebugMessage -Message "Ensuring registry path: $serviceRegPath"
        Ensure-RegistryPath -Path $serviceRegPath

        # Set Start to 2 (Automatic)
        Set-ItemProperty -Path $serviceRegPath -Name "Start" -Value 2 -Force
        Show-DebugMessage -Message "Set 'Start' to 2 (Automatic) for DCV Server."

        # Set DelayedAutoStart to 0 (Automatic)
        Set-ItemProperty -Path $serviceRegPath -Name "DelayedAutoStart" -Value 0 -Force
        Show-DebugMessage -Message "Set 'DelayedAutoStart' to 0 for DCV Server."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred while disabling delayed start: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 11: Restart DCV Server
$buttons[10].Add_Click({
    Show-DebugMessage -Message "Restart DCV Server button clicked."
    try {
        # Verify that the service exists
        if (-not (Get-Service -Name $serviceName -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show("Service '$serviceName' does not exist.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        Restart-Service -Name $serviceName -Force -ErrorAction Stop
        Show-DebugMessage -Message "DCV Server service restarted successfully."
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred while restarting DCV Server: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 12: Enable DCV Server debug mode
$buttons[11].Add_Click({
    Show-DebugMessage -Message "Enable DCV Server debug mode button clicked."
    try {
        $debugRegPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\log"

        Show-DebugMessage -Message "Ensuring registry path: $debugRegPath"
        # Ensure the debug registry path exists
        Ensure-RegistryPath -Path $debugRegPath

        # Set level to "debug" using New-ItemProperty
        New-ItemProperty -Path $debugRegPath -Name "level" -Value "debug" -PropertyType String -Force | Out-Null
        Show-DebugMessage -Message "Set 'level' to 'debug' in DCV Server log settings."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred while enabling debug mode: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 13: Disable DCV Server debug mode
$buttons[12].Add_Click({
    Show-DebugMessage -Message "Disable DCV Server debug mode button clicked."
    try {
        $debugRegPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\log"

        if (Test-Path $debugRegPath) {
            # Set level to "info" using Set-ItemProperty
            Set-ItemProperty -Path $debugRegPath -Name "level" -Value "info" -Force
            Show-DebugMessage -Message "Set 'level' to 'info' in DCV Server log settings."
        } else {
            # Ensure the path exists before setting
            Ensure-RegistryPath -Path $debugRegPath
            Set-ItemProperty -Path $debugRegPath -Name "level" -Value "info" -Force
            Show-DebugMessage -Message "Set 'level' to 'info' in DCV Server log settings."
        }

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred while disabling debug mode: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 14: Open DCV Server log directory
$buttons[13].Add_Click({
    Show-DebugMessage -Message "Open DCV Server log directory button clicked."
    try {
        $logDirectory = "C:\ProgramData\NICE\dcv\log"

        if (Test-Path $logDirectory) {
            Show-DebugMessage -Message "Opening DCV Server log directory: $logDirectory"
            Start-Process -FilePath "explorer.exe" -ArgumentList $logDirectory
        } else {
            [System.Windows.Forms.MessageBox]::Show("Log directory does not exist: $logDirectory", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred while opening log directory: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 15: Set mouse wheel sensitivity
$buttons[14].Add_Click({
    Show-DebugMessage -Message "Set mouse wheel sensitivity button clicked."
    while ($true) {
        $sensitivityInput = Show-InputBox -Message "Please enter mouse wheel sensitivity (integer between 0 and 480):" -Title "Set Mouse Wheel Sensitivity"
        if ($sensitivityInput -eq $null) {
            # User canceled the input
            return
        }

        # Trim and validate the input
        $sensitivityTrimmed = $sensitivityInput.Trim()
        $isInteger = [int]::TryParse($sensitivityTrimmed, [ref]$null)
        if ($isInteger) {
            $sensitivity = [int]$sensitivityTrimmed
            if ($sensitivity -ge 0 -and $sensitivity -le 480) {
                break
            }
        }

        # If invalid, show error and prompt again
        [System.Windows.Forms.MessageBox]::Show("Invalid input. Please enter an integer between 0 and 480.", "Invalid Input", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }

    try {
        $inputRegPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\input"

        Show-DebugMessage -Message "Ensuring registry path: $inputRegPath"
        # Ensure the input registry path exists
        Ensure-RegistryPath -Path $inputRegPath

        # Set or create mouse-wheel-sensitivity as a DWORD
        New-ItemProperty -Path $inputRegPath -Name "mouse-wheel-sensitivity" -Value $sensitivity -PropertyType DWord -Force | Out-Null
        Show-DebugMessage -Message "Set 'mouse-wheel-sensitivity' to '$sensitivity'."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred while setting mouse wheel sensitivity: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# ----------------------- New Button Handlers -----------------------

# Button 16: Set max-head-resolution
$buttons[15].Add_Click({
    Show-DebugMessage -Message "Set max-head-resolution button clicked."
    while ($true) {
        $widthInput = Show-InputBox -Message "Please enter the screen width (integer):" -Title "Set max-head-resolution - Width"
        if ($widthInput -eq $null) {
            # User canceled the input
            return
        }

        $widthTrimmed = $widthInput.Trim()
        $isWidthInteger = [int]::TryParse($widthTrimmed, [ref]$null)
        if (-not $isWidthInteger) {
            [System.Windows.Forms.MessageBox]::Show("Invalid input. Please enter a valid integer for width.", "Invalid Input", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            continue
        }

        $heightInput = Show-InputBox -Message "Please enter the screen height (integer):" -Title "Set max-head-resolution - Height"
        if ($heightInput -eq $null) {
            # User canceled the input
            return
        }

        $heightTrimmed = $heightInput.Trim()
        $isHeightInteger = [int]::TryParse($heightTrimmed, [ref]$null)
        if (-not $isHeightInteger) {
            [System.Windows.Forms.MessageBox]::Show("Invalid input. Please enter a valid integer for height.", "Invalid Input", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            continue
        }

        # Both inputs are valid integers
        $width = [int]$widthTrimmed
        $height = [int]$heightTrimmed
        break
    }

    try {
        $displayPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\display"

        Show-DebugMessage -Message "Ensuring registry path: $displayPath"
        # Ensure the display registry path exists
        Ensure-RegistryPath -Path $displayPath

        # Set max-head-resolution string
        $resolutionValue = "($width,$height)"
        New-ItemProperty -Path $displayPath -Name "max-head-resolution" -Value $resolutionValue -PropertyType String -Force | Out-Null
        Show-DebugMessage -Message "Set 'max-head-resolution' to '$resolutionValue'."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 17: Set web-client-max-head-resolution
$buttons[16].Add_Click({
    Show-DebugMessage -Message "Set web-client-max-head-resolution button clicked."
    while ($true) {
        $widthInput = Show-InputBox -Message "Please enter the web client screen width (integer):" -Title "Set web-client-max-head-resolution - Width"
        if ($widthInput -eq $null) {
            # User canceled the input
            return
        }

        $widthTrimmed = $widthInput.Trim()
        $isWidthInteger = [int]::TryParse($widthTrimmed, [ref]$null)
        if (-not $isWidthInteger) {
            [System.Windows.Forms.MessageBox]::Show("Invalid input. Please enter a valid integer for width.", "Invalid Input", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            continue
        }

        $heightInput = Show-InputBox -Message "Please enter the web client screen height (integer):" -Title "Set web-client-max-head-resolution - Height"
        if ($heightInput -eq $null) {
            # User canceled the input
            return
        }

        $heightTrimmed = $heightInput.Trim()
        $isHeightInteger = [int]::TryParse($heightTrimmed, [ref]$null)
        if (-not $isHeightInteger) {
            [System.Windows.Forms.MessageBox]::Show("Invalid input. Please enter a valid integer for height.", "Invalid Input", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            continue
        }

        # Both inputs are valid integers
        $width = [int]$widthTrimmed
        $height = [int]$heightTrimmed
        break
    }

    try {
        $displayPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\display"

        Show-DebugMessage -Message "Ensuring registry path: $displayPath"
        # Ensure the display registry path exists
        Ensure-RegistryPath -Path $displayPath

        # Set web-client-max-head-resolution string
        $resolutionValue = "($width,$height)"
        New-ItemProperty -Path $displayPath -Name "web-client-max-head-resolution" -Value $resolutionValue -PropertyType String -Force | Out-Null
        Show-DebugMessage -Message "Set 'web-client-max-head-resolution' to '$resolutionValue'."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Button 18: Set enable-yuv444-encoding
$buttons[17].Add_Click({
    Show-DebugMessage -Message "Set enable-yuv444-encoding button clicked."
    $options = @('always-on', 'always-off', 'default-on', 'default-off')

    # Create a form with ComboBox
    $formEncoding = New-Object System.Windows.Forms.Form
    $formEncoding.Text = "Set enable-yuv444-encoding"
    $formEncoding.Size = New-Object System.Drawing.Size(300, 150)
    $formEncoding.StartPosition = "CenterScreen"
    $formEncoding.FormBorderStyle = "FixedDialog"
    $formEncoding.MaximizeBox = $false
    $formEncoding.MinimizeBox = $false
    $formEncoding.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Select an option:"
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10,20)
    $formEncoding.Controls.Add($label)

    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.DropDownStyle = "DropDownList"
    $comboBox.Items.AddRange($options)
    $comboBox.Location = New-Object System.Drawing.Point(10,50)
    $comboBox.Width = 260
    $formEncoding.Controls.Add($comboBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(120,80)
    $okButton.Add_Click({
        if ($comboBox.SelectedItem -ne $null) {
            $formEncoding.DialogResult = "OK"
            $formEncoding.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("Please select an option.", "Input Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $formEncoding.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(200,80)
    $cancelButton.Add_Click({ $formEncoding.DialogResult = "Cancel"; $formEncoding.Close() })
    $formEncoding.Controls.Add($cancelButton)

    $result = $formEncoding.ShowDialog()
    if ($result -ne "OK") {
        return
    }

    $selectedOption = $comboBox.SelectedItem
    try {
        $displayPath = "Registry::HKEY_USERS\S-1-5-18\Software\GSettings\com\nicesoftware\dcv\display"

        Show-DebugMessage -Message "Ensuring registry path: $displayPath"
        # Ensure the display registry path exists
        Ensure-RegistryPath -Path $displayPath

        # Set enable-yuv444-encoding string with single quotes
        $encodingValue = "'$selectedOption'"
        New-ItemProperty -Path $displayPath -Name "enable-yuv444-encoding" -Value $encodingValue -PropertyType String -Force | Out-Null
        Show-DebugMessage -Message "Set 'enable-yuv444-encoding' to $encodingValue."

        Show-Warning
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# -------------------- Existing Button Handlers Continued --------------------
# Note: If there are more existing buttons beyond Button 15 and 18, you can continue adding their handlers here.

# Display the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
