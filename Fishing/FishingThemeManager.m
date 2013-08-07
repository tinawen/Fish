//
//  FishingThemeManager.m
//  Fishing
//
//  Created by tina on 8/7/13.
//  Copyright (c) 2013 tina. All rights reserved.
//

#import "FishingThemeManager.h"
#import "VSTheme.h"
#import "VSThemeLoader.h"

@implementation FishingThemeManager

+ (NSCache *)allThemes
{
    static NSCache *themes = nil;
    if (themes == nil) {
        themes = [[NSCache alloc] init];
    }
    return themes;
}

+ (VSTheme *)themeNamed:(NSString *)themeName
{
    VSThemeLoader *themeLoader = [[FishingThemeManager allThemes] objectForKey:themeName];
    if (!themeLoader) {
        themeLoader = [[VSThemeLoader alloc] initWithPathForResource:themeName];
        [[FishingThemeManager allThemes] setObject:themeLoader forKey:themeName];
    }
    return themeLoader.defaultTheme;
}

@end
