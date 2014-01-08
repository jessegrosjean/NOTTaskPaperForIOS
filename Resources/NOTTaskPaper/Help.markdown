# Welcome

This app is based on the open source TaskPaper for iOS release. It is NOT TaskPaper. It is NOT supported by Hog Bay Software.

#### ---

# Getting Started

TaskPaper formatted lists have three types of items: projects, tasks, and notes.

Any item can also be tagged.

---

## Quick Start

* To create an item tap the plus button.
* To change the item type (Project, Task, or Note) on a blank line, tap the Return key to cycle through your choices.
* To edit an existing item double tap on the item's text.
* To tag an item type '@' followed by the tag name anywhere in an item's text.
* To indent an item tap the space key when the cursor is at the start of the item's text.
* To unindent an item tap the delete key when the cursor is at the start of the item's text.

### Searching Lists

Use search to filter your lists and to focus on particular groups of items.

* To search by project tap the 'Go' button and select the project.
* To search by tag tap the '@' button and select the tag.
* To start your own search tap the bottom toolbar magnifying glass.
* To cancel a search tap the bottom toolbar's magnifying glass.
* To edit your current search, tap the magnifying glass icon at the top of the screen next to your search terms.
* The search icon's behavior changes when a search is active. This change is indicated with a dot drawn in the middle of the magnifying glass.
* To quickly search by excluding a project or tag, tap and hold on its name in the project or tag menus.

### Tips & Tricks
	
* To quickly tag an item as @done swipe left to right over the item.
* To cut, copy, paste, or delete an item swipe right to left over the item.
* To move items tap and hold, then drag to a new location.
* To create multiple items quickly tap the return key after typing each item.
* Selecting multiple items requires two fingers. With one finger, press and hold any toolbar item. While holding down that button, use another finger to tap the items you would like to select.
* If you have trouble completing swipe gestures try to shorten them. They only require a short 'push'.
* In version 2.1+, if you add a task when using a single @tag search (from the bottom toolbar), your new item will be automatically tagged.
* You can switch in and out of full screen mode by swiping left or right in the lower-left toolbar area or using "Focus In/Focus Out" from the More Actions (…) menu.

TaskPaper doesn't force you to work in a certain way; it provides basic to-do list elements that you use as you like.

#### ---

## Managing Documents

* To create a file, tap the 'new document' button in the bottom toolbar (file icon with a plus sign).
* To create a folder, tap the 'new folder' button in the bottom toolbar (folder icon with a plus sign).
	* A folder will display a '>' arrow in the Documents List.
* To navigate to a folder, tap its name in the Documents List.
	* To return to the previous folder, tap the back arrow in the Documents List.
