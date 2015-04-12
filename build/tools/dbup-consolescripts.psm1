<# Package Manager Console scripts to support DbUp #>

function New-Migration {
  param (
    [string] $Name
  )

   $project = Get-Project
   $projectDirectory = Split-Path $project.FullName
   $scriptsDirectoryName = "Scripts"
   $scriptDirectory = $projectDirectory + "\" +  $scriptsDirectoryName 
   $fileNameBase = (Get-Date -UFormat "%y%m%d%H%M%S")
 
   #Get reference to Scripts project item
   $targetProjectItem = $null
   
   try
   {
      $targetProjectItem = $project.ProjectItems.Item($scriptsDirectoryName)
   }
   catch
   {
      $project.ProjectItems.AddFolder($scriptsDirectoryName) | Out-Null
      $targetProjectItem = $project.ProjectItems.Item($scriptsDirectoryName)
   }   

   If ($name -ne ""){
      $fileNameBase = $fileNameBase + "_" + $Name
   }

   $fileNameBase = $fileNameBase.Replace(" ","")
   $fileName = $fileNameBase + ".sql"
   $filePath = $scriptDirectory + "\" + $fileName

   New-Item -path $scriptDirectory -name $fileName -type "file" -value "/* Migration Script */" | Out-Null
   $targetProjectItem.ProjectItems.AddFromFile($filePath) | Out-Null
   $item = $targetProjectItem.ProjectItems.Item($fileName) 
   $item.Properties.Item("BuildAction").Value = [int]3 #Embedded Resource
   Write-Host "Created new migration: ${fileName}"
}

function Start-Migrations {
  param (
    [switch] $WhatIf
  )

  $project = Get-Project
  Write-Host "Building..."
  $dte.Solution.SolutionBuild.BuildProject("Debug", $project.FullName, $true)
  $projectDirectory = Split-Path $project.FullName
    
    $args = " --fromconsole"

    if ($Whatif.IsPresent){
        $args = $args + " --whatif"
    }

  $projectExe = $projectDirectory + "\bin\Debug\" + $project.Name + ".exe" + $args
  iex $projectExe
 }