//
//  IPhoneDocumentViewFieldEditor.h
//  Documents
//
//  Created by Jesse Grosjean on 12/18/09.
//  Copyright 2009 Hog Bay Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IPhoneDocumentViewFieldEditor : UITextView {
	BOOL uncommitedChanges;
	NSString *placeholderText;
}

+ (IPhoneDocumentViewFieldEditor *)sharedInstance;

@property(assign, nonatomic) BOOL uncommitedChanges;
@property(retain, nonatomic) NSString *placeholderText;
	
@end
