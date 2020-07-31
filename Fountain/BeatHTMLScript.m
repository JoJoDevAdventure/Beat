//
//  BeatHTMLScript.m
//	Modified for Beat from FNHTMLScript
//
//  Copyright (c) 2012-2013 Nima Yousefi & John August
//  Parts copyright © 2019-2020 Lauri-Matti Parppei / KAPITAN!
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy 
//  of this software and associated documentation files (the "Software"), to 
//  deal in the Software without restriction, including without limitation the 
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
//  sell copies of the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in 
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
//  IN THE SOFTWARE.
//

/*
 
 N.B. This version of FNHTMLScript.m is customized for Beat. It still outputs HTML for printing out screenplays.
 
 There are certain differences:
 
 - the English language default "written by" has been removed: [body appendFormat:@"<p class='%@'>%@</p>", @"credit", @""];
 - HTML output links to either screen or print CSS depending on the target format.
   Print & PDF versions rely on PrintCSS.css and preview mode uses a modified ScriptCSS.css.
 - And - as I'm writing this, some functions in RegexKitLite.h have been deprecated in macOS 10.12+.
   Fair enough - it was apparently last updated in 2010.
 
   Back then, I hadn't made any films. In 2010, I was young, madly in love and had dreams and aspirations.
   I had just recently started my studies in a film school.
   In 9 years, I figured back then, I'd be making films that really communicated the pain I had gone through.
   My films would reach out to other lonely people, confined in their gloomy tomb, assured of their doom.
 
   Well.
 
   Instead, I'm reading about fucking C enumerators and OS spin locks to be able to build my own fucking software,
   which - mind you - ran just fine a few weeks ago.
 
   Hence, I tried to replace the deprecated spin locks of RegexKitLite.h with modern ones.
   It was about to destroy my inner child. I just wanted to write nice films, I wasn't planning on fucking
   learning any motherfucking C!!!!!!
 
   SO, if you are reading this: Beat now relies on a customized RegexKitLite, which might work or not.
   It could crash systems all around the world. It could consume your computer's soul and kill any glimpse of hope.
 
   I could have spent these hours with my dear friends, my lover or just watching flowers grow and maybe talking to them.
   Or even writing my film. I didn't. Here I am, typing this message to some random fucker who, for whatever reason,
   decides to take a look at my horrible code sometime in the future.
 
   Probably it's me, though.
 
   What can I say. STOP WASTING YOUR LIFE AND GO FUCK YOURSELF.

 ---
 
 UPDATE 21th Jan 2020:
 References to RegexKitLite have been removed. Totally.
 It has resulted in some pretty strange solutions, and self-customizing a Regex library,
 but for now it works - also on modern systems.
 
 UPDATE 17th May 2020:
 This could be rewritten to conform with our Line* class instead of FNElement / FNScript.
 I also stumbled upon the message written above, and omg past me, I'd send you some hugs and kisses
 if I could, but I'm writing this amidst the COVID-19 pandemic so I have to keep my distance.
 
*/

#import "BeatHTMLScript.h"
#import "Line.h"
#import "FountainRegexes.h"
#import "FountainPaginator.h"

// FUCK YOU REGEXKITLITE.H
//#import "RegexKitLite.h"
#import "RegExCategories.h"

@interface BeatHTMLScript ()

@property (readonly, copy, nonatomic) NSString *cssText;
@property (copy, nonatomic) NSString *bodyText;
@property (nonatomic) NSInteger numberOfPages;
@property (nonatomic) NSString *currentScene;

@end

@implementation BeatHTMLScript

- (id)initWithScript:(NSDictionary*) script {
    self = [super init];
    if (self) {
        _script = script[@"script"];
		_titlePage = script[@"title page"];
        _font = [QUQFont fontWithName:@"Courier" size:12];
    }
    return self;
}

- (id)initWithScript:(NSDictionary *)script print:(bool)print {
	self = [super init];
	if (self) {
        _script = script[@"script"];
		_titlePage = script[@"title page"];
        _font = [QUQFont fontWithName:@"Courier" size:12];
		_print = print;
	}
	return self;
}

