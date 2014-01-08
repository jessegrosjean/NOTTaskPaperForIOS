//
//  KeyboardAccessoryView.m
//  PlainText
//
//  Created by Jesse Grosjean on 4/21/11.
//

#import "KeyboardAccessoryView.h"
#import "ApplicationViewController.h"
#import "ApplicationController.h"
#import "UIResponder_Additions.h"


@interface KeyboardButton : UIButton {
}
@end

// hack hack hack, jesse is not proud of this class.

@implementation KeyboardAccessoryView

- (UIImage*)imageByCropping:(UIImage *)imageToCrop toRect:(CGRect)rect {
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef currentContext = UIGraphicsGetCurrentContext();
	
	CGRect clippedRect = CGRectMake(0, 0, rect.size.width, rect.size.height);
	CGContextClipToRect( currentContext, clippedRect);
	
	CGRect drawRect = CGRectMake(rect.origin.x * -1,
								 rect.origin.y * -1,
								 imageToCrop.size.width,
								 imageToCrop.size.height);
	
	CGContextTranslateCTM(currentContext, 0.0, drawRect.size.height);
	CGContextScaleCTM(currentContext, 1.0, -1.0);
	CGContextDrawImage(currentContext, drawRect, imageToCrop.CGImage);
	
	UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return cropped;
}

- (id)buttonWith:(NSString *)text cropLeft:(BOOL)cropLeft cropRight:(BOOL)cropRight {
	UIButton *button = [KeyboardButton buttonWithType:UIButtonTypeCustom];
	UIImage *normal = [UIImage imageNamed:@"keybackground.png"];
	UIImage *highlighted = [UIImage imageNamed:@"keypressedbackground.png"];

	if (cropLeft) {
		CGSize s = [normal size];
		normal = [self imageByCropping:normal toRect:CGRectMake(10, 0, s.width - 10, s.height)];
		highlighted = [self imageByCropping:highlighted toRect:CGRectMake(10, 0, s.width - 10, s.height)];
	}
	
	if (cropRight) {
		CGSize s = [normal size];
		normal = [self imageByCropping:normal toRect:CGRectMake(0, 0, s.width - 10, s.height)];
		highlighted = [self imageByCropping:highlighted toRect:CGRectMake(0, 0, s.width - 10, s.height)];
	}
	
    normal = [normal stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    highlighted = [highlighted stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    
	[button setBackgroundImage:normal forState:UIControlStateNormal];
	[button setBackgroundImage:highlighted forState:UIControlStateHighlighted];
	[button sizeToFit];
	[button setTitle:text forState:UIControlStateNormal];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button addTarget:self action:@selector(keyDown) forControlEvents:UIControlEventTouchDown];
	[button addTarget:self action:@selector(keyUp:) forControlEvents:UIControlEventTouchUpInside];
	button.titleLabel.shadowOffset = CGSizeMake(0, 1);
	button.titleLabel.font = [UIFont systemFontOfSize:26];
	button.titleLabel.textAlignment = UITextAlignmentCenter;
	//button.imageView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
	button.accessibilityTraits = UIAccessibilityTraitPlaysSound | UIAccessibilityTraitKeyboardKey;

	return button;
}

- (CGSize)sizeThatFits:(CGSize)size forOrientation:(UIInterfaceOrientation)orientation {
	BOOL isPortrait = UIInterfaceOrientationIsPortrait(orientation);
	if (isPortrait) {
		//size.height = 72;
		size.height = 72;
	} else {
		size.height = 72;
		//size.height = 95;
	}
	return size;
}

- (id)init {
    self = [super init];
    if (self) {
		self.image = [UIImage imageNamed:@"keyboardbackground.png"];
		self.userInteractionEnabled = YES;
		self.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
		
		CGRect f = self.frame;
		f.size = [self sizeThatFits:f.size forOrientation:APP_VIEW_CONTROLLER.interfaceOrientation];
		self.frame = f;

		UIButton *tab = [self buttonWith:@"tab" cropLeft:NO cropRight:NO];
		tab.tag = 1;
		f = tab.frame;
		f.size.width = roundf(f.size.width * 1.5);
		tab.titleLabel.font = [UIFont systemFontOfSize:19];
		tab.frame = f;
		[self addSubview:tab];
		
		NSString *extendedKeys = [[NSUserDefaults standardUserDefaults] objectForKey:ExtendedKeyboardKeysDefaultsKey];
		for (NSUInteger i = 0; i < [extendedKeys length]; i++) {
			[self addSubview:[self buttonWith:[extendedKeys substringWithRange:NSMakeRange(i, 1)] cropLeft:NO cropRight:NO]];
		}
		
		UIButton *left = [self buttonWith:@"" cropLeft:NO cropRight:YES];
        [left setImage:[UIImage imageNamed:@"LeftArrow.png"] forState:UIControlStateNormal];
        [left setImage:[UIImage imageNamed:@"LeftArrow.png"] forState:UIControlStateHighlighted];
        left.imageView.contentMode = UIViewContentModeCenter;
		left.tag = 2;
		left.titleLabel.font = [UIFont systemFontOfSize:14];
		[left setTitleColor:[UIColor colorWithWhite:0.2 alpha:1.0] forState:UIControlStateNormal];
		[self addSubview:left];
		
		UIImageView *separator = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"keydivider.png"]] autorelease];
		separator.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
		[self addSubview:separator];
		
		UIButton *right = [self buttonWith:@"" cropLeft:YES cropRight:NO];
        [right setImage:[UIImage imageNamed:@"RightArrow.png"] forState:UIControlStateNormal];
        [right setImage:[UIImage imageNamed:@"RightArrow.png"] forState:UIControlStateHighlighted];
        right.imageView.contentMode = UIViewContentModeCenter;
		right.tag = 3;
		right.titleLabel.font = [UIFont systemFontOfSize:14];
		[right setTitleColor:[UIColor colorWithWhite:0.2 alpha:1.0] forState:UIControlStateNormal];
		[self addSubview:right];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:KeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotateToInterfaceOrientation:) name:ApplicationViewWillRotateNotification object:nil];
		
		[self layoutSubviews];
	}    
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
	if ([APP_VIEW_CONTROLLER isHardwareKeyboard]) {
		self.window.alpha = 0;
		self.window.userInteractionEnabled = NO;
	} else {
		self.window.alpha = 1.0;
		self.window.userInteractionEnabled = YES;
	}
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
	if (!newWindow) {
		// when removed restore keyboard visiblity always.
		self.window.alpha = 1.0;
		self.window.userInteractionEnabled = YES;
	}
}

