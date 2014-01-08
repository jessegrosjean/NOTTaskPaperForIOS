//
//  TaskViewController.m
//  SimpleText
//
//  Created by Kim Young Hoo on 11. 3. 13..
//  Copyright 2011 CodingRobots. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>
#import "TaskViewController.h"
#import "NSString_Additions.h"
#import "PathViewWrapper.h"
#import "PathView.h"
#import "Titlebar.h"
#import "Button.h"
#import "TaskView.h"
#import "UIScrollView_Additions.h"

#import "Tree.h"
#import "Section.h"
#import "RootSection.h"
#import "Tag.h"
#import "TaskPaperSection.h"

#import "IPhoneDocumentViewCell.h"
#import "IPhoneDocumentViewFieldEditor.h"
#import "UITextView_Additions.h"

#import "NSArray_Additions.h"
#import "DiffMatchPatch.h"
#import "PathController.h"
#import "ApplicationController.h"
#import "ApplicationViewController.h"

#import "BrowserViewController.h"
#import "NSFileManager_Additions.h"

#import "TaskView.h"
#import "SearchViewController.h"
#import "MenuView.h"

#import "QueryParser.h"
#import "BrowserView.h"
#import "SearchView.h"
#import "Toolbar.h"
#import "Searchbar.h"

#define AUTOSCROLL_THRESHOLD 50.0

@interface TaskViewController(/*Private*/)  
- (void)updateSearch;
- (IBAction)email:(id)sender;
- (IBAction)archive:(id)sender;
- (IBAction)deleteDocument:(id)sender;
- (void)addShiftKeyListeners;
- (void)removeShiftKeyListeners;	
@end

@implementation TaskViewController 
@synthesize saveToDiskWhenKeyboardDidHide;

+ (void)initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithBool:NO], AddDateToDoneTagKey,
                                                             [NSNumber numberWithBool:YES], LiveSearchEnabledKey,
															 @"done today", DefaultTagsKey,
															 nil]];
}


@synthesize hasUnsavedChanges;

- (id)initWithPath:(NSString *)aPath {
	stringEncoding = NSUTF8StringEncoding;
	self = [super initWithPath:aPath];
	self.pathViewController.pathViewWrapper.pathView.returnKeyType = UIReturnKeyNext;
    searchViewController = [[SearchViewController alloc] init];
	searchViewController.delegate = self;
    keyboardHide = NO;
    return self;
}

- (TaskView *)taskView {
	return (id) self.view;
}


- (void)saveToDisk {
    if (keyboardHide) {
        self.hasUnsavedChanges = YES;
        [self syncViewWithDisk:NO];
        return;
    }
    if ([[IPhoneDocumentViewFieldEditor sharedInstance] isFirstResponder]) {
        return;
    }
    self.hasUnsavedChanges = YES;
    [self syncViewWithDisk:NO];
}



#pragma mark -
#pragma mark Memory management
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    self.taskView.delegate = nil;
    [sections release];
    [sectionSearchString release];
    [lineEnding release];
	[super dealloc];
}

#pragma mark -
#pragma mark View lifecycle
- (BOOL)isFileViewController {
	return YES;
}

- (void)loadView {
    TaskView *taskView = [[[TaskView alloc] init] autorelease];
    taskView.taskDelegate = self;
    
    pathViewController.view.accessibilityLabel = NSLocalizedString(@"Document title", nil);
	pathViewController.view.accessibilityHint = NSLocalizedString(@"Renames the document", nil);
    
	self.view = taskView;
}

- (NSUndoManager *)undoManager {
	return tree.undoManager;
}

- (void)updateIconBadgeNumberCount {
    [tree updateIconBadgeNumberCount];
}

