#DbUp.ConsoleScripts
#Example usage: rake release[1.2.0,"Release notes here..."]

require 'albacore'
require 'date'
require 'net/http'
require 'openssl'

project_name = "DbUp.ConsoleScripts"
project_title = "DbUp Package Manager Console Scripts"
project_owner = "Brady Holt"
project_authors = "Brady Holt"
project_description = "Package Manager Console scripts for DbUp"
project_copyright = "Copyright #{DateTime.now.strftime('%Y')}"

task :package, [:version_number, :notes] do |t, args|
	desc "Download nuget.exe"
	uri = URI.parse("https://api.nuget.org/downloads/nuget.exe")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
	data = http.get(uri.request_uri)
	open("nuget.exe", "wb") { |file| file.write(data.body) }
	desc "create the nuget package"
	sh "nuget.exe pack build\\#{project_name}.nuspec -Properties \"version=#{args.version_number};title=#{project_title};owner=#{project_owner};authors=#{project_authors};description=#{project_description};notes=v#{args.version_number} - #{args.notes};copyright=#{project_copyright}\""
end

task :push, [:version_number, :notes] do |t, args|
	sh "nuget.exe push build\\#{project_name}.#{args.version_number}.nupkg"
end

task :tag, [:version_number, :notes] do |t, args|
	sh "git tag -a v#{args.version_number} -m \"#{args.notes}\""
	sh "git push --tags"
end

task :release, [:version_number, :notes] => [:package, :push, :tag] do |t, args|
	puts "v#{args.version_number} Released!"
end