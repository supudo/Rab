//
//  RevealLocation.h
//  Rab
//
//  Created by Sergey Petrov on 2/28/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface RevealLocation : UIViewController <MKMapViewDelegate>

@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) NSDictionary *currentVenue;
@property (nonatomic, assign) IBOutlet MKMapView *mapView;
@property (nonatomic, assign) IBOutlet UISegmentedControl *scTravelMode;

- (IBAction)iboScTravelMode:(id)sender;

@end
