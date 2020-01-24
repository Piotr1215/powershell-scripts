Function Get-ProcessOnPort(){
    [cmdletbinding()]
    Param (
            [Parameter(Mandatory)]
            [string]
            $Port
          )
netstat -ano | findstr $Port | Select-String -Pattern "\d+$" -AllMatches |  % {$_.Matches } | foreach { tasklist |select-string -Pattern $_.Value } | Get-Unique
}

Function New-AngularProject(){
    [cmdletbinding()]
    Param (
            [Parameter(Mandatory)]
            [string]
            $Destination = "G:\DEV\$(Get-Date -Format o)_Angular2"
          )
    $referenceFiles = "G:\dev\Ang2ConfigFiles"
    md $Destination
    copy $referenceFiles\* -Recurse -Destination $Destination -Force
    code $Destination
}# end of Function New-AngularProject

Function Test-Connections(){
    [cmdletbinding()]
    Param (
            [string]$Subnet = "80.252.0.",
            [int]$Start  = 145,
            [int]$Stop   = 150
    )

    Write-Verbose "Pinging $Subnet from $Start to $Stop"

    $start..$stop | where { Test-Connection "$subnet$_" -Count 1 -Quiet } | % { "$subnet$_" }
}# end of Function Test-Connections

Function Start-GoogleMail(){
    [cmdletbinding()]
    param()

    start chrome -PassThru -ArgumentList 'googlemail.com',  --new-window
}# end of Function Start-GoogleMail

New-Alias -Name tc -Value Test-Connections -Force
New-Alias -Name mail -Value Start-GoogleMail -Force
New-Alias -Name ang2 -Value New-AngularProject -Force

Export-ModuleMember -Alias * -Function *