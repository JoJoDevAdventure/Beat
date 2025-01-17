/*
 
 Original code © Paulo Andrade
 Heavily modified for Beat by Lauri-Matti Parppei
 
 No license information available, so I'm guessing this is public domain
 
 */

#import "DynamicColor.h"

#define FORWARD( PROP, TYPE ) \
- (TYPE)PROP { return [self.effectiveColor PROP]; }


#if !TARGET_OS_IOS

/*
 ------------------------------------------------------------------
 macOS implementation
 ------------------------------------------------------------------
*/

#import <Cocoa/Cocoa.h>
#import "BeatAppDelegate.h"

@interface DynamicColor ()
@property (nonatomic, strong, readonly) NSColor *effectiveColor;
@end

@implementation DynamicColor

- (instancetype)initWithAquaColor:(NSColor *)aquaColor
                    darkAquaColor:(NSColor *)darkAquaColor
{
    self = [super init];
    if (self) {
        _aquaColor = aquaColor;
        _darkAquaColor = darkAquaColor;
    }
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _aquaColor = [coder decodeObjectOfClass:[NSColor class] forKey:@"aquaColor"];
        _darkAquaColor = [coder decodeObjectOfClass:[NSColor class] forKey:@"darkAquaColor"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.aquaColor forKey:@"aquaColor"];
    if (self.darkAquaColor) {
        [aCoder encodeObject:self.darkAquaColor forKey:@"darkAquaColor"];
    }
}

-(id)copy {
	DynamicColor *color = [DynamicColor.alloc initWithAquaColor:self.aquaColor darkAquaColor:self.darkAquaColor];
	return color;
}
-(id)copyWithZone:(NSZone *)zone {
	DynamicColor *color = [[self.class allocWithZone:zone] initWithAquaColor:self.aquaColor darkAquaColor:self.aquaColor];
	return color;
}

