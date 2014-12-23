//
//  Home.m
//  Rab
//
//  Created by Sergey Petrov on 2/27/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import "Home.h"
#import "MBProgressHUD.h"
#import "ShowMe.h"
#import "Categories.h"

@interface Home ()
@property (nonatomic, strong) MBProgressHUD *hud;
@property int shakeCounter;
@property (nonatomic, readwrite, strong) BZFoursquare *foursquare;
@property (nonatomic, strong) BZFoursquareRequest *request;
@property (nonatomic, copy) NSDictionary *meta;
@property (nonatomic, strong) NSMutableArray *fsCategories;
@property (nonatomic, copy) NSArray *notifications;
@property (nonatomic, copy) NSDictionary *response;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLHeading *currentHeading;

typedef enum FlowCurrentOperation {
    FlowCurrentOperationUnknown = 0,
    FlowCurrentOperationAuthorization,
    FlowCurrentOperationCategories,
    FlowCurrentOperationShaking,
    FlowCurrentOperationFetching,
    FlowCurrentOperationHeading
} FlowCurrentOperation;
@property FlowCurrentOperation currentOperation;
@end

@implementation Home

@synthesize foursquare, locationManager, txtInstructions, hud, shakeCounter, currentLocation, currentHeading;
@synthesize currentOperation, fsCategories, bannerView;

#pragma mark - System

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.foursquare = [[BZFoursquare alloc] initWithClientID:[RABSettings sharedInstance].fsClientID callbackURL:[RABSettings sharedInstance].fsCallbackURL];
        //[self.foursquare setVersion:@"20120609"];
        //[self.foursquare setVersion:@"20140227"];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyyMMdd"];
        [self.foursquare setVersion:[df stringFromDate:[NSDate date]]];
        [self.foursquare setLocale:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]];
        [self.foursquare setSessionDelegate:self];
        [self.foursquare setClientSecret:[RABSettings sharedInstance].fsClientSecret];
    }
    return self;
}

- (void)dealloc {
    self.foursquare.sessionDelegate = nil;
    [self cancelRequest];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.shakeCounter = 0;
    [self setupUI];
    [self.bannerView setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
    [self stopLocationUpdates];
    [self stopHeadingUpdates];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

#if (TARGET_IPHONE_SIMULATOR)
    self.currentLocation = [RABSettings sharedInstance].testCoordinates;
#endif

    self.currentOperation = FlowCurrentOperationUnknown;
    if ([RABSettings sharedInstance].fsSelectedCategoryID == nil || [[RABSettings sharedInstance].fsSelectedCategoryID isEqualToString:@""])
        [self startCategories];
    else
        [self startShaking];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [self.locationManager setDistanceFilter:kCLDistanceFilterNone];
        [self.locationManager setDelegate:self];
    }
    [self.locationManager startUpdatingLocation];
    [self.locationManager startUpdatingHeading];
}

#pragma mark - UI

- (void)setupUI {
    float x = 40;
    float w = self.view.frame.size.width - (x * 2);
    [self.txtInstructions setFrame:CGRectMake(x, 0, w, self.view.frame.size.height)];
    [self.txtInstructions setText:NSLocalizedString(@"Instructions", @"Instructions")];
    
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) &&
        [[UIScreen mainScreen] scale] > 1.0 &&
        [UIScreen mainScreen].bounds.size.height != 568.f)
        [self.txtInstructions setFont:[UIFont fontWithName:[RABSettings sharedInstance].fontName size:60.0]];
    else
        [self.txtInstructions setFont:[UIFont fontWithName:[RABSettings sharedInstance].fontName size:70.0]];
    [self.txtInstructions sizeToFit];
    
    CGRect f = self.txtInstructions.frame;
    f.size.width += 10;
    f.size.height += 10;
    [self.txtInstructions setFrame:f];
    
    [self.txtInstructions setCenter:self.view.center];
    
    UIColor *rc = [[RABSettings sharedInstance] getRandomColor];
    UIColor *newColor = [[RABSettings sharedInstance] getOpositeColor:rc];
    [self.view setBackgroundColor:rc];
    [self.txtInstructions setTextColor:newColor];
    
    UIColor *rsc = [[RABSettings sharedInstance] getRandomColor];
    [self.txtInstructions.layer setShadowColor:[rsc CGColor]];
    [self.txtInstructions.layer setShadowOffset:CGSizeZero];
    [self.txtInstructions.layer setShadowOpacity:1.0f];
    [self.txtInstructions.layer setShadowRadius:5.0f];
}

