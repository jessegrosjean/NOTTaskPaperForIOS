//
//  DocumentViewCell.h
//  TableTest
//
//  Created by Jesse Grosjean on 6/19/09.
//

#import "Section.h"


@class RowData;
@class Section;

@interface IPhoneDocumentViewCell : UIView {
	RowData *rowData;
	Section *section;
	BOOL selected;
	BOOL secondarySelected;
	BOOL edited;
}

+ (CGRect)textRectForSection:(Section *)aSection inBounds:(CGRect)aRect;

@property(retain, nonatomic) RowData *rowData;
@property(retain, nonatomic) Section *section;
@property(assign, nonatomic) BOOL selected;
@property(assign, nonatomic) BOOL secondarySelected;
@property(assign, nonatomic) BOOL edited;

@end

@interface Section (IPhoneDocumentViewCellAdditions)
- (UIFont *)sectionFont;
- (UIColor *)sectionColor;
- (CGSize)sizeThatFits:(CGSize)size;
@end
