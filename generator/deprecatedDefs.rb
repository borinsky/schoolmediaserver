def generateFachIndexes
	$faecher.each do |fach|
		@links = getFileOfFach(fach)
		@webpage = pasteLinksInIndexpage(@links)
		writeIndexPage($webverzeichnis+"index."+fach[0]+".html", @webpage)
	end
end


def generateKlassenIndexes
	@content = loadIndexTemplate
	$klassen.each { |klasse| writeIndexPage($webverzeichnis+"index."+klasse.to_s+".html", @content)}
end


def generateIndexPages
	generateFachIndexes
	generateKlassenIndexes
end

def getFileOfFach(fach)
	@links=[]
	@listOfFiles = []
	@filelist = getListOfTXTFiles
  @filelist.each  { |file| @listOfFiles.push(file[3..-5]) if file[0..1] == fach[0]}
  @listOfFiles.each { |file| @links.push(buildLink(fach, file))}
	return @links
end



# => buildSiteMap


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