- (id)initWithScript:(NSArray *)script document:(NSDocument*)aDocument
{
    self = [super init];
    if (self) {
        _script = script;
        _font = [QUQFont fontWithName:@"Courier" size:12];
        _document = aDocument;
    }
    return self;
}

- (id)initWithScript:(NSDictionary *)script document:(NSDocument*)document scene:(NSString*)scene
{
	self = [super init];
	if (self) {
        _script = script[@"script"];
		_titlePage = script[@"title page"];
        _font = [QUQFont fontWithName:@"Courier" size:12];
		_document = document;
		_currentScene = scene;
	}
	return self;
}

- (id)initWithScript:(NSDictionary *)script document:(NSDocument*)document print:(bool)print
{
	self = [super init];
	if (self) {
        _script = script[@"script"];
		_titlePage = script[@"title page"];
        _font = [QUQFont fontWithName:@"Courier" size:12];
		_document = document;
		_print = print;
	}
	return self;
}

- (NSInteger)pages {
	return _numberOfPages + 1;
}

- (NSString *)html
{
    if (!self.bodyText) {
        self.bodyText = [self bodyForScript];
    }
    
    NSMutableString *html = [NSMutableString string];
    [html appendString:@"<!DOCTYPE html>\n"];
    [html appendString:@"<html>\n"];
    [html appendString:@"<head><title>Print Preview</title>\n"];
	[html appendString:@"<meta name='viewport' content='width=device-width, initial-scale=1.2'/>\n"];
	
    [html appendString:@"<style type='text/css'>\n"];
    [html appendString:self.cssText];
    [html appendString:@"</style>\n"];
    [html appendString:@"</head>\n"];
	[html appendString:@"<body>"];
	[html appendString:@"<article>\n"];
	if (!_print) [html appendString:[self previewUI]];
    [html appendString:self.bodyText];
	[html appendString:@"</section>\n</article>\n"];
	
	[html appendString:[self previewJS]];
	[html appendString:@"<script name='scrolling'></script>"];
	[html appendString:@"</body>\n"];
    [html appendString:@"</html>"];
    return html;
}

- (NSString *)htmlClassForType:(NSString *)elementType
{
    return [[elementType lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
}

- (NSString *)cssText
{    
    NSError *error = nil;
	NSString *css;
	
	if (!_print) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"ScriptCSS.css" ofType:@""];
		css = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	} else {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"PrintCSS.css" ofType:@""];
		css = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	}

	if (error) {
		NSLog(@"Couldn't load CSS");
		css = @"";
	}

    return css;
}

- (NSString*)format:(NSString*) string {
	string = [RX(BOLD_ITALIC_UNDERLINE_PATTERN) stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@"<u><em><strong>$2</strong></em></u>"];
	string = [RX(BOLD_ITALIC_PATTERN) stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@"<strong><em>$2</em></strong>"];
	string = [RX(BOLD_UNDERLINE_PATTERN) stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@"<strong><u>$2</u></strong>"];
	string = [RX(ITALIC_UNDERLINE_PATTERN) stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@"<u><em>$2</em></u>"];
	string = [RX(BOLD_PATTERN) stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@"<strong>$2</strong>"];
	string = [RX(ITALIC_PATTERN) stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@"<em>$2</em>"];
	string = [RX(UNDERLINE_PATTERN) stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, string.length) withTemplate:@"<u>$2</u>"];
	
	// Remove escape characters
	string = [string stringByReplacingOccurrencesOfString:@"\\*" withString:@"*"];
	string = [string stringByReplacingOccurrencesOfString:@"\\_" withString:@"_"];
	string = [string stringByReplacingOccurrencesOfString:@"\\@" withString:@"@"];
	string = [string stringByReplacingOccurrencesOfString:@"\\**" withString:@"**"];

	
	return string;
}