- (NSColor *)effectiveColor
{
	// Don't allow calls to this class from anywhere else than main thread
	if (!NSThread.isMainThread) return self.aquaColor;

	if (@available(macOS 10.14, *)) {
		NSAppearance *appearance = [NSAppearance currentAppearance] ?: [NSApp effectiveAppearance];
		NSAppearanceName appearanceName = [appearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
		
		if (self.darkAquaColor != nil &&
			([appearanceName isEqualToString:NSAppearanceNameDarkAqua] ||
			[(BeatAppDelegate*)NSApp.delegate isDark]))
		{
			return self.darkAquaColor;
		}
	}

	return self.aquaColor;

}

FORWARD(colorSpace, NSColorSpace *)
- (NSColor *)colorUsingColorSpace:(NSColorSpace *)space
{
    return [self.effectiveColor colorUsingColorSpace:space];
}

FORWARD(colorSpaceName, NSColorSpaceName)
- (NSColor *)colorUsingColorSpaceName:(NSColorSpaceName)name
{
    return [self.effectiveColor colorUsingColorSpaceName:name];
}

FORWARD(numberOfComponents, NSInteger)
- (void)getComponents:(CGFloat *)components
{
    return [self.effectiveColor getComponents:components];
}

#pragma mark - RGB colorspace

FORWARD(redComponent, CGFloat)
FORWARD(greenComponent, CGFloat)
FORWARD(blueComponent, CGFloat)

- (void)getRed:(nullable CGFloat *)red green:(nullable CGFloat *)green blue:(nullable CGFloat *)blue alpha:(nullable CGFloat *)alpha
{
    return [self.effectiveColor getRed:red green:green blue:blue alpha:alpha];
}

#pragma mark - HSB colorspace

FORWARD(hueComponent, CGFloat)
FORWARD(saturationComponent, CGFloat)
FORWARD(brightnessComponent, CGFloat)

- (void)getHue:(nullable CGFloat *)hue saturation:(nullable CGFloat *)saturation brightness:(nullable CGFloat *)brightness alpha:(nullable CGFloat *)alpha
{
    return [self.effectiveColor getHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

#pragma mark - Gray colorspace

FORWARD(whiteComponent, CGFloat)

- (void)getWhite:(CGFloat *)white alpha:(CGFloat *)alpha
{
    return [self.effectiveColor getWhite:white alpha:alpha];
}

#pragma mark - CMYK colorspace

FORWARD(cyanComponent, CGFloat)
FORWARD(magentaComponent, CGFloat)
FORWARD(yellowComponent, CGFloat)
FORWARD(blackComponent, CGFloat)

- (void)getCyan:(nullable CGFloat *)cyan magenta:(nullable CGFloat *)magenta yellow:(nullable CGFloat *)yellow black:(nullable CGFloat *)black alpha:(nullable CGFloat *)alpha
{
    return [self.effectiveColor getCyan:cyan magenta:magenta yellow:yellow black:black alpha:alpha];
}

#pragma mark - Others

FORWARD(alphaComponent, CGFloat)
FORWARD(CGColor, CGColorRef)
FORWARD(catalogNameComponent, NSColorListName)
FORWARD(colorNameComponent, NSColorName)
FORWARD(localizedCatalogNameComponent, NSColorListName)
FORWARD(localizedColorNameComponent, NSString *)

- (void)setStroke
{
     [self.effectiveColor setStroke];
}

- (void)setFill
{
    [self.effectiveColor setFill];
}

- (void)set
{
    [self.effectiveColor set];
}

- (nullable NSColor *)highlightWithLevel:(CGFloat)val
{
    return [self.effectiveColor highlightWithLevel:val];
}

- (NSColor *)shadowWithLevel:(CGFloat)val
{
    return [self.effectiveColor shadowWithLevel:val];
}

- (NSColor *)colorWithAlphaComponent:(CGFloat)alpha
{
    return [self.effectiveColor colorWithAlphaComponent:alpha];
}

- (nullable NSColor *)blendedColorWithFraction:(CGFloat)fraction ofColor:(NSColor *)color
{
    return [self.effectiveColor blendedColorWithFraction:fraction ofColor:color];
}

- (NSColor *)colorWithSystemEffect:(NSColorSystemEffect)systemEffect NS_AVAILABLE_MAC(10_14)
{
    return [self.effectiveColor colorWithSystemEffect:systemEffect];
}

- (BOOL)isEqualToColor:(DynamicColor *)otherColor {
	CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
	
	NSColor *(^convertColorToRGBSpace)(NSColor*) = ^(NSColor *color) {
		if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
			const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
			CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
			CGColorRef colorRef = CGColorCreate( colorSpaceRGB, components );

			NSColor *color = [NSColor colorWithCGColor:colorRef];
			CGColorRelease(colorRef);
			return color;
		} else
			return color;
	};
	
	NSColor *lightColor = convertColorToRGBSpace(self.aquaColor);
	NSColor *darkColor = convertColorToRGBSpace(self.darkAquaColor);
	
	NSColor *lightOther = convertColorToRGBSpace(otherColor.aquaColor);
	NSColor *darkOther = convertColorToRGBSpace(otherColor.darkAquaColor);
	
	CGColorSpaceRelease(colorSpaceRGB);
	
	if ([lightColor isEqual:lightOther] && [darkColor isEqual:darkOther]) return YES;
	else return NO;
}

- (NSArray*)valuesAsRGB {
	NSColor *light = [self convertToRGB:self.aquaColor];
	NSColor *dark = [self convertToRGB:self.darkAquaColor];
	
	NSArray *result = @[
		@[ [NSNumber numberWithInt:(light.redComponent * 255)], [NSNumber numberWithInt:(light.greenComponent * 255)], [NSNumber numberWithInt:(light.blueComponent * 255)] ],
		@[ [NSNumber numberWithInt:(dark.redComponent * 255)], [NSNumber numberWithInt:(dark.greenComponent * 255)], [NSNumber numberWithInt:(dark.blueComponent * 255)] ]
	];
	
	return result;
}

- (NSColor*)convertToRGB:(NSColor*)color {
	if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
		CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
		
		const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
		CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
		CGColorRef colorRef = CGColorCreate( colorSpaceRGB, components );

		NSColor *color = [NSColor colorWithCGColor:colorRef];
		CGColorRelease(colorRef);
		CGColorSpaceRelease(colorSpaceRGB);
		return color;
	} else
		return color;
}


@end

#else

/*
 ------------------------------------------------------------------
 iOS implementation
 ------------------------------------------------------------------
*/

#import <UIKit/UIKit.h>

@interface DynamicColor ()
@property (nonatomic, strong, readonly) UIColor *effectiveColor;
@end

@implementation DynamicColor

- (instancetype)initWithAquaColor:(UIColor *)aquaColor
					darkAquaColor:(UIColor *)darkAquaColor
{
	self = [super init];
	if (self) {
		_aquaColor = aquaColor;
		_darkAquaColor = darkAquaColor;
	}
	return self;
}

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		_aquaColor = [coder decodeObjectOfClass:[UIColor class] forKey:@"aquaColor"];
		_darkAquaColor = [coder decodeObjectOfClass:[UIColor class] forKey:@"darkAquaColor"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:self.aquaColor forKey:@"aquaColor"];
	if (self.darkAquaColor) {
		[aCoder encodeObject:self.darkAquaColor forKey:@"darkAquaColor"];
	}
}

