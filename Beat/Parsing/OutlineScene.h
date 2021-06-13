//
//  OutlineScene.h
//  Beat
//
//  Created by Lauri-Matti Parppei on 18.2.2019.
//  Copyright © 2019 KAPITAN!. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContinousFountainParser.h"
#import "Line.h"
#import <JavaScriptCore/JavaScriptCore.h>

// JavaScript interface
@protocol OutlineSceneExports <JSExport>
@property (nonatomic, readonly) NSString * sceneNumber;
@property (nonatomic, readonly) NSString * color;
@property (nonatomic, readonly) Line * line;
@property (strong, nonatomic, readonly) NSString * string;
@property (nonatomic, readonly) NSString * stringForDisplay;
@property (nonatomic, readonly) NSArray * storylines;
@property (nonatomic, readonly) NSUInteger sceneStart;
@property (nonatomic, readonly) NSUInteger sceneLength;
@property (nonatomic, readonly) NSInteger sectionDepth;
@property (nonatomic, readonly) bool omitted;
@property (nonatomic, readonly) bool omited; // Legacy compatibility
@property (nonatomic, readonly) NSMutableArray * characters;
- (NSString*)typeAsString;
- (NSInteger)timeLength;
- (NSDictionary*)forSerialization;
@end

@interface OutlineScene : NSObject <OutlineSceneExports>
@property (nonatomic) NSMutableArray * scenes;
@property (strong, nonatomic) NSString * string;
@property (nonatomic) LineType type;
@property (nonatomic) NSString * sceneNumber;
@property (nonatomic) NSString * color;
@property (nonatomic) NSArray * storylines;
@property (nonatomic) NSUInteger sceneStart;
@property (nonatomic) NSUInteger sceneLength;
@property (nonatomic) NSInteger sectionDepth;
@property (nonatomic) NSMutableArray * characters;

@property (nonatomic) bool omitted;
@property (nonatomic) bool noOmitIn;
@property (nonatomic) bool noOmitOut;

@property (nonatomic) Line * line; // Is this overkill regarding memory? Isn't this just a pointer?

- (NSString*)stringForDisplay;
- (NSRange)range;
- (NSInteger)timeLength;
- (NSString*)typeAsString;
- (NSDictionary*)forSerialization;
@end
