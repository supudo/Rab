//
//  RABSettings.m
//  Rab
//
//  Created by Sergey Petrov on 2/26/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import "RABSettings.h"
#import "Reachability.h"

@implementation RABSettings

@synthesize inDebug, fontName, appURL, appStoreID, appStoreURL, fsClientID, fsClientSecret, fsCallbackURL;
@synthesize fsSelectedCategoryID, googleMapsURL, testCoordinates, inCheckin;

+ (RABSettings *)sharedInstance {
    static dispatch_once_t once;
    static RABSettings * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)LogThis:(NSString *)log, ... {
    if (self.inDebug) {
        NSString *output;
        va_list ap;
        va_start(ap, log);
        output = [[NSString alloc] initWithFormat:log arguments:ap];
        va_end(ap);
        NSLog(@"[Rab] %@", output);
    }
}

- (BOOL)internetAvailable {
	Reachability *r = [Reachability reachabilityForInternetConnection];
	NetworkStatus internetStatus = [r currentReachabilityStatus];
	BOOL result = FALSE;
	if (internetStatus == ReachableViaWiFi || internetStatus == ReachableViaWWAN)
	    result = TRUE;
	return result;
}

- (id) init {
	if (self = [super init]) {
#if (TARGET_IPHONE_SIMULATOR)
        self.inDebug = YES;
#else
        self.inDebug = NO;
#endif
        self.inCheckin = NO;
        
        self.appURL = @"rabapp";
        self.fsCallbackURL = [NSString stringWithFormat:@"%@://foursquare", self.appURL];

        self.appStoreID = @"834206488";
        self.appStoreURL = [NSString stringWithFormat:@"https://itunes.apple.com/us/app/rab/id%@?ls=1&mt=8", self.appStoreID];
        
        self.fsClientID = @"ZXYDWTOP3OH3MFBTTNTXCJJMTTOKAHG0DF5CVNGI3ORPM4N0";
        self.fsClientSecret = @"BUQBM5WTQPZ44J51OSVQHV4ES4WP4WFDN1ROFAKEMPP41JPV";
        self.googleMapsURL = @"http://maps.googleapis.com/maps/api/directions/json?";
        
        self.fontName = @"Harabara";//@"Karma Future";

        self.fsSelectedCategoryID = [[NSUserDefaults standardUserDefaults] objectForKey:@"fsSelectedCategoryID"];
        self.testCoordinates = [[CLLocation alloc] initWithLatitude:42.6663539 longitude:23.3216700];
    }
    return self;
}

- (UIColor *)getRandomColor {
    CGFloat red =  (CGFloat)arc4random() / (CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)arc4random() / (CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)arc4random() / (CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (UIColor *)getOpositeColor:(UIColor *)color {
    const CGFloat *componentColors = CGColorGetComponents(color.CGColor);
    UIColor *newColor = [[UIColor alloc] initWithRed:(1.0 - componentColors[0])
                                               green:(1.0 - componentColors[1])
                                                blue:(1.0 - componentColors[2])
                                               alpha:componentColors[3]];
    return newColor;
}

@end
