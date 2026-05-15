# CCBeep - Sound notifications for Claude Code events
# https://github.com/your-username/CCBeepp
#
# Native PowerShell version for Windows.
#
# Usage:
#   powershell -NoProfile -File ccbee.ps1 -Event prompt
#   powershell -NoProfile -File ccbee.ps1 -Event complete
#   powershell -NoProfile -File ccbee.ps1 -Event error
#   powershell -NoProfile -File ccbee.ps1 -Event stop   (reads stdin JSON)
#
# Hook integration (settings.json):
#   UserPromptSubmit → powershell -NoProfile -File "...\ccbee.ps1" -Event prompt
#   Notification     → powershell -NoProfile -File "...\ccbee.ps1" -Event complete
#   Stop             → powershell -NoProfile -File "...\ccbee.ps1" -Event stop

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("prompt", "complete", "error", "stop")]
    [string]$Event
)

function Play-Beep {
    param([int]$Frequency, [int]$Duration)
    try {
        [System.Console]::Beep($Frequency, $Duration)
    } catch {
        # Fallback: write BEL character
        Write-Host "`a" -NoNewline
    }
}

# Read stdin if Stop event (JSON from Claude Code)
$Reason = ""
if ($Event -eq "stop") {
    try {
        $inputJson = $input | Out-String
        if ($inputJson -match '"reason"\s*:\s*"(error|interrupted|failed)"') {
            $Reason = "error"
        } else {
            $Reason = "complete"
        }
    } catch {
        $Reason = "complete"
    }
    $Event = $Reason
}

switch ($Event) {
    "prompt" {
        # Short notification beep
        Play-Beep -Frequency 800 -Duration 200
    }
    "complete" {
        # Two ascending tones
        Play-Beep -Frequency 1000 -Duration 200
        Start-Sleep -Milliseconds 80
        Play-Beep -Frequency 1200 -Duration 300
    }
    "error" {
        # Low warning tone
        Play-Beep -Frequency 400 -Duration 500
    }
}
