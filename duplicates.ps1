param (
    [string]$sourceDirectory
)

if (-not $sourceDirectory) {
    Write-Host "Usage: script.ps1 -sourceDirectory <path>"
    Exit
}

if (-not (Test-Path $sourceDirectory -PathType Container)) {
    Write-Host "Source directory does not exist or is not a valid directory path: $sourceDirectory"
    Exit
}

function CopyFileToSubdirectory($currentPath, $subdirectory) {
    $destinationPath = Join-Path -Path $subdirectory -ChildPath (Split-Path -Leaf $currentPath)
    Copy-Item -Path $currentPath -Destination $destinationPath
}

function HandleDuplicate($file, $sourceDirectory, $category, [ref]$checkMap, $mapKey, $i) {
    if (!$checkMap.Value.ContainsKey($mapKey)) {
        $checkMap.Value[$mapKey] = $file.FullName
        return
    }
    $subDirectory = Join-Path -Path $sourceDirectory -ChildPath "$category\$i"
    if (-not (Test-Path $subDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $subDirectory
    }
    CopyFileToSubdirectory $checkMap.Value[$mapKey] $subdirectory
    CopyFileToSubdirectory $file.FullName $subdirectory
}

function PerformFileSizesCheck($file, $sourceDirectory, [ref]$fileSizes) {
    $fileSize = $file.Length
    HandleDuplicate $file $sourceDirectory "fileSizes" $fileSizes $fileSize $i
}

function PerformFileHashesCheck($file, $sourceDirectory, [ref]$fileHashes) {
    $fileContent = Get-FileHash -Path $file.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    HandleDuplicate $file $sourceDirectory "fileHashes" $fileHashes $fileContent $i
}

function PerformFileNamesWithoutExtensionCheck($file, $sourceDirectory, [ref]$fileNamesWithoutExtension) {
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    HandleDuplicate $file $sourceDirectory "fileNamesWithoutExtension" $fileNamesWithoutExtension $fileNameWithoutExtension $i
}

# Create subdirectories for each category of duplicate detection
$categories = @("fileSizes", "fileHashes", "fileNamesWithoutExtension")

foreach ($category in $categories) {
    $subDirectory = Join-Path -Path $sourceDirectory -ChildPath $category
    if (-not (Test-Path $subDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $subDirectory
    }
}

# Get the list of files (not directories) in the directory
$files = Get-ChildItem $sourceDirectory | Where-Object { -not $_.PSIsContainer }

$i = 1  # Initialize the iteration variable

# Define data structures to persist across iterations
$fileSizes = [System.Collections.Hashtable]::Synchronized(@{})
$fileHashes = [System.Collections.Hashtable]::Synchronized(@{})
$fileNamesWithoutExtension = [System.Collections.Hashtable]::Synchronized(@{})

# Loop through each file in the directory
foreach ($file in $files) {
    PerformFileSizesCheck $file $sourceDirectory ([ref]$fileSizes)
    PerformFileHashesCheck $file $sourceDirectory ([ref]$fileHashes)
    PerformFileNamesWithoutExtensionCheck $file $sourceDirectory ([ref]$fileNamesWithoutExtension)
    $i++  # Increment the iteration variable
}

Write-Host "Duplicate check and copy complete."
