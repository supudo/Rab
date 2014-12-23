//
//  RABSettings.h
//  Rab
//
//  Created by Sergey Petrov on 2/26/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface RABSettings : NSObject

@property BOOL inDebug, inCheckin;
@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, strong) NSString *appURL, *appStoreID, *appStoreURL, *fsClientID, *fsClientSecret, *fsCallbackURL;
@property (nonatomic, strong) NSString *fsSelectedCategoryID, *googleMapsURL;
@property (nonatomic, strong) CLLocation *testCoordinates;

- (void)LogThis:(NSString *)log, ...;
- (BOOL)internetAvailable;
- (UIColor *)getRandomColor;
- (UIColor *)getOpositeColor:(UIColor *)color;

+ (RABSettings *)sharedInstance;

@end
