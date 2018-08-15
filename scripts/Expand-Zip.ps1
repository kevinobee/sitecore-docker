[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    $FileName,
    [Parameter(Mandatory = $true)]
    $OutputDir,
    [Parameter(Mandatory = $true)]
    $Regex
)
Add-Type -Assembly System.IO.Compression.FileSystem
$FileName = Resolve-Path "$FileName"
# #extract list entries for dir myzipdir/c/ into myzipdir.zip
$zip = [IO.Compression.ZipFile]::OpenRead("$FileName")
$entries=$zip.Entries | Where-Object {
    $_.FullName -match "$Regex"
} 

# #create dir for result of extraction
New-Item -ItemType Directory -Path "$OutputDir" -Force

# #extraction
$entries | ForEach-Object {
    $target = Join-Path -Path "$OutputDir" -ChildPath $_.Name
    if(-not (Test-Path $target)){
        [IO.Compression.ZipFileExtensions]::ExtractToFile( $_, "$target") 
    }
}

# #free object
$zip.Dispose()
