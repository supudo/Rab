//
//  Home.h
//  Rab
//
//  Created by Sergey Petrov on 2/27/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BZFoursquare.h"
#import <CoreLocation/CoreLocation.h>
#import <iAd/iAd.h>

@interface Home : UIViewController <BZFoursquareRequestDelegate, BZFoursquareSessionDelegate, CLLocationManagerDelegate, ADBannerViewDelegate>

@property (nonatomic, readonly, strong) BZFoursquare *foursquare;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, assign) IBOutlet UITextView *txtInstructions;
@property (nonatomic, assign) IBOutlet ADBannerView *bannerView;

@end
