#import <UIKit/UIKit.h>

@class FontPickerViewController;

@protocol FontPickerViewControllerDelegate <NSObject>
- (void)fontPickerViewController:(FontPickerViewController *)fontPicker didSelectFont:(NSString *)fontName;
@end

@interface FontPickerViewController : UITableViewController {
	id<FontPickerViewControllerDelegate> delegate;
}

@property(nonatomic,assign)	id<FontPickerViewControllerDelegate> delegate;

@end
