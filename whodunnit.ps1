﻿

# Structures 
class Log_Struct {
    [Array]$Application
    [Array]$HardwareEvents
    [Array]$InternetExplorer
    [Array]$KeyManagement
    [Array]$OAlerts
    [Array]$Security
    [Array]$System
    [Array]$WindowsAzure
    [Array]$WindowsPowershell
    [bool]$loaded = $false
}

class Filter_Struct {
    [System.Collections.ArrayList]$Usernames
    [datetime]$TimeStart
    [datetime]$TimeEnd
    [System.Collections.ArrayList]$EventCodes
    [System.Collections.ArrayList]$EventTypes
    [System.Collections.ArrayList]$EventSources
    [Log_Struct]$MatchingLogs
    [bool]$loaded
}

# Functions
class Menu_Functions {
    
    [void]Write_Menu_Main($menu) {

        $UserInput = 0
        $Logs = [Log_Struct]::new()
        $Filter = [Filter_Struct]::new()

        do {

            Clear-Host
            Write-Host "============================="
            Write-Host "          Whodunnit"
            Write-Host "============================="
            Write-Host
            Write-Host "1) Load Logs"
            Write-Host "2) Active Filter"
            Write-Host "3) Display Logs"
            Write-Host "4) Export Logs"
            Write-Host

    
            $UserInput = Read-Host "whodunnit> "
        
            switch($UserInput) {
                '1' {$Logs = $menu.Write_Menu_Load($Logs)}
                '2' {$Filter = Write-Menu-Filter($Filter, $Logs)}
                '3' {Show-Log-Stats}
                '4' {Export_Logs($Logs)}
            }
    
        } until ($UserInput -ne "1" -and $UserInput -ne "2" -and $UserInput -ne "3" -and $UserInput -ne "4")

    }

    [Log_Struct]Write_Menu_Load($Logs) {
        
        $UserInput = 0
        $load = [Load_Functions]::new()

        do {

            Clear-Host
            Write-Host "============================="
            Write-Host "      Whodunnit > Load"
            Write-Host "============================="
            Write-Host
            Write-Host "1) Read From File"
            Write-Host "2) Read From Local Machine"
            Write-Host "3) Read From Remote Machine [NI]"
            Write-Host "4) Back"
            Write-Host
    
        
            $UserInput = Read-Host "whodunnit> load> "
            
            switch($UserInput) {
                '1' {Return $load.Import_Logs($Logs)}
                '2' {Return $load.Read_From_Local(($Logs)}
                '3' {Return $Logs}
                '4' {Return $Logs}
            }
        
        } until ($UserInput -ne "1" -and $UserInput -ne "2" -and $UserInput -ne "3" -and $UserInput -ne "4")
    
        return $Logs
    }

    [Filter_Struct]Write_Menu_Filter($Filter, $Logs) {
        
        $UserInput = 0

        do {

            Clear-Host
            Write-Host "============================="
            Write-Host "     Whodunnit > Filter "
            Write-Host "============================="
            Write-Host
            Write-Host "1) Load Filter"
            Write-Host "2) Edit Filter"
            Write-Host "3) Export Filter"
            Write-Host "4) Apply"
            Write-Host "5) Back"
            Write-Host

        
            $UserInput = Read-Host "whodunnit> filter>"
            
            switch($UserInput) {
                '3' {Export_Filter($Filter)}
                '1' {$Filter = Import-Filter($Filter)}
                '2' {$Filter = Write-Lame-Menu-Filter-Edit($Filter)}
                '4' {$Filter = Apply-Filter($Filter, $Logs)}
            }
        
        } until ($UserInput -ne "1" -and $UserInput -ne "2" -and $UserInput -ne "3" -and $UserInput -ne "4")

        Return $Filter
    }

    [Filter_Struct]Write_Menu_Edit($Filter) {
        
        $UserInput = 0
        $Bak = $Filter

        do {

            Clear-Host
            Write-Host "============================="
            Write-Host "  Whodunnit > Filter > Edit"
            Write-Host "============================="
            Write-Host
            Write-Host "1) Username"
            Write-Host "2) Time Window"
            Write-Host "3) Event Codes"
            Write-Host "4) Event Types"
            Write-Host "5) Event Sources"
            Write-Host "6) Save"
            Write-Host "7) Cancel"
            Write-Host
    
        
            $UserInput = Read-Host "whodunnit> filter> edit> "
            
            switch($UserInput) {
                '1' {$Filter.Username = Edit-Filter-User($Filter.Username)}
                '2' {$Filter = Edit-Filter-Time($Filter)}
                '3' {$Filter.EventCodes = Edit-Filter-EventCodes($Filter.EventCodes)}
                '4' {$Filter.EventTypes = Edit-Filter-EventTypes($Filter.EventTypes)}
                '5' {$Filter.EventSources = Edit-Filter-EventSources($Filter.EventSources)}
                '6' {Return $Filter}
                '7' {Return $Bak}
            }
        
        } until ($UserInput -ne "1" -and $UserInput -ne "2" -and $UserInput -ne "3" -and $UserInput -ne "4" -and $UserInput -ne "5" -and $UserInput -ne "6" -and $UserInput -ne "7")

        Write-Host
        $UserInput = Read-Host "Save Changes? [(y)/n]> "

        if ($UserInput.ToLower() -eq "n") {Return $Bak}
        Return $Filter
    }
}

class Load_Functions {
    
