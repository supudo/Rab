//
//  AppDelegate.m
//  Rab
//
//  Created by Sergey Petrov on 2/27/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import "AppDelegate.h"
#import "Appirater.h"
#import "BZFoursquare.h"
#import "Home.h"
#import "ShowMe.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Appirater setAppId:[RABSettings sharedInstance].appStoreID];
    [Appirater setDaysUntilPrompt:2];
    [Appirater setUsesUntilPrompt:10];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:5];
    [Appirater setDebug:NO];
    [Appirater appLaunched:YES];
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
    [Appirater appEnteredForeground:YES];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([RABSettings sharedInstance].inCheckin) {
        UINavigationController *navCont = (UINavigationController *)[[UIApplication sharedApplication] keyWindow].rootViewController;
        ShowMe *sm = (ShowMe *)navCont.presentedViewController;//navCont.viewControllers[0];
        BZFoursquare *foursquare = sm.foursquare;
        BOOL res = [foursquare handleOpenURL:url];
        if (res && [sm respondsToSelector:@selector(doCheckIn)])
            [sm doCheckIn];
        return res;
    }
    return NO;
    
    
    UIViewController *topVC = [[UIApplication sharedApplication] keyWindow].rootViewController;
    if (topVC != nil) {
        if ([RABSettings sharedInstance].inCheckin) {
            ShowMe *pv = (ShowMe *)topVC;
            if (pv != nil && pv.foursquare != nil) {
                BZFoursquare *foursquare = pv.foursquare;
                return [foursquare handleOpenURL:url];
            }
        }
        else {
            Home *pv = (Home *)topVC;
            if (pv != nil && pv.foursquare != nil) {
                BZFoursquare *foursquare = pv.foursquare;
                return [foursquare handleOpenURL:url];
            }
        }
    }
    return NO;
}

@end