* To delete a file or folder, swipe its name in the item list view and then tap the 'Delete' button.
* To search for a file, tap the 'search' button in the bottom toolbar (magnifying glass icon). You can tell if a search is active when the icon has a dot in the middle of the 'magnifying glass.'
* To sync all files with [Dropbox](http://www.dropbox.com), tap the document or folder title and select 'Sync All Now' from the menu. You must have internet access, a Dropbox account, and be logged in for sync.
* To sync just the current folder with Dropbox, tap the folder's name in the titlebar and select 'Sync This Folder' from the menu.
* To print a file with an [AirPrint](http://support.apple.com/kb/ht4356)-compatible printer, tap the document name in its titlebar and select 'Print'.
* To move files between different folders, you'll need to use Dropbox's official iOS app or their website if you're syncing with Dropbox. Moving files is not supported in-app for this version.

#### ---

## Writing and Editing Text

* To scroll through long documents & lists tap and hold on the right side of the view where scroll indicator shows. Then drag to quickly scroll through your document (optional).
* (iPad) To customize your extended keyboard row, go to Settings (gear icon) > Advanced > Extended Keyboard. Tap in the text field next to "Extended Keyboard Keys" and type in the keys you'd like to use, up to a maximum of 9.

#### ---

# Working with Lists

## Selecting items

* To select one item tap it once.
* Selecting multiple items requires two fingers. With one finger, press and hold any toolbar item. While holding down that button, use another finger to tap the items you would like to select.

#### ---

## Editing items

* To edit an item's text double-tap on the text where you wish to start editing.
* Or to edit an item's text select it and then choose 'Edit' from the actions menu (bottom right toolbar).

#### ---

## Adding items

* To create an item tap the plus (+) button and then tap the return key to choose the item's type.
* Once you are editing you can enter many items quickly by tapping 'return' after finishing each item.

#### ---

## Moving items

* To drag and drop, press and hold on an item, then drag to a new location.
* To copy and paste, select the item, and then choose cut or copy from the actions menu.
* To quickly move an item to any project, select the item and then choose 'Move to...' from the actions menu.

#### ---

## Creating Outlines

* To indent an item tap the space key when the cursor is at the start of an item's text or (iPad only) tap the Tab key on the extended keyboard row.
* To unindent an item tap the delete key when the cursor is at the start of an item's text.

#### ---

## Tagging items

* To create a new tag, type the @ symbol followed by the tag name.
* To apply an existing tag, choose 'Tag with...' from the actions menu.
* To apply @done, swipe left to right across an item.

#### ---

## Completing tasks

* To cross out an item swipe left to right to apply the @done tag.
* To delete an item and its subitems, swipe right to left across the item and then tap the Cut button.
* To delete an item without deleting its subitems, begin editing the item and delete the entire line of text.
* To move @done items to the 'Archive' project, tap the document title in the toolbar and choose 'Archive Done'. 

#### ---

## Searching lists

The search field allows you to filter your lists. Matching items and the items that contain them are displayed.

* To search by project tap the 'Go' button and select the project.
* To search by tag tap the '@' button and select the tag.
* To start your own search tap the bottom toolbar magnifying glass.
* To cancel a search tap the magnifying glass, then tap the 'x' in the search box. The search icon's behavior changes when a search is active. This change is indicated with a dot drawn in the middle of the magnifying glass.
* For more advanced searching please read 'Query Language'.

#### ---

## Undoing changes

TaskPaper tracks edits in your open document and allows you to undo them using the standard 'shake to undo' behavior. On the iPad keyboard, you can use the Undo button on the numbers layer of the keyboard:

1. Open the keyboard; start from the normal 'qwerty' letters layer.
2. Tap one of the ".?123" keys at the bottom.
3. The 'undo' will be above the "ABC" key in the lower-left.
4. Tap the "#+=" key to go to the symbols layer, and the "undo" key will change to a redo key.

There are two levels of undo.

First there is undo for changes that are being made to the line that you are currently editing.

To undo further back, you need to stop editing the current line, and then undo again.

They are part of different 'undo stacks,' and in the iOS code switching to one will clear the other.

#### ---

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

    <attribute> <relation> <search term>

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

_The iOS version does not use the +d or -a flags found in the Mac version. These have been marked for deprecation._

### Relations

The query language supports the following relations:

<dl>
 	<dt>=</dt>
	<dd>Is true if the values are equal.</dd>
 	<dt>></dt>
	<dd>Is true if the attribute is alphabetically greater-than the search term. Can also mix signs for 'greater than or equal to.'</dd>
 	<dt><</dt>
	<dd>Is true if the attribute is as alphabetically less-than the search term. Can also mix signs for 'less than or equal to.'</dd>
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

# Syncing Documents

## Sync with Dropbox

* To enable Dropbox sync, tap 'Settings' (gear icon), then tap 'Dropbox' and 'Link to Dropbox Account.'
* Dropbox sync will only look at what is in your ~/Dropbox/NOTTaskPaper/ folder by default. If you want to change this, tap the text field after Link Folder in Settings to customize when unlinked.
* Dropbox sync works at the folder level. When you open a folder, or modify an item in it, the contents of that folder is synced. Subfolders and parent folders are not synced until you visit to them.
* Dropbox can sync automatically or manually. If Automatic Sync is disabled, you will need to press 'Sync All Now' from either the Dropbox settings or the titlebar menu item. You can always use the titlebar 'Sync All' even if Automatic Sync is enabled.
* If you un-link from your Dropbox account, all synced files will be removed from TaskPaper. Any files with unsynced changes will remain in the list as local files.
* To add or remove items from the File Extensions whitelist, you will need to unlink, edit the list, and then relink to Dropbox to start downloading the new files.
* If you're also using TaskPaper for Mac, make sure you explicitly save your document on the Mac before working with it here (File > Save or command+s). Dropbox sync doesn't merge changes very well in documents that are being edited in multiple places.

#### ---

## Sync without Dropbox

Dropbox is not required to get documents into and out of TaskPaper.

You can use iTunes or an application like [PadSync](http://www.ecamm.com/mac/padsync/) (on Mac) that supports the iTunes document sharing infrastructure.

Please note that iTunes currently doesn't support browsing TaskPaper's folders, but PadSync does!

#### ---

## Document Security

TaskPaper isn't designed to be an extremely secure application.

Your documents are stored unencrypted, so if your phone gets stolen someone could read them.

#### ---

# TaskPaper Settings

## Dropbox

### When unlinked from Dropbox:

* **Link Folder:** Use the default /TaskPaper or set your custom folder path.
* **Sync File Types:** Add other plain text file types here and TaskPaper will sync and read them.
* **Link to Dropbox:** Tap this to log into Dropbox and start syncing your files.

### When linked to Dropbox:

* **Dropbox Status:** Tapping this will launch Dropbox's official status page in Safari.
* **Sync Automatically:** Toggle this OFF if you want to use manual sync only (default is ON).
* **Unlink from Dropbox:** Tap this to log out and unlink from your Dropbox account. All synced files will be removed from TaskPaper (they are still safe in Dropbox).

#### ---

## Fonts & Colors

* Set your favorite font and size in the first section. Not all fonts will use their Bold setting properly. We have tried to whitelist the fonts that work better, but some may look better than others.
* Set your favorite text color, background color, and TaskPaper's screen brightness in the second.
* **Tint Cursor:** When enabled, the cursor and selection highlight will be tinted like your text.
* **Brightness:** Use this slider to set TaskPaper's screen brightness (this does not change your default device brightness settings).
* **Interface Tint:** Use this slider to set the tint level for TaskPaper interface including the "close keyboard" button and file list selection highlight (iPad). 

#### ---

## TextExpander
* [TextExpander](http://www.smilesoftware.com/TextExpander/touch/) is a third-party app that allows you to type short abbreviations that are expanded into long snippets.

#### ---

## Advanced

* **Sort By:** Select how to sort your files, by name or recently changed date (default is NAME, ascending).
* **Sort Folders:** Select how folders are sorted in the documents list, to top, bottom, or with files alphabetically (default is WITH FILES).
* **Autocorrection:** Set Autocorrect to be always on, always off, or use your device's default setting (default is DEFAULT).
* **Extended Keyboard:** iPad Only. When enabled the on-screen keyboard will have an extra row of useful keys (default is ON). Tap on "Extended Keyboard Keys >" to manually edit the seven middle keys in the row.
* **Passcode:** When enabled, set your 4-digit application startup passcode. When this option is turned off, it clears the current passcode (default is OFF).
* **Passcode Timeout:** If you're using a Passcode, you can choose how long the app will take before asking for your password on the next launch: Immediately, 1 minute, 5 minutes, or 15 minutes.
* **Default Tags:** If you have tags you use a lot enter them here, separated by a space, to quickly use them via the "Tag with..." menu command.
* **Add Date to Done:** When enabled, @done tags will be given the current date as its value. For example, @done(2011-01-01) if the item is marked as done on January 1st, 2011.
* **Enable Live Search**: When enabled, search updates the view on every keystroke.
* **Show Badge Number:** Displays the number for not-done tasks for the current open document as a badge on the application icon on your home screen. If you don't see a badge and you have undone tasks in an open document, make sure you have TaskPaper's badges enabled in Settings.app's Notifications.
* **Lock Orientation:** iPhone/iPod touch only. Toggle this on to lock the current orientation, intended for locking to landscape orientation.
* **ALL-CAPS Headings:** When enabled your document titles will display as ALL-CAPS regardless of file capitalization (default is ON).
* **Show File Extensions:** When enabled your document titles will also display their file extensions (default is OFF).
* **New File Extension:** Sets the default file extension to use with all new files, such as if you prefer using .txt.
* **Debug:** If you're having issues with TaskPaper, we may ask you to change the debug setting to log more information. Generally you can leave this alone and not worry about it.