- (void)didMoveToWindow {
	if (self.window) {
		// when moved to new window... hide if there's a hardware keyboard.
		if ([APP_VIEW_CONTROLLER isHardwareKeyboard]) {
			self.window.alpha = 0;
			self.window.userInteractionEnabled = NO;
		} else {
			self.window.alpha = 1.0;
			self.window.userInteractionEnabled = YES;
		}
	}
}

- (void)willRotateToInterfaceOrientation:(NSNotification *)aNotification {
	CGRect f = self.frame;
	UIInterfaceOrientation toOrientation = [[[aNotification userInfo] objectForKey:ToOrientation] integerValue];
	if (UIInterfaceOrientationIsPortrait(toOrientation)) {
		f.size = [self sizeThatFits:f.size forOrientation:UIInterfaceOrientationPortrait];
	} else {
		f.size = [self sizeThatFits:f.size forOrientation:UIInterfaceOrientationLandscapeLeft];
	}
	self.frame = f;
	[self setNeedsLayout];
}

@synthesize target;

- (BOOL)enableInputClicksWhenVisible {
    return YES;
}

- (void)keyDown {
	[[UIDevice currentDevice] playInputClick];
}

- (void)insertString: (NSString *) insertingString intoTextView: (UITextView *) textView {
    NSRange range = textView.selectedRange;
    NSString *firstHalfString = [textView.text substringToIndex:range.location];
    NSString *secondHalfString = [textView.text substringFromIndex: range.location];
    textView.scrollEnabled = NO;  
    textView.text = [NSString stringWithFormat: @"%@%@%@",
                     firstHalfString,
                     insertingString,
                     secondHalfString];
    range.location += [insertingString length];
    textView.selectedRange = range;
    textView.scrollEnabled = YES;
}

