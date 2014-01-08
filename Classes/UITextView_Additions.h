//
//  UITextView_Additions.h
//  PlainText
//
//  Created by Jesse Grosjean on 10/29/10.
//  Copyright 2010 Hog Bay Software. All rights reserved.
//

@interface UITextView (Additions)

- (void)myMakeSelectionWithPoint:(CGPoint)aPoint;
- (CGRect)myRectForSelection:(NSRange)aRange;
- (void)myHighlightRange:(NSRange)aRange;
- (void)myAcceptAutocorrection;
- (void)adjustForTypewriterScrolling;
@end

