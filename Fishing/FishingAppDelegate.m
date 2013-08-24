//
//  FishingAppDelegate.m
//  Fishing
//
//  Created by tina on 8/6/13.
//  Copyright (c) 2013 tina. All rights reserved.
//

#import "FishingAppDelegate.h"
#import <Dropbox/Dropbox.h>

@implementation FishingAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    #ifdef DEBUG
    DBAccountManager *mgr =
    [[DBAccountManager alloc] initWithAppKey:@"3vlq3ku9ut4lisf" secret:@"p73ho4ee68uxxyo"];
	[DBAccountManager setSharedManager:mgr];
    #endif
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	UIViewController *root = [storyboard instantiateInitialViewController];
	self.window.rootViewController = root;
    
    [self.window makeKeyAndVisible];
    return YES;
}

#ifdef DEBUG
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	
	[[DBAccountManager sharedManager] handleOpenURL:url];
	
	return YES;
}
#endif

@end
