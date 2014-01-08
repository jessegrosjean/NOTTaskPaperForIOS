//
//  TaskPaperSection.h
//  Documents
//
//  Created by Jesse Grosjean on 7/13/09.
//

#import "Section.h"


enum {
	TaskPaperSectionTypeProject = 'TPpt',
	TaskPaperSectionTypeTask = 'TPtt',
	TaskPaperSectionTypeNote = 'TPnt'
};
typedef NSUInteger TaskPaperSectionType;

@interface TaskPaperSection : Section {

}

- (NSString *)goToProjectSearchText;

@end
