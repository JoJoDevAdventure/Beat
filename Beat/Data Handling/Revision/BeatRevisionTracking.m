//
//  BeatRevisionTracking.m
//  Beat
//
//  Created by Lauri-Matti Parppei on 16.3.2021.
//  Copyright © 2021 Lauri-Matti Parppei. All rights reserved.
//

/*
 
 This is used in Preview and Export to bake attributed ranges into the screenplay.
 
 */

#import "BeatRevisionTracking.h"
#import "BeatRevisionItem.h"
#import "Line.h"

#define DEFAULT_COLOR @"blue"
#define REVISION_ORDER @[@"blue", @"orange", @"purple", @"green"]

#if !TARGET_OS_IOS
    #import <Cocoa/Cocoa.h>
#else
    #import <UIKit/UIKit.h>
#endif

@implementation BeatRevisionTracking

+ (NSString*)defaultRevisionColor {
	return DEFAULT_COLOR;
}

+ (NSArray*)revisionColors {
	return REVISION_ORDER;
}

+ (void)bakeRevisionsIntoLines:(NSArray*)lines text:(NSAttributedString*)string parser:(ContinuousFountainParser*)parser
{
	[string enumerateAttribute:@"Revision" inRange:(NSRange){0,string.length} options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
		if (range.length < 1 || range.location == NSNotFound || range.location + range.length > string.length) return;
		
		BeatRevisionItem *item = value;
		
		if (item.type != RevisionNone) {
			NSArray *linesInRange = [parser linesInRange:range];
			for (Line* line in linesInRange) {
				line.changed = YES;
				
				// Set revision color
				NSString *revisionColor = item.colorName;
				if (!revisionColor.length) revisionColor = DEFAULT_COLOR;
				
				if (line.revisionColor.length) {
					// The line already has a revision color, apply the higher one
					NSInteger currentRevision = [REVISION_ORDER indexOfObject:line.revisionColor];
					NSInteger thisRevision = [REVISION_ORDER indexOfObject:revisionColor];
					
					if (thisRevision != NSNotFound && thisRevision > currentRevision) line.revisionColor = revisionColor;
				}
				else line.revisionColor = revisionColor;
								
				if (!line.removalRanges) line.removalRanges = [NSMutableIndexSet indexSet];
				
				NSRange localRange = [line globalRangeToLocal:range];
				if (item.type == RevisionRemoval) [line.removalRanges addIndexesInRange:localRange];
				else if (item.type == RevisionAddition) [line.additionRanges addIndexesInRange:localRange];
			}
		}
	}];
}
+ (void)bakeRevisionsIntoLines:(NSArray*)lines revisions:(NSDictionary*)revisions string:(NSString*)string parser:(ContinuousFountainParser*)parser
{
	if (revisions.count && !string.length) NSLog(@"NOTE: No string available for baking the revisions.");

	for (NSString *key in revisions.allKeys) {
		NSArray *items = revisions[key];
		for (NSArray *item in items) {
			NSString *color;
			NSInteger loc = [(NSNumber*)item[0] integerValue];
			NSInteger len = [(NSNumber*)item[1] integerValue];
			
			// Load color if available
			if (item.count > 2) {
				color = item[2];
			}
			
			// Ensure the revision is in range, find lines in range and bake revisions
			if (len > 0 && loc + len <= string.length) {
				RevisionType type;
				NSRange range = (NSRange){loc, len};
				
				if ([key isEqualToString:@"Addition"]) type = RevisionAddition;
				else if ([key isEqualToString:@"Removal"]) type = RevisionRemoval;
				else type = RevisionNone;
				
				BeatRevisionItem *revision = [BeatRevisionItem type:type color:color];
				//if (revisionItem) [self.textView.textStorage addAttribute:revisionAttribute value:revisionItem range:range];
				
				if (revision.type != RevisionNone) {
					NSArray *linesInRange = [parser linesInRange:range];
					for (Line* line in linesInRange) {
						line.changed = YES;
						
						// Set revision color
						line.revisionColor = revision.colorName;
						if (!line.revisionColor.length) line.revisionColor = DEFAULT_COLOR;
						
						if (!line.removalRanges) line.removalRanges = [NSMutableIndexSet indexSet];
						
						NSRange localRange = [line globalRangeToLocal:range];
						if (revision.type == RevisionRemoval) [line.removalRanges addIndexesInRange:localRange];
						else if (revision.type == RevisionAddition) [line.additionRanges addIndexesInRange:localRange];
					}
				}
			}
		}
	}
}

+ (NSDictionary*)rangesForSaving:(NSAttributedString*)string {
	NSMutableAttributedString *str = string.mutableCopy;
	
	NSDictionary *ranges = @{
		@"Addition": [NSMutableArray array],
		@"Removal": [NSMutableArray array],
		@"Comment": [NSMutableArray array]
	};
	
	// Find all line breaks and remove the revision attributes
	NSRange searchRange = NSMakeRange(0,1);
	NSRange foundRange;
	
	while (searchRange.location < string.length) {
		searchRange.length = string.length-searchRange.location;
		foundRange = [string.string rangeOfString:@"\n" options:0 range:searchRange];
		
		if (foundRange.location != NSNotFound) {
			[str setAttributes:nil range:foundRange]; // Remove attributes from line berak
			searchRange.location = foundRange.location+foundRange.length; // Continue the search
		} else {
			// Done
			break;
		}
	}
	
	// Enumerate through revisions and save them.
	[str enumerateAttribute:@"Revision" inRange:(NSRange){0,string.length} options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
		BeatRevisionItem *item = value;
		
		if (item.type != RevisionNone) {
			NSMutableArray *values = ranges[item.key];
			
			NSArray *lastItem = values.lastObject;
			NSInteger lastLoc = [(NSNumber*)lastItem[0] integerValue];
			NSInteger lastLen = [(NSNumber*)lastItem[1] integerValue];
			NSString *lastColor = lastItem[2];
			
			if (lastLoc + lastLen == range.location && [lastColor isEqualToString:item.colorName]) {
				// This is a continuation of the last range
				values[values.count-1] = @[@(lastLoc), @(lastLen + range.length), item.colorName];
			} else {
				// This is a new range
				[values addObject:@[@(range.location), @(range.length), item.colorName]];
			}
		}
	}];
	
	return ranges;
}

@end
