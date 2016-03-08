--Original Concept & Written by John 'Joker' Martini
--https://www.jokermartini.com/
--Additional Code by Dave 'Max Made Easy' Wortley
--https://davewortley.wordpress.com/

taggerCA= attributes assetTags
(	
	parameters main rollout:params
	(
		BaseNode type:#maxObject
		TagInput type:#string ui:uiTagInput default:""
		Tags type:#stringTab tabSize:0 tabSizeVariable:true
		
		on Tags tabChanged change tabIndex tabCount do 
		(
			this.params.updateUi ui:#Tags --I always use this, because I can fire 1 central function from many event handler
			--print Tags.count
		)
	)
	 
	rollout params "Asset Tags"
	(
		local validCharacters = #("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "_")
		
		edittext uiTagInput width:140 offset:[-4,0]
		multilistbox uiTags items:#("","","","")
		button uiSelect "Select" width:135 tooltip:"Select scene objects containing highlighted tags"
		button uiRemove "Remove" width:65 across:2 tooltip:"Remove the highlighted tags"
		button uiClear "Clear" width:65 tooltip:"Clear entire list of tags"
		
		/* Functions */
		fn RemoveInvalidCharacters txt:"" =
		(
			local str = ""
			for i = 1 to txt.count do
			(
				letter = txt[i]
				if findItem validCharacters (toLower letter) != 0 do
				(
					append str letter
				)
			)
			str
		)

		fn AppendTag txt:"" =
		(
			local str = RemoveInvalidCharacters txt:txt
			if str != "" AND str != " " do
			(
				appendIfUnique Tags str
			)
		)

		fn GetSelectedTags =
		(
			local tagNames = #()
			local indices = uiTags.selection as array
			if indices.count >= 1 do
			(
				for i in indices do 
				(
					name = Tags[i]
					append tagNames name
				)
			)
			tagNames
		)

		fn GetNodesByTags tagNames:#() =
		(
			local nodes = #()
			for o in objects where isProperty o #Tags do
			(
				for t in tagNames where findItem o.tags t != 0 do append nodes o
			)
			nodes
		)

		fn updateUi ui: =
		(
			case ui of
			(
				#Tags : uiTags.items = for x in Tags collect x
			)
		)

		/* Button Actions */
		on uiTagInput changed txt do
		(
			str = RemoveInvalidCharacters txt:txt
			uiTagInput.text = str
		)
		on uiTagInput entered txt do
		(
			AppendTag txt:txt
			uiTagInput.text = ""
			uiTags.items = for x in Tags collect x
		)
		on uiSelect pressed do
		(
			local nodes = GetNodesByTags tagNames:(GetSelectedTags())
			select nodes
		)
		on uiRemove pressed do
		(
			curSel = uiTags.selection
			for i = uiTags.items.count to 1 by -1 where curSel[i] do (deleteItem Tags i)
			uiTags.items = for i in Tags collect i -- update list with array
			uiTags.selection = #{}
		)
		on uiClear pressed do 
		(
			Tags = #()
			uiTags.items = for x in Tags collect x -- assigning the stringTab directly gives you an error so we go through and collect everyitem
		)
		on params open do
		(
			updateUi ui:#Tags
		)
	)
)



-- scene setup
fn AddTagsCA =
(
	for x in selection do
	(
		if not isproperty x #Tags do
		(
			custAttributes.add x taggerCA
			x.assetTags.BaseNode = (nodeTransformMonitor node:x forwardTransformChangeMsgs:false)
		)
	)
)

-- clearlistener()
-- delete objects
-- for i = 1 to 20 do
-- (
-- 	p = random [-50,-50,50] [50,50,0]
-- 	r = random 3 8
-- 	w = random white black
-- 	sphere pos:p radius:r wirecolor:w
-- 	cylinder pos:[p[1], p[2], 0] wirecolor:w radius:r
-- )
----Don't turn tags on unless we want to
--AddTagsCA()
-- select objects[1]



