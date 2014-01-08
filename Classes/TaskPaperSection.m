//
//  TaskPaperSection.m
//  Documents
//
//  Created by Jesse Grosjean on 7/13/09.
//

#import "TaskPaperSection.h"
#import "Tree.h"
#import "Tag.h"
//#import "TreeViewTheme.h"
#import "NSString_Additions.h"


@implementation TaskPaperSection

- (NSUInteger)headerType {
	return TaskPaperSectionTypeProject;
}

- (void)setType:(NSUInteger)newType {
	if (type != newType) {
		switch (newType) {
			case TaskPaperSectionTypeProject:
			case TaskPaperSectionTypeTask:
			case TaskPaperSectionTypeNote:
				break;
			default:
				newType = TaskPaperSectionTypeNote;
		}		
		[super setType:newType];
	}
}

- (NSString *)typeAsString {
	switch (type) {
		case TaskPaperSectionTypeProject:
			return @"project";
		case TaskPaperSectionTypeTask:
			return @"task";
		case TaskPaperSectionTypeNote:
			return @"note";
		default:
			return @"unknown";
	}		
}

- (void)setLevel:(NSInteger)newLevel includeChildren:(BOOL)includeChildren {
	if (level != newLevel) {
		[self noteSelfStringChanged];
		
		NSArray *trackedLocations = [tree trackedLocationsFor:self];
		if (trackedLocations) {
			NSInteger delta = newLevel - level;
			for (TrackedLocation *each in trackedLocations) {
				NSUInteger eachOffset = each.sectionOffset;
				if (eachOffset >= level) {
					each.sectionOffset += delta;
				} else if (delta < 0) {
					if (eachOffset > newLevel) {
						each.sectionOffset = newLevel;
					}
				}
			}
		}
		[super setLevel:newLevel includeChildren:includeChildren];
	}
}

- (void)setSelfString:(NSString *)newSectionString {
	newSectionString = [Section validateSectionString:newSectionString];
		
	[tree beginChangingSections];
	
	NSUInteger length = [newSectionString length];
	NSRange contentRange = NSMakeRange(0, length);
	
	// Level determined by tabs.
	NSUInteger newLevel = 0;
	while (newLevel < contentRange.length && [newSectionString characterAtIndex:newLevel] == '\t') {
		newLevel++;
	}
	contentRange.location += newLevel;
	contentRange.length -= newLevel;
	
	// Tags
	NSRange trailingTagsRange = [Tag parseTrailingTagsRangeInString:newSectionString inRange:contentRange];
	[tags release];
	tags = nil;
	if (trailingTagsRange.location != NSNotFound) {
		contentRange.length -= trailingTagsRange.length; // trim trailing tags for type detection... they will be added to content after that.
	}

	// Type
	TaskPaperSectionType newType = type;
	if (newLevel + 2 <= length && [newSectionString characterAtIndex:newLevel] == '-' && [newSectionString characterAtIndex:newLevel + 1] == ' ') {
		contentRange.location += 2;
		if (contentRange.length >= 2) {
			contentRange.length -= 2;
		} else {
			contentRange.length = 0; // special case when task has no content, claim back space taken by tags.
		}
		newType = TaskPaperSectionTypeTask;
		
		if (contentRange.length == 0 && trailingTagsRange.location != NSNotFound) {
			trailingTagsRange.location += 1;
			trailingTagsRange.length -= 1;
		}
	} else {
		if (contentRange.length > 0 && [newSectionString characterAtIndex:NSMaxRange(contentRange) - 1] == ':') {
			newType = TaskPaperSectionTypeProject;
			contentRange.length -= 1;
		} else {
			newType = TaskPaperSectionTypeNote;
		}
	}
	
	if (type != newType) {
		[self willChangeValueForKey:@"type"];
		type = newType;
		[self didChangeValueForKey:@"type"];
	}
	
	// Content
	[self willChangeValueForKey:@"content"];
	[content release];
	if (trailingTagsRange.location != NSNotFound) {
		content = [[[newSectionString substringWithRange:contentRange] stringByAppendingString:[newSectionString substringWithRange:trailingTagsRange]] retain];
	} else {
		content = [[newSectionString substringWithRange:contentRange] retain];
	}
	[self didChangeValueForKey:@"content"];
	
	
	[selfString release];
	selfString = nil;
	
	if (newLevel != level) {
		if (tree) {
			[self setLevel:newLevel includeChildren:NO]; // Make sure property treeChanged notifications are sent if structure changes.
		} else {
			[self willChangeValueForKey:@"level"];
			level = newLevel;
			[self didChangeValueForKey:@"level"];
		}
	} else {
		[tree sectionUpdated:self];
	}
	
	[tree endChangingSections];
}

