(*


V1.3

TOFIX

FEATURES
- converts almost every field including estimated time
- converts tags to contexts

KNOWN ISSUES: 
(TODO)
- DOES NOT CONVERT THL:/// LINKS 

- all completed tasks from Inbox are moved to Miscellaneous
- there's no priority in Omnifocus so we just set flagged if priority is high (is 1)
- there are no tags in Omnifocus so the algorithm is as follows
1) All tags are converted to context
2) All tags are preserved in the task title
3) The first tag is assigned to the task as a contect
- if there was picture in notes, then it shows list of what wasn't converted and context is beging added
- repeating adds "repeating context" and message to the title, as there are no way to get repeating from THL


USAGE 
1) DELETE EVERYTHING FROM OmniFocus
2) If you don't want to convert completed tasks set completedCounted to false AND SET "show all Completed" in every view of THL

*)


set tst to {}
set exitNow to false
set exitMessage to "OK"
set thlImageSymbol to "￼" -- here's a hidden symbol
set containImages to {"1"}
set thlContexts to {}

set completedCounted to true


tell application "OmniFocus"
	set ofDoc to front document
	set ofTaskgroupParent to ofDoc -- to every section of ofDoc
	
	set ofInbox to inbox tree
	
	set repeatingContextProp to {name:"(THL) REPEATING"}
	set containsImagesContextProp to {name:"(THL) CONTAINED IMAGES"}
	set containsImagesAndRepeatingContextProp to {name:"(THL) REPEATING + CONTAINED IMAGES"}
	
	tell default document
		set repeatingContext to make new context with properties repeatingContextProp
		set containsImagesContext to make new context with properties containsImagesContextProp
		set containsImagesAndRepeatingContext to make new context with properties containsImagesAndRepeatingContextProp
	end tell
end tell

-- MAIN LOOP

tell application "The Hit List"
	--repeat with thlTaskgroup in inbox
	my addTasks(inbox, ofInbox, "task", "inbox")
	--end repeat
	repeat with thlTaskgroup in groups of (folders group)
		set thlTaskgroupName to name of thlTaskgroup
		if (thlTaskgroupName is not equal to "SYNC") then
			my addTasks(thlTaskgroup, ofTaskgroupParent, "folder", thlTaskgroupName)
		end if
	end repeat
end tell

to split(someText, delimiter)
	set AppleScript's text item delimiters to delimiter
	set someText to someText's text items
	set AppleScript's text item delimiters to {""} --> restore delimiters to default value
	return someText
end split

on addContextIfNeeded(tagName)
	global thlContexts
	set foundContext to true
	repeat with i from 1 to count thlContexts
		if (tagName is equal to myTagName of item i of thlContexts) then
			return myContext of item i of thlContexts
		end if
	end repeat
	tell application "OmniFocus"
		tell default document
			set newContext to make new context with properties {name:tagName}
		end tell
	end tell
	copy {myTagName:tagName, myContext:newContext} to the end of thlContexts
	return newContext
end addContextIfNeeded

on extractContexts(nm, contextMarker)
	global thlContexts
	set firstRun to true
	set firstContext to missing value
	set skipFirst to false
	if (nm contains contextMarker) then
		set splitter to space & contextMarker
		set thlTags to split(nm, splitter)
		if ((count of thlTags) > 1) then
			if (character 1 of nm is not equal to contextMarker) then
				set skipFirst to true
			end if
			repeat with i from 1 to count thlTags
				if ((skipFirst and i > 1) or (not skipFirst)) then
					set thlTag to thlTags's item i
					set thlTag to item 1 of split(thlTag, space)
					try -- the character count may be zero
						if (character 1 of thlTag is equal to contextMarker) then
							set thlTag to (characters 2 thru end of thlTag) as string
						end if
					end try
					set ofContext to addContextIfNeeded(thlTag)
					if (firstRun) then
						set firstContext to ofContext
						set firstRun to false
					end if
				end if
			end repeat
		else
			if (character 1 of nm is equal to contextMarker) then
				set thlTag to item 1 of split(nm, space)
				try -- the character count may be zero
					set thlTag to (characters 2 thru end of thlTag) as string
				end try
				set ofContext to addContextIfNeeded(thlTag)
				set firstContext to ofContext
			end if
		end if
	end if
	return firstContext