- (void)saveSearch {
    NSData *searchData = [[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentSearchDefaultsKey];
    NSMutableDictionary *searchDict;
    if (searchData != nil && ![searchData isKindOfClass:[NSString class]]) {
        searchDict = [NSKeyedUnarchiver unarchiveObjectWithData:searchData];
    } else {
        searchDict = [NSMutableDictionary dictionary];
    }
    [searchDict setValue:sectionSearchString forKey:self.path];
    searchData = [NSKeyedArchiver archivedDataWithRootObject:searchDict];
    [[NSUserDefaults standardUserDefaults] setObject:searchData forKey:OpenDocumentSearchDefaultsKey];
}

- (void)restoreSearch {
    NSData *searchData = [[NSUserDefaults standardUserDefaults] objectForKey:OpenDocumentSearchDefaultsKey];
    if (searchData && [searchData isKindOfClass:[NSString class]]) {
        return;
    }
    if (searchData) {
        NSMutableDictionary *searchDict = [NSKeyedUnarchiver unarchiveObjectWithData:searchData];
        self.sectionSearchString = [searchDict valueForKey:self.path];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    self.browserViewController.browserView.titlebar.rightButton = [Button buttonWithImage:[UIImage imageNamed:@"newTask.png"] accessibilityLabel:NSLocalizedString(@"Add Task", nil) accessibilityHint:nil target:self action:@selector(addItem:) edgeInsets:UIEdgeInsetsMake(0, 5, 0, 10)];	
    [self.browserViewController.browserView.titlebar setNeedsLayout];
    [self.browserViewController.browserView.titlebar layoutIfNeeded];
    
    self.browserViewController.browserView.searchbar.rightButton = [Button buttonWithImage:[UIImage imageNamed:@"newTask.png"] accessibilityLabel:NSLocalizedString(@"Add Task", nil) accessibilityHint:nil target:self action:@selector(addItem:) edgeInsets:UIEdgeInsetsMake(0, 5, 0, 10)];
    if (!IS_IPAD) {
        Button *back = [Button buttonWithImage:[UIImage imageNamed:@"back.png"] accessibilityLabel:NSLocalizedString(@"Back", nil) accessibilityHint:nil target:self.browserViewController action:@selector(back:) edgeInsets:UIEdgeInsetsMake(0, 5, 0, 10)];
        self.browserViewController.browserView.searchbar.leftButton = back;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [self keyboardDidHide:nil];
    
    [self saveContentOffset];
    [self saveSearch];
    
    [self removeShiftKeyListeners];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [self.taskView removeFieldEditor];
}

- (void)viewDidLoad {
    [self addShiftKeyListeners];
    [self restoreContentOffset];
    [self restoreSearch];
}

static NSUInteger rotateRow;
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	rotateRow = [self.taskView rowAtPoint:CGPointMake(0, self.taskView.contentOffset.y + 1)];
	[[MenuView sharedInstance] close];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	NSIndexSet *rotateRows = [[self.taskView.selectedRows copy] autorelease];
	[self.taskView reloadData];
	[self.taskView setSelectedRows:rotateRows];
	if (rotateRow != NSNotFound) {
		[self.taskView setContentOffset:[self.taskView rectForRow:rotateRow].origin];
	}	
}

- (void)toggleDocumentFocusModeAnimationDidStop:(id)sender {
	[self.taskView reloadData];    
}

- (void)keyboardDidShow:(NSNotification *)notification {
    keyboardHide = NO;
	[self.taskView scrollFieldEditorToVisible:YES];
}


- (void)keyboardDidHide:(NSNotification *)notification {	
    if (saveToDiskWhenKeyboardDidHide) {
        saveToDiskWhenKeyboardDidHide = NO;
        keyboardHide = YES;
        [self saveToDisk];
    }
}

- (void)loadDocumentIntoView {
    [self.taskView performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
    [self.taskView becomeFirstResponder];
	
	if (tree != nil && [tree lastSection] == nil) {
        tree.skipSave = YES;
		[tree addSubtreeSectionsObject:[[[TaskPaperSection alloc] initWithString:@":"] autorelease]];
        [self.taskView performSelector:@selector(beginFieldEditorForRow:) withObject:0 afterDelay:0.1];
	} else if ([tree lastSection] == [tree firstSection] && [[tree firstSection] isBlank]) {
        tree.skipSave = YES;
		[tree firstSection].type = TaskPaperSectionTypeProject;
        if (![self.pathViewController.pathViewWrapper.pathView isFirstResponder]) {
            [self.taskView performSelector:@selector(beginFieldEditorForRow:) withObject:0 afterDelay:0.1];            
        }
	}
}

- (void)closeEditor {
	if (IS_IPAD) {
        self.browserViewController.browserView.titlebar.rightButton = nil;
		[self.browserViewController pop:NO];
	} else {
		[APP_VIEW_CONTROLLER openItem:[self.path stringByDeletingLastPathComponent] animated:YES];
	}
}

- (void)syncViewWithDisk:(BOOL)animated {
    if ([[IPhoneDocumentViewFieldEditor sharedInstance] isFirstResponder] && !keyboardHide) {
        return;
    }
    
	[super syncViewWithDisk:animated];

    NSError *error;
	BOOL isDirectory;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL fileDeleted = ![fileManager fileExistsAtPath:self.path isDirectory:&isDirectory];

    if (!hasUnsavedChanges && (fileDeleted || isDirectory)) {
		[self closeEditor];
		return;
	} else {
		NSString *fileContents = [NSString myStringWithContentsOfFile:self.path usedEncoding:&stringEncoding error:&error];
        
        // 2. If load file then detect line endings
		if (fileContents) {
			NSRange paragraphRange = [fileContents paragraphRangeForRange:NSMakeRange(0, [fileContents length])];
			NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
			
			[lineEnding release];
			lineEnding = nil;
			
			if (paragraphRange.length > 0) {
				unichar c = [fileContents characterAtIndex:paragraphRange.length - 1];
				if ([newlineCharacterSet characterIsMember:c]) {
					if (paragraphRange.length > 1 && c == '\n') {
						if ([fileContents characterAtIndex:paragraphRange.length - 2] == '\r') {
							lineEnding = [@"\r\n" retain];
						}
					} else {
						lineEnding = [[NSString stringWithFormat:@"%C", c] retain];
					}
				}
			}
			
			if (!lineEnding) {
				lineEnding = [@"\n" retain];
			}
            
            if ([lineEnding isEqualToString:@"\r\n"]) {
                fileContents = [fileContents stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
            }
		} else {
			LogError(@"Failed to load path %@ %@", self.path, error);
			[self closeEditor];
			return;
		}

        
   		// 3. Apply any changes from file to view. In case of conflict change view to save in conflict path.
        NSString *contentInView;
        if (tree == nil) {
            contentInView = @"";
        } else {
            contentInView = tree.textContent;
        }
        
        if ([contentInView isEqualToString:@""] && [fileContents isEqualToString:@""]) {
            [tree autorelease];
            tree = [[Tree alloc] initWithPatchHistory:nil textContent:@""];
            tree.delegate = self;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(treeChangedNotification:) name:TreeChanged object:tree];
            sections = (id)[[tree.enumeratorOfSubtreeSections allObjects] retain];
            [self loadDocumentIntoView];	
            return;
        }
        
        DiffMatchPatch *dmp = [[[DiffMatchPatch alloc] init] autorelease];
        NSMutableArray *filePatches = [dmp patch_makeFromOldString:lastFileContents == nil ? @"" : lastFileContents andNewString:fileContents];
        if ([filePatches count] > 0) {
            NSArray *patchResults = [dmp patch_apply:filePatches toString:contentInView];		
			NSString *patchResultsText = [patchResults objectAtIndex:0];
            
            BOOL patchApplied = YES;
			
			for (NSNumber *each in [patchResults objectAtIndex:1]) {
				if (![each boolValue]) {
					patchApplied = NO;
				}
			}
            
            [tree autorelease];
            tree = [[Tree alloc] initWithPatchHistory:nil textContent:patchResultsText];
            tree.delegate = self;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(treeChangedNotification:) name:TreeChanged object:tree];
            sections = (id)[[tree.enumeratorOfSubtreeSections allObjects] retain];
            [self loadDocumentIntoView];	
            NSString *previousSectionSearchString = self.sectionSearchString;
            sectionSearchString = @"";
            self.sectionSearchString = previousSectionSearchString;
            
            if (![fileContents isEqualToString:patchResultsText]) {
                hasUnsavedChanges = YES;
            }
            
            
			if (!patchApplied) {
				NSString *conflictPath = [fileManager conflictPathForPath:self.path includeMessage:YES error:&error];
				if (conflictPath) {
					self.path = conflictPath;
				} else {
					LogError(@"Failed to create conflict path %@ %@", self.path, error);
					return;
				}
			}
        }
        
        if (hasUnsavedChanges) {
			[fileManager createDirectoryAtPath:[self.path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
			
			BOOL fileExists = [fileManager fileExistsAtPath:self.path];
            
            
			if ([tree.textContent writeToFile:self.path atomically:YES encoding:stringEncoding error:&error]) {
				hasUnsavedChanges = NO;
				savingTextContentToDisk = YES;
				
				if (fileExists) {
					[PATH_CONTROLLER enqueuePathChangedNotification:self.path changeType:ModifiedPathsKey];
				} else {
					[PATH_CONTROLLER enqueuePathChangedNotification:self.path changeType:CreatedPathsKey];
				}
				savingTextContentToDisk = NO;				
				
				PathController *pathController = PATH_CONTROLLER;
				if (pathController.syncAutomatically) {
					[PATH_CONTROLLER enqueueFolderSyncPathOperationRequest:[self.path stringByDeletingLastPathComponent]];
				}
			} else {
				[APP_VIEW_CONTROLLER presentError:error];
			}			
		}

        [lastModificationDate autorelease];
		lastModificationDate = [[[fileManager attributesOfItemAtPath:self.path error:NULL] fileModificationDate] retain];
		[lastFileContents release];
		lastFileContents = [tree.textContent retain];
    }
}

- (NSArray *)toolbarItems {
    Button *beginSearchButton = searchViewController.beginSearchButton; 
    
	return [NSArray arrayWithObjects:
			[Button buttonWithImage:[UIImage imageNamed:@"go.png"] accessibilityLabel:NSLocalizedString(@"Projects", nil) accessibilityHint:nil target:self action:@selector(showProjects:) edgeInsets:UIEdgeInsetsMake(0, 5, 0, 15)],
			[Toolbar flexibleSpace],
			[Button buttonWithImage:[UIImage imageNamed:@"at.png"] accessibilityLabel:NSLocalizedString(@"Tags", nil) accessibilityHint:nil target:self action:@selector(showTags:) edgeInsets:UIEdgeInsetsMake(0, 15, 0, 15)],
			[Toolbar flexibleSpace],
			beginSearchButton,
            [Toolbar flexibleSpace],
			[Button buttonWithImage:[UIImage imageNamed:@"actions.png"] accessibilityLabel:NSLocalizedString(@"Actions", nil) accessibilityHint:nil target:self action:@selector(showActions:) edgeInsets:UIEdgeInsetsMake(0, 15, 0, 5)],
			nil];	
}

- (IBAction)addItem:(id)sender {
    Section *selection = [self.taskView.selectedSections lastObject];
	
	if (!selection) {
		selection = [sections lastObject];
	} else {
		self.taskView.selectedRows = nil; // clear selection before a new item is added. Otherwise if new item is added in background
		// selection cover can get messed up. For example select a project with one childen, and create new item. The projects original
		// child would stay in selection cover if the above line wasn't in positions. Probably a better way to handle this!
	}
    Section *newSection = [[[TaskPaperSection alloc] init] autorelease];
	Section *newSectionParent = nil;
	Section *newSectionInsertAfter = nil;
    
    if ([self.sectionSearchString componentsSeparatedByString:@" "].count == 1) {
        if ([self.sectionSearchString hasPrefix:@"@"]) {
            newSection.selfString = [NSString stringWithFormat:@" %@", self.sectionSearchString];
        }
    }
    
    tree.skipSave = YES;
	
	if (selection) {
		switch (selection.type) {
			case TaskPaperSectionTypeProject:
				newSectionParent = selection;
				newSectionInsertAfter = nil;
				newSection.type = TaskPaperSectionTypeTask;
				break;
			case TaskPaperSectionTypeTask:
				newSectionParent = selection.parent;
				newSectionInsertAfter = selection;
				newSection.type = TaskPaperSectionTypeTask;
				break;
			case TaskPaperSectionTypeNote:
				newSectionParent = selection.parent;
				newSectionInsertAfter = selection;
				newSection.type = TaskPaperSectionTypeNote;
				break;
		}
	} else {
		newSectionParent = tree.rootSection;
		newSectionInsertAfter = tree.lastSection;
		newSection.type = TaskPaperSectionTypeProject;
	}
	
	[newSectionParent insertChildrenObject:newSection after:newSectionInsertAfter];
    [tree commitCurrentPatch:NSLocalizedString(@"Add", nil)];
	[self.taskView beginFieldEditorForRow:[sections indexOfObject:newSection]];
    if ([newSection.selfString length] != 0) {
        [IPhoneDocumentViewFieldEditor sharedInstance].selectedRange = NSMakeRange(0, 0);
    }
}


- (void)showWordCount {
	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	NSUInteger paragraphCount;
	NSUInteger wordCount;
	NSUInteger characterCount;
	UIAlertView *alertView;

    NSString *content = tree.textContent;   
    [content statistics:&paragraphCount words:&wordCount characters:&characterCount];
    alertView = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:NSLocalizedString(@"%@ words\n%@ paragraphs\n%@ characters", nil), 
                                                                [numberFormatter stringFromNumber:[NSNumber numberWithUnsignedInteger:wordCount]], 
                                                                [numberFormatter stringFromNumber:[NSNumber numberWithUnsignedInteger:paragraphCount]],
                                                                [numberFormatter stringFromNumber:[NSNumber numberWithUnsignedInteger:characterCount]],
                                                                nil] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

- (IBAction)print:(id)sender {
    UIPrintInteractionController *printInteractionController = [UIPrintInteractionController sharedPrintController];
    printInteractionController.delegate = self;
	
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGrayscale;
    printInfo.jobName = [NSString stringWithFormat:@"%@ %@", [[NSProcessInfo processInfo] processName], [self.path lastPathComponent], nil];
    printInteractionController.printInfo = printInfo;
	
    NSString *printText = [[Section sectionsToString:[sections objectEnumerator] includeTags:YES] stringByReplacingOccurrencesOfString:@"\t" withString:@"    "] ;
    printText = [printText stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\n"];
    
    UISimpleTextPrintFormatter *formatter = [[[UISimpleTextPrintFormatter alloc] initWithText:printText] autorelease];
    formatter.startPage = 0;
    formatter.contentInsets = UIEdgeInsetsMake(72.0, 72.0, 72.0, 72.0); // 1 inch margins
    formatter.maximumContentWidth = 6 * 72.0;
	formatter.font = APP_VIEW_CONTROLLER.font;
	
    printInteractionController.printFormatter = formatter;
    printInteractionController.showsPageRange = YES;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[printInteractionController presentFromRect:pathViewController.pathViewWrapper.pathView.bounds inView:pathViewController.pathViewWrapper.pathView animated:YES completionHandler:NULL];
    } else {
        [printInteractionController presentAnimated:YES completionHandler:NULL];
    }
}

#pragma mark -
#pragma mark UIPrintInteractionController delegate

- (void)printInteractionControllerWillStartJob:(UIPrintInteractionController *)printInteractionController {
	LogInfo(@"Will Start Print Job %@", printInteractionController);
}

- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController *)printInteractionController {
	LogInfo(@"Did Finish  Print Job %@", printInteractionController);
}

#pragma mark -
#pragma mark Menu
- (MenuView *)pathViewPopupMenuView:(PathViewController *)aPathTextFieldController {
	MenuView *menuView = [MenuView sharedInstance];
    
    if (NSClassFromString(@"UIPrintInteractionController")) {
		[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Print", nil) indentationLevel:1 enabled:YES checked:NO userData:@"print"]];
	}
    [menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Email", nil) indentationLevel:1 enabled:YES checked:NO userData:@"email"]];
    [menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Rename", nil) indentationLevel:1 enabled:YES checked:NO userData:@"rename"]];
    [menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Archive Done", nil) indentationLevel:1 enabled:YES checked:NO userData:@"archive"]];
    [menuView addItem:[MenuViewItem separatorItem]];

	[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Sync All Now", nil) indentationLevel:1 enabled:YES checked:NO userData:@"sync"]];
    
    menuView.target = self;
	menuView.action = @selector(pathViewPopupMenuViewChoice:);
	
	return menuView;
}

- (void)pathViewPopupMenuViewChoice:(MenuView *)menuView {
    MenuViewItem *selectedItem = [menuView.selectedItems lastObject];
	if (selectedItem) {
		NSString *userData = selectedItem.userData;
		if ([userData isEqualToString:@"email"]) {
			[self email:nil];
		} else if([userData isEqualToString:@"archive"]) {
            [self archive:nil];
        } else if ([userData isEqualToString:@"rename"]) {
			[self rename:nil];
		} else if ([userData isEqualToString:@"delete"]) {
            [self deleteDocument:nil];
        } else if ([userData isEqualToString:@"sync"]) {
			[self sync:nil];
		} else if ([userData isEqualToString:@"wordCount"]) {
            [self showWordCount];
        } else if ([userData isEqualToString:@"print"]) {
			[self print:nil];
		}
	}
	[menuView close];
}

- (IBAction)email:(id)sender {
	if (![MFMailComposeViewController canSendMail]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't send email", nil) message:NSLocalizedString(@"You must setup email on your phone before you can use this feature.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	} else {
		MFMailComposeViewController *mailComposeViewController = [[[MFMailComposeViewController alloc] init] autorelease];
		[mailComposeViewController setSubject:[NSString stringWithFormat:@"[%@] %@", [[NSProcessInfo processInfo] processName], [self.path lastPathComponent]]];
        [mailComposeViewController setMessageBody:[[Section sectionsToString:[sections objectEnumerator] includeTags:YES] stringByReplacingOccurrencesOfString:@"\t" withString:@"    "] isHTML:NO];
		mailComposeViewController.mailComposeDelegate = self;
		[APP_VIEW_CONTROLLER presentModalViewController:mailComposeViewController animated:YES];
	}
}

- (IBAction)archive:(id)sender {
    Section *archiveProject = [tree firstSubtreeSectionMatchingPredicate:[NSPredicate predicateWithFormat:@"type == %i AND content like[cd] %@", TaskPaperSectionTypeProject, NSLocalizedString(@"Archive", nil)]];
    NSArray *doneEntries = [tree subtreeSectionsMatchingPredicate:[NSPredicate predicateWithFormat:@"ANY tags.name == \"done\""]];
    doneEntries = [doneEntries filteredArrayUsingPredicate:[[QueryParser sharedInstance] parse:@"not project Archive" highlight:nil]];
    doneEntries = [Section commonAncestorsForSections:[doneEntries objectEnumerator]];
    
    if ([doneEntries count] > 0) {
        [self.taskView beginUpdates];
        [tree beginChangingSections];
        
        if (!archiveProject) {
            archiveProject = [[[TaskPaperSection alloc] initWithString:NSLocalizedString(@"Archive", nil)] autorelease];
            archiveProject.type = TaskPaperSectionTypeProject;
            [tree addSubtreeSectionsObject:archiveProject];
        }
        
        for (Section *each in [doneEntries reverseObjectEnumerator]) {
            NSMutableString *projects = nil;
            Section *parent = each;
            
            while (parent) {
                if (parent.type == TaskPaperSectionTypeProject) {
                    if (projects) {
                        [projects insertString:[NSString stringWithFormat:@"%@ / ", parent.content] atIndex:0];
                    } else {
                        projects = [[[NSMutableString alloc] initWithString:parent.content] autorelease];
                    }
                }
                parent = parent.parent;
            }
            
            if (projects && [projects length] > 0) {
                [each addTag:[Tag tagWithName:@"project" value:[Tag validateTagValue:projects]]];
            }
            
            [archiveProject insertChildrenObject:each after:nil];
        }
        
        [tree endChangingSections];
        [tree commitCurrentPatch:NSLocalizedString(@"Archive Done", nil)];
        [self.taskView endUpdates];
        
        NSString *previousSectionSearchString = self.sectionSearchString;
        sectionSearchString = @"";
        self.sectionSearchString = previousSectionSearchString;
        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Nothing to Archive", nil) message:NSLocalizedString(@"There is nothing tagged with @done that needs to be archived.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    }
}

- (IBAction)deleteDocument:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Document", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Are you sure that you want to delete \"%@\"?", nil), [APP_VIEW_CONTROLLER displayNameForPath:self.path isDirectory:NO]] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Delete", nil), nil];
	[alertView show];
	[alertView release];
}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if ([alertView.title isEqualToString:NSLocalizedString(@"Delete Document", nil)]) {
		if (buttonIndex == 1) { // Delete OK
            NSError *error;
            if (![PATH_CONTROLLER removeItemAtPath:self.path error:&error]) {
                [APP_VIEW_CONTROLLER presentError:error];
            }
            [self.browserViewController pop:YES];
		}
	} 
}

#pragma mark -
#pragma mark MFMailComposeViewController delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	if (result == MFMailComposeResultFailed) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Error Emailing Document", nil), nil] message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
		[alertView show];
		[alertView release];		
	}
	[APP_VIEW_CONTROLLER dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma Search
@synthesize sectionSearchString;
- (void)setSectionSearchString:(NSString *)aString {
	if (aString != sectionSearchString && ![aString isEqualToString:sectionSearchString]) {
		[sectionSearchString release];
		sectionSearchString = [aString retain];
		
		[self updateSearch];
	}
}

- (void)updateSearch {
    if (self.taskView.editedRow != NSNotFound) {
        [self.taskView commitAndRemoveFieldEditor];
    }
    
 	[sections release];
    if ([sectionSearchString length] > 0) {
		sections = [[tree subtreeSectionsMatchingPredicate:[[QueryParser sharedInstance] parse:sectionSearchString highlight:nil] includeAncestors:YES includeDescendants:NO] retain];		
		if ([sections count] == 0) {
			self.taskView.placeholderText = NSLocalizedString(@"No Results", nil);
		} else {
			self.taskView.placeholderText = nil;
		}
	} else {
		sections = (id)[[tree.enumeratorOfSubtreeSections allObjects] retain];
		self.taskView.placeholderText = nil;
	}
    
    [self.taskView reloadData];
    
    if (sectionSearchString != nil && ![self.searchViewController.searchView.text isEqualToString:sectionSearchString]) {
        [self.searchViewController updateSearchText:sectionSearchString];
        CGRect searchFrame = self.browserViewController.browserView.searchbar.frame;
        CGFloat searchY = searchFrame.origin.y + searchFrame.size.height;
        [self.taskView setContentOffset:CGPointMake(0, -searchY) animated:YES];
    }
}

#pragma mark -
#pragma SearchViewController delegate
- (void)searchViewTextDidChange:(SearchViewController *)aSearchViewController {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:LiveSearchEnabledKey] || [aSearchViewController.searchView.text length] == 0) {
		self.sectionSearchString = aSearchViewController.searchView.text;
	}
}

- (void)searchViewShouldReturn:(UITextField *)textField {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:LiveSearchEnabledKey]) {
        self.sectionSearchString = textField.text;
    }
}

