#import "FontPickerViewController.h"

NSString *const kFontPickerViewControllerCellIdentifier = @"FontPickerViewControllerCellIdentifier";

@interface FontPickerViewController (PrivateMethods)

- (NSString *)_fontFamilyForSection:(NSInteger)section;
- (NSString *)_fontNameForRow:(NSInteger)row inFamily:(NSString *)family;

@end

@implementation FontPickerViewController

@synthesize delegate;

#pragma mark -
#pragma mark UITableViewController methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[UIFont familyNames] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSString *familyName = [self _fontFamilyForSection:section];
	return [[UIFont fontNamesForFamilyName:familyName] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [self _fontFamilyForSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFontPickerViewControllerCellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kFontPickerViewControllerCellIdentifier] autorelease];
    }
    
    NSString *familyName = [self _fontFamilyForSection:indexPath.section];
	NSString *fontName = [self _fontNameForRow:indexPath.row inFamily:familyName];
	UIFont *font = [UIFont fontWithName:fontName size:[UIFont smallSystemFontSize]];
	
	cell.textLabel.text = fontName;
	cell.textLabel.font = font;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (nil != delegate) {
		NSString *familyName = [self _fontFamilyForSection:indexPath.section];
		NSString *fontName = [self _fontNameForRow:indexPath.row inFamily:familyName];
		[delegate fontPickerViewController:self didSelectFont:fontName];
	}
}

#pragma mark -
#pragma mark Private methods

- (NSString *)_fontFamilyForSection:(NSInteger)section {
	@try {
		return [[UIFont familyNames] objectAtIndex:section];
	}
	@catch (NSException * e) {
		// ignore
	}
	return nil;
}

- (NSString *)_fontNameForRow:(NSInteger)row inFamily:(NSString *)family {
	@try {
		return [[UIFont fontNamesForFamilyName:family] objectAtIndex:row];
	}
	@catch (NSException * e) {
		// ignore
	}
	return nil;
}

@end