end extractContexts

on createInboxTask(ofTaskProp)
	tell application "OmniFocus"
		tell first document
			set ofTask to make inbox task with properties ofTaskProp
			return ofTask
		end tell
	end tell
end createInboxTask

on addTask(thlTask, ofParent, thlPath)
	global exitNow
	global exitMessage
	global thlImageSymbol
	global containImages
	global repeatingContext
	global containsImagesContext
	global containsImagesAndRepeatingContext
	global thlContexts
	set isThereAnImage to false
	global completedCounted
	using terms from application "The Hit List"
		set nm to timing task of thlTask
		if (nm is equal to "test") then
			-- set exitNow to true
		end if
		set cd to completed date of thlTask
		set dd to due date of thlTask
		set sd to start date of thlTask
		set actt to actual time of thlTask
		set compl to completed of thlTask
		set canc to canceled of thlTask
		set pr to priority of thlTask
		set rp to repeating of thlTask
		set rep to repeating of thlTask
		set nt to notes of thlTask
		set estim to estimated time of thlTask
		if (estim is not missing value) then
			set estim to estim / 60
		end if
		if (nt contains thlImageSymbol) then
			copy thlPath & " -> " & timing task of thlTask to the end of containImages
			set isThereAnImage to true
			set nm to nm & " (THL) CONTAINED IMAGES"
		end if
		-- now find tags
		set cont to missing value
		set cont to extractContexts(nm, "@")
		set tempCont to extractContexts(nm, "/")
		if (cont is missing value) then
			set cont to tempCont
		end if
	end using terms from
	set ofTaskProp to {name:nm}
	using terms from application "OmniFocus"
		if cd is not missing value then set ofTaskProp to ofTaskProp & {completion date:cd}
		if dd is not missing value then set ofTaskProp to ofTaskProp & {due date:dd}
		if sd is not missing value then set ofTaskProp to ofTaskProp & {defer date:sd}
		if (estim is not missing value and estim > 0) then set ofTaskProp to ofTaskProp & {estimated minutes:estim}
		if (compl is not missing value and compl is true) then set ofTaskProp to ofTaskProp & {completed:true}
		if nt is not missing value then set ofTaskProp to ofTaskProp & {note:nt}
		if (rep) then
			set name of ofTaskProp to name of ofTaskProp & " (THL) REPEATING"
			if (isThereAnImage) then
				set cont to containsImagesAndRepeatingContext
			else
				set cont to repeatingContext
			end if
		else
			if (isThereAnImage) then
				set cont to containsImagesContext
			end if
		end if
		if (cont is not missing value) then
			set ofTaskProp to ofTaskProp & {context:cont}
		end if
		-- ??? if sd is not missing value then set ofTaskProp to ofTaskProp & {start date:sd}
		-- ??? if canc is not missing value then set ofTaskProp to ofTaskProp & {completion date:compl}
		-- ??? if pr is not missing value then set ofTaskProp to ofTaskProp & {completion date:compl}
		--!!!! if repeating is not missing value then set ofTaskProp to ofTaskProp & {completion date:compl}
		if ((pr is not missing value) and (pr is 1)) then set ofTaskProp to ofTaskProp & {flagged:true}
		if (not compl or completedCounted) then
			--display dialog "add FINAL: " & nm
			if (ofParent is inbox tree) then
				set ofTask to createInboxTask(ofTaskProp)
			else
				tell ofParent
					set ofTask to make new task with properties ofTaskProp
				end tell
			end if
		end if
	end using terms from
	return ofTask
end addTask

