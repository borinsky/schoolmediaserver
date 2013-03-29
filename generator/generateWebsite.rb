#!/usr/bin/env ruby -w
require 'yaml'
require 'fileutils'
require 'digest/md5'

# configs - Global
# prefix@proklos
PREFIX="/Volumes/proklos/Users/cb/schoolmediaserver"

$quellen = PREFIX+"/sources/"
$webverzeichnis = PREFIX+"/www/"
$generaterroot= PREFIX+"/generator/"

$templatefile = PREFIX+"/generator/template-video.html"
$templateindex = PREFIX+"/generator/template-index.html"
$templateindexall = PREFIX+"/generator/template-index-all.html"
$cssfile = PREFIX+"/generator/style.css"

$build_all = true

# Variablen in der Webseite
$header				= "Lernvideos Grundschule Nadorst"
$footer 			= "(c) Grundschule Nadorst"
$navigation		= ""
$klasse 			= ""
$fach 				= ""
$thema 				= ""
$beschreibung = ""
$videourl			= ""
$aufgaben			= ""
$nextvideo 		= ""

$klassen = ["klasse1", "klasse2", "klasse3", "klasse4"]
$faecher = [["de", "Deutsch"], ["ma", "Mathe"], ["su", "Sachunterricht"]]



def checkCSSandJavascript
	FileUtils.cp $generaterroot+"style.css", $webverzeichnis+"style.css" if !File.exist?($webverzeichnis+'styles.css')
	FileUtils.cp $generaterroot+"jquery.js", $webverzeichnis+"jquery.js" if !File.exist?($webverzeichnis+'jquery.js')
	FileUtils.cp $generaterroot+"animation.js", $webverzeichnis+"animation.js" if !File.exist?($webverzeichnis+'animation.js')
end

#-------------------
#  build Indexpage
# ------------------

def generateIndexForAll
	@indexpage =	loadTemplate($templateindexall)
	@indexpage =  setHeaderAndFooter(@indexpage)
	@indexpage =  pasteLinks4All(@indexpage)
	writePage($webverzeichnis+"index.html", @indexpage)		
end

def loadTemplate(filename)
	@template = IO.readlines(filename).map(&:chomp)
	return @template
end

def setHeaderAndFooter(website)
	website.each do |line|
		line.replace($header) if line.include?("#HEADER#")
		line.replace($footer) if line.include?("#FOOTER#")
	end
end

def pasteLinks4All(filename)
	@indexpage = filename
	@filelist = getListOfTXTFiles
	$faecher.each do |fach|
		@listOfFiles = selectFach(fach[0], @filelist)
		@placeholder = "#LINKS_"+fach[0].upcase
		@linkString = ""		
		@listOfFiles.each do |file|
			@linkString += buildLink(fach, file)
		end
		@indexpage = pasteLinksInIndex4All(@placeholder, @linkString, @indexpage)
	end
	return @indexpage
end

def getListOfTXTFiles
	Dir.chdir($quellen)
	@filelist = Dir.glob("*.txt")
	return @filelist
end

def selectFach(fach, filelist)
	# Fach must be: de,ma,su,en
	# first 2 char of file is shortcut4subject
	@list = []
	filelist.each {|file| @list.push(file) if file[0..1]==fach}
	return @list
end

def buildLink(fach, filename)
	@url 				=	fach[0]+"."+filename[3..-5]+".html"
  @linkname 	=	getLinktext(filename)+"</br>"
	@link = "\t\t<a href=\""+@url+"\">"+@linkname+"</a>\n"
	return @link
end

def getLinktext(filename)
	@linktext = filename[0..-5]
	@lines = IO.readlines($quellen+filename).map(&:chomp)
  @lines.each { |line| @linktext = line.split(':')[1] if line.split(':')[0] =="linktext"}
	return @linktext.strip
end

def pasteLinksInIndexpage(listOfLinks)
  @listOfLinksString = ""
	@webpage	=	loadTemplate($templateindex)
	@webpage.each do |line|
      if line.include?("#LINKS#")
	    	listOfLinks.each { |link| @listOfLinksString = @listOfLinksString + link}
	    	line.replace(@listOfLinksString) end
	end
	@webpage = setHeaderAndFooter(@webpage)
	return @webpage
end

def pasteLinksInIndex4All(placeholder, links, webpage)
	@webpage = webpage
	@placeholder = placeholder
	@links = links
	@webpage.each {|line| line.replace(@links) if line.include?(@placeholder)}
	return @webpage
end

def writePage(filename, content)
	File.open(filename, 'w') {|f| content.each { |line| f.write(line+"\n") }}
end

#-------------------------------
# build Videopages
#-------------------------------

def buildVideoPages
	@files = checkForNewVideos
	@files.each do |file|
		FileUtils.cp $quellen+file, $webverzeichnis if file[-3,3]=='mp4'
		template=loadTemplate($templatefile) 				if file[-3,3]=='txt'
  	generateVideopage(template, file) 					if file[-3,3]=='txt'
  	puts "Build Website from  "+file
	end
	writeMD5FileData
end

def checkForNewVideos
		@listOfChanges = []
		@currentMD5s = getMD5FileData
		@oldMD5s = readMD5Values
		@newFiles=@currentMD5s-@oldMD5s
	  @newFiles.each { |file| @listOfChanges.push(file[0])}
	  @currentMD5s.each do |file|
		   @listOfChanges.push(file[0]) if !File.exist?($webverzeichnis+file[0][0..-4]+"html")
		   @listOfChanges.push(file[0]) if !File.exist?($webverzeichnis+file[0][0..-4]+"mp4")
		end
		return @listOfChanges
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

def getListOfFiles
	Dir.chdir($quellen)
	@filelist = Dir.glob("*")
	return @filelist
end

def readMD5Values
	if File.exist?($webverzeichnis+"md5sum")
		@MD5s = YAML.load_file($webverzeichnis+"md5sum")
		@MD5s.sort
	else
		@MD5s = []
	end
	return @MD5s.to_a.sort
end

def generateVideopage (template, filename)
	@filename = filename
	@template = template
	@data 		= getDataAndVideoUrl(@filename)
	@website 	= pasteDateInTemplate(@template, @data)
	writeWebPage(@filename, @website)
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
  # duplicate with writeinde
  @filename = $webverzeichnis+File.basename(filename)[0..-4]+"html"
  File.open(@filename, 'w') {|f| content.each { |line| f.write(line+"\n") }}
	@videofile = File.basename(filename)[0..-4]+"mp4"
	FileUtils.cp $quellen+@videofile, $webverzeichnis if !File.exist?($webverzeichnis+@videofile)
end

def writeMD5FileData
	@md5sums = getMD5FileData
	f = File.open($webverzeichnis+"md5sum","w")
	@md5sums.each { |file| f.puts(file[0]+": "+file[1])}
end

def main
  FileUtils.rm_r Dir.glob($webverzeichnis+'*.*') if $build_all
  checkCSSandJavascript
  generateIndexForAll
  buildVideoPages
  puts "Well done!"
end

main