//
//  ShowMe.m
//  Rab
//
//  Created by Sergey Petrov on 2/27/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import "ShowMe.h"
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "RevealLocation.h"

@interface ShowMe () <CLLocationManagerDelegate, UITextFieldDelegate>
@property (nonatomic, readwrite, strong) BZFoursquare *foursquare;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property float degrees, venueLat, venueLon;
@property double distance;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLHeading *currentHeading;
@property BOOL inLocating;
@property int shakeCounter;
@property (nonatomic, strong) NSDictionary *currentVenue;
@property (nonatomic, strong) BZFoursquareRequest *request;
@property int checkinBroadcast;
@property (nonatomic, strong) NSString *checkInMessage;
@end

@implementation ShowMe

@synthesize foursquare, jsonVenues, imgCompass, locationManager, degrees, venueLat, venueLon, txtTitle, hud, lblDistance;
@synthesize currentLocation, currentHeading, inLocating, distance, shakeCounter, currentVenue, checkinBroadcast, checkInMessage;

#pragma mark - System

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.foursquare = [[BZFoursquare alloc] initWithClientID:[RABSettings sharedInstance].fsClientID callbackURL:[RABSettings sharedInstance].fsCallbackURL];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyyMMdd"];
        [self.foursquare setVersion:[df stringFromDate:[NSDate date]]];
        [self.foursquare setLocale:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]];
        [self.foursquare setSessionDelegate:self];
        [self.foursquare setClientSecret:[RABSettings sharedInstance].fsClientSecret];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    self.foursquare.sessionDelegate = nil;
    [self cancelRequest];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.locationManager = [[CLLocationManager alloc] init];
	[self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
	[self.locationManager setHeadingFilter:1];
	[self.locationManager setDelegate:self];
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
    
    self.currentLocation = [locationManager location];
    [self calculateUserAngle];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:self.imgCompass.frame];
    [btn setBackgroundColor:[UIColor clearColor]];
    [btn addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.shakeCounter = 0;
    self.checkinBroadcast = 0;
    self.checkInMessage = @"";
    
    [self setupUI];

    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
    
    if ([RABSettings sharedInstance].inCheckin)
        [self doCheckIn];
    else {
#if (TARGET_IPHONE_SIMULATOR)
        self.currentLocation = [RABSettings sharedInstance].testCoordinates;
#endif
        if (self.currentVenue == nil)
            [self loadRandomVenue];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
}

#pragma mark - UI

- (void)setupUI {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:self.view.frame];
    [btn addTarget:self action:@selector(showLocation) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    [self.lblDistance setFont:[UIFont fontWithName:[RABSettings sharedInstance].fontName size:24.0]];
}

- (void)showLocation {
    //[self doCheckIn];
    [self performSegueWithIdentifier:@"openRevealLocation" sender:self];
}

- (void)setupTitle:(NSString *)title {
    float x = 30;
    float y = 60;
    float w = self.view.frame.size.width - (x * 2);
    [self.txtTitle setFrame:CGRectMake(x, y, w, self.view.frame.size.height)];
    [self.txtTitle setText:title];
    [self.txtTitle setFont:[UIFont fontWithName:[RABSettings sharedInstance].fontName size:24.0]];
    [self.txtTitle sizeToFit];
    
    CGRect f = self.txtTitle.frame;
    f.size.width += 10;
    f.size.height += 10;
    [self.txtTitle setFrame:f];

    [self.txtTitle setTextAlignment:NSTextAlignmentCenter];
    CGPoint cp = self.txtTitle.center;
    cp.x = self.view.frame.size.width / 2;
    [self.txtTitle setCenter:cp];
    
    UIColor *rc = [[RABSettings sharedInstance] getRandomColor];
    UIColor *newColor = [[RABSettings sharedInstance] getOpositeColor:rc];
    [self.view setBackgroundColor:rc];
    [self.txtTitle setTextColor:newColor];
    
    UIColor *rsc = [[RABSettings sharedInstance] getRandomColor];
    [self.txtTitle.layer setShadowColor:[rsc CGColor]];
    [self.txtTitle.layer setShadowOffset:CGSizeZero];
    [self.txtTitle.layer setShadowOpacity:1.0f];
    [self.txtTitle.layer setShadowRadius:5.0f];
    
    [self.lblDistance setTextAlignment:NSTextAlignmentCenter];
    [self.lblDistance.layer setShadowColor:[rsc CGColor]];
    [self.lblDistance.layer setShadowOffset:CGSizeZero];
    [self.lblDistance.layer setShadowOpacity:1.0f];
    [self.lblDistance.layer setShadowRadius:5.0f];
    cp = self.lblDistance.center;
    cp.x = self.view.frame.size.width / 2;
    [self.lblDistance setCenter:cp];
    [self.lblDistance setTextColor:newColor];
    
    [self getDistance];
}

- (void)goBack:(UIButton *)btn {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"openRevealLocation"]) {
        RevealLocation *ce = (RevealLocation *)segue.destinationViewController;
        [ce setCurrentVenue:self.currentVenue];
        [ce setCurrentLocation:self.currentLocation];
    }
}

