<# Package Manager Console scripts to support Database Migrations

   This file is located in the \SolutionScripts folder and is auto-loaded into the Package Manager Console (PCM)
   by the SolutionScripts package (http://www.nuget.org/packages/solutionscripts) when the solution is opened.

   If any changes are made to this file, you need to run 'Update-SolutionScripts' from the PCM
   to allow the changes to take effect.
#>

function New-Migration {
	param (
		[string] $Name,
		[switch] $JournalOnly,
		[string] $ProjectName = "FTDNA.Database"
	)

   $project = Get-DatabaseProject $ProjectName
   $projectDirectory = Split-Path $project.FullName
   $scriptDirectory = $projectDirectory + "\Migrations"
   $fileNameBase = (Get-Date -UFormat "%y%m%d%H%M%S")
 
   #Get reference to Migrations project item
   $targetProjectItem = $null
   try
   {
		$targetProjectItem = $project.ProjectItems.Item("Migrations")
   }
   catch
   {
		$project.ProjectItems.AddFolder("Migrations") | Out-Null
		$targetProjectItem = $project.ProjectItems.Item("Migrations")
   }   

   #If Git branch name is available, change target project item to Migrations\[GitBranch] (nested folder)
   $gitBranch = Get-Branch
   if ($gitBranch -ne $null){
	   try
	   {
			$targetProjectItem = $targetProjectItem.ProjectItems.Item($gitBranch)
	   }
	   catch
	   {
			$targetProjectItem.ProjectItems.AddFolder($gitBranch) | Out-Null
			$targetProjectItem = $targetProjectItem.ProjectItems.Item($gitBranch)
	   }   

	   $scriptDirectory = $scriptDirectory + "\" + $gitBranch 
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
   $item.Properties.Item("BuildAction").Value = [int]2 #Content
   $item.Properties.Item("CopyToOutputDirectory").Value = [int]2 #Copy if newer
   Write-Host "Created new migration: ${fileName}"

   if ($JournalOnly.IsPresent){
        Start-Migrations -JournalOnly -ScriptFile $fileName
   }
}

function Start-Migrations {
    param (
     [switch] $WhatIf,
     [switch] $JournalOnly,
     [string] $ScriptFile,
	 [string] $ProjectName = "FTDNA.Database"
    )

	$project = Get-DatabaseProject $ProjectName
	Write-Host "Building..."
	$dte.Solution.SolutionBuild.BuildProject("Release", $project.FullName, $true)
	$projectDirectory = Split-Path $project.FullName
    
    $args = " --scriptDefinitions"

    if ($Whatif.IsPresent){
        $args = $args + " --whatif"
    }

    if ($JournalOnly.IsPresent){
        $args = $args + " --journalOnly"
    }

    if ($ScriptFile -ne $null){
        $args = $args + " --file=" + $ScriptFile
    }

	$projectExe = $projectDirectory + "\bin\Release\" + $project.Name + ".exe" + $args
	iex $projectExe
 }

 function Start-DatabaseScript {
  param (
	 [string] $ProjectName = "FTDNA.Database"
    )

	$project = Get-DatabaseProject $ProjectName
	Write-Host "Building..."
	$dte.Solution.SolutionBuild.BuildProject("Release", $project.FullName, $true)
	$projectDirectory = Split-Path $project.FullName
	$projectExe = $projectDirectory + "\bin\Release\" + $project.Name + ".exe" + " --scriptAllDefinitions"
	Write-Host "Scripting..."
	iex $projectExe
 }

function Get-Branch {
	$branch = $null
	if(Test-Path .git) {
     try{
			 git branch | foreach {
			  if ($_ -match "^\* (.*)"){
			   $branch += $matches[1]
			  }
			}
		}
	  catch {
		 $branch = $null
	  }
     }

     return $branch
}

function Get-DatabaseProject {
	param (
	 [string] $ProjectName
    )

  $project = Get-Project

  if ($project.Name -ne $ProjectName) {
    Get-Project -All | ForEach-Object -Process { 
      if ($_.Name -eq $ProjectName) {
         $project = $_  
      }
    }
  }
  return $project
}