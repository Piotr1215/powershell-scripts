Function Get-GoogleSearch{
<#
.Synopsis
Searches the Googes
.DESCRIPTION
Lets you quickly start a search from within Powershell
.EXAMPLE
Search-Google Error code 5
--New google search results will open listing top entries for 'error code 5'

.EXAMPLE
search-google (gwmi win32_baseboard).Product maximum ram

If you need to get the maximum ram for your motherboard, you can even use this
type of syntax
#>
Begin
{
$query='https://www.google.com/search?q='
}
Process
{
if ($args.Count -eq 0)
{
"Args were empty, commiting `$input to `$args"
Set-Variable -Name args -Value (@($input) | % {$_})
"Args now equals $args"
$args = $args.Split()
}
ELSE
{
"Args had value, using them instead"
}

Write-Host $args.Count, "Arguments detected"
$nargs = -join 'powershell', $args
"Parsing out Arguments: $nargs"
for ($i=0;$i -le $nargs.Count;$i++){
$nargs | % {"Arg $i `t $_ `t Length `t" + $_.Length, " characters"} }

$nargs | % {$query = $query + "$_+"}

}
End
{
$url = $query.Substring(0,$query.Length-1)
"Final Search will be $url `nInvoking..."
start "$url"
}

}         # end of Function Get-GoogleSearch

Function Get-ImagesFromSearch(){
# script parameters
Param
(
      [string]$downloadFolder = "$(split-path $profile)\Images",

      [int]$nrOfImages = 12,

      [Parameter(Mandatory = $true, Position = 0)]
      [string]$searchFor
)


# create a WebClient instance that will handle Network communications 
$webClient = New-Object System.Net.WebClient

# load System.Web so we can use HttpUtility
Add-Type -AssemblyName System.Web

# URL encode our search query
$searchQuery = [System.Web.HttpUtility]::UrlEncode($searchFor)

$url = "http://www.bing.com/images/search?q=$searchQuery&first=0&count=$nrOfImages&qft=+filterui%3alicense-L2_L3_L4"

# get the HTML from resulting search response
$webpage = $webclient.DownloadString($url)

# use a 'fancy' regular expression to finds Urls terminating with '.jpg' or '.png'
$regex = "[(http(s)?):\/\/(www\.)?a-z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-z0-9@:%_\+.~#?&//=]*)((.jpg(\/)?)|(.png(\/)?)){1}(?!([\w\/]+))"

$listImgUrls = $webpage | Select-String -pattern $regex -Allmatches | ForEach-Object {$_.Matches} | Select-Object $_.Value -Unique

# let's figure out if the folder we will use to store the downloaded images already exists
if((Test-Path $downloadFolder) -eq $false) 
{
    Write-Output "Creating '$downloadFolder'..."

    New-Item -ItemType Directory -Path $downloadFolder | Out-Null
}


foreach($imgUrlString in $listImgUrls) 
{
    [Uri]$imgUri = New-Object System.Uri -ArgumentList $imgUrlString

    # this is a way to extract the image name from the Url
    $imgFile = [System.IO.Path]::GetFileName($imgUri.LocalPath)

    # build the full path to the target download location
    $imgSaveDestination = Join-Path $downloadFolder $imgFile

    Write-Output "Downloading '$imgUrlString' to '$imgSaveDestination'..."

    $webClient.DownloadFile($imgUri, $imgSaveDestination)    
}
}   # end of Function Get-ImagesFromSearch

Function Get-ServicesHTML(){
    [cmdletbinding()]
    param()

    $a = "<style>"
    $a = $a + "BODY{background-color:peachpuff;}"
    $a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
    $a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:PaleGoldenrod}"
    $a = $a + "</style>"

    $file = "Services$((Get-Date).Ticks).html"

    Get-Service | Select-Object Status, Name, DisplayName | 
    ConvertTo-HTML -head $a -body "<H2>Service Information</H2>" | 
    Out-File $docs\$file

    Invoke-Expression $docs\$file
}       # end of Function Get-ServicesHTML

New-Alias -Name sg   -Value Get-GoogleSearch       
New-Alias -Name sim  -Value Get-ImagesFromSearch   
New-Alias -Name sham -Value Get-ServicesHTML       

Export-ModuleMember -Alias * -Function *