#pragma mark -
#pragma mark Toolbar Menu
static NSPredicate *projectsPredicate = nil;

- (MenuView *)buildProjectsMenuView:(BOOL)isSearch {
	if (!projectsPredicate) {		
		projectsPredicate = [[[QueryParser sharedInstance] parse:@"type = \"project\"" highlight:nil] retain];
	}
	
	MenuView *menuView = [MenuView sharedInstance];
    
	NSArray *projects = [tree subtreeSectionsMatchingPredicate:projectsPredicate];
	if ([projects count] > 0) {
		[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Go to Project...", nil) indentationLevel:0 enabled:NO]];
		for (TaskPaperSection *each in projects) {
            if (isSearch) {
                [menuView addItem:[MenuViewItem menuViewItem:each.content indentationLevel:each.level + 1 enabled:YES checked:NO userData:[each goToProjectSearchText]]];
            } else {
                [menuView addItem:[MenuViewItem menuViewItem:each.content indentationLevel:each.level + 1 enabled:YES checked:NO userData:each]];
            }
		}
	} else {
		[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"No Projects", nil) indentationLevel:0 enabled:NO]];
	}
	
	menuView.target = self;
	menuView.action = @selector(showProjectsMenuChoice:);
    menuView.longPressAction = @selector(showMenuChoiceNot:);
    menuView.anchorView = [self.browserViewController.browserView.toolbar.toolbarItems objectAtIndex:0];
	menuView.anchorRelativePosition = PositionUpRight;
    //menuView.shiftDown = YES;
	
	return menuView;
}

