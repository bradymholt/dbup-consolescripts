<# Package Manager Console scripts to support DbUp #>

function New-Migration {
  param (
    [string] $Name,
    [string] $Encoding = ""
  )
  _New-Migration-Private -isDynamic 0 -Name $Name -Encoding $Encoding
}

# Adds a migration file on disk but - doesn't add this in VS project 
# This function is usable when we have a dynamic creation of Scripts in csproj - example below
# <!-- Include all scripts from Scripts Folder -->
# <Target Name="BeforeBuild">  
#	<ItemGroup>
#		<EmbeddedResource Include="Scripts\*.sql"/>
#	</ItemGroup>
#  </Target> 

 function New-Migration-Dynamic {
  param (
    [string] $Name,
    [string] $Encoding = ""
  )

  _New-Migration-Private -isDynamic 1 -Name $Name -Encoding $Encoding
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

  If($outputPath.IndexOf("netcoreapp") -ge 0) {
	$projectCmd = $projectDirectory + "\" + $outputPath + $outputAssemblyName + ".dll"
	dotnet $projectCmd $args
  }
  Else {
    $projectExe = $projectDirectory + "\" + $outputPath + $outputAssemblyName + ".exe"
    & $projectExe $args
  }
}
 

function _New-Migration-Private{
  param (
    [bool] $isDynamic,
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
   if($isDynamic -eq $False){
       try
       {
          $targetProjectItem = $project.ProjectItems.Item($scriptsDirectoryName)
       }
       catch
       {
          $project.ProjectItems.AddFolder($scriptsDirectoryName) | Out-Null
          $targetProjectItem = $project.ProjectItems.Item($scriptsDirectoryName)
       }
   }   

   If ($name -ne ""){
      $fileNameBase = $fileNameBase + "_" + $Name
   }

   $fileNameBase = $fileNameBase.Replace(" ","_")
   $fileName = $fileNameBase + ".sql"
   $filePath = $scriptDirectory + "\" + $fileName

   New-Item -path $scriptDirectory -name $fileName -type "file" | Out-Null
   try
   {
      "/* Migration Script ${fileName} */" | Out-File -Encoding $Encoding -FilePath $filePath
   }
   catch
   {
      "/* Migration Script ${fileName} */" | Out-File -Encoding ascii -FilePath $filePath
   }
   if($isDynamic -eq $False){
        $targetProjectItem.ProjectItems.AddFromFile($filePath) | Out-Null
        $item = $targetProjectItem.ProjectItems.Item($fileName) 
        $item.Properties.Item("BuildAction").Value = [int]3 #Embedded Resource
   }
   Write-Host "Created new migration: ${filePath}"
   $dte.ExecuteCommand("File.OpenFile", $filePath)

}

Export-ModuleMember -Function New-Migration,New-Migration-Dynamic,Start-Migrations

