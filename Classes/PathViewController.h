//
//  BrowserViewController.h
// PlainText
//
//  Created by Jesse Grosjean on 6/24/10.
//

#import "TextFieldViewController.h"
#import "SMTEDelegateController.h"

@class PathViewController;
@class PathViewWrapper;
@class MenuView;

@protocol PathViewControllerDelegate <NSObject>
- (MenuView *)pathViewPopupMenuView:(PathViewController *)aPathTextFieldController;
- (void)pathViewChangedTitle:(PathViewController *)aPathTextFieldController;
- (void)pathViewReturnKeypressed:(PathViewController *)aPathTextFieldController;
- (void)pathViewWillChangePath:(PathViewController *)aPathTextFieldController from:(NSString *)oldPath to:(NSString *)newPath;
- (void)pathViewDidChangePath:(PathViewController *)aPathTextFieldController from:(NSString *)oldPath to:(NSString *)newPath;
@end

@interface PathViewController : TextFieldViewController {
	NSString *path;
	BOOL isDirectory;
}

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) PathViewWrapper *pathViewWrapper;

- (void)setPath:(NSString *)aPath isDirectory:(BOOL)isDirectory;

@end