- (void)keyUp:(UIButton *)sender {
	NSString *text = nil;
	
	switch (sender.tag) {
		case 1:
#ifdef TASKPAPER
            if ([target respondsToSelector:@selector(selectedRange)]) {
				NSRange r = NSMakeRange(NSMaxRange(((UITextView *)target).selectedRange), 0);
				r.location = 0;
				((UITextView *)target).selectedRange = r;
			}
            text = @" ";
#else
			text = @"\t";
            UITextView *textView = (id)target;
            [self insertString:text intoTextView:textView];
            text = nil;
#endif
			break;
		case 2: {
			if ([target respondsToSelector:@selector(selectedRange)]) {
				NSRange r = NSMakeRange(((UITextView *)target).selectedRange.location, 0);
				r.location--;
				((UITextView *)target).selectedRange = r;
			}
			break;
		}
		
		case 3: {
			if ([target respondsToSelector:@selector(selectedRange)]) {
				NSRange r = NSMakeRange(NSMaxRange(((UITextView *)target).selectedRange), 0);
				r.location++;
				((UITextView *)target).selectedRange = r;
			}
			break;
		}
		
		default:
			text = sender.titleLabel.text;
			break;
	}
	
	if (text) {
		[target pasteInsertText:text];
	}
}

- (void)layoutSubviews {
	UIFont *defaultFont;
	CGFloat defaultWidth;
//	CGFloat defaultHeight;
	BOOL isPortrait = UIInterfaceOrientationIsPortrait(APP_VIEW_CONTROLLER.interfaceOrientation);
	
	//if (isPortrait) {
		//defaultWidth = 69;
		//defaultHeight = 72;
		defaultFont = [UIFont systemFontOfSize:26];
		
	/*} else {
		defaultWidth = 93;
		defaultHeight = 95;
		defaultFont = [UIFont systemFontOfSize:32];
	}*/
	
	if (isPortrait) {
		defaultWidth = 69;
	} else {
		defaultWidth = 93;
	}

	CGFloat x = 0;
	CGFloat y = 2;
	CGRect bounds = self.bounds;
	CGFloat tabWidth = roundf(defaultWidth * 1.5);
	CGFloat arrowWidth = roundf(((bounds.size.width - (defaultWidth * ([[self subviews] count] - 4))) - (tabWidth + 1)) / 2.0);
	
	for (UIButton *each in self.subviews) {
		CGRect f = each.frame;

		if ([each isKindOfClass:[UIButton class]]) {
			if (each.tag == 1) {
				f.size.width = tabWidth;
				//if (isPortrait) {
					each.titleLabel.font = [UIFont systemFontOfSize:19];
				//} else {
				//	each.titleLabel.font = [UIFont systemFontOfSize:23];
				//}
 			} else if (each.tag != 0) {
				f.size.width = arrowWidth;
				//if (isPortrait) {
					each.titleLabel.font = [UIFont systemFontOfSize:16];
				//} else {
				//	each.titleLabel.font = [UIFont systemFontOfSize:20];
				//}
			} else {
				f.size.width = defaultWidth;
				each.titleLabel.font = defaultFont;
			}
	
			f.origin.x = x;
			f.origin.y = y;
			f.size.height = bounds.size.height - y;
			each.frame = CGRectIntegral(f);
			x += f.size.width;
		} else {
			f.origin.x = x;
			f.origin.y = y;
			f.size.height = bounds.size.height - y;
			each.frame = f;
			x += f.size.width;
		}
	}
}

@end
	
@implementation KeyboardButton

- (void)layoutSubviews {
	[super layoutSubviews];
	CGRect b = self.bounds;
	self.imageView.frame = b;
	UILabel *l = self.titleLabel;
	if (self.tag == 0) {
		b.origin.y -= 4;
	} else if (self.tag != 1) {
		b.origin.y -= 2;		
	}
	l.frame = b;
}

@end
	