#pragma mark - Heading

- (void)showHeading {
    [self hideHud];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [[RABSettings sharedInstance] LogThis:@"Heading..."];
    //[self.txtInstructions setText:[NSString stringWithFormat:@"%@", _response]];
    [self performSegueWithIdentifier:@"openShowMe" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"openShowMe"]) {
        ShowMe *ce = (ShowMe *)segue.destinationViewController;
        [ce setJsonVenues:_response];
    }
    else if ([segue.identifier isEqualToString:@"openCategories"]) {
        Categories *ce = (Categories *)segue.destinationViewController;
        [ce setFsCategories:self.fsCategories];
        [ce setIsTop:YES];
    }
}

#pragma mark - 4Square & delegates

- (void)startCategories {
    self.currentOperation = FlowCurrentOperationCategories;
    [self showHud:NSLocalizedString(@"Fetching", @"Fetching")];
    [self prepareForRequest];
    
    self.request = [self.foursquare userlessRequestWithPath:@"venues/categories" HTTPMethod:@"GET" parameters:nil delegate:self];
    [_request start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)showCategories {
    if (self.fsCategories != nil)
        [self.fsCategories removeAllObjects];
    else
        self.fsCategories = [[NSMutableArray alloc] init];

    NSArray *categories = [_response valueForKey:@"categories"];
    for (NSDictionary *cat in categories) {
        NSMutableArray *arrCategory = [NSMutableArray array];
        [arrCategory addObject:[cat valueForKey:@"id"]];
        [arrCategory addObject:[cat valueForKey:@"name"]];
        [arrCategory addObject:[NSString stringWithFormat:@"%@bg_64%@", [[cat valueForKey:@"icon"] valueForKey:@"prefix"], [[cat valueForKey:@"icon"] valueForKey:@"suffix"]]];

        NSMutableArray *subCats = [NSMutableArray array];
        NSArray *subs = [cat valueForKey:@"categories"];
        if (subs != nil && [subs count] > 0) {
            for (NSDictionary *subcat in subs) {
                NSMutableArray *arrSubCategory = [NSMutableArray array];
                [arrSubCategory addObject:[subcat valueForKey:@"id"]];
                [arrSubCategory addObject:[subcat valueForKey:@"name"]];
                [arrSubCategory addObject:[NSString stringWithFormat:@"%@bg_64%@", [[subcat valueForKey:@"icon"] valueForKey:@"prefix"], [[subcat valueForKey:@"icon"] valueForKey:@"suffix"]]];
                [subCats addObject:arrSubCategory];
            }
        }
        [arrCategory addObject:subCats];

        [self.fsCategories addObject:arrCategory];
    }
    [self performSegueWithIdentifier:@"openCategories" sender:self];
}

- (void)fsAuthorize {
    self.currentOperation = FlowCurrentOperationAuthorization;
    [self showHud:NSLocalizedString(@"AllowApp", @"AllowApp")];
    [self.foursquare startAuthorization];
}

- (void)searchVenues {
    self.currentOperation = FlowCurrentOperationFetching;
    [self showHud:NSLocalizedString(@"Fetching", @"Fetching")];
    [self prepareForRequest];
    
    NSString *latitude = [[NSNumber numberWithDouble:self.currentLocation.coordinate.latitude] stringValue];
    NSString *longitude = [[NSNumber numberWithDouble:self.currentLocation.coordinate.longitude] stringValue];
    [[RABSettings sharedInstance] LogThis:@"Searching @ Coordinates - Lat: %@, Long: %@", latitude, longitude];
    
    NSString *coords = [NSString stringWithFormat:@"%@,%@", latitude, longitude];
    NSDictionary *parameters = @{ @"ll" : coords, @"categoryId" : [RABSettings sharedInstance].fsSelectedCategoryID }; // 4d4b7105d754a06374d81259 - night life
    self.request = [self.foursquare userlessRequestWithPath:@"venues/search" HTTPMethod:@"GET" parameters:parameters delegate:self];
    [_request start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
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
    self.meta = nil;
    self.notifications = nil;
    self.response = nil;
}

#pragma mark - BZFoursquareRequestDelegate

- (void)requestDidFinishLoading:(BZFoursquareRequest *)request {
    self.meta = request.meta;
    self.notifications = request.notifications;
    self.response = request.response;
    self.request = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    switch (self.currentOperation) {
        case FlowCurrentOperationAuthorization:
            [self startCategories];
            break;
        case FlowCurrentOperationCategories:
            [self showCategories];
            break;
        case FlowCurrentOperationShaking:
            [self searchVenues];
            break;
        case FlowCurrentOperationFetching:
            [self showHeading];
            break;
        default:
            break;
    }
}

- (void)request:(BZFoursquareRequest *)request didFailWithError:(NSError *)error {
    [[RABSettings sharedInstance] LogThis:@"%s: %@", __PRETTY_FUNCTION__, error];
    [self hideHud];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[error userInfo][@"errorDetail"]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                              otherButtonTitles:nil];
    [alertView show];
    self.meta = request.meta;
    self.notifications = request.notifications;
    self.response = request.response;
    self.request = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self startShaking];
}