#pragma mark - GoogleMaps

- (void)getDistance {
    if ([[RABSettings sharedInstance] internetAvailable]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

            NSString *startPoint = [NSString stringWithFormat:@"%f,%f", self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
#if (TARGET_IPHONE_SIMULATOR)
            startPoint = [NSString stringWithFormat:@"%f,%f", [RABSettings sharedInstance].testCoordinates.coordinate.latitude, [RABSettings sharedInstance].testCoordinates.coordinate.longitude];;
#endif
            NSDictionary *dataLocation = [self.currentVenue valueForKey:@"location"];
            NSString *endPoint = [NSString stringWithFormat:@"%f,%f", [[dataLocation valueForKey:@"lat"] floatValue], [[dataLocation valueForKey:@"lng"] floatValue]];

            NSString *strUrl = [NSString stringWithFormat:@"%@origin=%@&destination=%@&sensor=true&mode=walking", [RABSettings sharedInstance].googleMapsURL, startPoint, endPoint];
            strUrl = [strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [[RABSettings sharedInstance] LogThis:@"GoogleMaps - %@", strUrl];
            NSData *data =[NSData dataWithContentsOfURL:[NSURL URLWithString:strUrl]];
            [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
        });
    }
}

- (void)fetchedData:(NSData *)responseData {
    NSError *error;
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    NSArray *arrRouts = [json objectForKey:@"routes"];
    if ([arrRouts isKindOfClass:[NSArray class]] && arrRouts.count == 0)
        return;
    
    NSString *totalDuration = [[[json valueForKeyPath:@"routes.legs.duration.text"] objectAtIndex:0] objectAtIndex:0];
    NSString *totalDistance = [[[json valueForKeyPath:@"routes.legs.distance.text"] objectAtIndex:0] objectAtIndex:0];
    NSString *s = [NSString stringWithFormat:@"%@ - %@", totalDistance, totalDuration];
    [self.lblDistance setText:s];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - Foursquare

- (void)doCheckIn {
    if (![RABSettings sharedInstance].inCheckin) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CheckIn", @"CheckIn")
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                  otherButtonTitles:NSLocalizedString(@"OK", @"OK"),
                                                                    NSLocalizedString(@"Facebook", @"Facebook"),
                                                                    NSLocalizedString(@"Twitter", @"Twitter"),
                                                                    NSLocalizedString(@"Both", @"Both"), nil];
        [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[alertView textFieldAtIndex:0] setDelegate:self];
        [alertView show];
    }
    else {
        [self prepareForRequest];
        NSDictionary *parameters = nil;
        switch (self.checkinBroadcast) {
            case 1:
                parameters = @{ @"venueId": [self.currentVenue objectForKey:@"id"], @"shout" : self.checkInMessage, @"broadcast" : @"public" };
                break;
            case 2:
                parameters = @{ @"venueId": [self.currentVenue objectForKey:@"id"], @"shout" : self.checkInMessage, @"broadcast" : @"public,facebook" };
                break;
            case 3:
                parameters = @{ @"venueId": [self.currentVenue objectForKey:@"id"], @"shout" : self.checkInMessage, @"broadcast" : @"public,twitter" };
                break;
            case 4:
                parameters = @{ @"venueId": [self.currentVenue objectForKey:@"id"], @"shout" : self.checkInMessage, @"broadcast" : @"public,facebook,twitter" };
                break;
            default:
                break;
        }
        self.request = [self.foursquare requestWithPath:@"checkins/add" HTTPMethod:@"POST" parameters:parameters delegate:self];
        [_request start];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [RABSettings sharedInstance].inCheckin = NO;
        [self showHud:NSLocalizedString(@"CheckInComplete", @"CheckInComplete")];
        [self performSelector:@selector(hideHud) withObject:nil afterDelay:3.0];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 25) ? NO : YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    self.checkinBroadcast = buttonIndex;
    self.checkInMessage = [[alertView textFieldAtIndex:0] text];
    if (buttonIndex > 0) {
        [RABSettings sharedInstance].inCheckin = YES;
        if (![self.foursquare isSessionValid])
            [self.foursquare startAuthorization];
    }
}

