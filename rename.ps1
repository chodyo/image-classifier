param (
    [string]$sourceDirectory,
    [string]$destinationDirectory,
    [int]$maxFilesToRename = -1  # Default to -1 to indicate no limit
)

if (-not $sourceDirectory -or -not $destinationDirectory) {
    Write-Host "Usage: rename.ps1 -sourceDirectory <source_path> -destinationDirectory <destination_path> [-maxFilesToRename <max_count>] [-Debug]"
    Exit
}

if (-not (Test-Path $sourceDirectory -PathType Container)) {
    Write-Host "Source directory does not exist or is not a valid directory path: $sourceDirectory"
    Exit
}

if (-not (Test-Path $destinationDirectory -PathType Container)) {
    Write-Host "Destination directory does not exist or is not a valid directory path: $destinationDirectory"
    Exit
}

# Get the list of files in the source directory
$files = Get-ChildItem $sourceDirectory

if ($maxFilesToRename -ne -1) {
    $files = $files | Select-Object -First $maxFilesToRename
}

foreach ($file in $files) {
    $fileName = $file.Name
    $newFileName = $fileName -replace '^\d+ - ', ''
    $counter = 1

    Write-Host "Processing $fileName"

    # Check if the new file name already exists in the destination directory
    while (Test-Path (Join-Path -Path $destinationDirectory -ChildPath $newFileName)) {
        $newFileName = $newFileName -replace '(.*?)(\..*)', "`$1_$counter`$2"
        $counter++
    }

    # Create the full path to the new file in the destination directory
    $newFilePath = Join-Path -Path $destinationDirectory -ChildPath $newFileName

    # Move the file to the destination directory with the new name
    Move-Item -Path $file.FullName -Destination $newFilePath

    # Output a debug-level log
    Write-Host "Renamed '$fileName' to '$newFilePath'"
}

Write-Host "Renaming and moving complete."
