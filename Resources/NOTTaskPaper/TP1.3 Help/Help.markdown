# Welcome

## Getting Started

TaskPaper lists have three types of items: projects, tasks, and notes. Any item can also be tagged.

* To create an item tap the plus button and then tap the return key to choose the item's type.
* To edit an existing item double tap on the item's text.
* To tag an item type '@' followed by the tag name anywhere in an item's text.
* To indent an item tap the space key when the cursor is at the start of the item's text.
* To unindent an item tap the delete key when the cursor is at the start of the item's text.
* To focus on your document (iPad only) tap the two-arrow icon in the lower right-hand of the screen. Exit by tapping it again.

## Searching Lists

Use search to filter your lists and to focus on particular groups of items.

* To search by project tap the 'Go' button and select the project.
* To search by tag tap the '@' button and select the tag.
* To start your own search tap the bottom toolbar magnifying glass.
* To cancel a search tap the magnifying glass – its behavior changes when a search is active. This change is indicated with a dot drawn in the middle of the glass.

## Tips & Tricks
	
* To quickly tag an item as done swipe left to right over the item.
* To cut, copy, paste, or delete an item swipe right to left over the item.
* To move items tap and hold, then drag to a new location.
* To select multiple items press and hold any bottom toolbar item while selecting.
* To create multiple items quickly tap the return key after typing each item.
* If you have trouble completing swipe gestures try to shorten them. They only require a short 'push'.

TaskPaper doesn't force you to work in a certain way; it provides basic to-do list elements that you use as you like.

# Working with Lists

## Selecting items

* To select one item tap it once.
* To select multiple items press and hold down on any bottom toolbar button while selecting. Works like a shift key.

## Editing items

* To edit an item's text double-tap on the text where you wish to start editing.
* Or to edit an item's text select it and then choose 'Edit' from the actions menu (bottom right toolbar).

## Adding items

* To create an item tap the plus (+) button and then tap the return key to choose the item's type.
* Once you are editing you can enter many items quickly by tapping 'return' after finishing each item.

## Moving items

* To drag and drop, press and hold on an item, then drag to a new location.
* To copy and paste, select the item, and then choose cut or copy from the actions menu.
* To quickly move an item to any project, select the item and then choose 'Move to...' from the actions menu.

## Creating Outlines

* To indent an item tap the space key when the cursor is at the start of an item's text.
* To unindent an item tap the delete key when the cursor is at the start of an item's text.

## Tagging items

* To create a new tag, type the @ symbol followed by the tag name.
* To apply an existing tag, choose 'Tag with...' from the actions menu.
* To apply @done, swipe left to right across an item.

## Completing tasks

* To cross out an item swipe left to right to apply the @done tag.
* To delete an item and its subitems, swipe right to left across the item and then tap the Cut button.
* To delete an item without deleting its subitems, begin editing the item and delete the entire line of text.
* To move @done items to the 'Archive' project, tap the document title in the toolbar and choose 'Archive Done'. 

## Searching lists

The search field allows you to filter your lists. Matching items and the items that contain them are displayed.

* To search by project tap the 'Go' button and select the project.
* To search by tag tap the '@' button and select the tag.
* To start your own search tap the bottom toolbar magnifying glass.
* To cancel a search tap the magnifying glass–its behavior changes when a search is active. This change is indicated with a dot drawn in the middle of the glass.
	
For more advanced searching please read 'Query Language'.

## Undoing changes

TaskPaper tracks edits in your open document and allows you to undo them using the standard 'shake to undo' behavior.

There are two levels of undo. First there is undo for changes that are being made to the line that you are currently editing. To undo further back, you need to stop editing the current line, and then shake to undo again.

# Managing Documents

Each list is stored in a document that's listed in the document list view.

* To create a file, tap the 'new document' button in the bottom toolbar (file icon with a plus sign).
* To create a folder, tap the 'new folder' button in the bottom toolbar (folder icon with a plus sign).
	* A folder will display a '>' arrow in the Documents List.
* To navigate to a folder, tap its name in the Documents List.
	* To return to the previous folder, tap the back arrow in the Documents List.
* To delete a file or folder, swipe its name in the item list view and then tap the 'Delete' button.

## Syncing Documents

### Sync with Dropbox

