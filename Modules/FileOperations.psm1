Function Open-Item {
    [cmdletbinding()]
    param([Parameter()]
        [switch]
        $Recurse,

        [Parameter()]
        [string]
        $Filter = '*.*',

        [Parameter()]
        [string]
        $Path = $(Get-Location).Path
    )

    $result = (ls -Path $Path -Recurse:$Recurse -Filter $Filter | Select FullName, Attributes, LastAccessTimeUtc | ogv -PassThru).FullName

    if ($result -ne $null) {
        ii $result
    }
}               # end of Function Open-Item

Function Get-FolderSize {
    <#
.SYNOPSIS
Get-FolderSize will recursively search all files and folders at a given path to show the total size

.DESCRIPTION
Get-FolderSize accepts a file path through the Path parameter and then recursively searches the directory in order to calculate the overall file size.
The size is displayed in GB, MB, or KB depending on the Unit selected, defaults to GB.  Will accept Multiple paths.

.EXAMPLE
Get-FolderSize -path C:\users\Someuser\Desktop

Returns the size of the desktop folder in Gigabytes

.EXAMPLE
Get-FolderSize -path \\Server\Share\Folder, c:\custom\folder -unit MB

Returns the size of the folders, \\Server\Share\Folder and C:\Custom\Folder, in Megabytes

#>
    [CmdletBinding()]
    Param
    (
        # Enter the path to the target folder
        [Parameter(
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            Mandatory = $true,
            HelpMessage = 'Enter the path to the target folder'
        )]
        [Alias("Fullname")]
        [ValidateScript( { Test-Path $_ })]
        [String[]]$Path,
        # Set the unit of measure for the function, defaults to GB, acceptable values are GB, MB, and KB
        [Parameter(
            HelpMessage = "Set the unit of measure for the function, defaults to GB, acceptable values are GB, MB, and KB")]
        [ValidateSet('GB', 'MB', 'KB')]
        [String]$Unit = 'GB'
    )
    Begin {
        Write-Verbose "Setting unit of measure"
        $value = Switch ($Unit) {
            'GB' { 1GB }
            'MB' { 1MB }
            'KB' { 1KB }
        }
    }
    Process {
        Foreach ($FilePath in $Path) {
            Try {
                Write-Verbose "Collecting Foldersize"
                $Size = Get-ChildItem $FilePath -Force -Recurse -ErrorAction Stop | Measure-Object -Property length -Sum
            }
            Catch {
                Write-Warning $_.Exception.Message
                $Problem = $True
            }
            If (-not($Problem)) {
                Try {
                    Write-Verbose "Creating Object"
                    New-Object -TypeName PSObject -Property @{
                        FolderName = $FilePath
                        FolderSize = "$([math]::Round(($size.sum / $value), 2)) $($unit.toupper())"
                    }
                }
                Catch {
                    Write-Warning $_.Exception.Message
                    $Problem = $True
                }
            }
            if ($Problem) { $Problem = $false }
        }
    }
    End { }
}         # end of Function Get-FolderSize

Function Get-InstantAccess() {
    <#
    .Synopsis
       Searches the files in given locations using wildcards filter and returns enumerated list.
    .DESCRIPTION
       This function helps to navigate and interact with search results automatically opening
       files in their default programms.
    .PARAMETER Path
       Path Parameter can denote single path or an array of them.
    .PARAMETER FileFilter
       FileFilter parameter uses wildcards to create search pattern for the files.
    .PARAMETER Recurse
       Recurse is a switch parameter that is used to denote recursive directories search.
    .INPUTS
       After the search is completed give the number denoting the location of the file
       on the list. The file will be opened in a default program.
    .OUTPUTS
       [System.Object] with enumerated list of search results.
    .EXAMPLE
       Find all pdf files recursivelly from current location.
       Get-InstantAccess -FileFilter *.pdf -Recurse
    .EXAMPLE
       Find all pdf files from two paths refursivelly.
       Get-InstantAccess -Path $HOME, G:\Dokumenty -FileFilter *.pdf -Recurse
    #>
    [cmdletbinding()]
    param(
        [string[]]$Path = $(Get-Location).Path,
        [string]$FileFilter = "*.*",
        [switch]$Recurse
    )
    Begin {
        $files = ls -Path $Path -File -Recurse:$Recurse -Filter $FileFilter
    }

    Process {
        for ($i = 1; $i -lt $files.Length; $i++) {
            Write-Host $i $files[$i].FullName
        }

        $fileNumber = Read-Host -Prompt 'Input File Number'

        if ($fileNumber -gt $files.Count) {
            Write-Error "File number outside of scope" -ErrorAction Stop
        }
        ii $files[$fileNumber].FullName
    }

    End {
    }
}      # end of Function Get-InstantAccess