- (void)showProjectsMenuChoice:(MenuView *)aMenuView {
	[aMenuView close];
     NSString *userData  = [[[aMenuView selectedItems] lastObject] userData];
	self.sectionSearchString = userData;
}

- (IBAction)showProjects:(id)sender {
	if (selectionChangedWhileShiftKeyDown) {
		selectionChangedWhileShiftKeyDown = NO;
		return;
	}
	
    [[self buildProjectsMenuView:YES] show];
}

- (MenuView *)buildTagsMenuView {
	MenuView *menuView = [MenuView sharedInstance];
	NSMutableArray *tags = [[tree.allTagNames mutableCopy] autorelease];
	
	for (NSString *eachTag in [[[NSUserDefaults standardUserDefaults] stringForKey:DefaultTagsKey] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,"]]) {
		if ([eachTag length] > 0) {
			if (![tags containsObject:eachTag]) {
				[tags addObject:eachTag];
			}
		}
	}
	
	if ([tags count] > 0) {
		[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Go to Tag...", nil) indentationLevel:0 enabled:NO]];
	} else {
		[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"No Tags", nil) indentationLevel:0 enabled:NO]];
	}
    
	[tags sortUsingSelector:@selector(caseInsensitiveCompare:)];
	
	for (NSString *each in tags) {
		[menuView addItem:[MenuViewItem menuViewItem:[NSString stringWithFormat:@"@%@", each] indentationLevel:1 enabled:YES]];
	}
	
	menuView.target = self;
	menuView.action = @selector(showTagsMenuChoice:);
    menuView.longPressAction = @selector(showMenuChoiceNot:);
    menuView.anchorView = [self.browserViewController.browserView.toolbar.toolbarItems objectAtIndex:2];
	menuView.anchorRelativePosition = PositionUp;
	//menuView.shiftDown = YES;
    
	return menuView;
}

