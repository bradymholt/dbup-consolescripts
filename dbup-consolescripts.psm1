<# Package Manager Console scripts to support DbUp #>

function New-Migration {
  param (
    [string] $Name,
    [string] $Encoding = ""
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

   New-Item -path $scriptDirectory -name $fileName -type "file" | Out-Null
   try
   {
      "/* Migration Script */" | Out-File -Encoding $Encoding -FilePath $filePath
   }
   catch
   {
      "/* Migration Script */" | Out-File -Encoding ascii -FilePath $filePath
   }
   $targetProjectItem.ProjectItems.AddFromFile($filePath) | Out-Null
   $item = $targetProjectItem.ProjectItems.Item($fileName) 
   $item.Properties.Item("BuildAction").Value = [int]3 #Embedded Resource
   Write-Host "Created new migration: ${fileName}"
   $dte.ExecuteCommand("File.OpenFile", $scriptsDirectoryName + "\" + $fileName)
}

function Start-Migrations {
  param (
    [switch] $WhatIf
  )

  $project = Get-Project
  $outputPath = $project.ConfigurationManager.ActiveConfiguration.Properties.Item("OutputPath").Value
  $activeConfiguration = $dte.Solution.SolutionBuild.ActiveConfiguration.Name  

  Write-Host "Building..."
  $dte.Solution.SolutionBuild.BuildProject($activeConfiguration, $project.FullName, $true)

  $outputAssemblyName = $project.Properties.Item("AssemblyName").Value

  $projectDirectory = Split-Path $project.FullName
    
    $args = " --fromconsole"

    if ($Whatif.IsPresent){
        $args = $args + " --whatif"
    }

  $projectExe = $projectDirectory + "\" + $outputPath + $outputAssemblyName + ".exe"
  & $projectExe $args
 }
