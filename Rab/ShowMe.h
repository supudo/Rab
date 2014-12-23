//
//  ShowMe.h
//  Rab
//
//  Created by Sergey Petrov on 2/27/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BZFoursquare.h"

@interface ShowMe : UIViewController <BZFoursquareRequestDelegate, BZFoursquareSessionDelegate>

@property (nonatomic, readonly, strong) BZFoursquare *foursquare;
@property (nonatomic, strong) NSDictionary *jsonVenues;
@property (nonatomic, assign) IBOutlet UIImageView *imgCompass;
@property (nonatomic, assign) IBOutlet UITextView *txtTitle;
@property (nonatomic, assign) IBOutlet UILabel *lblDistance;

- (void)doCheckIn;

@end
