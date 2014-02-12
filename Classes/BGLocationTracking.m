//
//  BGLocationTracking.m
//  BGLocationTracking
//
//  Created by Alex Shmaliy on 8/20/13.
//  MIT Licensed
//

#import "BGLocationTracking.h"
#import "CDVInterface.h"

#define LOCATION_MANAGER_LIFETIME_MAX (60 * 60) // in seconds
#define DISTANCE_FILTER_IN_METERS 10.0
#define MINIMUM_DISTANCE_BETWEEN_DIFFERENT_LOCATIONS 1.0 // in meters

@interface BGLocationTracking ()

@property (strong, nonatomic) CDVInvokedUrlCommand *successCB;
@property (strong, nonatomic) CDVInvokedUrlCommand *errorCB;
@property (strong, nonatomic) NSDate *locationManagerCreationDate;
@property BOOL isTracking;

@end


@implementation BGLocationTracking

@synthesize locationManager, cordInterface;
@synthesize successCB, errorCB;
@synthesize locationManagerCreationDate;
@synthesize isTracking;


- (id) initWithCDVInterface:(CDVInterface*)cordova{
    self = [super init];
    if(self){
        self.cordInterface = cordova;
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManagerCreationDate = [NSDate date];
        [self.locationManager setDelegate:self];
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        locationManager.distanceFilter = DISTANCE_FILTER_IN_METERS;
        locationManager.activityType = CLActivityTypeFitness;
        isTracking=false;
    }
    return self;
}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    if ([newLocation distanceFromLocation:oldLocation] >= MINIMUM_DISTANCE_BETWEEN_DIFFERENT_LOCATIONS) {
        //NSLog(@"%@", [newLocation description]);
        [self.cordInterface insertCurrLocation:(newLocation)];
    }
    
    // if location manager is very old, need to re-init
    NSDate *currentDate = [NSDate date];
    if ([currentDate timeIntervalSinceDate:self.locationManagerCreationDate] >= LOCATION_MANAGER_LIFETIME_MAX) {
        //TODO: re-initialize here
    }
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    //TODO: handle error
}



- (void)resumeTracking{
    if(!isTracking){
        [locationManager startUpdatingLocation];
        isTracking = true;
        NSLog(@"iOS: RESUMED TRACKING");
        
    }
}

- (void)pauseTracking{
    if(isTracking){
        [locationManager stopUpdatingLocation];
        isTracking = false;
        NSLog(@"iOS: PAUSED TRACKING");
    }
}


@end
