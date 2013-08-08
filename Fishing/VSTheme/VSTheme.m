//
//  VSTheme.m
//  Q Branch LLC
//
//  Created by Brent Simmons on 6/26/13.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import "VSTheme.h"
#import <Dropbox/Dropbox.h>

static BOOL stringIsEmpty(NSString *s);
static UIColor *colorWithHexString(NSString *hexString);


@interface VSTheme ()

@property (nonatomic, strong) NSDictionary *themeDictionary;
@property (nonatomic, strong) NSCache *colorCache;
@property (nonatomic, strong) NSCache *fontCache;
@property (nonatomic, strong) NSString *fileName;

@end


@implementation VSTheme

- (DBDatastore *)store {
    static DBDatastore *store = nil;
	if (!store) {
		store = [DBDatastore openDefaultStoreForAccount:[DBAccountManager sharedManager].linkedAccount error:nil];
	}
	return store;
}

// handle unlink case

- (DBTable *)table {
    return [[self store] getTable:self.fileName];
}

#pragma mark Init

- (id)initWithDictionary:(NSDictionary *)themeDictionary andFileName:(NSString *)fileName {
	
	self = [super init];
	if (self == nil)
		return nil;
	
	_themeDictionary = themeDictionary;

	_colorCache = [NSCache new];
	_fontCache = [NSCache new];
    _fileName = fileName;
    [self uploadTheme];
    [self update];

	return self;
}

- (id)objectForKey:(NSString *)key {

	id obj = [self.themeDictionary valueForKeyPath:key];
	if (obj == nil && self.parentTheme != nil)
		obj = [self.parentTheme objectForKey:key];
	return obj;
}

- (void)update {
    NSString *newFileName = self.fileName;
    if (newFileName.length > 23) {
        newFileName = [newFileName substringToIndex:23];
    }
    DBRecord *updated_record = [[self table] getOrInsertRecord:[NSString stringWithFormat:@"%@_updated", newFileName] fields:nil inserted:nil error:nil];
    DBRecord *original_record = [[self table] getOrInsertRecord:[NSString stringWithFormat:@"%@_original", newFileName] fields:nil inserted:nil error:nil];
    
    for (NSString *key in [self.themeDictionary allKeys]) {
        NSString *newKey = key;
        if (key.length > 32) {
            newKey = [key substringToIndex:32];
        }
        id originalValue = [original_record objectForKey:newKey];
        id newValue = [updated_record objectForKey:newKey];
        NSLog(@"new value is %@", newValue);
        if (newValue) {
            if ([[self.themeDictionary objectForKey:key] isKindOfClass:[NSNumber class]] && ![originalValue isEqual:newValue]) {
                NSMutableDictionary *newThemeDict = [NSMutableDictionary dictionaryWithDictionary:self.themeDictionary];
                [newThemeDict setObject:[[[NSNumberFormatter alloc] init] numberFromString:newValue] forKey:key];
                self.themeDictionary = newThemeDict;
            } else if ([[self.themeDictionary objectForKey:key] isKindOfClass:[NSString class]] && ![originalValue isEqualToString:newValue]) {
                NSMutableDictionary *newThemeDict = [NSMutableDictionary dictionaryWithDictionary:self.themeDictionary];
                [newThemeDict setObject:newValue forKey:key];
                self.themeDictionary = newThemeDict;
            }
        }
	}
    NSLog(@"after update, new themedict is %@", self.themeDictionary);
}

