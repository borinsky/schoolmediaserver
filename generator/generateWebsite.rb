#!/usr/bin/env ruby -w
require 'yaml'
require 'fileutils'
require 'digest/md5'

# configs
# prefix@proklos
PREFIX="/Volumes/proklos/Users/cb/schoolmediaserver"

$quellen = PREFIX+"/sources/"
$webverzeichnis = PREFIX+"/www/"
$generaterroot= PREFIX+"/generator/"

$templatefile = PREFIX+"/generator/template.html"
$cssfile = PREFIX+"/generator/style.css"

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
	return @data
end

def getListOfTXTFiles
	Dir.chdir($quellen)
	@filelist = Dir.glob("*.txt")
	return @filelist
end

def getListOfFiles
	Dir.chdir($quellen)
	@filelist = Dir.glob("*")
	return @filelist
end

def generateWebpage (template, filename)
	@filename = filename
	@template = template
	@data 		= getDataAndVideoUrl(@filename)
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
 	FileUtils.cp $generaterroot+"style.css", $webverzeichnis+"style.css" if !File.exist?($webverzeichnis+'styles.css')
  @filename = $webverzeichnis+File.basename(filename)[0..-4]+"html"
  File.open(@filename, 'w') {|f| content.each { |line| f.write(line+"\n") }}
	@videofile = File.basename(filename)[0..-4]+"mp4"
	FileUtils.cp $quellen+@videofile, $webverzeichnis if !File.exist?($webverzeichnis+@videofile)
end


def getMD5FileData
	@md5list = []
	@filelist = getListOfFiles
	@filelist.each do |filename|
		md5value =  Digest::MD5.file($quellen+filename)
		@md5list.push([filename, md5value.to_s])
	end
	return @md5list
end

def writeMD5FileData
	@md5sums = getMD5FileData
	f = File.open($webverzeichnis+"md5sum","w")
	@md5sums.each {|file| f.puts(file[0]+": "+file[1])}
end

def readMD5Values
	@MD5s = YAML.load_file($webverzeichnis+"md5sum")
	return @MD5s
end

def checkForNewVideos
		@listOfChanges = []
		@currentMD5s = getMD5FileData.sort
		@oldMD5s = readMD5Values.to_a.sort
		@newFiles=@currentMD5s-@oldMD5s
	  @newFiles.each { |file| @listOfChanges.push(file[0])}
	  @currentMD5s.each do |file|
		   @listOfChanges.push(file[0]) if !File.exist?($webverzeichnis+file[0][0..-4]+"html")
		   @listOfChanges.push(file[0]) if !File.exist?($webverzeichnis+file[0][0..-4]+"mp4")
		end
		return @listOfChanges
end


def buildWebsite
	@files = checkForNewVideos
	@files.each do |file|
		FileUtils.cp $quellen+file, $webverzeichnis if file[-3,3]=='mp4'
		template=loadTemplate 											if file[-3,3]=='txt'
  	generateWebpage(template, file) 						if file[-3,3]=='txt'
  	puts "Build Website from  "+file
	end
	writeMD5FileData
end


def buildSiteMap
	@liste = getListOfTXTFiles
	puts @liste
end



@buildWebsite
buildSiteMap


#listOfNewFile = []
#aktuelle_md5werte = getMD5FileData
#oldmd5werte = IO.read($webverzeichnis+"md5sum")

#puts oldmd5werte.inspect


# FileUtils.rm_r Dir.glob($webverzeichnis+'*.*')
#files = getListOfTXTFiles
#files.each do |file|
#	template=loadTemplate
#	generateWebsite(template, file)
#end
#@md5sums = getMD5FileData
#   IO.write($webverzeichnis+"md5sum", @md5sums)