- (IBAction)showTags:(id)sender {
	if (selectionChangedWhileShiftKeyDown) {
		selectionChangedWhileShiftKeyDown = NO;
		return;
	}
	
	[[self buildTagsMenuView] show];
}

- (void)showTagsMenuChoice:(MenuView *)aMenuView {
	[aMenuView close];
	self.sectionSearchString = [[[aMenuView selectedItems] lastObject] text];
}

- (void)showMenuChoiceNot:(MenuView *)aMenuView {
    [aMenuView close];
    NSString *tagString = [[aMenuView longPressItem] text];
    if ([tagString hasPrefix:@"@"]) {
        if (self.sectionSearchString.length > 0) {
            self.sectionSearchString = [NSString stringWithFormat:@"%@ AND not %@", self.sectionSearchString, tagString];
        } else {
            self.sectionSearchString = [NSString stringWithFormat:@"not %@", tagString];
        }
    } else {
        if (self.sectionSearchString.length > 0) {
            self.sectionSearchString = [NSString stringWithFormat:@"%@ AND not project = %@", self.sectionSearchString, tagString];
        } else {
            self.sectionSearchString = [NSString stringWithFormat:@"not project = %@", tagString];
        }
    }
}

- (IBAction)showActions:(id)sender {
	if (selectionChangedWhileShiftKeyDown) {
		selectionChangedWhileShiftKeyDown = NO;
		return;
	}
	
	MenuView *menuView = [MenuView sharedInstance];
	
   	BOOL hasSelection = [self.taskView.selectedSections count] > 0;
    
    if (IS_IPAD) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:DocumentFocusModeDefaultsKey]) {
            [menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Focus Out", nil) indentationLevel:0 enabled:YES checked:NO userData:@"focusout"]];
        } else {
            [menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Focus In", nil) indentationLevel:0 enabled:YES checked:NO userData:@"focusin"]];
        }
        [menuView addItem:[MenuViewItem separatorItem]];
    }
    
    if (NSClassFromString(@"UIPrintInteractionController")) {
		[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Print", nil) indentationLevel:0 enabled:YES checked:NO userData:@"print"]];
	}
    [menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Email", nil) indentationLevel:0 enabled:YES checked:NO userData:@"email"]];
    [menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Archive Done", nil) indentationLevel:0 enabled:YES checked:NO userData:@"archive"]];
    
    [menuView addItem:[MenuViewItem separatorItem]];
    
    [menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Move to...", nil) indentationLevel:0 enabled:hasSelection]];
	[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Tag with...", nil) indentationLevel:0 enabled:hasSelection]];
	[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Item Type...", nil) indentationLevel:0 enabled:hasSelection]];
	[menuView addItem:[MenuViewItem separatorItem]];    
	[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Edit", nil) indentationLevel:0 enabled:hasSelection]];
	[menuView addItem:[MenuViewItem separatorItem]];
	[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Cut", nil) indentationLevel:0 enabled:hasSelection]];
	[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Copy", nil) indentationLevel:0 enabled:hasSelection]];
	[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Paste", nil) indentationLevel:0 enabled:[[UIPasteboard generalPasteboard] valueForPasteboardType:(id)kUTTypeUTF8PlainText] != nil]];
	[menuView addItem:[MenuViewItem separatorItem]];
	[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Delete", nil) indentationLevel:0 enabled:hasSelection]];
	
	menuView.target = self;
	menuView.action = @selector(showActionsMenuChoice:);
    menuView.anchorView = [self.browserViewController.browserView.toolbar.toolbarItems objectAtIndex:6];
	menuView.anchorRelativePosition = PositionUpLeft;
    
	[menuView show];
}

- (void)showActionsMenuChoice:(MenuView *)aMenuView {
    
	NSString *menu = [[[aMenuView selectedItems] lastObject] text];
    if ([menu isEqualToString:NSLocalizedString(@"Focus In", nil)]) {
        [APP_VIEW_CONTROLLER.view performSelector:@selector(toggleDocumentFocusMode:) withObject:nil];
    } else if ([menu isEqualToString:NSLocalizedString(@"Focus Out", nil)]) {
        [APP_VIEW_CONTROLLER.view performSelector:@selector(toggleDocumentFocusMode:) withObject:nil];        
    } else if ([menu isEqualToString:NSLocalizedString(@"Print", nil)]) {
        [self print:nil];
        [aMenuView close];
    } else if ([menu isEqualToString:NSLocalizedString(@"Email", nil)]) {
        [self email:nil];
        [aMenuView close];
    } else if ([menu isEqualToString:NSLocalizedString(@"Archive Done", nil)]) {
        [self archive:nil];
        [aMenuView close];
    }
    
    if ([menu isEqualToString:NSLocalizedString(@"Cut", nil)]) {
        [aMenuView close];
		[self cut:nil];
	} else if ([menu isEqualToString:NSLocalizedString(@"Copy", nil)]) {
        [aMenuView close];
		[self copy:nil];
	} else if ([menu isEqualToString:NSLocalizedString(@"Paste", nil)]) {
        [aMenuView close];
		[self paste:nil];
	} else if ([menu isEqualToString:NSLocalizedString(@"Delete", nil)]) {
        [aMenuView close];
		[self delete:nil];
	} else if ([menu isEqualToString:NSLocalizedString(@"Edit", nil)]) {
        [aMenuView close];
		[self.taskView beginFieldEditorForRow:[self.taskView.selectedRows lastIndex]];
		[[IPhoneDocumentViewFieldEditor sharedInstance] setSelectedRange:NSMakeRange(0, 0)];
	} else if ([menu isEqualToString:NSLocalizedString(@"Move to...", nil)]) {
        [aMenuView removeAllItems];
		MenuView *menuView = [self buildProjectsMenuView:NO];
		[[menuView.items objectAtIndex:0] setText:NSLocalizedString(@"Move to...", nil)];
		menuView.action = @selector(moveToMenuChoice:);
        menuView.anchorView = [self.browserViewController.browserView.toolbar.toolbarItems objectAtIndex:6];
        menuView.anchorRelativePosition = PositionUpLeft;
		[menuView show];
	} else if ([menu isEqualToString:NSLocalizedString(@"Tag with...", nil)]) {
        [aMenuView removeAllItems];
		MenuView *menuView = [self buildTagsMenuView];
		if ([menuView.items count] > 1) {
			[[menuView.items objectAtIndex:0] setText:NSLocalizedString(@"Tag with...", nil)];
		}
        menuView.anchorView = [self.browserViewController.browserView.toolbar.toolbarItems objectAtIndex:6];
        menuView.anchorRelativePosition = PositionUpLeft;
		menuView.action = @selector(tagWithMenuChoice:);
		[menuView show];
	} else if ([menu isEqualToString:NSLocalizedString(@"Item Type...", nil)]) {
        [aMenuView removeAllItems];
		MenuView *menuView = [MenuView sharedInstance];
		[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Change to Task", nil) indentationLevel:0 enabled:YES]];
		[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Change to Note", nil) indentationLevel:0 enabled:YES]];
		[menuView addItem:[MenuViewItem menuViewItem:NSLocalizedString(@"Change to Project", nil) indentationLevel:0 enabled:YES]];
		menuView.target = self;
		menuView.action = @selector(changeTypeMenuChoice:);
		menuView.anchorRelativePosition = PositionCentered;
		menuView.anchorView = nil;
		[menuView show];
	}
}


- (void)moveToMenuChoice:(MenuView *)aMenuView {
	NSArray *selectedSections = [Section commonAncestorsForSections:[self.taskView.selectedSections objectEnumerator]];
	Section *moveToProject = [[[aMenuView selectedItems] lastObject] userData];
    
	[aMenuView close];
    
	if (moveToProject) {
		[self.taskView beginUpdates];
		[tree beginChangingSections];
		for (Section *each in selectedSections) {
			if ([moveToProject isDecendent:each] || moveToProject == each || each == moveToProject.lastChild) {
				NSLog(@"couldn't move");
			} else {
				[moveToProject insertChildrenObject:each after:moveToProject.leftmostDescendantOrSelf];
			}			
		}
		[self.taskView endUpdatesAnimated:YES];
		[tree endChangingSections];
        [tree commitCurrentPatch:NSLocalizedString(@"Move to...", nil)];
		[self.taskView setSelectedRows:[sections indexesOfObjects:selectedSections]];
		return;
	}
}

- (void)tagWithMenuChoice:(MenuView *)aMenuView {
	NSArray *selectedSections = self.taskView.selectedSections;
	NSString *tagName = [[[[aMenuView selectedItems] lastObject] text] substringFromIndex:1];
	BOOL allHaveTags = YES;
    
	[aMenuView close];
    
	for (Section *each in selectedSections) {
		if (![each tagWithName:tagName]) {
			allHaveTags = NO;
		}
	}
    
	[tree beginChangingSections];
	for (Section *each in selectedSections) {
		if (allHaveTags) {
			Tag *eachTag = [each tagWithName:tagName];
			if (eachTag) {
				[each removeTag:eachTag];
			}
		} else {
			[each tagWithName:tagName createIfNeccessary:YES];
		}
	}
	[tree endChangingSections];
    [tree commitCurrentPatch:NSLocalizedString(@"Tag with...", nil)];
}

- (void)changeTypeMenuChoice:(MenuView *)aMenuView {
	NSArray *selectedSections = self.taskView.selectedSections;
	NSString *menu = [[[aMenuView selectedItems] lastObject] text];
    
	[aMenuView close];
	
	[tree beginChangingSections];
	for (Section *each in selectedSections) {
		if ([menu isEqualToString:NSLocalizedString(@"Change to Task", nil)]) {
			each.type = TaskPaperSectionTypeTask;
		} else if ([menu isEqualToString:NSLocalizedString(@"Change to Note", nil)]) {
			each.type = TaskPaperSectionTypeNote;
		} else {
			each.type = TaskPaperSectionTypeProject;
		}
	}
	[tree endChangingSections];
    [tree commitCurrentPatch:menu];
}



- (IBAction)delete:(id)sender {
	[self.taskView beginUpdates];
	[tree beginChangingSections];
	for (Section *each in [Section commonAncestorsForSections:[self.taskView.selectedSections objectEnumerator]]) {
		[each removeFromParent];
	}
	[tree endChangingSections];
    [tree commitCurrentPatch:NSLocalizedString(@"Delete", nil)];
	[self.taskView endUpdatesAnimated:YES];
}

- (IBAction)cut:(id)sender {
	[self.taskView beginUpdates];
	[tree beginChangingSections];
	[self copy:sender];
	for (Section *each in [Section commonAncestorsForSections:[self.taskView.selectedSections objectEnumerator]]) {
		[each removeFromParent];
	}
	[tree endChangingSections];
    [tree commitCurrentPatch:NSLocalizedString(@"Cut", nil)];
	[self.taskView endUpdatesAnimated:YES];
}

- (IBAction)copy:(id)sender {
	NSMutableArray *allSelectedSections = [NSMutableArray array];
	NSArray *selectedSections = [Section commonAncestorsForSections:[self.taskView.selectedSections objectEnumerator]];
	for (Section *each in selectedSections) {
		[allSelectedSections addObjectsFromArray:[each.descendantsWithSelf allObjects]];
	}
	NSString *sectionsAsString = [Section sectionsToString:[allSelectedSections objectEnumerator] includeTags:YES];
	[[UIPasteboard generalPasteboard] setValue:sectionsAsString forPasteboardType:(id)kUTTypeUTF8PlainText];
}

- (IBAction)paste:(id)sender {
	Section *section = [self.taskView.selectedSections lastObject];
	NSString *sectionsAsString = [[UIPasteboard generalPasteboard] valueForPasteboardType:(id)kUTTypeUTF8PlainText];
	NSArray *pastedSections = [Section sectionsFromString:sectionsAsString];
	
	if (!section) section = tree.lastSection;
	
	[self.taskView beginUpdates];
	[tree beginChangingSections];
	for (Section *each in [pastedSections reverseObjectEnumerator]) {
		[tree insertSubtreeSection:each after:section];
	}
	[tree endChangingSections];
    [tree commitCurrentPatch:NSLocalizedString(@"Paste", nil)];
	[self.taskView endUpdatesAnimated:YES];
	[self.taskView setSelectedRows:[sections indexesOfObjects:pastedSections]];
}

#pragma mark TreeChanged notifications

- (void)treeChangedNotification:(NSNotification *)aNotification {
	NSDictionary *userInfo = [aNotification userInfo];
	
	NSMutableIndexSet *insertedIndexes = nil;
	NSMutableIndexSet *updatedIndexes = nil;
	NSMutableIndexSet *deletedIndexes = nil;
	NSArray *insertedSectionsSortedByTreeIndex = [[[userInfo objectForKey:InsertedSectionsKey] allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"treeIndexPath" ascending:YES] autorelease]]];
	Section *editedSection = self.taskView.editedSection;
	TrackedLocation *editLocation = editedSection == nil ? nil : [TrackedLocation trackedLocationWithSection:editedSection offset:0];
    
	if (editLocation) {
		[tree addTrackedLocation:editLocation];
	}
	
	for (Section *eachDeleted in [userInfo objectForKey:DeletedSectionsKey]) {
		NSUInteger index = [sections indexOfObject:eachDeleted];
		if (index != NSNotFound) {
			if (!deletedIndexes) deletedIndexes = [NSMutableIndexSet indexSet];
			[deletedIndexes addIndex:index];
		}
	}
    
	if (deletedIndexes) {
		[sections removeObjectsAtIndexes:deletedIndexes];
	}
	
	for (Section *eachInserted in insertedSectionsSortedByTreeIndex) {
		Section *treeOrderPrevious = eachInserted.treeOrderPrevious;
		NSUInteger insertIndex = NSNotFound;
		
		while (insertIndex == NSNotFound && treeOrderPrevious != nil) {
			insertIndex = [sections indexOfObject:treeOrderPrevious];
			if (insertIndex != NSNotFound) {
				insertIndex++;
			}
			treeOrderPrevious = treeOrderPrevious.treeOrderPrevious;
		}
		
		if (insertIndex == NSNotFound) insertIndex = 0;
		[sections insertObject:eachInserted atIndex:insertIndex];
		if (!insertedIndexes) insertedIndexes = [NSMutableIndexSet indexSet];
        
		[insertedIndexes addIndex:insertIndex];        
	}
    
	for (Section *eachUpdated in [userInfo objectForKey:UpdatedSectionsKey]) {
		NSUInteger index = [sections indexOfObject:eachUpdated];
		if (index != NSNotFound) {
			if (!updatedIndexes) updatedIndexes = [NSMutableIndexSet indexSet];
			[updatedIndexes addIndex:index];
		}
	}
	
	[self.taskView beginUpdates];
    
	NSUInteger newEditedRow = NSNotFound;
	if (editLocation) {
		editedSection = editLocation.section;
		newEditedRow = [sections indexOfObject:editedSection];
		[tree removeTrackedLocation:editLocation];
		if (newEditedRow != self.taskView.editedRow) {
			self.taskView.editedRow = NSNotFound;
		}
	}
	
	if (insertedIndexes) [self.taskView insertRows:insertedIndexes animated:NO];
	if (updatedIndexes) [self.taskView reloadRows:updatedIndexes animated:NO];
	if (deletedIndexes) [self.taskView removeRows:deletedIndexes animated:NO];	
    
	[self.taskView endUpdates];
	
	if (newEditedRow != self.taskView.editedRow) {
		self.taskView.editedRow = newEditedRow;
	}
}

#pragma mark DocumentView Delegate


- (NSUInteger)numberOfRowsInDocumentView:(TaskView *)documentView {
	return [sections count];
}

- (Section *)documentView:(TaskView *)documentView sectionForRow:(NSUInteger)row {
    if ([sections count] > row) {
        return [sections objectAtIndex:row];        
    }
    return nil;
}

- (NSUInteger)documentView:(TaskView *)documentView rowForSection:(Section *)aSection {
	return [sections indexOfObject:aSection];
}

- (IPhoneDocumentViewCell *)documentView:(TaskView *)aDocumentView cellForRow:(NSUInteger)row {
	IPhoneDocumentViewCell *cell = [self.taskView dequeueReusableCell];
	
	if (!cell) {
		cell = [[[IPhoneDocumentViewCell alloc] init] autorelease];
	}
    
	cell.selected = [self.taskView.selectedRows containsIndex:row];
	cell.secondarySelected = [self.taskView.selectedRowsCover containsIndex:row];
	cell.edited = self.taskView.editedRow == row;
	cell.section = [sections objectAtIndex:row];
	
	return cell;
}

- (void)documentView:(TaskView *)aDocumentView tapAtPoint:(CGPoint)aPoint {
}

- (void)documentView:(TaskView *)aDocumentView touchAtPoint:(CGPoint)aPoint {
	NSMutableIndexSet *selelectedRows = [[self.taskView.selectedRows mutableCopy] autorelease];
	NSUInteger row = [self.taskView rowAtPoint:aPoint];
    
	if (shiftKeyDown) {
		if (row != NSNotFound) {
			if ([selelectedRows containsIndex:row]) {
				[selelectedRows removeIndex:row];
			} else {
				[selelectedRows addIndex:row];
			}
		}
		selectionChangedWhileShiftKeyDown = YES;
	} else {
		if (row == NSNotFound) {
			[selelectedRows removeAllIndexes];			
		} else if (![selelectedRows containsIndex:row]) {
			[selelectedRows removeAllIndexes];
			[selelectedRows addIndex:row];
		}
	}
    
	if (![self.taskView.selectedRows isEqualToIndexSet:selelectedRows]) {
		[self.taskView beginUpdates];
		self.taskView.selectedRows = selelectedRows;
		[self.taskView endUpdatesAnimated:NO];
	}	
}

- (void)documentView:(TaskView *)aDocumentView doubleTapAtPoint:(CGPoint)aPoint {
	if (!shiftKeyDown) {
		[self.taskView beginFieldEditorForRowAtPoint:aPoint];
	}
}

- (void)documentView:(TaskView *)aDocumentView twoFingerTapAtPoint:(CGPoint)aPoint {
}

- (void)documentView:(TaskView *)aDocumentView swipeRightFromPoint:(CGPoint)aPoint {
	NSUInteger row = [self.taskView rowAtPoint:aPoint];
	Section *section = [sections objectAtIndex:row];
	Tag *done = [section tagWithOnlyName:@"done"];
	
	[self.taskView beginUpdates];
	if (done) {
		[section removeTag:done];
	} else {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:AddDateToDoneTagKey]) {
			[section addTag:[Tag tagWithName:@"done" value:[[Tag tagDateFormatter] stringFromDate:[NSDate date]]]];
		} else {
			[section addTag:[Tag tagWithName:@"done" value:@""]];
		}
	}
    [tree commitCurrentPatch:@"@done"];
	[self.taskView endUpdatesAnimated:YES];
}


- (void)showContextMenuForRow:(NSUInteger)aRow {
    TaskView *taskView = self.taskView;
	[taskView becomeFirstResponder];
	UIMenuController *theMenu = [UIMenuController sharedMenuController];
	[theMenu setTargetRect:[taskView rectForRow:aRow] inView:taskView];
    [theMenu setMenuVisible:YES animated:YES];
}

- (void)documentView:(TaskView *)aDocumentView swipeLeftFromPoint:(CGPoint)aPoint {
	[self showContextMenuForRow:[aDocumentView rowAtPoint:aPoint]];
}

- (void)documentView:(TaskView *)aDocumentView deleteRow:(NSUInteger)aRow {
	Section *delete = [sections objectAtIndex:aRow];
	[self.taskView beginUpdates];
	[delete.tree removeSubtreeSectionsObject:delete includeChildren:YES];
	[self.taskView endUpdatesAnimated:YES];
}

- (void)delayedBeginFieldEditorForRow:(NSNumber *)number {
	[self.taskView beginFieldEditorForRow:[number integerValue]];
}

- (BOOL)documentView:(TaskView *)aDocumentView fieldEditor:(IPhoneDocumentViewFieldEditor *)fieldEditor shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	NSUInteger returnLocation = [text rangeOfString:@"\n"].location;
    
	[[MenuView sharedInstance] close];
	
	if (returnLocation != NSNotFound) {
		[fieldEditor myAcceptAutocorrection];
		
		if ([fieldEditor.text length] < range.location) {
			range.location = [fieldEditor.text length];
			range.length = 0;
		}
        
		NSString *remaining = [[fieldEditor.text substringToIndex:range.location] stringByAppendingString:[text substringToIndex:returnLocation]];
		NSString *trailing = [fieldEditor.text substringFromIndex:NSMaxRange(range)];
		NSMutableArray *lines = [[[text componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
		[lines removeObjectAtIndex:0]; // already added to remainign
		NSUInteger sectionIndex = self.taskView.editedRow;
		Section *section = [sections objectAtIndex:sectionIndex];
		
		if ([text isEqualToString:@"\n"] && [remaining length] == 0 && [trailing length] == 0) {
			switch (section.type) {
				case TaskPaperSectionTypeProject:
					section.type = TaskPaperSectionTypeTask;
					break;
				case TaskPaperSectionTypeTask:
					section.type = TaskPaperSectionTypeNote;
					break;
				case TaskPaperSectionTypeNote:
					section.type = TaskPaperSectionTypeProject;
					break;
			}
			return NO;
		} else {
			NSString *lastLine = [[lines lastObject] stringByAppendingString:trailing];
			
			fieldEditor.text = remaining;
			fieldEditor.uncommitedChanges = YES;
			
			[lines removeLastObject];
			[lines addObject:lastLine];
			
			NSUInteger insertCount = 0;
			Section *insertAfterSection = section;
			NSUInteger insertLevel = insertAfterSection.level;
			
			[tree beginChangingSections];
			[self.taskView commitFieldEditor];
            
			if ([lines count] == 1) {
				Section *newSection = [[[TaskPaperSection alloc] initWithString:[lines lastObject]] autorelease];
				
				switch (section.type) {
					case TaskPaperSectionTypeProject:
						newSection.type = TaskPaperSectionTypeTask;
						insertLevel++;
						break;
					case TaskPaperSectionTypeTask:
						newSection.type = TaskPaperSectionTypeTask;
						break;
					case TaskPaperSectionTypeNote:
						newSection.type = TaskPaperSectionTypeNote;
						break;
				}
				
				newSection.level += insertLevel;
				[section.tree insertSubtreeSection:newSection after:insertAfterSection];
				insertAfterSection = newSection;
				insertCount++;
			} else {
				for (NSString *each in [lines objectEnumerator]) {
					Section *newSection = [[[TaskPaperSection alloc] initWithString:each] autorelease];
					newSection.level += insertLevel;
					[section.tree insertSubtreeSection:newSection after:insertAfterSection];
					insertAfterSection = newSection;
					insertCount++;
				}
			}
			[tree endChangingSections];
			
			NSRange insertRange = NSMakeRange(sectionIndex + 1, insertCount);
			[self.taskView layoutSubviews];
			[self.taskView beginFieldEditorForRow:NSMaxRange(insertRange) - 1];
			[fieldEditor setSelectedRange:NSMakeRange([lastLine length] - [trailing length], 0)];
			return NO;
		}
	} else if (NSEqualRanges(range, NSMakeRange(0, 0))) {
		NSInteger levelShift = 0;
		
		if ([text length] == 0) {
			levelShift--;
		} else if ([text isEqualToString:@" "]) {
			levelShift++;
		}
		
		if (levelShift != 0) {
			Section *section = [sections objectAtIndex:self.taskView.editedRow];
            fieldEditor.uncommitedChanges = YES;
			if (section.level > 0 || levelShift > 0) {
				[tree beginChangingSections];
				[section setLevel:section.level + levelShift includeChildren:NO];
				[tree endChangingSections];
				return NO;
			} else {
				Section *treeOrderPrevious = section.treeOrderPrevious;
				
				while (treeOrderPrevious != nil && ![sections containsObject:treeOrderPrevious]) {
					treeOrderPrevious = treeOrderPrevious.treeOrderPrevious;
				}
				
				if (treeOrderPrevious) {
					NSRange nextSelectedRange = NSMakeRange([treeOrderPrevious.content length], 0);
					treeOrderPrevious.content = [treeOrderPrevious.content stringByAppendingString:section.content];
					[tree beginChangingSections];
					[self.taskView commitFieldEditor];
					[self.taskView beginUpdates];
					[tree removeSubtreeSectionsObject:section includeChildren:NO];
					[self.taskView beginFieldEditorForRow:self.taskView.editedRow - 1];
					[tree endChangingSections];
					[self.taskView endUpdatesAnimated:NO];
					[fieldEditor setSelectedRange:nextSelectedRange];
					return NO;
				}
			}
		}
	} else if ([text isEqualToString:@":"]) {
		NSUInteger sectionIndex = self.taskView.editedRow;
		Section *section = [sections objectAtIndex:sectionIndex];
		if (NSMaxRange(range) == [section.content length]) {
			[section replaceContentInRange:range withString:@": "];
			[fieldEditor setSelectedRange:NSMakeRange(NSMaxRange(range) + 1, 0)];
			return NO;
		}
	}
	
	return YES;
}



- (void)documentViewStartedDrag:(TaskView *)aDocumentView {
	NSArray *selectedRoots = [Section commonAncestorsForSections:[aDocumentView.selectedSections objectEnumerator]];
	NSMutableArray *draggedSections = [NSMutableArray array];
	
	for (Section *each in selectedRoots) {
		[draggedSections addObjectsFromArray:[[each descendantsWithSelf] allObjects]];
	}
	
	NSString *sectionsAsString = [Section sectionsToString:[draggedSections objectEnumerator] includeTags:NO];
    sectionsAsStringOnDragging = [sectionsAsString copy];
    
	[aDocumentView beginUpdates];
	[tree beginChangingSections];
	[selectedRoots makeObjectsPerformSelector:@selector(removeFromParent)];
	[tree endChangingSections];
	[aDocumentView setSelectedRows:[NSIndexSet indexSet]];
	[aDocumentView endUpdatesAnimated:YES];
	aDocumentView.multipleTouchEnabled = NO;
}

- (void)documentViewEndedDrag:(TaskView *)aDocumentView {
	NSUInteger droppedRow = self.taskView.droppedRow;
	NSUInteger droppedLevel = self.taskView.dropLevel;
	Section *afterSection = nil;
	
	if (droppedRow < [sections count]) {
		afterSection = [sections objectAtIndex:droppedRow];
		if (self.taskView.droppedAbove) {
			afterSection = afterSection.treeOrderPrevious;
		}
	}
	
    NSArray *draggedSections = [Section sectionsFromString:sectionsAsStringOnDragging];
    [sectionsAsStringOnDragging release];
    
	[self.taskView beginUpdates];
	[tree beginChangingSections];
	for (Section *each in draggedSections) {
		each.level = droppedLevel;
		[tree insertSubtreeSection:each after:afterSection];
		afterSection = each;
	}
	[tree endChangingSections];
    [tree commitCurrentPatch:NSLocalizedString(@"Move", nil)];
    NSLog(@"commitCurrentPatch:Move");
	[self.taskView endUpdatesAnimated:YES];
	[self.taskView setSelectedRows:[sections indexesOfObjects:draggedSections]];
	self.taskView.multipleTouchEnabled = YES;
}

#pragma mark -
#pragma mark Shift Key
- (void)shiftKeyDown:(id)sender {
	shiftKeyDown = YES;
}

- (void)shiftKeyUp:(id)sender {
	shiftKeyDown = NO;
}

- (void)addShiftKeyListeners {
	for (UIView *each in self.browserViewController.browserView.toolbar.toolbarItems) {
        if ([each isKindOfClass:[Button class]]) {
            Button *button = (Button*)each;
            [button addTarget:self action:@selector(shiftKeyDown:) forControlEvents:UIControlEventTouchDown];
            [button addTarget:self action:@selector(shiftKeyUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];            
        }
	}    
}

- (void)removeShiftKeyListeners {
	for (Button *each in self.browserViewController.browserView.toolbar.toolbarItems) {
        if ([each isKindOfClass:[Button class]]) {
            Button *button = (Button*)each;
            [button removeTarget:self action:@selector(shiftKeyDown:) forControlEvents:UIControlEventTouchDown];
            [button removeTarget:self action:@selector(shiftKeyUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        }
	}      
}


@end

NSString *DefaultTagsKey = @"DefaultTagsKey";
NSString *AddDateToDoneTagKey = @"AddDateToDoneTagKey";
NSString *LiveSearchEnabledKey = @"LiveSearchEnabledKey";