- (void)loadRandomVenue {
    NSArray *arrVenues = [self.jsonVenues objectForKey:@"venues"];
    int r = arc4random() % [arrVenues count];
    self.currentVenue = [arrVenues objectAtIndex:r];
    NSDictionary *dataLocation = [self.currentVenue valueForKey:@"location"];
    self.venueLat = [[dataLocation valueForKey:@"lat"] floatValue];
    self.venueLon = [[dataLocation valueForKey:@"lng"] floatValue];
    [self setupTitle:[self.currentVenue valueForKey:@"name"]];
    [self.locationManager startUpdatingLocation];
	[self.locationManager startUpdatingHeading];
    [self hideHud];
}

- (void)cancelRequest {
    if (_request) {
        _request.delegate = nil;
        [_request cancel];
        self.request = nil;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

- (void)prepareForRequest {
    [self cancelRequest];
}

- (void)foursquareDidAuthorize:(BZFoursquare *)foursquare {
    [[RABSettings sharedInstance] LogThis:@"%s: authorized...", __PRETTY_FUNCTION__];
}

- (void)foursquareDidNotAuthorize:(BZFoursquare *)foursquare error:(NSDictionary *)errorInfo {
    [[RABSettings sharedInstance] LogThis:@"%s: %@", __PRETTY_FUNCTION__, errorInfo];
}

#pragma mark - Location

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [[RABSettings sharedInstance] LogThis:@"Location fail : %@", [error localizedDescription]];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    if (self.currentLocation.coordinate.latitude != newLocation.coordinate.latitude &&
        self.currentLocation.coordinate.longitude != newLocation.coordinate.longitude) {
        [[RABSettings sharedInstance] LogThis:@"New user location..."];
#if (TARGET_IPHONE_SIMULATOR)
        self.currentLocation = [RABSettings sharedInstance].testCoordinates;
#else
        self.currentLocation = newLocation;
#endif
        self.inLocating = NO;
        double dist = [self.currentLocation distanceFromLocation:newLocation];
        self.distance = dist;
        [self calculateUserAngle];
    }

    if (self.currentLocation.coordinate.latitude == self.venueLat &&
        self.currentLocation.coordinate.longitude == self.venueLon)
        [self doCheckIn];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    self.imgCompass.transform = CGAffineTransformMakeRotation((degrees - newHeading.magneticHeading) * M_PI / 180);

    //float oldRad = -manager.heading.trueHeading * M_PI / 180.0f;
	//float newRad = -newHeading.trueHeading * M_PI / 180.0f;
	//CABasicAnimation *theAnimation;
    //theAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    //theAnimation.fromValue = [NSNumber numberWithFloat:oldRad];
    //theAnimation.toValue = [NSNumber numberWithFloat:newRad];
    //theAnimation.duration = 0.5f;
    //[self.imgCompass.layer addAnimation:theAnimation forKey:@"animateMyRotation"];
    //self.imgCompass.transform = CGAffineTransformMakeRotation(newRad);
}

#pragma mark - Shake

- (void)startShaking {
    [self showHud:NSLocalizedString(@"Shake", @"Shake")];
    [self becomeFirstResponder];
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventSubtypeMotionShake) {
        self.shakeCounter++;
        if (self.shakeCounter == 1) {
            [self showHud:NSLocalizedString(@"OneMoreShake", @"OneMoreShake")];
            [self performSelector:@selector(hideHud) withObject:nil afterDelay:1.0];
        }
        if (self.shakeCounter >= 2) {
            [self showHud:NSLocalizedString(@"Locating", @"Locating")];
            [self.lblDistance setText:@""];
            
            UIColor *rc = [[RABSettings sharedInstance] getRandomColor];
            [self.view setBackgroundColor:rc];
            
            UIColor *newColor = [[RABSettings sharedInstance] getOpositeColor:rc];
            [self.txtTitle setTextColor:newColor];

            self.inLocating = YES;
            self.currentLocation = nil;
            self.currentHeading = nil;
            [self loadRandomVenue];
            self.shakeCounter = 0;
        }
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - HUD

- (void)showHud:(NSString *)txt {
    [self hideHud];
    [self.view setBackgroundColor:[[RABSettings sharedInstance] getRandomColor]];
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.hud setMode:MBProgressHUDModeIndeterminate];
    [self.hud setLabelText:txt];
    [self.hud setLabelFont:[UIFont fontWithName:[RABSettings sharedInstance].fontName size:16.0]];
    [self.hud setDimBackground:YES];
}

- (void)hideHud {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

#pragma mark - Location calcs

- (void)calculateUserAngle {
    float locLat = self.venueLat;
    float locLon = self.venueLon;
    
    float pLat = 0;
    float pLon = 0;
    
    if (locLat > self.currentLocation.coordinate.latitude && locLon > self.currentLocation.coordinate.longitude) {
        // north east
        pLat = self.currentLocation.coordinate.latitude;
        pLon = locLon;
        self.degrees = 0;
    }
    else if (locLat > self.currentLocation.coordinate.latitude && locLon < self.currentLocation.coordinate.longitude) {
        // south east
        pLat = locLat;
        pLon = self.currentLocation.coordinate.longitude;
        self.degrees = 45;
    }
    else if (locLat < self.currentLocation.coordinate.latitude && locLon < self.currentLocation.coordinate.longitude) {
        // south west
        pLat = locLat;
        pLon = self.currentLocation.coordinate.latitude;
        self.degrees = 180;
    }
    else if (locLat < self.currentLocation.coordinate.latitude && locLon > self.currentLocation.coordinate.longitude) {
        // north west
        pLat = locLat;
        pLon = self.currentLocation.coordinate.longitude;
        degrees = 225;
    }
    
    // Vector QP (from user to point)
    float vQPlat = pLat - self.currentLocation.coordinate.latitude;
    float vQPlon = pLon - self.currentLocation.coordinate.longitude;
    
    // Vector QL (from user to location)
    float vQLlat = locLat - self.currentLocation.coordinate.latitude;
    float vQLlon = locLon - self.currentLocation.coordinate.longitude;
    
    // degrees between QP and QL
    float cosDegrees = (vQPlat * vQLlat + vQPlon * vQLlon) / sqrt((vQPlat * vQPlat + vQPlon * vQPlon) * (vQLlat * vQLlat + vQLlon * vQLlon));
    self.degrees = self.degrees + acos(cosDegrees);
}

@end
