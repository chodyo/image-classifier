param (
    [string]$sourceDirectory,
    [string]$destinationDirectory,
    [string]$filenamePrefixFilter,
    [switch]$dryRun
)

if (-not $sourceDirectory -or -not $destinationDirectory -or -not $filenamePrefixFilter) {
    Write-Host "Usage: script.ps1 -sourceDirectory <source_path> -destinationDirectory <destination_path> -filenamePrefixFilter <prefix> [-dryRun]"
    Exit
}

if (-not (Test-Path $sourceDirectory -PathType Container)) {
    Write-Host "Source directory does not exist or is not a valid directory path: $sourceDirectory"
    Exit
}

# Create the destination directory if it doesn't exist
if (-not (Test-Path $destinationDirectory -PathType Container)) {
    Write-Host "Destination directory does not exist. Creating it..."
    New-Item -ItemType Directory -Path $destinationDirectory
}

# Get the list of zip files in the source directory matching the prefix filter
$zipFiles = Get-ChildItem $sourceDirectory -Filter "$filenamePrefixFilter*.zip"

foreach ($zipFile in $zipFiles) {

    $zipDestination = Join-Path -Path $destinationDirectory -ChildPath $zipFile.BaseName.Trim()
    $destinationPath = Join-Path -Path $destinationDirectory -ChildPath $zipFile.Name

    if (-not (Test-Path $zipDestination -PathType Container)) {
        New-Item -ItemType Directory -Path $zipDestination
    }

    Write-Host "Extracting contents of '$zipFile' to '$zipDestination'"

    Expand-Archive -Path $zipFile.FullName -DestinationPath $zipDestination -Force

    Write-Host "Extracted contents of '$zipFile' to '$zipDestination'"

    # Iterate over each file inside the zip archive
    $zipContents = Get-ChildItem $zipDestination -Recurse
    foreach ($zipContent in $zipContents) {
        $fileDestination = Join-Path -Path $destinationDirectory -ChildPath $zipContent.Name
        $counter = 1
        while (Test-Path $fileDestination) {
            # Handle filename collisions by generating a new name
            $newFileName = "{0}{1}{2}" -f $zipContent.BaseName, $counter, $zipContent.Extension
            $fileDestination = Join-Path -Path $destinationDirectory -ChildPath $newFileName
            $counter++
        }

        Move-Item -Path $zipContent.FullName -Destination $fileDestination
        Write-Host "Moved '$zipContent' to '$fileDestination'"
    }

    # Remove the empty directory created by Expand-Archive
    Remove-Item -Path $zipDestination -Force

    if ($dryRun) {
        Write-Host "Dry run mode enabled. Halting execution after extracting one zip archive from '$zipFile'."
        break
    }
}

Write-Host "Extraction complete."