- (NSString *)bodyForScript
{
    NSMutableString *body = [NSMutableString string];

    // Add title page
    NSMutableDictionary *titlePage = [NSMutableDictionary dictionary];
    
	for (NSDictionary *dict in self.titlePage) {
        [titlePage addEntriesFromDictionary:dict];
    }
    
	 
    if ([titlePage count] > 0) {
        [body appendString:@"<section id='script-title' class='page'>"];
		
		[body appendFormat:@"<div class='mainTitle'>"];
		
        // Title
        if (titlePage[@"title"]) {
            NSArray *obj = titlePage[@"title"];
            NSMutableString *values = [NSMutableString string];
            for (NSString *val in obj) {
                [values appendFormat:@"%@<br>", val];
            }
			
            [body appendFormat:@"<p class='%@'>%@</p>", @"title", [self format:values]];
			[titlePage removeObjectForKey:@"title"];
        }
        else {
            [body appendFormat:@"<p class='%@'>%@</p>", @"title", @"Untitled"];
        }

		// Credit
		// Added support for "author" (without the plural)
        if (titlePage[@"credit"] || titlePage[@"authors"] || titlePage[@"author"]) {
            if (titlePage[@"credit"]) {
                NSArray *obj = titlePage[@"credit"];
                NSMutableString *values = [NSMutableString string];
                for (NSString *val in obj) {
                    [values appendFormat:@"%@<br>", val];
                }
				[body appendFormat:@"<p class='%@'>%@</p>", @"credit", [self format:values]];
				[titlePage removeObjectForKey:@"credit"];
            }
            else {
                [body appendFormat:@"<p class='%@'>%@</p>", @"credit", @""];
            }
            
            // Authors
            if (titlePage[@"authors"]) {
                NSArray *obj = titlePage[@"authors"];
                NSMutableString *values = [NSMutableString string];
                for (NSString *val in obj) {
                    [values appendFormat:@"%@<br>", val];
                }
                [body appendFormat:@"<p class='%@'>%@</p>", @"authors", [self format:values]];
				[titlePage removeObjectForKey:@"authors"];
            }
			else if (titlePage[@"author"]) {
                NSArray *obj = titlePage[@"author"];
                NSMutableString *values = [NSMutableString string];
                for (NSString *val in obj) {
                    [values appendFormat:@"%@<br>", val];
                }
                [body appendFormat:@"<p class='%@'>%@</p>", @"authors", [self format:values]];
				[titlePage removeObjectForKey:@"author"];
            }
            else {
                [body appendFormat:@"<p class='%@'>%@</p>", @"authors", @""];
            }
        }
		// Source
		if (titlePage[@"source"]) {
			NSArray *obj = titlePage[@"source"];
			NSMutableString *values = [NSMutableString string];
			for (NSString *val in obj) {
				[values appendFormat:@"%@<br>", val];
			}
			[body appendFormat:@"<p class='%@'>%@</p>", @"source", [self format:values]];
			[titlePage removeObjectForKey:@"source"];
		}
		
		[body appendFormat:@"</div>"];
		
		// Draft date
		[body appendFormat:@"<div class='versionInfo'>"];
		if (titlePage[@"draft date"]) {
			NSArray *obj = titlePage[@"draft date"];
			NSMutableString *values = [NSMutableString string];
			for (NSString *val in obj) {
				[values appendFormat:@"%@<br>", val];
			}
			[body appendFormat:@"<p class='%@'>%@</p>", @"draft-date", [self format:values]];
			[titlePage removeObjectForKey:@"draft date"];
		}
		[body appendFormat:@"</div>"];
		
		
		[body appendFormat:@"<div class='info'>"];
        
        // Contact
        if (titlePage[@"contact"]) {
            NSArray *obj = titlePage[@"contact"];
            NSMutableString *values = [NSMutableString string];
            for (NSString *val in obj) {
                [values appendFormat:@"%@<br>", val];
            }
            [body appendFormat:@"<p class='%@'>%@</p>", @"contact", [self format:values]];
			[titlePage removeObjectForKey:@"contact"];
        }
		
		// Notes
		if (titlePage[@"notes"]) {
			NSArray *obj = titlePage[@"notes"];
			NSMutableString *values = [NSMutableString string];
			for (NSString *val in obj) {
				[values appendFormat:@"%@<br>", val];
			}
			[body appendFormat:@"<p class='%@'>%@</p>", @"notes", [self format:values]];
			[titlePage removeObjectForKey:@"notes"];
		}
		
		// Append rest of the stuff
		for (NSString* key in titlePage) {
			NSArray *obj = titlePage[key];
			NSMutableString *values = [NSMutableString string];

			for (NSString *val in obj) {
				[values appendFormat:@"%@<br>", val];
			}
			// We won't set a class value based on the custom key, because it might conflict with existing css styles
			[body appendFormat:@"<p>%@</p>", [self format:values]];
		}
		
		[body appendFormat:@"</div>"];
		
        [body appendString:@"</section>"];
    }
    
    NSInteger dualDialogueCharacterCount = 0;
    NSSet *ignoringTypes = [NSSet setWithObjects:@"Boneyard", @"Comment", @"Synopsis", @"Section Heading", nil];
	
	FountainPaginator *paginator = [[FountainPaginator alloc] initWithScript:_script document:_document];
    NSUInteger maxPages = [paginator numberOfPages];
	
	_numberOfPages = maxPages;

	bool pageBreak = false;
	
    for (NSInteger pageIndex = 0; pageIndex < maxPages; pageIndex++) {
        NSArray *elementsOnPage = [paginator pageAtIndex:pageIndex];
        
        // Print what page we're on -- used for page jumper
		[body appendFormat:@"<section>"];
		
		int index = (int)pageIndex+1;
		int elementCount = 0;
		
        if (self.customPage) {
            if ([self.customPage integerValue] == 0) {
                if ([self.forRendering boolValue]) {
                    [body appendFormat:@"<p class='page-break-render'></p>\n"];
                } else {
                    [body appendFormat:@"<p class='page-break'></p>\n"];
                }
            } else {
                if ([self.forRendering boolValue]) {
					// I don't understand this part. For some reason certain elements are cut off the page and have a random page number there when rendering. So, as a rational and solution-oriented person, I just removed the page number altogether if this happens.
					if (index < 2) {
                    	[body appendFormat:@"<p class='page-break-render'>%d.</p>\n", [self.customPage intValue]];
					}
                } else {
                    [body appendFormat:@"<p class='page-break'>%d.</p>\n", [self.customPage intValue]];
                }
            }
        } else {
            if ([self.forRendering boolValue]) {
                [body appendFormat:@"<p class='page-break-render'>%d.</p>\n", (int)pageIndex+1];
            } else {
                [body appendFormat:@"<p class='page-break'>%d.</p>\n", (int)pageIndex+1];
            }
        }
		
		// We need to catch lyrics not to make them fill up a paragraph
		bool isLyrics = false;
		
        for (Line *line in elementsOnPage) {
			bool beginBlock = false;
			
			if ([ignoringTypes containsObject:line.typeAsFountainString]) {
				
				// Close possible blocks
				if (isLyrics) {
					// Close lyrics block
					[body appendFormat:@"</p>\n"];
					isLyrics = false;
				}
				
                continue;
            }
			
			if ([line.typeAsFountainString isEqualToString:@"Page Break"]) {
				// Close possible blocks
				if (isLyrics) {
					// Close lyrics block
					[body appendFormat:@"</p>\n"];
					isLyrics = false;
				}
				
				pageBreak = true;
                continue;
            }
			
			// NEEDS TO BE DEBUGGED
			 
			// Stop dual dialogue
			if (dualDialogueCharacterCount == 2 &&
				!(line.type == dualDialogueParenthetical ||
				 line.type == dualDialogue)) {
				[body appendString:@"</div></div>\n"];
				dualDialogueCharacterCount = 0;
			}
			
			// Catch dual dialogue
			if (line.type == character && line.nextElementIsDualDialogue) {
				dualDialogueCharacterCount++;
				[body appendString:@"<div class='dual-dialogue'>\n"];
				[body appendString:@"<div class='dual-dialogue-left'>\n"];
            }
			
			if (line.type == dualDialogueCharacter && dualDialogueCharacterCount == 1) {
				dualDialogueCharacterCount++;
                    [body appendString:@"</div>\n<div class='dual-dialogue-right'>\n"];
			}
            
            NSMutableString *text = [NSMutableString string];            
			if (line.type == heading && line.sceneNumber) {
                [text appendFormat:@"<span id='scene-%@' class='scene-number-left'>%@</span>", line.sceneNumber, line.sceneNumber];
				[text appendString:line.cleanedString];
				[text appendFormat:@"<span class='scene-number-right'>%@</span>", line.sceneNumber];
            }
            else {
                [text appendString:line.string];
            }
			
			// Remove any formatting symbols
			// (these should be caught by Line methods, though)
			if (line.type == dualDialogueCharacter) {
                [text replaceOccurrencesOfString:@"^" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, text.length)];
            }
            
			if (line.type == heading) {
                [text setString:[text replace:RX(@"^\\.") with:@""]];
				[text setString:[NSString stringWithFormat:@"<a href='#' onclick='selectScene(this);' sceneIndex='%lu'>%@</a>", line.sceneIndex, text]];
            }
            if (line.type == character) {
				[text setString:[text replace:RX(@"^@") with:@""]];
			}
			if (line.type == lyrics) {
                [text setString:[text replace:RX(@"^~") with:@""]];
				if (!isLyrics) {
					beginBlock = true;
					isLyrics = true;
				}
			} else {
				// Close possible blocks
				if (isLyrics) {
					// Close lyrics block
					[body appendFormat:@"</p>\n"];
					isLyrics = false;
				}
			}
            
			if (line.type == action) {
                [text setString:[text replace:RX(@"^\\!") with:@""]];
            }
            
			// Format string for HTML
			[text setString:[self format:text]];
            [text setString:[text replace:RX(@"\\[{2}(.*?)\\]{2}") with:@""]];
            
            //Find newlines and replace them with <br/>
            text = [[text stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"] mutableCopy];
            
            if (![text isEqualToString:@""]) {
                NSMutableString *additionalClasses = [NSMutableString string];
				if (line.centered) {
                    [additionalClasses appendString:@" center"];
                }
				if (elementCount == 0) [additionalClasses appendString:@" first"];
				
				// If this line isn't part of a larger block, output it as paragraph
				if (!beginBlock && !isLyrics) {
					[body appendFormat:@"<p class='%@%@'>%@</p>\n", [self htmlClassForType:line.typeAsFountainString], additionalClasses, text];
				} else {
					if (beginBlock) {
						// Begin new block
						[body appendFormat:@"<p class='%@%@'>%@<br>\n", [self htmlClassForType:line.typeAsFountainString], additionalClasses, text];
					} else {
						// Continue the block
						[body appendFormat:@"%@<br>\n", text];
					}
				}
			} else {
				// Just in case
				if (isLyrics) {
					// Close lyrics block
					[body appendFormat:@"</p>\n"];
					isLyrics = false;
				}
			}
			
			elementCount++;
        }
		//if (!pageBreak) [body appendFormat:@"</section>"];
		[body appendFormat:@"</section>"];
    }
	
    return body;
}

- (NSString*)previewUI {
	return @"" \
	"<div id='close' class='ui' onclick='closePreview();'>✕</div>" \
	
	//"<div class='left'>" \
	//    "<div id='zoomIn' class='ui' onclick='zoomIn();'>+</div>" \
		"<div id='zoomOut' class='ui' onclick='zoomOut();'>-</div>" \
	// "</div>"
	"";
}

- (NSString*)previewJS {
	return @"" \
	"<script>function scrollToScene(scene) { var el = document.getElementById('scene-' + scene); el.scrollIntoView({ behavior:'auto',block:'center',inline:'center' }); }</script>" \
	"<script>var zoomLevel = 100;" \
		"function zoomIn() { if (zoomLevel < 200) { zoomLevel += 10; document.body.style.zoom = zoomLevel + '%'; } }" \
		"function zoomOut() { if (zoomLevel > 50) { zoomLevel -= 10;  document.body.style.zoom = zoomLevel + '%'; } }" \
	"</script>" \
	"<script>function selectScene(e) { window.webkit.messageHandlers.selectSceneFromScript.postMessage(e.getAttribute('sceneIndex')); }</script>" \
	"<script>function closePreview () { window.webkit.messageHandlers.closePrintPreview.postMessage('close'); } </script>";
}

@end