- (void)uploadTheme {
    __weak VSTheme *slf = self;
    [[self store] addObserver:self block:^ {
        if ([self store].status & (DBDatastoreIncoming | DBDatastoreOutgoing)) {
            [[self store] sync:nil];
        }
            [slf update];
    }];

    // make sure to add the check
    //sanitize the dictionary
    NSMutableDictionary *uploadDict = [[NSMutableDictionary alloc] init];
    for (NSString *key in self.themeDictionary) {
        NSString *newKey = key;
        if (key.length > 32) {
            newKey = [key substringToIndex:32];
        }
        [uploadDict setObject:self.themeDictionary[key] forKey:newKey];
    }
    
    //delete all records
//    NSArray *tableIds = [[self store] getTables:nil];
//    for (DBTable *table in tableIds) {
//        NSArray *toDelete = [[[self store] getTable:[table tableId]]  query:nil error:nil];
//        for (DBRecord *record in toDelete) {
//            [record deleteRecord];
//        }
//    }
//    [[self store] sync:nil];
//    NSArray *records = [self.table query:nil error:nil];
//    NSString *errorString = [NSString stringWithFormat:@"there should only be one record in table %@", self.fileName];
//    NSAssert([records count] <= 1, errorString);
//    if ([records count] == 0) {
//        [self.table insert:uploadDict];
//    } else {
//        DBRecord *record = records[0];
        BOOL inserted = NO;
    NSString *newFileName = self.fileName;
    if (newFileName.length > 23) {
        newFileName = [newFileName substringToIndex:23];
    }
    DBRecord *newRecord = [self.table getOrInsertRecord:[NSString stringWithFormat:@"%@_original", newFileName] fields:uploadDict inserted:&inserted error:nil];
    [newRecord update:uploadDict];
    NSLog(@"inserted is %d", inserted);
    NSLog(@"new record is %@", newRecord);
        [[self store] sync:nil];
//    }
}

- (BOOL)boolForKey:(NSString *)key {

	id obj = [self objectForKey:key];
	if (obj == nil)
		return NO;
	return [obj boolValue];
}


- (NSString *)stringForKey:(NSString *)key {
	
	id obj = [self objectForKey:key];
	if (obj == nil)
		return nil;
	if ([obj isKindOfClass:[NSString class]])
		return obj;
	if ([obj isKindOfClass:[NSNumber class]])
		return [obj stringValue];
	return nil;
}


- (NSInteger)integerForKey:(NSString *)key {

	id obj = [self objectForKey:key];
	if (obj == nil)
		return 0;
	return [obj integerValue];
}


- (CGFloat)floatForKey:(NSString *)key {
	
	id obj = [self objectForKey:key];
	if (obj == nil)
		return  0.0f;
	return [obj floatValue];
}


- (NSTimeInterval)timeIntervalForKey:(NSString *)key {

	id obj = [self objectForKey:key];
	if (obj == nil)
		return 0.0;
	return [obj doubleValue];
}


- (UIImage *)imageForKey:(NSString *)key {
	
	NSString *imageName = [self stringForKey:key];
	if (stringIsEmpty(imageName))
		return nil;
	
	return [UIImage imageNamed:imageName];
}


- (UIColor *)colorForKey:(NSString *)key {

	UIColor *cachedColor = [self.colorCache objectForKey:key];
	if (cachedColor != nil)
		return cachedColor;
    
	NSString *colorString = [self stringForKey:key];
	UIColor *color = colorWithHexString(colorString);
	if (color == nil)
		color = [UIColor blackColor];

	[self.colorCache setObject:color forKey:key];

	return color;
}


- (UIEdgeInsets)edgeInsetsForKey:(NSString *)key {

	CGFloat left = [self floatForKey:[key stringByAppendingString:@"Left"]];
	CGFloat top = [self floatForKey:[key stringByAppendingString:@"Top"]];
	CGFloat right = [self floatForKey:[key stringByAppendingString:@"Right"]];
	CGFloat bottom = [self floatForKey:[key stringByAppendingString:@"Bottom"]];

	UIEdgeInsets edgeInsets = UIEdgeInsetsMake(top, left, bottom, right);
	return edgeInsets;
}


- (UIFont *)fontForKey:(NSString *)key {

	UIFont *cachedFont = [self.fontCache objectForKey:key];
	if (cachedFont != nil)
		return cachedFont;
    
	NSString *fontName = [self stringForKey:key];
	CGFloat fontSize = [self floatForKey:[key stringByAppendingString:@"Size"]];

	if (fontSize < 1.0f)
		fontSize = 15.0f;

	UIFont *font = nil;
    
	if (stringIsEmpty(fontName))
		font = [UIFont systemFontOfSize:fontSize];
	else
		font = [UIFont fontWithName:fontName size:fontSize];

	if (font == nil)
		font = [UIFont systemFontOfSize:fontSize];
    
	[self.fontCache setObject:font forKey:key];

	return font;
}