#pragma mark - BZFoursquareSessionDelegate

- (void)foursquareDidAuthorize:(BZFoursquare *)foursquare {
    [self startShaking];
}

- (void)foursquareDidNotAuthorize:(BZFoursquare *)foursquare error:(NSDictionary *)errorInfo {
    [[RABSettings sharedInstance] LogThis:@"%s: %@", __PRETTY_FUNCTION__, errorInfo];
}

#pragma mark - Location

- (void)stopLocationUpdates {
    [self.locationManager stopUpdatingLocation];
}

- (void)stopHeadingUpdates {
    [self.locationManager stopUpdatingHeading];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    if (locationManager.location != nil) {
        [[RABSettings sharedInstance] LogThis:@"%s: Core location has a position.", __PRETTY_FUNCTION__];
        self.currentLocation = locationManager.location;
        [self stopLocationUpdates];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    if (newHeading != nil) {
        [[RABSettings sharedInstance] LogThis:@"%s: Core location has a heading.", __PRETTY_FUNCTION__];
        self.currentHeading = newHeading;
        [self stopHeadingUpdates];
    }
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [[RABSettings sharedInstance] LogThis:@"%s: Core location can't get a fix.", __PRETTY_FUNCTION__];
}

#pragma mark - Shake

- (void)startShaking {
    self.currentOperation = FlowCurrentOperationShaking;
    //[self showHud:NSLocalizedString(@"Shake", @"Shake")];
    [self.view setBackgroundColor:[[RABSettings sharedInstance] getRandomColor]];
    [self becomeFirstResponder];
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventSubtypeMotionShake) {
        self.shakeCounter++;
        self.hud.labelText = [NSString stringWithFormat:@"Shakes : %i", self.shakeCounter];
        [self.view setBackgroundColor:[[RABSettings sharedInstance] getRandomColor]];
        if (self.shakeCounter > 0 && self.currentLocation != nil) {
            [self searchVenues];
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

#pragma mark - Banner

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    [self.bannerView setHidden:NO];
    [[RABSettings sharedInstance] LogThis:@"bannerViewDidLoadAd %@", [banner description]];
    [self layoutForCurrentOrientation];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    [self.bannerView setHidden:YES];
    [[RABSettings sharedInstance] LogThis:@"didFailToReceiveAdWithError %@", error];
    [self layoutForCurrentOrientation];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
}

- (void)layoutForCurrentOrientation {
}

@end
