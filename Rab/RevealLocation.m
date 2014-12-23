//
//  RevealLocation.m
//  Rab
//
//  Created by Sergey Petrov on 2/28/14.
//  Copyright (c) 2014 supudo.net. All rights reserved.
//

#import "RevealLocation.h"
#import "MBProgressHUD.h"

typedef enum LocTravelModes {
	LocTravelModeDriving, // G_TRAVEL_MODE_DRIVING
	LocTravelModeWalking  // G_TRAVEL_MODE_WALKING
} LocTravelModes;

static NSString *annotaionIdentifier = @"locAnnotationIdentifier";

@interface RevealLocation ()
@property (nonatomic, strong) MBProgressHUD *hud;
@property LocTravelModes currentTravelMode;
@property (nonatomic, retain) NSArray *wayPoints;
@property (nonatomic, retain) NSString *startPoint, *endPoint;
@property (nonatomic, strong) NSDictionary *googleMapsResponse;
@end

@implementation RevealLocation

@synthesize currentLocation, currentVenue, mapView, scTravelMode, currentTravelMode;
@synthesize wayPoints, startPoint, endPoint, googleMapsResponse, hud;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupUI];
    [self setupMap];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

#pragma mark - UI

- (void)setupUI {
    UIFont *font = [UIFont fontWithName:[RABSettings sharedInstance].fontName size:18.0];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    [self.scTravelMode setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.scTravelMode setTintColor:[UIColor whiteColor]];
}

- (void)setupMap {
    NSDictionary *dataLocation = [self.currentVenue valueForKey:@"location"];
    float venueLat = [[dataLocation valueForKey:@"lat"] floatValue];
    float venueLon = [[dataLocation valueForKey:@"lng"] floatValue];
    
    CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(venueLat, venueLon);
    self.startPoint = [NSString stringWithFormat:@"%f,%f", self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude];
    self.endPoint = [NSString stringWithFormat:@"%f,%f", loc.latitude, loc.longitude];
    [[RABSettings sharedInstance] LogThis:@"Current user location - %@ - to location - %@", self.startPoint, self.endPoint];
    
    self.currentTravelMode = LocTravelModeWalking;
    [self drawRoute];
}

- (void)drawRoute {
    if ([[RABSettings sharedInstance] internetAvailable]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            NSString *strUrl;
            
            if (self.wayPoints.count > 0) {
                strUrl = [NSString stringWithFormat:@"%@origin=%@&destination=%@&sensor=true&waypoints=optimize:true", [RABSettings sharedInstance].googleMapsURL, self.startPoint, self.endPoint];
                for (NSString *strViaPoint in self.wayPoints)
                    strUrl = [strUrl stringByAppendingFormat:@"|via:%@", strViaPoint];
            }
            else
                strUrl = [NSString stringWithFormat:@"%@origin=%@&destination=%@&sensor=true", [RABSettings sharedInstance].googleMapsURL, self.startPoint, self.endPoint];
            
            if (self.currentTravelMode == LocTravelModeWalking)
                strUrl = [strUrl stringByAppendingFormat:@"&mode=walking"];
            
            strUrl = [strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [[RABSettings sharedInstance] LogThis:@"GoogleMaps - %@", strUrl];
            NSData *data =[NSData dataWithContentsOfURL:[NSURL URLWithString:strUrl]];
            [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
        });
    }
    else
        [self hideHud];
}

- (IBAction)iboScTravelMode:(id)sender {
    [self showHud:NSLocalizedString(@"Calculating", @"Calculating")];
    switch (self.currentTravelMode) {
        case LocTravelModeWalking:
            self.currentTravelMode = LocTravelModeDriving;
            break;
        case LocTravelModeDriving:
            self.currentTravelMode = LocTravelModeWalking;
            break;
        default:
            break;
    }
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self drawRoute];
}

#pragma mark - GoogleMaps JSON

