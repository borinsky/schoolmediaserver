#!/usr/bin/env ruby -w
require 'yaml'
require 'fileutils'

# configs
$quellen = "../sources"
$webverzeichnis = "../www"

$templatefile = "template.html"
$cssfile = "style.css"

build_all = true

# Variablen in der Webseite
$header				= "Mediaserver Lernvideos Grundschule Nadorst"
$footer 			= "by Grundschule Nadorst"
$navigation		= ""
$klasse 			= ""
$fach 				= ""
$thema 				= ""
$beschreibung = ""
$videourl			= ""
$aufgaben			= ""
$nextvideo 		= ""

def loadTemplate
	@template = IO.readlines($templatefile).map(&:chomp)
	return @template
end

def getDataAndVideoUrl(filename)
	@data = YAML.load_file(filename)
	#-------------------------------------
	# Add header an footer as globalvar
	#------------------------------------
	@data["footer"]			= $footer			if !@data["footer"]
	@data["header"] 		= $header			if !@data["header"]
	@data["aufgaben"] 	= $aufgaben 	if !@data["aufgaben"]
	@data["nextvideo"] 	= $nextvideo	if !@data["nextvideo"]
	#--------------------------------------
	# Check if Videoexist
	#--------------------------------------
	mp4url = filename[0..-5]+".mp4"
	oggurl = filename[0..-5]+".ogg"
	@data["videourl"] = "found no (mp4/ogg) video"
	@data["videourl"] = mp4url if File.exist?(mp4url)
	@data["videourl"] = oggurl if File.exist?(oggurl)
	puts @data
	return @data
end

def generateNavigation
	
end

def generateHeader
	
end

def generateFooter
	
end

def generateWebsite (template, filename)
	@filename = filename
	@template = template
	@data 		= getDataAndVideoUrl(filename)
	@website 	= pasteDateInTemplate(@template, @data)
	writeWebPage(@filename, @website)
end

def pasteDateInTemplate(template, data)
	@data = data
	@webpage = template
	@data.each_key do |key|
		replaceStr = "#"+key.upcase+"#"
		@webpage.each do |line|
			if line.match(replaceStr)
				newline = line.sub(replaceStr, @data[key].to_s)
				line.replace(newline)
			end
		end
	end
	return @webpage
end

def writeWebPage(filename, content)
	### only 4 testing ###
	FileUtils.rm_r Dir.glob('../www/*.*')
	######################
  if !File.exist?("../www/styles.css")
	  FileUtils.cp './style.css', '../www/style.css'
	end
  @filename = "../www/"+File.basename(filename)[0..-4]+"html"
	File.open(@filename, 'w') {|f| content.each { |line| f.write(line+"\n") }}
end

def makeSHA1
	if FileTest.exist?("SHA1SUMS")
		exec('sha1sum * > newSHA1SUM')
	else
		exec('sha1sum * > SHA1SUMS')
	end
end

def checkForNewVideos
		#Build in not exist a hash-list of videos
		#Build an second list an compair
		#give back a lsit of new Video
		sums = IO.readlines("SHA1SUMS").map(&:chomp)
		newsums = IO.readlines("newSHA1SUM").map(&:chomp)
		puts "HALLO"
		puts sums.to_s
		puts newsums.to_s
end

$template=loadTemplate

@files = getListOfFiles

@files.each { |file| generateWebsite($template, file) }
 