Function Open-ItemFromGrid() {
    <#
    .Synopsis
       Searches the files in given locations using wildcards filter and returns enumerated list.
    .DESCRIPTION
       This function helps to navigate and interact with search results automatically opening
       files in their default programms.
    .PARAMETER Path
       Path Parameter can denote single path or an array of them.
    .PARAMETER FileFilter
       FileFilter parameter uses wildcards to create search pattern for the files.
    .PARAMETER Recurse
       Recurse is a switch parameter that is used to denote recursive directories search.
    .INPUTS
       After the search is completed give the number denoting the location of the file
       on the list. The file will be opened in a default program.
    .OUTPUTS
       [System.Object] with enumerated list of search results.
    .EXAMPLE
       Find all pdf files recursivelly from current location.
       Get-InstantAccess -FileFilter *.pdf -Recurse
    .EXAMPLE
       Find all pdf files from two paths refursivelly.
       Get-InstantAccess -Path $HOME, G:\Dokumenty -FileFilter *.pdf -Recurse
    #>
    [cmdletbinding()]
    param(
        [string[]]$Path = $(Get-Location).Path,
        [string]$FileFilter = "*.*",
        [switch]$Recurse
    )
    Begin {
        $files = ls -Path $Path -File -Recurse:$Recurse -Filter $FileFilter
    }

    Process {
        (ls $Path | ogv -PassThru) | ii
    }

    End {
    }
}      # end of Function Get-InstantAccess

Function Copy-CurrentPath() {
    $executionContext.SessionState.Path.CurrentLocation.Path | clip
}       # end of Function Copy-CurrentPath

Function Get-ProcessWithTitle() {
    [cmdletbinding()]
    Param(
        [string]$Process = "*",
        [string]$WindowTitle = "*"
    )

    ps $Process | Where-Object { $_.MainWindowTitle -like $WindowTitle } | Select-Object -Property Id, ProcessName, MainWindowTitle
    Write-Verbose "Getting processes for process: $Process with MainWindowTitle of: $WindowTitle"

}  # end of Function Get-ProcessWithTitle

Function Get-DefaultApp() {
    [CmdletBinding()]
    param
    (
        [string]$Extension
    )

    try {
        $default = (Get-ItemProperty -Path "HKLM:\Software\Classes\.$Extension" -Name '(Default)' -ErrorAction Stop).'(Default)'

        (Get-ItemProperty "HKLM:\Software\Classes\$default\shell\open\command" -Name '(Default)' -ErrorAction Stop).'(Default)' -match
        '([^"^\s]+)\s*|"([^"]+)"\s*' | Out-Null
        $path = $matches[0].ToString()

        Write-Verbose "Getting default app for $Extension"

        $path.Trim('"', ' ')
    }
    catch {
        Write-Error "An application path was not found for the filetype '.$Extension'."
    }
}         # end of Function Get-DefaultApp

function Add-Reminder {
    <#
.Synopsis
Creates a scheduled task that will display a reminder.
.Description
Creates a scheduled task that will display a reminder.
.Parameter Time
Time when the reminder should be displayed.
.Parameter Reminder
Message of the reminder.
.Example
Add-Reminder -Reminder  "Clean Kitchen" -time "1/1/2016 12:00 PM"
This example will remind you to clean your kitchen on 1/1/2016 at 12:00 PM
#>
    Param(
        [string]$Reminder,
        [datetime]$Time
    )
    $Task = New-ScheduledTaskAction -Execute msg -Argument "* $Reminder"
    $trigger = New-ScheduledTaskTrigger -Once -At $Time
    $Random = (Get-random)
    Register-ScheduledTask -Action $task -Trigger $trigger -TaskName "Reminder_$Random" -Description "Reminder"
}

Function Start-FileSystemWatcher {

    $FileSystemWatcherParams = @{

        Path         = 'D:\dev\azure\azure-arch-resources'

        Recurse      = $False

        NotifyFilter = 'FileName'

        Verbose      = $True

        Action       = {

            $Item = Get-Item $Event.SourceEventArgs.FullPath

            $WriteHostParams = @{

                ForegroundColor = 'Green'

                BackgroundColor = 'Black'

            }

            Switch  -regex ($Item.Extension) {

                '\.(png|jpg|gif)' {
                    $WriteHostParams.Object = "Processing  print screen files: $($Item.Name)"
                }

                '\.(xmind)' { $WriteHostParams.Object = "Processing  mind map: $($Item.Name)" }

                Default { $WriteHostParams.Object = "Processing  File: $($Item.Name)" }

            }

            git add $Item.Name
            git commit -m "Adding" + $Item.Name
            git push

            Write-Host  @WriteHostParams

        }

    }
    @('Created') | ForEach {

        $FileSystemWatcherParams.EventName = $_

        Start-FileSystemWatcher  @FileSystemWatcherParams

    }
}


New-Alias -Name gfoz        -Value Get-FolderSize
New-Alias -Name cop         -Value Copy-CurrentPath
New-Alias -Name proc        -Value Get-ProcessWithTitle
New-Alias -Name gap         -Value Get-DefaultApp
New-Alias -Name ils         -Value Get-InstantAccess
New-Alias -Name open        -Value Open-Item
New-Alias -Name remind      -Value Add-Reminder


Export-Modulemember -Alias * -Function *
