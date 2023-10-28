# Given a directory structure as follows:

# $sourceDir/$method/$i

# Where $sourceDir contains:
# - any number of images
# - any number of $method subdirectories named after a variety of methods (such as "fileHashes", "fileSizes", ...)

# And where the $method subdirectories contain:
# - any number of $i subdirectories named after an iteration value (1, 203, 899, ...)

# And where the $i subdirectories contain:
# - a pair of files with two separate names that are duplicates of each other and copies of files in $sourceDir

# For example,

# ```
# dirA
#   dirB
#     dir2
#       img1
#       img5
#   dirC
#     dir7
#       img2
#       img3
#   img1
#   img2
#   img3
#   img4
#   img5
# ```

# This directory structure indicates that (img1, img5) are duplicates of each other, and (img2, img3) are duplicates of each other.

# Write a powershell script to deduplicate files out of "sourceDir". The script should take "sourceDir" and "dryrun" as a script param and:
# - prints help text and exits if sourceDir is not specified
# - errors if
#   - the sourceDir doesn't exist
#   - the sourceDir doesn't contain any "method" dirs
# - iterates through all sourceDir/method/i directories:
#     - logs and continues if
#         - sourceDir/method dirs don't contain any "i" dirs
#         - sourceDir/method/i dirs don't contain pairs of files
#   - gets the filename of one of the files in sourceDir/method/i and constructs a path from it: $sourceDir + $fileName
#   - confirms the constructed file path exists
#   - if dryrun:
#     - prints the constructed file path and sourceDir/method/i
#     - continue
#   - if not dryrun:
#     - deletes constructed file path
#     - deletes sourceDir/method/i

param(
    [string]$sourceDir,
    [switch]$dryrun
)

# Function to check if a directory contains duplicate files and perform deduplication
function Deduplicate-Directory($directory) {
    if (Test-Path $directory) {
        $files = Get-ChildItem $directory
        $fileHashes = @{}

        foreach ($file in $files) {
            $hash = Get-FileHash $file.FullName -Algorithm MD5
            $fileHash = $hash.Hash
            if ($fileHashes.ContainsKey($fileHash)) {
                if ($dryrun) {
                    Write-Host "Dry Run: Duplicate files found in $directory"
                    Write-Host "Duplicate files: $($file.Name), $($fileHashes[$fileHash].Name)"
                } else {
                    Write-Host "Deduplicating: Deleting $($file.Name) in $directory"
                    Remove-Item $file.FullName -Force
                }
            } else {
                $fileHashes[$fileHash] = $file
            }
        }
    }
}

# Check if sourceDir is specified
if ([string]::IsNullOrWhiteSpace($sourceDir)) {
    Write-Host "Please specify the source directory using -sourceDir parameter."
    exit
}

# Check if the sourceDir exists
if (-not (Test-Path $sourceDir -PathType Container)) {
    Write-Host "Source directory $sourceDir does not exist."
    exit
}

# Get the method directories in sourceDir
$methodDirs = Get-ChildItem $sourceDir | Where-Object { $_.PSIsContainer }

# Check if sourceDir contains any "method" directories
if ($methodDirs.Count -eq 0) {
    Write-Host "Source directory $sourceDir does not contain any 'method' directories."
    exit
}

foreach ($methodDir in $methodDirs) {
    # Get the "i" directories in each "method" directory
    $iDirs = Get-ChildItem $methodDir.FullName | Where-Object { $_.PSIsContainer }

    # Check if "method" directories don't contain any "i" directories
    if ($iDirs.Count -eq 0) {
        Write-Host "No 'i' directories found in $methodDir"
        continue
    }

    foreach ($iDir in $iDirs) {
        # Get one of the files in the "i" directory
        $files = Get-ChildItem $iDir.FullName

        # Check if "i" directories don't contain pairs of files
        if ($files.Count -ne 2) {
            Write-Host "Invalid number of files found in $iDir. Skipping."
            continue
        }

        # Construct the file path from one of the files in the "i" directory
        $constructedFilePath = Join-Path $sourceDir $files[0].Name

        # Confirm the constructed file path exists
        if (-not (Test-Path $constructedFilePath)) {
            Write-Host "Constructed file path $constructedFilePath does not exist. Skipping."
            continue
        }

        if ($dryrun) {
            $detectedPath = $files[0].FullName
            Write-Host "Dry Run: $constructedFilePath from $detectedPath in $iDir"
        } else {
            # Delete the constructed file path
            Remove-Item $constructedFilePath -Force

            # Delete the "i" directory
            Remove-Item $iDir.FullName -Force -Recurse
        }
    }
    exit # we need to make sure we don't dedupe the same file twice
}