-- panel
try(
	cui.UnRegisterDialogBar ::TagsToolRO
	destroyDialog ::TagsToolRO
)catch()
rollout TagsToolRO "Tags Tool"
(
	local validCharacters = #("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "_")
	struct tagData (name = "", count = 0, nodes = #())
	local callbackContainer = undefined
	local tagDataCollection = #()
	local bufferCopy = #()

	button uiaddCAtoSelected "Add Tag UI to Sel. Objects" width:200 offset:[-5,0] tooltip:"Add an empty Tag UI Custom Attribute to the base-object of the selected objects. Open the modifier panel to see the UI."
	--group "Add Tag to Selected Objects:"
	label lbl_tag "Add Tag to Selected Objects:" align:#left offset:[-3,0]
	edittext uiTagInput "" width:200 align:#left offset:[-9,0]
	
	dotNetControl uiTagList "listview" width:200 height:400 offset:[-5,0]
	dropdownlist uiTagDisplay items:#("Selected","Scene") width:200 offset:[-5,0]
	
	button uiSelect "Select" width:45 across:5 align:#left offset:[-9,0] tooltip:"Select all the objects in the scene with the above selected tags"
	button uiRemove "Remove" width:45 align:#left tooltip:"Remove tags highlighted in the list" offset:[0,0]
	button uiCopy "Copy" width:45 align:#left tooltip:"Copy Tags of selected nodes" offset:[9,0]
	button uiPaste "Paste" width:45 align:#left tooltip:"Paste Tags onto selected Nodes" offset:[18,0]
	button uiDock "D" width:16 offset:[15,0] tooltip:"Dock Left / Undock Dialog"
	/* Functions */
	fn CompareNames str1 str2 = stricmp str1.name str2.name

	fn RemoveInvalidCharacters txt:"" =
	(
		local str = ""
		for i = 1 to txt.count do
		(
			letter = txt[i]
			if findItem validCharacters (toLower letter) != 0 do
			(
				append str letter
			)
		)
		str
	)

	fn GetNodesByTags tagNames:#() =
	(
		local nodes = #()
		for o in objects where isProperty o #Tags do
		(
			for t in tagNames where findItem o.tags t != 0 do append nodes o
		)
		nodes
	)

	fn AppendTag txt:"" =
	(
		local str = RemoveInvalidCharacters txt:txt
		if str != "" AND str != " " do
		(
			--if we haven't got tags on these objects, then add them
			AddTagsCA()
			
			for o in selection where isProperty o #Tags do
			(
				appendIfUnique o.Tags str
			)
		)
	)

	fn StyleListView ctrl:unsupplied =
	(
		ctrl.columns.add "Tags" 145
		ctrl.columns.add "#" 34
		ctrl.view = ctrl.View.details
		ctrl.HideSelection = false
		ctrl.FullRowSelect = true
		ctrl.GridLines = true 		
		ctrl.MultiSelect = true
		ctrl.BackColor = (dotnetclass "System.Drawing.SystemColors").Menu
	)

	fn GetListViewItems nodes:objects =
	(
 		tagDataCollection = #()
 		local collectionItems = #()

 		for o in nodes where isProperty o #Tags do
 		(
 			local objectTags = (getProperty o #Tags)
 			for t in objectTags do
 			(
 				local existingTags = for s in tagDataCollection collect (toLower s.name)
 				index = findItem existingTags (toLower t)
 				if index == 0 then
 				(
 					append tagDataCollection (tagData name:t count:1 nodes:#(o))
 				)
 				else
 				(
 					tagDataCollection[index].count += 1
 					append tagDataCollection[index].nodes o
 				)
 			)
 		)

 		qSort tagDataCollection CompareNames
 		for s in tagDataCollection do 
 		(
 			li = dotNetObject "System.Windows.Forms.ListViewItem" s.name
 			li.subitems.add (s.count as string)
 			append collectionItems li
 		)
 		collectionItems
	)

	fn PopulateUI =
	(
		local selectedItems = case uiTagDisplay.selected of
		(
			"Selected": GetListViewItems nodes:(getCurrentSelection())
			"Scene": GetListViewItems nodes:objects
			default: GetListViewItems nodes:#()
		)

		uiTagList.items.Clear()
		if selectedItems.count != 0 do
		(
			uiTagList.items.addRange selectedItems
		)
		uiTagList.update()
	)

	fn CallbackHandler event nodes =
	(
		--t1 = timestamp()
		--m1 = heapfree
		PopulateUI()
		--format "time:% memory:%\n" (timestamp() - t1) (m1 - heapfree)
	)

	fn AddCAtoSelected =
	(
		AddTagsCA()
	)
	
	fn GetSelectedIndices ctrl: =
	(
		local indices = #()

		if ctrl != unsupplied do
		(
			local selItems = ctrl.SelectedItems
				
			for i = 0 to (selItems.count-1) do 
			(
				id = selItems.item[i].index + 1
				append indices id
			)
		)
		indices
	)

	fn SelectNodesByID indices:#() =
	(
		local nodes = #()
		
		for i in indices do 
		(
			join nodes tagDataCollection[i].nodes
		)
		select nodes
	)

	fn RemoveTagsByID indices:#() =
	(		
		for i in indices do 
		(
			tagName = tagDataCollection[i].name
			
			-- go through each tag collected nodes
			for node in tagDataCollection[i].nodes where isProperty node #tags do
			(
				-- within in each node loop through it's tags and remove the tag if found
				for t in node.tags do
				(
					id = findItem node.tags tagName
					if id != 0 then
					(
						deleteItem node.tags id
					)
				)
			)
		)
		PopulateUI()
	)

	fn CopyToBuffer = 
	(
		bufferCopy = #()
		for o in selection where isProperty o #Tags do
 		(
 			local objectTags = (getProperty o #Tags)
			join bufferCopy objectTags
		)
 		bufferCopy = makeUniqueArray bufferCopy

 		ss = ""
 		for b in bufferCopy do 
 		(
 			ss += b
 			ss += ","
 		)
 		uiPaste.tooltip = "Paste Tags onto selected Nodes\n\nPaste: " + ss
	)

	fn PasteBuffer =
	(
		AddTagsCA()
		
		for o in selection where isProperty o #Tags do
		(
			for b in bufferCopy do appendIfUnique o.tags b
		)
		PopulateUI()
	)
	fn dockUnDock =
	(
		if cui.getDockState TagsToolRO == #cui_floatable then
		(
			cui.DockDialogBar TagsToolRO #cui_dock_left
		)
		else
		(
			cui.FloatDialogBar TagsToolRO
		)
	)
	
	
	/* Button Actions */
	on uiAddCAtoSelected pressed do
	(
		AddCAtoSelected()
	)
	
	on uiSelect pressed do
	(
 		local indices = GetSelectedIndices ctrl:uiTagList
 		SelectNodesByID indices:indices
	)

	on uiPaste pressed do
	(
		PasteBuffer()
	)

	on uiRemove pressed do
	(
		local indices = GetSelectedIndices ctrl:uiTagList
		RemoveTagsByID indices:indices
	)

	on uiCopy pressed do 
	(
		CopyToBuffer()
	)
	on uiDock pressed do
	(
		dockUnDock()
	)
	on uiTagInput changed txt do 
	(
		str = RemoveInvalidCharacters txt:txt
		uiTagInput.text = str
	)

	on uiTagInput entered txt do
	(
		AppendTag txt:txt
		uiTagInput.text = ""
		PopulateUI()
	)

	on uiTagList MouseDoubleClick s e do 
	(
		itm = s.GetItemAt e.x e.y	
		if itm != undefined do 
		(
			nodes = GetNodesByTags tagNames:#(itm.text)
		)
		if keyboard.controlPressed then
		(
			selectMore nodes
		)else(
			select nodes
		)
	)

	on uiTagDisplay selected val do PopulateUI()

	on TagsToolRO open do
	(
		StyleListView ctrl:uiTagList

		callbackContainer = NodeEventCallback mouseUp:true delay:1 all:CallbackHandler
		PopulateUI()
	)

	on TagsToolRO close do
	(
		if isProperty callbackContainer #enabled do setProperty callbackContainer #enabled off
		callbackContainer = undefined
		gc()
	)
	
	on TagsToolRO resized arg do
	(
		--TagsToolRO.width = 220
		uiTagList.height = arg[2] - 130
		uiTagDisplay.pos = [uiTagDisplay.pos[1], arg[2] - 54]
		
		
		uiSelect.pos = [uiselect.pos[1], arg[2] - 26]
		uiRemove.pos = [uiRemove.pos[1], arg[2] - 26]
		uiCopy.pos = [uiCopy.pos[1], arg[2] - 26]
		uiPaste.pos = [uiPaste.pos[1], arg[2] - 26]
		uiDock.pos = [uiDock.pos[1], arg[2] - 26]
	)

)
createDialog TagsToolRO width:225 height:536 style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox, #style_resizing)

cui.RegisterDialogBar TagsToolRO minSize:[220,180] maxSize:[220,1000] style:#(#cui_dock_left, #cui_floatable, #cui_dock_right, #cui_handles) --, #cui_max_sized
