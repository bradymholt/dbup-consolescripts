# DbUp Package Manager Console Scripts
Package Manager Console scripts for [DbUp](http://dbup.github.io/).

## Install
    Install-Package dbup-consolescripts

## Commands
- **New-Migration [Name]** - Create a new migration .sql file in the \Scripts folder of the current project and marks it as an *Embedded Resource*.  Uses the timestamped name format %y%m%d%H%M%S.sql (i.e. 150411194108.sql for 04/11/2015 7:41:08 PM).  Optionally, specify a [Name] which will be appended to the file name.
- **Start-Migrations** - Runs any pending migrations by building and running the current project.  With the recommended DbUp configuration, simply running the application will execute pending migrations.