- (CGPoint)pointForKey:(NSString *)key {

	CGFloat pointX = [self floatForKey:[key stringByAppendingString:@"X"]];
	CGFloat pointY = [self floatForKey:[key stringByAppendingString:@"Y"]];

	CGPoint point = CGPointMake(pointX, pointY);
	return point;
}


- (CGSize)sizeForKey:(NSString *)key {

	CGFloat width = [self floatForKey:[key stringByAppendingString:@"Width"]];
	CGFloat height = [self floatForKey:[key stringByAppendingString:@"Height"]];

	CGSize size = CGSizeMake(width, height);
	return size;
}


- (UIViewAnimationOptions)curveForKey:(NSString *)key {
    
	NSString *curveString = [self stringForKey:key];
	if (stringIsEmpty(curveString))
		return UIViewAnimationOptionCurveEaseInOut;

	curveString = [curveString lowercaseString];
	if ([curveString isEqualToString:@"easeinout"])
		return UIViewAnimationOptionCurveEaseInOut;
	else if ([curveString isEqualToString:@"easeout"])
		return UIViewAnimationOptionCurveEaseOut;
	else if ([curveString isEqualToString:@"easein"])
		return UIViewAnimationOptionCurveEaseIn;
	else if ([curveString isEqualToString:@"linear"])
		return UIViewAnimationOptionCurveLinear;
    
	return UIViewAnimationOptionCurveEaseInOut;
}


- (VSAnimationSpecifier *)animationSpecifierForKey:(NSString *)key {

	VSAnimationSpecifier *animationSpecifier = [VSAnimationSpecifier new];

	animationSpecifier.duration = [self timeIntervalForKey:[key stringByAppendingString:@"Duration"]];
	animationSpecifier.delay = [self timeIntervalForKey:[key stringByAppendingString:@"Delay"]];
	animationSpecifier.curve = [self curveForKey:[key stringByAppendingString:@"Curve"]];

	return animationSpecifier;
}


- (VSTextCaseTransform)textCaseTransformForKey:(NSString *)key {

	NSString *s = [self stringForKey:key];
	if (s == nil)
		return VSTextCaseTransformNone;

	if ([s caseInsensitiveCompare:@"lowercase"] == NSOrderedSame)
		return VSTextCaseTransformLower;
	else if ([s caseInsensitiveCompare:@"uppercase"] == NSOrderedSame)
		return VSTextCaseTransformUpper;

	return VSTextCaseTransformNone;
}


@end


@implementation VSTheme (Animations)


- (void)animateWithAnimationSpecifierKey:(NSString *)animationSpecifierKey animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {

    VSAnimationSpecifier *animationSpecifier = [self animationSpecifierForKey:animationSpecifierKey];

    [UIView animateWithDuration:animationSpecifier.duration delay:animationSpecifier.delay options:animationSpecifier.curve animations:animations completion:completion];
}

@end


#pragma mark -

@implementation VSAnimationSpecifier

@end


static BOOL stringIsEmpty(NSString *s) {
	return s == nil || [s length] == 0;
}


static UIColor *colorWithHexString(NSString *hexString) {

	/*Picky. Crashes by design.*/
	
	if (stringIsEmpty(hexString))
		return [UIColor blackColor];

	NSMutableString *s = [hexString mutableCopy];
	[s replaceOccurrencesOfString:@"#" withString:@"" options:0 range:NSMakeRange(0, [hexString length])];
	CFStringTrimWhitespace((__bridge CFMutableStringRef)s);

	NSString *redString = [s substringToIndex:2];
	NSString *greenString = [s substringWithRange:NSMakeRange(2, 2)];
	NSString *blueString = [s substringWithRange:NSMakeRange(4, 2)];

	unsigned int red = 0, green = 0, blue = 0;
	[[NSScanner scannerWithString:redString] scanHexInt:&red];
	[[NSScanner scannerWithString:greenString] scanHexInt:&green];
	[[NSScanner scannerWithString:blueString] scanHexInt:&blue];

	return [UIColor colorWithRed:(CGFloat)red/255.0f green:(CGFloat)green/255.0f blue:(CGFloat)blue/255.0f alpha:1.0f];
}
