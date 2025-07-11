function Prompt-Direction {
    param($port)
    do {
        Write-Host "Enter mirroring direction for source port $port (ingress, egress, bidirectional): " -ForegroundColor DarkCyan -NoNewline
        $dir = Read-Host
    } while ($dir -notin @('ingress', 'egress', 'bidirectional'))
    return $dir
}

function Prompt-YesNo {
    param($prompt)
    do {
        Write-Host "$prompt (y/n): " -ForegroundColor DarkCyan -NoNewline
        $answer = Read-Host
        $valid = $answer -match '^(y|n)$'
        if (-not $valid) {
            Write-Host "Please enter 'y' or 'n'." -ForegroundColor Yellow
        }
    } while (-not $valid)
    return $answer -eq 'y'
}

# Show banner
Clear-Host
$line1 = '     L U M I N E X   N E T W O R K   I N T E L L I G E N C E'
$line2 = '         A P I   P O R T   M I R R O R I N G   T O O L'
Write-Host ""
Write-Host $line1 -ForegroundColor DarkBlue
Write-Host $line2 -ForegroundColor DarkBlue
Write-Host ""

# Step 1: Prompt for inputs
Write-Host "Enter the switch IP address (e.g. 192.168.1.1): " -ForegroundColor DarkCyan -NoNewline
$ip = Read-Host
Write-Host "Enter session number (1 to 4): " -ForegroundColor DarkCyan -NoNewline
$session = Read-Host
Write-Host "Enter the destination port number: " -ForegroundColor DarkCyan -NoNewline
$destinationPort = Read-Host
[int]$destinationPort = $destinationPort

# Step 2: Collect source ports
$sourcePorts = @()
do {
    Write-Host "Enter a source port number (or leave blank to finish): " -ForegroundColor DarkCyan -NoNewline
    $srcPortInput = Read-Host
    if (![string]::IsNullOrWhiteSpace($srcPortInput)) {
        [int]$srcPort = $srcPortInput
        if ($srcPort -eq $destinationPort) {
            Write-Host "ERROR: Source port cannot be the same as destination port ($destinationPort)." -ForegroundColor Red
        } elseif ($sourcePorts.port -contains $srcPort) {
            Write-Host "WARNING: Port $srcPort is already in the source list." -ForegroundColor Yellow
        } else {
            $direction = Prompt-Direction -port $srcPort
            $sourcePorts += @{
                port = $srcPort
                mirror = $true
                direction = $direction
            }
        }
    }
} while ($srcPortInput)

# Step 3: CPU mirroring option
$mirrorCPU = Prompt-YesNo "Do you want to mirror the CPU?"
if ($mirrorCPU) {
    $cpuDirection = Prompt-Direction -port "CPU"
    $cpuSettings = @{
        mirror = $true
        direction = $cpuDirection
    }
} else {
    $cpuSettings = @{
        mirror = $false
        direction = "bidirectional"
    }
}

# Step 4: Build enable payload
$bodyEnable = @{
    session = [int]$session
    enabled = $true
    destination = @{ port = $destinationPort }
    source = @{
        ports = $sourcePorts
        cpu = $cpuSettings
    }
}

# Step 5: Send enable request
$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}
$uri = "http://$ip/api/port_mirror/session"
$payloadEnable = $bodyEnable | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $payloadEnable
    Write-Host ""
    Write-Host "Mirroring is now active for session $session." -ForegroundColor Green

    Write-Host ""
    Write-Host "Active Configuration:" -ForegroundColor Cyan
    Write-Host "  Destination port: $destinationPort"
    foreach ($src in $sourcePorts) {
        Write-Host "  Source port $($src.port): $($src.direction)"
    }
    if ($cpuSettings.mirror) {
        Write-Host "  CPU: $($cpuSettings.direction)"
    }

} catch {
    Write-Host ""
    Write-Host "Error enabling mirroring!" -ForegroundColor Red
    Write-Host ("Details: " + $_.Exception.Message) -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host ("Details: " + $_.ErrorDetails.Message) -ForegroundColor Red
    }
    Read-Host "Press Enter to exit..."
    exit
}

# Step 6: Wait for user input
Read-Host "`nPress Enter to disable mirroring..."

# Step 7: Disable mirroring
$sourcePortsDisabled = @()
foreach ($item in $sourcePorts) {
    $sourcePortsDisabled += @{
        port = $item.port
        mirror = $false
        direction = $item.direction
    }
}

$cpuDisabled = @{
    mirror = $false
    direction = $cpuSettings.direction
}

$bodyDisable = @{
    session = [int]$session
    enabled = $false
    destination = @{ port = $destinationPort }
    source = @{
        ports = $sourcePortsDisabled
        cpu = $cpuDisabled
    }
}
$payloadDisable = $bodyDisable | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri $uri -Method PUT -Headers $headers -Body $payloadDisable
    Write-Host ""
    Write-Host "Mirroring disabled for session $session." -ForegroundColor Yellow
} catch {
    Write-Host ""
    Write-Host "Failed to disable mirroring!" -ForegroundColor Red
    Write-Host ("Details: " + $_.Exception.Message) -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host ("Details: " + $_.ErrorDetails.Message) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
