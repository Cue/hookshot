//
//  AppDelegate.m
//  HookshotDemo
//
//  Created by Robby Walker on 1/15/13.
//  Copyright (c) 2013 Cue. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"
#import "hookshot.h"

@implementation AppDelegate

+ (void)initialize;
{
    if (self != [AppDelegate class]) {
        return;
    }
    if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"HookshotProfile"] isEqualToString:@"YES"]) {
        PROFILE_CLASS(self);
        PROFILE_CLASS([UIWebView class]);
    }
}

- (void)dealloc;
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

    self.viewController = [[[ViewController alloc] initWithNibName:@"ViewController" bundle:nil] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)doSomethingExpensive;
{
    [NSThread sleepForTimeInterval:0.02];
}

- (void)applicationDidBecomeActive:(UIApplication *)application;
{
    for (int i = 0; i < 25; i++) {
        [self doSomethingExpensive];
    }
}

@end