- (void)writeSelfToString:(NSMutableString *)aString includeTags:(BOOL)includeTags {
	// Level
	NSUInteger i = level;
	while (i > 0) {
		[aString appendString:@"\t"];
		i--;
	}
	
	if (type == TaskPaperSectionTypeTask) {
		[aString appendString:@"- "];
	}
	
	if (type == TaskPaperSectionTypeProject) {
		// If has tags, then check for trailing tags, because they need to be inserted after projects ':'
        NSRange trailingTagsRange = [Tag parseTrailingTagsRangeInString:content];
        if (trailingTagsRange.location != NSNotFound) {
            [aString appendString:[content substringToIndex:trailingTagsRange.location]];
            [aString appendString:@":"];
            [aString appendString:[content substringFromIndex:trailingTagsRange.location]];
        } else {
            if ([content length] > 0) {
                [aString appendString:content];
            }
            [aString appendString:@":"];
        }
	} else {
		if ([content length] > 0) {
			[aString appendString:content];
		}
	}
	
    [aString appendString:@"\n"];        
}

- (NSString *)goToProjectSearchText {
    NSString *searchText = [NSString stringWithFormat:@"project = \"%@\"", self.content];
    Section *parentSection = self.parent;
    while (parentSection != nil) {
        if (parentSection.content && parentSection.content.length > 0 && parentSection.type == TaskPaperSectionTypeProject) {
            searchText = [NSString stringWithFormat:@"project = \"%@\" and %@", parentSection.content, searchText]; 
        }
        parentSection = parentSection.parent;
    }
    return searchText;
}

#if !TARGET_OS_IPHONE

//- (NSString *)writeSelfToDOMElement:(DOMElement *)element theme:(TreeViewTheme *)theme {		
//	DOMDocument *document = element.ownerDocument;
//	DOMElement *tabs = nil;
//	DOMElement *dash = nil;
//	
//	NSUInteger i = level;
//	if (i > 0) {
//		NSMutableString *tabsContent = [NSMutableString string];
//		while (i > 0) {
//			[tabsContent appendString:@"\t"];
//			i--;
//		}
//		tabs = [document createElement:@"span"];
//		[tabs setAttribute:@"class" value:@"tabs"];
//		[tabs setTextContent:tabsContent];
//	}
//	
//	NSMutableString *textContent = [NSMutableString stringWithString:content];
//	NSMutableString *classValue = nil;
//
//	switch (type) {
//		case TaskPaperSectionTypeProject:
//			classValue = [NSMutableString stringWithString:@"project"];
//			[textContent appendString:@":"];
//			break;
//		case TaskPaperSectionTypeTask:
//			classValue = [NSMutableString stringWithString:@"task"];
//			dash = [document createElement:@"span"];
//			[dash setAttribute:@"class" value:@"dash"];
//			[dash setTextContent:@"- "];
//			break;
//		case TaskPaperSectionTypeNote:
//			classValue = [NSMutableString stringWithString:@"note"];
//			break;
//	}
//	
//	if ([textContent length] > 0) {
//		[textContent replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, [textContent length])];
//		[textContent replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, [textContent length])];
//
//		for (TreeViewThemeReplacement *eachThemeReplacement in theme.replacements) {
//			[textContent documents_replaceOccurrencesOfRegex:eachThemeReplacement.regex withString:eachThemeReplacement.replacement];
//		}
//
//		[(id)element setInnerHTML:textContent];
//	} else {
//		[(id)element setInnerHTML:@""];
//	}
//	
//	if (dash) {
//		[element insertBefore:dash refChild:element.firstChild];
//	}
//	
//	if (tabs) {
//		[element insertBefore:tabs refChild:element.firstChild];
//	}
//		
//	if ([tags count] > 0) {
//		DOMElement *tagsElement = [document createElement:@"span"];
//		[tagsElement setAttribute:@"class" value:@"tags"];
//		
//		BOOL addSpaceBeforeTag = [textContent length] > 0;
//		
//		for (Tag *eachTag in tags) {
//			if (addSpaceBeforeTag) {
//				[tagsElement appendChild:[document createTextNode:@" @"]];
//			} else {
//				[tagsElement appendChild:[document createTextNode:@"@"]];
//				addSpaceBeforeTag = YES;
//			}
//			
//			DOMElement *nameLink = [document createElement:@"a"];
//			[nameLink setAttribute:@"href" value:[NSString stringWithFormat:@"#tag-name-%@", eachTag.name]];
//			[nameLink setAttribute:@"class" value:@"name"];
//			[nameLink setTextContent:eachTag.name];
//			[tagsElement appendChild:nameLink];
//			
//			if ([eachTag.value length] > 0) {
//				[tagsElement appendChild:[document createTextNode:@"("]];
//				DOMElement *valueLink = [document createElement:@"a"];
//				[valueLink setAttribute:@"href" value:[NSString stringWithFormat:@"#tag-value-%@", eachTag.value]];
//				[valueLink setAttribute:@"class" value:@"value"];
//				[valueLink setTextContent:eachTag.value];		
//				[tagsElement appendChild:valueLink];
//				[tagsElement appendChild:[document createTextNode:@")"]];
//			}
//		}
//		
//		[element appendChild:tagsElement];
//	}
//
//	[element appendChild:[document createTextNode:@"\n"]];
//	
//	for (TreeViewThemeRule *eachThemeRule in theme.rules) {
//		if ([eachThemeRule.predicate evaluateWithObject:self]) {
//			[classValue appendString:@" "];
//			[classValue appendString:eachThemeRule.name];
//		}
//	}
//	
//	if (self.isBlank) {
//		[classValue appendString:@" "];
//		[classValue appendString:@"blank"];
//	}
//	
//	return classValue;
//}

#endif

@end
