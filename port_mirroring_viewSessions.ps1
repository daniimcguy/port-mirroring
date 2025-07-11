Clear-Host

# Banner
$line1 = '     L U M I N E X   N E T W O R K   I N T E L L I G E N C E'
$line2 = '        V I E W   P O R T   M I R R O R I N G   S T A T U S'
Write-Host ""
Write-Host $line1 -ForegroundColor DarkBlue
Write-Host $line2 -ForegroundColor DarkBlue
Write-Host ""

# Prompt for IP and session
Write-Host "Enter the switch IP address (e.g. 192.168.195.215): " -ForegroundColor DarkCyan -NoNewline
$ip = Read-Host

Write-Host "Enter session number to view (1-4 or 'all'): " -ForegroundColor DarkCyan -NoNewline
$sessionInput = Read-Host

# Determine session range
if ($sessionInput -eq 'all') {
    $sessions = 1..4
} elseif ($sessionInput -match '^[1-4]$') {
    $sessions = @([int]$sessionInput)
} else {
    Write-Host "Invalid session input. Must be 1-4 or 'all'." -ForegroundColor Red
    exit
}

# Set headers
$headers = @{
    "Accept" = "application/json"
}

# GET and display session info
foreach ($session in $sessions) {
    $url = "http://$ip/api/port_mirror/session/$session"
    Write-Host ""
    Write-Host "Session ${session}:" -ForegroundColor Cyan
    try {
        $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
        $response | ConvertTo-Json -Depth 5
    } catch {
        Write-Host "Failed to fetch session ${session}." -ForegroundColor Red
        Write-Host ("Details: " + $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