    <# Reads in logs from a previously exported logset #>
    [Log_Struct]Import_Logs($Logs) {
        
        if ($Logs.loaded) {
            Write-Host "Logs are already loaded!"
            $UserInput = Read-Host "Overwrite? [y/N]> "
            
            if ($UserInput.ToLower() -ne "y" -and $UserInput.ToLower() -ne "yes") {Return $Logs}
        } 

        Return Import-Clixml -LiteralPath (Read-Host "whodunnit> load> import path> ")
    }

    <# Reads in logs from the local machine #>
    [Log_Struct]Read_From_Local($Logs) {

        # Prevent Overwrites
        if ($Logs.loaded) {
            Write-Host "Logs are already loaded!"
            $UserInput = Read-Host "Overwrite? [y/N]> "
            
            if ($UserInput.ToLower() -ne "y" -and $UserInput.ToLower() -ne "yes") {Return $Logs}
        }

        $LogTypes = "Application", "HardwareEvents", "Internet Explorer", "Key Management Service", "OAlerts", "System", "Windows Azure", "Windows PowerShell", "Security"

        # Loop executes for every log type
        for ($i = 0; $i -lt $LogTypes.Length; $i++) {

            $LogType = $LogTypes[$i]
            $Count = $i + 1

            # Display Progress
            Write-Progress  -Activity "Loading Event Logs from Local Host" `
                        -Status "$Count of 9" `
                        -CurrentOperation "Loading $LogType Logs" `
                        -PercentComplete ($Count / 9 * 100) `
                        -Id 1
            
            # Check Perms on security logs
            if ($LogType -eq "Security") {

                $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
                
                if (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                    Write-Host "Warning! Insignificant priviledges to load security logs!"
                    Continue
                }
            }

            # If no logs, skip the call to set. Prevents error message.
            if ((Get-EventLog -List | Where-Object Log -eq $LogType).Entries.Count -eq 0) {Continue}

            # Sets the appropriate list to the contents of the log list
            $Logs.($LogType.ToString().Remove(" ")) = Get-EventLog -LogName $LogType 

        }

        $Logs.loaded = $true
        Write-Progress -Activity "Loading Event Logs from Local Host" -Id 1 -Completed
        Return $Logs

    }

}

class Export_Functions {

    <# Exports Logs as an xml object. very space intensive. #>
    <# ROADMAP: Issue #2 #>
    [bool]Export_Logs($Logs) {
            
        if ($Logs.loaded -eq $false) {
            Read-Host "Error: No logs are loaded"
            Return $false
        }

        $UserInput = Read-Host "whodunnit> Export Path> "

        try {
            Export-Clixml -LiteralPath $UserInput -InputObject $Logs
        }
        catch {
            Read-Host "Error: Encountered Problem Writing File"
            Return $false
        }
        
        Return $true

    }
}

class Filter_Functions {

    <# Exports a filter as an xml object. #>
    [bool]Export_Filter($Filter) {

        $UserInput = Read-Host "whodunnit> filter> export path> "

        try {
            Export-Clixml -LiteralPath $UserInput -InputObject $Filter
        }
        catch {
            Read-Host "Error Encountered Problem Writing File"
            Return $false
        }

        Return $true

    }

    <# Imports a filter from an exported xml. #>
    [Filter_Struct]Import_Filter($Filter) {

        if ($Filter.loaded) {
            Write-Host "A filter is already loaded!"
            $UserInput = Read-Host "Overwrite? [y/N]> "

            if ($UserInput.ToLower() -ne "y" -and $UserInput.ToLower() -ne "yes") {Return $Filter}
        }

        Return Import-Clixml -LiteralPath (Read-Host "whodunnit> filter> import path> ")
    }
}

$menu = New-Object -TypeName Menu_Functions
$menu.write_menu_main($menu)