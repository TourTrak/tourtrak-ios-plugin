//
//  BGLocationTracking.m
//  BGLocationTracking
//
//  Created by Alex Shmaliy on 8/20/13 modified by Chris Ketant.
//  MIT Licensed
//
// TODO - Find out how to retrieve single location data
//        at a time for algorithm sake
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
@property UIBackgroundTaskIdentifier bgTask;

@end


@implementation BGLocationTracking

@synthesize locationManager, cordInterface;
@synthesize successCB, errorCB;
@synthesize locationManagerCreationDate;
@synthesize isTracking;
@synthesize bgTask;


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
        [locationManager startUpdatingLocation];
        isTracking=YES;
    }
    return self;
}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
   
    // don't assume normal network access if this is being executed in the background.
    // Tell OS that we are doing a background task that needs to run to completion. 
    UIApplication* app = [UIApplication sharedApplication];
    
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
    }];
   
    if ([newLocation distanceFromLocation:oldLocation] >= MINIMUM_DISTANCE_BETWEEN_DIFFERENT_LOCATIONS) {
        NSLog(@"%@", [newLocation description]);
        [self.cordInterface insertCurrLocation:(newLocation)];
    }
    
    // if location manager is very old, need to re-init
    NSDate *currentDate = [NSDate date];
    if ([currentDate timeIntervalSinceDate:self.locationManagerCreationDate] >= LOCATION_MANAGER_LIFETIME_MAX) {
        //TODO: re-initialize here
    }
    
    // Close the task when done!
    if (bgTask != UIBackgroundTaskInvalid)
    {
        [app endBackgroundTask:bgTask];
         bgTask = UIBackgroundTaskInvalid;
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