* To enable Dropbox sync, tap 'Settings' (gear icon), then tap 'Dropbox' and 'Link to Dropbox Account.'
* Dropbox sync will only look at what is in your /Dropbox/TaskPaper/ folder by default. If you want to change this, tap the text field after Link Folder in Settings to customize (you must unlink from Dropbox before you can edit this field). For example, if you choose '/' only, you can navigate your entire Dropbox folder.
* Dropbox sync works at the folder level. When you open a folder, or modify an item in it, the contents of that folder is synced. Subfolders and parent folders are not synced until you visit to them.
* Dropbox sync can merge multiple edits, allowing you to share and edit documents through Dropbox shared folders without losing your changes. If there's ever a problem you can recover previous versions of your document by visiting Dropbox.com.
* If you un-link from your Dropbox account, all synced files will be removed from TaskPaper. Any files with unsynced changes will remain in the list.

### Sync without Dropbox

*  Dropbox is not required to get documents into and out of TaskPaper. You can use iTunes or an application like [PadSync](http://www.ecamm.com/mac/padsync/) (on Mac) that supports the iTunes document sharing infrastructure. Please note that iTunes doesn't support browsing TaskPaper's folders, but PadSync does!

## Document Security

TaskPaper isn't designed to be an extremely secure application. Your documents are stored unencrypted, so if your phone gets stolen someone could read them, even if you have set a startup passcode. 

# Query Language

TaskPaper's query language allows your searches to be more specific and powerful. This section is fun for geeks, but you can safely skip it if search by project and search by tag are all you need.

I'll start with some examples:

    project = Inbox

Matches all items in the Inbox project.

    project = Inbox and not @done

Matches all items in the Inbox and not tagged with @done.

    project Inbox and not @done and (@priority > 1 or @today)

Matches all items in the Inbox and not tagged with @done and that have a @priority tag with a value greater than 1 or are that are tagged with @today.

## Query language syntax

The query language syntax follows this basic pattern:

    &lt;attribute&gt; &lt;relation&gt; &lt;search term&gt;

The first example, 'project = Inbox', follows the pattern exactly.

* *project* is the attribute,
* *=* is the relation,
* *Inbox* is the search term.

But if you just type 'project Inbox' or even just 'Inbox' that works too.

'Inbox' works because you don't have to fully specify each search. If you leave out part of the search, TaskPaper will anticipate your meaning:

* If you don't provide an attribute, TaskPaper will assume the default 'line' attribute.
* If you don't provide a relation, TaskPaper will assume the default 'contains' relation.

Because of these defaults the following four searches are all equivalent:

    line contains Inbox
    line Inbox
    contains Inbox
    Inbox

### Attributes

Each item has built-in attributes that you can use in your searches:

<dl>
	<dt>type</dt>
	<dd>The item's type. This attribute will have the value project, task, or note. For example search for 'type = task' to see just your tasks. Because project is a keyword when searching for type = 'project' you need to enclose 'project' in quotes. </dd>
	<dt>line</dt>
	<dd>The item's entire line of text. For example you can use 'line contains joe' to match all items that contain the text 'joe'.</dd>
	<dt>content</dt>
	<dd>The item's text content. This is similar to the line attribute, except it doesn't include the item formatting, trailing tags, or the end of line character.</dd>
	<dt>level</dt>
	<dd>The item's indentation level. For example you can use 'level = 0' to only match items that are not indented.</dd>
	<dt>project</dt>
	<dd>The text content of any of the item's enclosing projects. The item will match if any of its containing projects match. For example, use 'project = Inbox' to match all items contained in the Inbox project.</dd>
	<dt>index</dt>
	<dd>The entry's position in its list of siblings. For example, use 'index = 0' to show only the first entry in each sublist of entries.</dd>
</dl>

### Tags

You can also use tags as search attributes. If your search only contains a tag value, then the search will match any item that has that tag. For example this search will match all items that have the @done tag:

    @done

You can search for the values that are associated with tags. If you have tag @priority(1) then this search will find it, and not other @priority tags that have different values:

    @priority = 1

You can add the +d flag to matches all entries tagged with @today and shows their descendants. So for instance if a note entry is indented under another entry that is tagged with @today, then adding +d will also show that note entry:

    @today +d

### Relations

The query language supports the following relations:

<dl>
 	<dt>=</dt>
	<dd>Is true if the values are equal.</dd>
 	<dt>></dt>
	<dd>Is true if the attribute is alphabetically greater-than the search term.</dd>
 	<dt>&lt;</dt>
	<dd>Is true if the attribute is as alphabetically less-than the search term.</dd>
 	<dt>beginswith</dt>
	<dd>Is true if the attribute case-insensitive begins with the search term.</dd>
 	<dt>contains</dt>
	<dd>Is true if the attribute case-insensitive contains the search term.</dd>
 	<dt>endswith</dt>
	<dd>Is true if the attribute case-insensitive ends with the search term.</dd>
 	<dt>like</dt>
	<dd>Is true if the attribute case-insensitive matches the search term where ? and * are allowed as wildcard characters.</dd>
 	<dt>matches</dt>
	<dd>Is true if the attribute matches the regular expression defined by the search term. Most regular expressions will need to be enclosed in quotes.</dd>
</dl>

Because of alphabetical sort ordering, some tag value formats work better than others.

If you want to have date values, then you should use a date format that sorts correctly in alphabetical order. TaskPaper's recommended date format is YYYY-MM-DD.

### Search terms

You need to enclose query language keywords in double quotes. For example to search for items that contain '=' you need to type:

    line contains '='

If a search term is not a keyword you can skip the double quotes, and even string together multiple words. For example:

    line contains my search terms and not @done

Matches items that have the text 'my search terms' and are not tagged with @done.

### Logical operations

You can combine TaskPaper's basic search patterns with logical and, or, and not operators.

    one and two

Matches items that contain both the text one and the text two.

    not @done

Matches items that do not have an @done tag.

    project Inbox and not @done and (@priority > 1 or @today)

Matches all items in the Inbox project, and not tagged with @done, and with a @priority tag with a value greater than 1 or are tagged with @today.

# Known Issues

* If your text isn’t opening, or some characters are displayed incorrectly, it’s likely that you have saved the text in an encoding that TaskPaper doesn’t understand. Re-save the text using UTF8 encoding to fix the problem.
* If you name a top level folder "Inbox" iOS will automatically set it's contents to read-only. I've filed a bug report, but for now it's best to avoid creating a top level "Inbox" folder.
* Filenames that contain ; ~ or \ characters cause problems when syncing with Dropbox. TaskPaper doesn't allow you to create names with these characters, but it's still possible to create them via iTunes document sharing or syncing them down from Dropbox. For now it's best to just avoid using them altogether. 

# Upgrading from 1.3

Welcome to the new TaskPaper for iOS!

TaskPaper now syncs your files with [Dropbox.com](http://www.dropbox.com), support for syncing to [SimpleText.ws](http://www.simpletext.ws) has been removed. If you still have unsynced files on SimpleText.ws, the service will continue to be online for a while longer.

Local network file sharing feature has been removed. Instead TaskPaper now stores your files as normal text files on your iOS device. You can access them on your local computer via iTunes document sharing, or with a third party tool such as PadSync.

# Contact Us

Please contact us directly if you have a comment, question, or bug to report. We love seeing good reviews in the App Store comments section, but good or bad, the App Store doesn't give us any way to answer your questions. If you need a response please:

* First check the [FAQs](http://www.hogbaysoftware.com/products/taskpaper/faq) to see if your question is already answered!
* Visit the [support forums](http://groups.google.com/group/taskpaper) for most questions and comments! We read every post, and a lot of incredibly helpful people hang out there.

# Thanks!

TaskPaper for iOS relies on several great pieces of open source software:

* **[ParseKit](http://parsekit.com/)** is used for parsing TaskPaper's query language. Todd Ditchendorf (ParseKit's creator) was extremely nice in helping me port my previous parser to ParseKit, highly recommended.
* **[RegexKitLite](http://regexkit.sourceforge.net/RegexKitLite/)** is used for finding tags and tag values among other things. John Engelhart (RegexKitLite's creator) helped me get my head around regular expressions.
* **[DiffMatchPatch](http://code.google.com/p/google-diff-match-patch/)** is used to drive TaskPaper's sync engine from the SimpleText.ws days. The algorithm is above my head, but the functionality is great. Thanks to Neil Fraser and Google for releasing the code.
* **[Vicent Martí](http://fossil.instinctive.eu/libupskirt/index)** for his [markdown parser](https://github.com/tanoku/upskirt), used for the help book.
* **[Craig Hockenberry](http://furbo.org/2009/04/30/matt-gallagher-deserves-a-medal/)** and [Matt Gallagher](http://cocoawithlove.com/2008/12/heterogeneous-cells-in.html) for the table view code. As requested, have some link love for [Iconfactory](http://iconfactory.com/iphone)!
* **Chris Miles** for [CMTextStylePicker](https://github.com/chrismiles/CMTextStylePicker).
* **Claus Bönnhoff** for [Color Picker](https://github.com/sycx/ColorPicker).

# Release Notes

## TaskPaper 2.0

## TaskPaper 1.3