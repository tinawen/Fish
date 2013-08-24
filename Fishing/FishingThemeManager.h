//
//  FishingThemeManager.h
//  Fishing
//
//  Created by tina on 8/7/13.
//  Copyright (c) 2013 tina. All rights reserved.
//
#import <Foundation/Foundation.h>

@class VSTheme;
@interface FishingThemeManager : NSObject

+ (VSTheme *)themeNamed:(NSString *)themeName;

@end