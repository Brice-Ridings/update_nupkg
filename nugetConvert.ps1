# Iterate Nuget packages, Unzip, include new repository url in nuspec, zip, review and confirm push to github. 

param(
    [Parameter(Mandatory=$true)][string]$sourceDirectory,
    [Parameter(Mandatory=$true)][string]$repository
)

Write-Host "Updating Nuget packages with repository " $repository 

$workingDirectory = "$sourceDirectory\convert"
$tempDirectory = "$workingDirectory\temp"
$extractDirectory = "$tempDirectory\extracts"

If (Test-Path $workingDirectory){
    Remove-Item -path $workingDirectory -Recurse -Force
}

Write-Host "Working Directory is $workingDirectory"
New-Item -Path $sourceDirectory -Name "convert" -Type "directory" -Force
New-Item -Path $workingDirectory -Name "temp" -Type "directory" -Force
New-Item -Path $tempDirectory -Name "extracts" -Type "directory" -Force


# Read each Nuget Package name and List 
Get-ChildItem "$sourceDirectory\*.nupkg" -Recurse | % {
    $fileName = $_.Name
    $baseName = $_.BaseName
    $nupkgPath = "$tempDirectory\$fileName"

    # Copy File to Working Directory
    Copy-Item -Path $_.FullName -Destination $tempDirectory -force

    # Rename .nupkg to .zip 
    $newName = "$baseName.zip"
    Rename-Item $nupkgPath $newName -force
    Write-Host $newName

    # Extract Files 
    $zipPath = "$tempDirectory\$newName"
    $extractPath = "$extractDirectory\$basename"
    Expand-Archive -Path $zipPath -Destination $extractPath

    # Add <repository> field to nuspec
    [xml] $nuspec = Get-Content "$extractPath\*.nuspec"
    Write-Host "Appending <Repository> node as $repository"

    $repositoryNode = $nuspec.CreateNode("element", "repository", "")
    $repositoryAttr = $repositoryNode.OwnerDocument.CreateAttribute("url")
    $repositoryAttr.Value = $repository
    $repositoryNode.Attributes.Append($repositoryAttr)
    $nuspec.package.metadata.AppendChild($repositoryNode)

    # Save File
    $nuspec.save((Resolve-Path "$extractPath\*.nuspec"))

    # Compress Package
    Write-Host $extractPath
    Write-Host $workingDirectory
    Compress-Archive -Path $extractPath -DestinationPath "$workingDirectory\$newName"

    # Rename to include .nuget exe
    Rename-Item "$workingDirectory/$newName" $_.Name

    Write-Host "Saving $workingDirectory/$newName"
}