on addTasks(thlTaskgroup, ofTaskgroupParent, what, thlPath)
	global exitNow
	global exitMessage
	global completedCounted
	if exitNow then return
	---	global tst
	global ofDoc
	-- first check if it's not smart folder
	using terms from application "The Hit List"
		if (not (class of thlTaskgroup is smart folder)) then
			set smartFolder to false
		else
			set smartFolder to true
		end if
	end using terms from
	-- if it's task full of tasks
	if (what is equal to "task") then
		using terms from application "The Hit List"
			
			set thlTasks to tasks of thlTaskgroup
			repeat with thlTask in thlTasks
				--display dialog "add 1: " & timing task of thlTask
				if (completed of thlTask is false or completedCounted) then
					set ofTask to addTask(thlTask, ofTaskgroupParent, thlPath)
				end if
				try
					set thlTasks to tasks of thlTask
				on error errorStr number errorNumber
					set thlTasks to missing value
				end try
				if (thlTasks is not missing value) then
					addTasks(thlTask, ofTask, "task", "") -- thlPath & " -> " & name of thlTaskgroup)
				end if
			end repeat
		end using terms from
	end if
	-- if it's project
	if (what is equal to "project") then
		set ofTaskProperties to {name:name of thlTaskgroup}
		using terms from application "OmniFocus"
			tell ofTaskgroupParent
				set ofProject to make new project with properties ofTaskProperties
			end tell
		end using terms from
		using terms from application "The Hit List"
			set thlTasks to tasks of thlTaskgroup
			-- display dialog "PROJECT: " & name of thlTaskgroup & ": " & (count of thlTasks)
		end using terms from
		repeat with thlTask in thlTasks
			try
				set compl to completed of thlTask
			on error
				set compl to false
			end try
			if (compl is missing value) then
				set compl to false
			end if
			if (compl is false or completedCounted) then
				set ofTask to addTask(thlTask, ofProject, thlPath)
			end if
			using terms from application "The Hit List"
				--display dialog "add 2: " & timing task of thlTask
				try
					set thlTasks to tasks of thlTask
				on error errorStr number errorNumber
					set thlTasks to missing value
				end try
				if (thlTasks is not missing value) then
					addTasks(thlTask, ofTask, "task", "") --, thlPath & " -> " & name of thlTaskgroup)
				end if
			end using terms from
		end repeat
	end if
	-- if it's folder
	if (what is equal to "folder") then
		if (not smartFolder) then
			set ofTaskProperties to {name:name of thlTaskgroup}
			using terms from application "OmniFocus"
				tell ofTaskgroupParent
					set ofFolder to make new folder with properties ofTaskProperties
				end tell
			end using terms from
			
			using terms from application "The Hit List"
				(*try
					set thlFolders to folders of thlTaskgroup
				on error errorStr number errorNumber
					set thlFolders to missing value
				end try*)
				
				try
					set thlLists to lists of thlTaskgroup
				on error errorStr number errorNumber
					set thlLists to missing value
				end try
				
				(*if (thlFolders is not missing value) then
					repeat with thlSubfolder in thlFolders
						addTasks(thlSubfolder, ofFolder, "folder")
					end repeat
				end if*)
				
				if (thlLists is not missing value) then
					repeat with thlSublist in thlLists
						if (class of thlSublist is folder) then
							addTasks(thlSublist, ofFolder, "folder", "") --thlPath & " -> " & timing task of thlTaskgroup)
						end if
						if (class of thlSublist is list) then
							addTasks(thlSublist, ofFolder, "project", "") --thlPath & " -> " & name of thlTaskgroup)
						end if
					end repeat
				end if
			end using terms from
			--		repeat with thlList 
		end if -- not smart folder
	end if -- folder
end addTasks

display dialog "SCRIPT OK. Don't forget to select all trees and run Expand all notes script"

"ATTENTION!!! THE FOLLOWING NOTE BLOCKS CONTAIN IMAGES, YOU MUST COPY THEM MANUALLY: "
containImages
"FOUND CONTEXTS"
thlContexts
