//
//  ApplicationViewController.h
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//

@class BrowserViewController;
@class FileViewController;

#define BROWSER_ANIMATION_DURATION 0.4

enum {
	SortByName = 0,
	SortByNameDescending,
	SortByModified,
	SortByModifiedDescending,
	SortByCreated,
	SortByCreatedDescending
};
typedef NSUInteger SortBy;

enum {
	SortFoldersToTop = 0,
	SortFoldersToBottom,
	SortFoldersWithFiles
};
typedef NSUInteger SortFolders;


void CGContextAddRoundedRect(CGContextRef c, CGRect rect, int corner_radius);
void DrawFadeFunction(CGContextRef context, CGRect bounds, CGColorRef background, CGFloat angle);

@interface ApplicationViewController : UIViewController {
	UIFont *font;
	UIFont *menuFont;
    UIFont *projectFont;
	UIColor *inkColor;
	UIColor *paperColor;
    UIImage *gradientLine;
    UIImage *bullet;
	BOOL tintCursor;
	BOOL showFileExtensions;
	BOOL scrollsHeadings;
	BOOL allCapsHeadings;
	BOOL detectLinks;
	BOOL showStatusBar;
	BOOL textExpanderEnabled;
    BOOL iconBadgeNumberEnabled;
	UITextAutocorrectionType autocorrectionType;
	SortBy sortBy;
	SortFolders sortFolders;
	NSMutableDictionary *inkColorByPercentDictionary;
	CGFloat lineHeightMultiple;
	CGFloat secondaryBrightness;
	BrowserViewController *primaryBrowser;
	BrowserViewController *secondaryBrowser;
	BOOL disableOpenItems;
	BOOL isHardwareKeyboard;
	BOOL isClosingKeyboard;
	BOOL animatingKeyboardOrDocumentFocusMode;
	CGFloat keyboardHeight;
	CGFloat adsHeight;
    BOOL textRightToLeft;
}

@property (nonatomic, readonly) UIFont *font;
@property (nonatomic, readonly) UIFont *menuFont;
@property (nonatomic, readonly) UIFont *projectFont;
@property (nonatomic, readonly) CGFloat leading;
@property (nonatomic, readonly) CGFloat unadjustedLeading;
@property (nonatomic, readonly) UIColor *inkColor;
@property (nonatomic, readonly) UIColor *paperColor;
@property (nonatomic, readonly) UIColor *highlightColor;
@property (nonatomic, readonly) UIKeyboardAppearance keyboardAppearance;
@property (nonatomic, readonly) UIImage *gradientLine;
@property (nonatomic, readonly) UIImage *bullet;


- (UIColor *)inkColorByPercent:(CGFloat)percent;

- (void)clearDefaultsCaches:(BOOL)andRefreshResponders;

@property (nonatomic, readonly) BOOL lockOrientation;
@property (nonatomic, readonly) UIInterfaceOrientation lockedOrientation;
@property (nonatomic, assign) BOOL tintCursor;
@property (nonatomic, readonly) UIImage *selectionDragDotImage;
@property (nonatomic, readonly) UIColor *selectionHighlightColor;
@property (nonatomic, readonly) UIColor *selectionBarColor;
@property (nonatomic, readonly) UIColor *insertionPointColor;
@property (nonatomic, assign) BOOL showFileExtensions;
@property (nonatomic, assign) BOOL scrollsHeadings;
@property (nonatomic, assign) BOOL allCapsHeadings;
@property (nonatomic, assign) BOOL detectLinks;
@property (nonatomic, assign) BOOL showStatusBar;
@property (nonatomic, assign) BOOL textExpanderEnabled;
@property (nonatomic, assign) UITextAutocorrectionType autocorrectionType;
@property (nonatomic, assign) BOOL isHardwareKeyboard;
@property (nonatomic, assign) BOOL isClosingKeyboard;
@property (nonatomic, assign) BOOL animatingKeyboardOrDocumentFocusMode;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, assign) CGFloat adsHeight;
@property (nonatomic, assign) SortBy sortBy;
@property (nonatomic, assign) SortFolders sortFolders;
@property (nonatomic, assign) BOOL textRightToLeft;
@property (nonatomic, assign) BOOL iconBadgeNumberEnabled;

- (NSString *)displayNameForPath:(NSString *)aPath isDirectory:(BOOL)isDirectory;

- (void)search:(NSString *)searchText;
- (IBAction)newFile:(id)sender;
- (IBAction)newFolder:(id)sender;
- (IBAction)showSettings:(id)sender;
- (BOOL)openItem:(NSString *)aPath animated:(BOOL)animated;
- (BOOL)openItem:(NSString *)aPath editingPath:(BOOL)editingPath allowAutosync:(BOOL)allowAutosync animated:(BOOL)animated;
- (void)saveState;
- (void)hideKeyboard;
- (void)hideKeyboardDarnIt;
- (void)presentError:(NSError *)error;
- (void)reloadData;

@end

@interface UIResponder (ApplicationViewController)
- (void)refreshFromDefaults;
@end

@interface UIView (ApplicationViewController)
- (void)refreshSelfAndSubviewsFromDefaults;
@end

extern NSString *DocumentFocusModeDefaultsKey;
extern NSString *LockOrientationDefaultsKey;
extern NSString *LockedOrientationDefaultsKey;
extern NSString *DetectLinksDefaultsKey;
extern NSString *ShowStatusBarDefaultsKey;
extern NSString *ShowFileExtensionsDefaultsKey;
extern NSString *ScrollsHeadingsDefaultsKey;
extern NSString *ExtendedKeyboardDefaultsKey;
extern NSString *ExtendedKeyboardKeysDefaultsKey;
extern NSString *DraggableScrollerDefaultsKey;
extern NSString *AllCapsHeadingsDefaultsKey;
extern NSString *TextExpanderEnabledDefaultsKey;
extern NSString *AutocorrectionTypeDefaultsKey;
extern NSString *SecondaryBrightnessDefaultsKey;
extern NSString *InkColorDefaultsKey;
extern NSString *PaperColorDefaultsKey;
extern NSString *TintCursorDefaultsKey;
extern NSString *SortByDefaultsKey;
extern NSString *FontNameDefaultsKey;
extern NSString *FontSizeDefaultsKey;
extern NSString *LineHeightMultipleDefaultsKey;
extern NSString *SortFoldersDefaultsKey;
extern NSString *TextRightToLeftDefaultsKey;
extern NSString *ShowIconBadgeNumberDefaultsKey;
extern NSString *AllowFlurryDefaultsKey;

extern NSString *KeyboardWillHideNotification;
extern NSString *KeyboardWillShowNotification;
extern NSString *ApplicationViewWillRotateNotification;
extern NSString *DocumentFocusModeAnimationWillStart;
extern NSString *DocumentFocusModeAnimationDidStop;
extern NSString *TextExpanderEnabledChangedNotification;
extern NSString *ShowFileExtensionsChangedNotification;
extern NSString *ScrollsHeadingsChangedNotification;
extern NSString *AllCapsHeadingsChangedNotification;
extern NSString *SortByChangedNotification;
extern NSString *SortFoldersChangedNotification;
extern NSString *DetectLinksChangedNotification;
extern NSString *TextRightToLeftChangedNotification;
extern NSString *ShowIconBadgeNumberChangedNotification;

extern NSString *ToOrientation;
