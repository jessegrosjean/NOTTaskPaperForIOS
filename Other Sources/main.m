//
//  main.m
// PlainText
//
//  Created by Jesse Grosjean on 6/23/10.
//  Copyright Hog Bay Software 2010. All rights reserved.
//

#import <UIKit/UIKit.h>


int main(int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, NSStringFromClass([[NSBundle mainBundle] principalClass]), @"ApplicationController");
    [pool release];
    return retVal;
}