- (void)fetchedData:(NSData *)responseData {
    NSError *error;
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    NSArray *arrRouts = [json objectForKey:@"routes"];
    if ([arrRouts isKindOfClass:[NSArray class]] && arrRouts.count == 0)
        return;

    NSArray *arrDistance = [[[json valueForKeyPath:@"routes.legs.steps.distance.text"] objectAtIndex:0] objectAtIndex:0];
    NSString *totalDuration = [[[json valueForKeyPath:@"routes.legs.duration.text"] objectAtIndex:0] objectAtIndex:0];
    NSString *totalDistance = [[[json valueForKeyPath:@"routes.legs.distance.text"] objectAtIndex:0] objectAtIndex:0];
    NSArray *arrDescription = [[[json valueForKeyPath:@"routes.legs.steps.html_instructions"] objectAtIndex:0] objectAtIndex:0];
    self.googleMapsResponse = [NSDictionary dictionaryWithObjectsAndKeys:totalDistance, @"totalDistance", totalDuration, @"totalDuration", arrDistance, @"distance", arrDescription, @"description", nil];
    
    NSArray *arrpolyline = [[[json valueForKeyPath:@"routes.legs.steps.polyline.points"] objectAtIndex:0] objectAtIndex:0];
    double srcLat = [[[[json valueForKeyPath:@"routes.legs.start_location.lat"] objectAtIndex:0] objectAtIndex:0] doubleValue];
    double srcLong = [[[[json valueForKeyPath:@"routes.legs.start_location.lng"] objectAtIndex:0] objectAtIndex:0] doubleValue];
    double destLat = [[[[json valueForKeyPath:@"routes.legs.end_location.lat"] objectAtIndex:0] objectAtIndex:0] doubleValue];
    double destLong = [[[[json valueForKeyPath:@"routes.legs.end_location.lng"] objectAtIndex:0] objectAtIndex:0] doubleValue];
    CLLocationCoordinate2D sourceCordinate = CLLocationCoordinate2DMake(srcLat, srcLong);
    CLLocationCoordinate2D destCordinate = CLLocationCoordinate2DMake(destLat, destLong);
    
    [self addAnnotationSrcAndDestination:sourceCordinate withDestination:destCordinate];

    NSMutableArray *polyLinesArray =[[NSMutableArray alloc]initWithCapacity:0];
    
    for (int i=0; i<[arrpolyline count]; i++) {
        NSString *encodedPoints = [arrpolyline objectAtIndex:i];
        MKPolyline *route = [self polylineWithEncodedString:encodedPoints];
        [polyLinesArray addObject:route];
    }
    
    [self.mapView addOverlays:polyLinesArray level:MKOverlayLevelAboveRoads];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - Routes

- (void)addAnnotationSrcAndDestination:(CLLocationCoordinate2D)srcCord withDestination:(CLLocationCoordinate2D)destCord {
    MKPointAnnotation *sourceAnnotation = [[MKPointAnnotation alloc] init];
    MKPointAnnotation *destAnnotation = [[MKPointAnnotation alloc] init];

    [sourceAnnotation setCoordinate:srcCord];
    [destAnnotation setCoordinate:destCord];

    [sourceAnnotation setTitle:self.startPoint];
    [destAnnotation setTitle:self.endPoint];
    
    [self.mapView addAnnotation:sourceAnnotation];
    [self.mapView addAnnotation:destAnnotation];
    
    MKCoordinateRegion region;
    
    MKCoordinateSpan span;
    span.latitudeDelta = 2;
    span.latitudeDelta = 2;
    region.center = srcCord;
    region.span = span;

    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    for (NSString *strVia in self.wayPoints) {
        [geocoder geocodeAddressString:strVia completionHandler:^(NSArray *placemarks, NSError *error) {
            if ([placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks objectAtIndex:0];
                CLLocation *location = placemark.location;
                MKPointAnnotation *viaAnnotation = [[MKPointAnnotation alloc] init];
                viaAnnotation.coordinate = location.coordinate;
                [self.mapView addAnnotation:viaAnnotation];
            }
        }];
    }
    region.span = MKCoordinateSpanMake(0.01, 0.01);
    [self.mapView setRegion:region animated: YES];
    [self hideHud];
}

- (MKPolyline *)polylineWithEncodedString:(NSString *)encodedString {
    const char *bytes = [encodedString UTF8String];
    NSUInteger length = [encodedString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSUInteger idx = 0;
    
    NSUInteger count = length / 4;
    CLLocationCoordinate2D *coords = calloc(count, sizeof(CLLocationCoordinate2D));
    NSUInteger coordIdx = 0;
    
    float latitude = 0;
    float longitude = 0;
    while (idx < length) {
        char byte = 0;
        int res = 0;
        char shift = 0;
        
        do {
            byte = bytes[idx++] - 63;
            res |= (byte & 0x1F) << shift;
            shift += 5;
        } while (byte >= 0x20);
        
        float deltaLat = ((res & 1) ? ~(res >> 1) : (res >> 1));
        latitude += deltaLat;
        
        shift = 0;
        res = 0;
        
        do {
            byte = bytes[idx++] - 0x3F;
            res |= (byte & 0x1F) << shift;
            shift += 5;
        } while (byte >= 0x20);
        
        float deltaLon = ((res & 1) ? ~(res >> 1) : (res >> 1));
        longitude += deltaLon;
        
        float finalLat = latitude * 1E-5;
        float finalLon = longitude * 1E-5;
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(finalLat, finalLon);
        coords[coordIdx++] = coord;
        
        if (coordIdx == count) {
            NSUInteger newCount = count + 10;
            coords = realloc(coords, newCount * sizeof(CLLocationCoordinate2D));
            count = newCount;
        }
    }
    
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords count:coordIdx];
    free(coords);
    
    return polyline;
}

#pragma mark - Map delegates

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKPolylineRenderer *lineView = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    [lineView setLineWidth:2];
    [lineView setStrokeColor:[UIColor redColor]];
    [lineView setFillColor:[[UIColor redColor] colorWithAlphaComponent:0.1f]];
    return lineView;
}

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation {
    if (annotation == self.mapView.userLocation)
        return nil;
    MKPinAnnotationView *aView = (MKPinAnnotationView *)[mv dequeueReusableAnnotationViewWithIdentifier:annotaionIdentifier];
    if (aView == nil) {
        aView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:annotaionIdentifier];
        [aView setPinColor:MKPinAnnotationColorRed];
        [aView setRightCalloutAccessoryView:[UIButton buttonWithType:UIButtonTypeDetailDisclosure]];
        [aView setAnimatesDrop:TRUE];
        [aView setCanShowCallout:YES];
        [aView setCalloutOffset:CGPointMake(-5, 5)];
    }
	return aView;
}

#pragma mark - Shake

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventSubtypeMotionShake)
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - HUD

- (void)showHud:(NSString *)txt {
    [self hideHud];
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [self.hud setMode:MBProgressHUDModeIndeterminate];
    [self.hud setLabelText:txt];
    [self.hud setLabelFont:[UIFont fontWithName:[RABSettings sharedInstance].fontName size:16.0]];
    [self.hud setDimBackground:YES];
}

- (void)hideHud {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

@end
