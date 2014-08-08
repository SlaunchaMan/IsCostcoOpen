//
//  JRKCostcoFinderViewController.m
//  IsCostcoOpen
//
//  Created by Jeff Kelley on 2/13/14.
//  Copyright (c) 2014 Jeff Kelley. All rights reserved.
//


#import "JRKCostcoFinderViewController.h"

#import "JRKCostcoStore.h"


// Constants
static NSString * const kGoogleTimeZoneAPIEndpoint = @"https://maps.googleapis.com/maps/api/timezone/json";


@import MapKit;


@interface JRKCostcoFinderViewController () <MKMapViewDelegate>

@property (weak) IBOutlet MKMapView *mapView;

@end


@implementation JRKCostcoFinderViewController

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Search"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(searchForStores)];
}

#pragma mark - View Controller Lifecycle

- (void)determineOpenStatusForStore:(MKMapItem *)store
                             atTime:(NSDate *)searchTime
{
    MKPlacemark *placemark = store.placemark;
    
    NSString *queryString =
    [NSString stringWithFormat:@"location=%f,%f&timestamp=%lu&sensor=true",
     placemark.coordinate.latitude, placemark.coordinate.longitude,
     (unsigned long)[searchTime timeIntervalSince1970]];
    
    NSURL *googleURL =
    [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",
                          kGoogleTimeZoneAPIEndpoint,
                          queryString]];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:googleURL];
    
    void (^responseHandler)(NSURLResponse *, NSData *, NSError *) =
    ^(NSURLResponse *response,
      NSData *data,
      NSError *connectionError) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if ([httpResponse statusCode] == 200) {
                NSDictionary *responseData =
                [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:NULL];
                
                if ([responseData isKindOfClass:[NSDictionary class]]) {
                    JRKCostcoStore *costcoStore =
                    [[JRKCostcoStore alloc] initWithResponse:responseData
                                                   placemark:store.placemark];
                    
                    [self.mapView addAnnotation:costcoStore];
                }
            }
        }
    };
    
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:responseHandler];
}

- (void)searchForStores
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = @"Costco";
    request.region = self.mapView.region;
    
    MKLocalSearch *search = [[MKLocalSearch alloc]
                             initWithRequest:request];
    
    [[UIApplication sharedApplication]
     setNetworkActivityIndicatorVisible:YES];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response,
                                         NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (response) {
            [self processSearchResponse:response];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Search Error"
                                        message:[error localizedDescription]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }];
}

- (void)processSearchResponse:(MKLocalSearchResponse *)response
{
    [self.mapView setRegion:response.boundingRegion animated:YES];
    
    NSDate *searchTime = [NSDate date];
    
    for (MKMapItem *mapItem in response.mapItems) {
        [self determineOpenStatusForStore:mapItem
                                   atTime:searchTime];
    }
}

#pragma mark - MKMapViewDelegate Protocol Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[JRKCostcoStore class]]) {
        JRKCostcoStore *store = annotation;
        
        MKPinAnnotationView *annotationView =
        (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
        
        if (annotationView) {
            annotationView.annotation = annotation;
        }
        else {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                             reuseIdentifier:@"pin"];
        }
        
        annotationView.pinColor = ([store isOpenAtDate:[NSDate date]] ?
                                   MKPinAnnotationColorGreen :
                                   MKPinAnnotationColorRed);
        
        annotationView.canShowCallout = YES;
        
        return annotationView;
    }
    
    return nil;
}

#pragma mark -

@end