- (UIColor *)effectiveColor
{
	// Don't allow calls to this class from anywhere else than main thread
	if (!NSThread.isMainThread) return self.aquaColor;
	
	if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) return self.darkAquaColor;
	else return self.aquaColor;
}

- (UIColor *)effectiveColorFor:(UIView*)view
{
	// Don't allow calls to this class from anywhere else than main thread
	if (!NSThread.isMainThread) return self.aquaColor;
	
	if (view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) return self.darkAquaColor;
	else return self.aquaColor;
}



#pragma mark - RGB colorspace

- (bool)getRed:(nullable CGFloat *)red green:(nullable CGFloat *)green blue:(nullable CGFloat *)blue alpha:(nullable CGFloat *)alpha
{
	return [self.effectiveColor getRed:red green:green blue:blue alpha:alpha];
}


#pragma mark - Others

FORWARD(CGColor, CGColorRef)

-(NSUInteger)hash {
	return [self.effectiveColor hash];
}
 
- (void)setStroke
{
	 [self.effectiveColor setStroke];
}

- (void)setFill
{
	[self.effectiveColor setFill];
}

- (void)set
{
	[self.effectiveColor set];
}

- (UIColor *)colorWithAlphaComponent:(CGFloat)alpha
{
	return [self.effectiveColor colorWithAlphaComponent:alpha];
}

- (BOOL)isEqual:(id)color {
	UIColor *other = convertColorToRGBSpace(color);
	UIColor *current = convertColorToRGBSpace(self.effectiveColor);
	
	if ([other isEqual:current]) return YES;
	else return NO;
}

UIColor *(^convertColorToRGBSpace)(UIColor*) = ^(UIColor *color) {
	CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
	
	if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
		const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
		CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
		CGColorRef colorRef = CGColorCreate( colorSpaceRGB, components );

		UIColor *color = [UIColor colorWithCGColor:colorRef];
		CGColorRelease(colorRef);
		return color;
	} else
		return color;
};

- (BOOL)isEqualToColor:(DynamicColor *)otherColor {
	CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
	
	UIColor *lightColor = convertColorToRGBSpace(self.aquaColor);
	UIColor *darkColor = convertColorToRGBSpace(self.darkAquaColor);
	
	UIColor *lightOther = convertColorToRGBSpace(otherColor.aquaColor);
	UIColor *darkOther = convertColorToRGBSpace(otherColor.darkAquaColor);
	
	CGColorSpaceRelease(colorSpaceRGB);
	
	if ([lightColor isEqual:lightOther] && [darkColor isEqual:darkOther]) return YES;
	else return NO;
}

- (NSArray*)valuesAsRGB {
	UIColor *light = [self convertToRGB:self.aquaColor];
	UIColor *dark = [self convertToRGB:self.darkAquaColor];
	
	CGFloat lRed, lBlue, lGreen, dRed, dBlue, dGreen;
	[light getRed:&lRed green:&lGreen blue:&lBlue alpha:nil];
	[dark getRed:&dRed green:&dGreen blue:&dBlue alpha:nil];
	
	NSArray *result = @[
		@[ [NSNumber numberWithInt:(lRed * 255)], [NSNumber numberWithInt:(lGreen * 255)], [NSNumber numberWithInt:(lBlue * 255)] ],
		@[ [NSNumber numberWithInt:(dRed * 255)], [NSNumber numberWithInt:(dGreen * 255)], [NSNumber numberWithInt:(dBlue * 255)] ]
	];
	
	return result;
}

- (UIColor*)convertToRGB:(UIColor*)color {
	if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
		CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
		
		const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
		CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
		CGColorRef colorRef = CGColorCreate( colorSpaceRGB, components );

		UIColor *color = [UIColor colorWithCGColor:colorRef];
		CGColorRelease(colorRef);
		CGColorSpaceRelease(colorSpaceRGB);
		return color;
	} else
		return color;
}

@end


#endif
