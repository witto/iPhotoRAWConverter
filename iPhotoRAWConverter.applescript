-- hubionmac.com 2009-09-27
-- converts selected images in iPhoto 
-- (format PNG,TIFF,JPEG),
-- resizes them (place 0 as new width to get orig. size)
-- imports them into iphoto
-- copies info like date, name, rating to new converted version
-- tested with Mac OS 10.6 and iPhoto 8.1
-- Original script here: http://hubionmac.com/wordpress/2009/11/iphoto-raw2sonstwas-converter/#

tell application "iPhoto"
	--Get selected images
	set myPhotos to selection
	--init some lists
	set newfiles to {}
	set newfiles_record to {}
	--make a new album for the converted images
	set myAlbum to my set_Album((do shell script "date '+Converted at %Y-%m-%d %H:%M:%S'"))
	--Loop through each image
	repeat with p in myPhotos
		--make a unique string, so images are not overwritten
		set current_time_md5 to "hubionmac_iphoto_temp_" & (do shell script "date | md5")
		-- now this is 2 in 1 line
		-- first it converts the current image 
		--second it stores the converted image's path in a list
		set newfiles to newfiles & {(my convert_image((POSIX file (image path of p)) as alias, (POSIX file ("/tmp/") & current_time_md5) as string, 1024, "JPEG"))}
		--this is an info record so later on the converted image gets the same informations (name, date, rating, etc)
		set newfiles_record to newfiles_record & {{new_name:current_time_md5, l:(latitude of p), ll:(longitude of p), myComment:(comment of p), myName:(name of p), myTitle:(title of p), myRating:(rating of p), mydate:(date of p)}}
		--label the orig_image, by adding _was_converted to the image's name
		if name of p does not end with "_was_converted" then
			set name of p to name of p & "_was_converted"
		end if
	end repeat
	-- import all converted images into iphoto in a new album
	import from newfiles to album myAlbum
	-- do-nothing-loop until iPhoto imported all images....
	repeat until (importing) is false
		delay 5
	end repeat
	-- copy infos like name, date, rating to the corresponding "new" image....
	my post_process(newfiles_record, myAlbum)
end tell
on post_process(newfiles_record, myAlbum)
	repeat with r in newfiles_record
		tell application "iPhoto"
			set a to photo ((new_name of r) as text) of album myAlbum
			set latitude of a to (l of r)
			set longitude of a to (ll of r)
			set comment of a to (myComment of r)
			set name of a to (myName of r) & "_converted"
			set title of a to (myTitle of r)
			set rating of a to (myRating of r)
			set date of a to (mydate of r)
		end tell
	end repeat
	do shell script "rm /tmp/hubionmac_iphoto_temp_*"
	
end post_process
on convert_image(image_file, target_path, target_width, target_format)
	tell application "Image Events"
		launch
		-- open the image file
		set this_image to open image_file
		if target_width > 0 then
			copy dimensions of this_image to {current_width, current_height}
			
			if current_width is greater than current_height then
				scale this_image to size target_width
			else
				set new_height to (target_width * current_width) / current_height
				scale this_image to size new_height
				
			end if
		end if
		if target_format = "PNG" then
			set target_path to target_path & "." & target_format
			save this_image in target_path as PNG
		else if target_format = "JPEG" then
			set target_path to target_path & "." & target_format
			save this_image in target_path as JPEG
		else if target_format = "JPEG2" then
			set target_path to target_path & ".JPEG"
			save this_image in target_path as JPEG2
		else if target_format = "TIFF" then
			set target_path to target_path & "." & target_format
			save this_image in target_path as TIFF
		end if
	end tell
	return target_path as alias
	
end convert_image
on set_Album(albumname)
	tell application "iPhoto"
		if album albumname exists then
			return albumname
		else
			new album name albumname
			return albumname
		end if
	end tell
end set_Album