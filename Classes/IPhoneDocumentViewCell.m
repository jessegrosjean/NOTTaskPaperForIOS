//
//  DocumentViewCell.m
//  TableTest
//
//  Created by Jesse Grosjean on 6/19/09.
//

#import "IPhoneDocumentViewCell.h"
#import "TaskView.h"
#import "IPhoneDocumentViewFieldEditor.h"
#import "Section.h"
#import "TaskPaperSection.h"
#import "ApplicationController.h"
#import "ApplicationViewController.h"
#import "UIImage_Additions.h"

#define H_PADDING 8
#define V_PADDING 8
#define LEVEL_WIDTH 20.0

static UIColor *DEFAULT_COLOR = nil;

@implementation IPhoneDocumentViewCell

+ (void)initialize {
	DEFAULT_COLOR = [[UIColor grayColor] retain];
}

- (void)refreshFromDefaults {
    [self setNeedsDisplay];
}

+ (CGRect)textRectForSection:(Section *)aSection inBounds:(CGRect)aRect {
	NSInteger level = aSection.level;
	CGFloat indent = LEVEL_WIDTH * level;
	aRect.origin.y += V_PADDING / 2;
	aRect.size.height -= V_PADDING;
	aRect.origin.x +=  indent + H_PADDING;
	aRect.size.width -= indent + (H_PADDING * 2);
	
	//if (aSection.type == TaskPaperSectionTypeProject) {
	//	aRect.origin.y += PADDING * 1;
	//}
	
	return aRect;
}

- (id)initWithFrame:(CGRect)aFrame {
	self = [super initWithFrame:aFrame];
	self.opaque = YES;
	self.userInteractionEnabled = NO;
	return self;
}

- (void)dealloc {
	if (rowData) {
		[rowData setValue:nil forKey:@"cell"];
	}
	[rowData release];
	[section release];
	[super dealloc];
}

@synthesize rowData;
@synthesize section;

- (void)setSection:(Section *)aSection {
	[section autorelease];
	section = [aSection retain];
	[self setNeedsLayout];
	[self setNeedsDisplay];
}

@synthesize selected;

- (void)setSelected:(BOOL)aBool {
	selected = aBool;
	[self setNeedsDisplay];
}

@synthesize secondarySelected;

- (void)setSecondarySelected:(BOOL)aBool {
	secondarySelected = aBool;
	[self setNeedsDisplay];
}

@synthesize edited;

- (void)setEdited:(BOOL)aBool {
	edited = aBool;
	[self setNeedsDisplay];
}

- (CGSize)sizeThatFits:(CGSize)size {
	return [section sizeThatFits:size];
}

- (void)drawRect:(CGRect)rect {
    [[APP_VIEW_CONTROLLER paperColor] set];
	UIRectFill(rect);
	
	CGRect textRect = [IPhoneDocumentViewCell textRectForSection:section inBounds:self.bounds];
	UIFont *font = section.sectionFont;
	
	if ((selected || secondarySelected) && !edited) {
		if (selected) {
            [[APP_VIEW_CONTROLLER inkColorByPercent:0.10] set];
		} else {
            [[APP_VIEW_CONTROLLER inkColorByPercent:0.05] set];
		}
		UIRectFill(rect);
	}

	NSString *text = [section content];
    
	if ([text length] > 0) {
		[section.sectionColor set];
        
        if (section.type == TaskPaperSectionTypeProject) {
            text = [[section.selfString stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        [text drawInRect:textRect withFont:font lineBreakMode:UILineBreakModeTailTruncation];
		
		if ([section tagWithOnlyName:@"done"]) {			
			CGFloat leading = font.leading;
			CGFloat yPos = textRect.origin.y + (leading / 2);
			CGFloat yEnd = CGRectGetMaxY(textRect);
			
			while (yPos < yEnd) {
                [APP_VIEW_CONTROLLER.gradientLine drawInRect:CGRectMake(textRect.origin.x, (NSUInteger)yPos, textRect.size.width, 3)];
				yPos += leading;
			}
		}
	}
	
	if (section.level > 0 && section.type == TaskPaperSectionTypeTask) {		
		if (!font) {
			font = section.sectionFont;
		}
		
		CGFloat leading = font.leading;
		CGFloat yPos = textRect.origin.y + (leading / 2);
		CGPoint p = textRect.origin;
		p.x -= LEVEL_WIDTH / 2;
		p.y = yPos;
		p.x -= APP_VIEW_CONTROLLER.bullet.size.width / 1.5;
		p.y -= APP_VIEW_CONTROLLER.bullet.size.height / 2;
		p.x = (NSInteger) p.x;
		p.y = (NSInteger) p.y;
		
        
		[APP_VIEW_CONTROLLER.bullet drawAtPoint:p];
	}
}

@end

@implementation Section (IPhoneDocumentViewCellAdditions)

- (UIFont *)sectionFont {
	switch (type) {
		case TaskPaperSectionTypeProject:
            return [APP_VIEW_CONTROLLER projectFont];
		case TaskPaperSectionTypeTask:
            return [APP_VIEW_CONTROLLER font];
		default:
            return [APP_VIEW_CONTROLLER font];
	}
}

- (UIColor *)sectionColor {
	switch (type) {
		case TaskPaperSectionTypeProject:
            return [APP_VIEW_CONTROLLER inkColor];
		case TaskPaperSectionTypeTask:
            return [APP_VIEW_CONTROLLER inkColor];
		default:
			return [APP_VIEW_CONTROLLER inkColorByPercent:0.40];
	}
}

- (CGSize)sizeThatFits:(CGSize)size {	
	CGFloat availibleWidth = size.width;
	availibleWidth -= level * LEVEL_WIDTH + (H_PADDING * 2);
	
	NSString *measuerText = [self content];
	if ([measuerText length] == 0) {
		measuerText = @"\n";
	}
	
	CGSize result = [measuerText sizeWithFont:self.sectionFont constrainedToSize:CGSizeMake(availibleWidth, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
	result.width = size.width;
	result.height += V_PADDING;
		
	return result;
}

@end
