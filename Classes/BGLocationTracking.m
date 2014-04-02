//
//  BGLocationTracking.m
//  BGLocationTracking
//
//  Created by Alex Shmaliy on 8/20/13.
//  Modified b Christopher Ketant
//  MIT Licensed
//

#import "BGLocationTracking.h"
#import "CDVInterface.h"

#define LOCATION_MANAGER_LIFETIME_MAX (1 * ( 60 * 60 ) ) // in seconds
#define DISTANCE_FILTER_IN_METERS 10.0
#define MINIMUM_DISTANCE_BETWEEN_DIFFERENT_LOCATIONS 3.0 // in meters

@interface BGLocationTracking ()

@property (strong, nonatomic) CDVInvokedUrlCommand *successCB;
@property (strong, nonatomic) CDVInvokedUrlCommand *errorCB;
@property (strong, nonatomic) NSDate *locationManagerCreationDate;
@property (nonatomic)  BOOL isTracking;
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
        isTracking=false;
    }
    return self;
}


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
        //Each time this method is called, it polls for a new location
        //Based on a timer. This saves battery by turning off after
        //each poll and only polls when the wait interval is finished
    
        // don't assume normal network access if this is being executed in the background.
        // Tell OS that we are doing a background task that needs to run to completion. 
        UIApplication* app = [UIApplication sharedApplication];
        
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            [app endBackgroundTask:bgTask];
        }];
    
        NSLog(@"Time: %f | Polled New Location: %@", [[NSDate date] timeIntervalSince1970], [newLocation description]);
        [self.cordInterface insertCurrLocation:(newLocation)];
        
        //Stop Updating Location Manager here
        //Resumes after time is elapsed, see CDVInterface.m
        //in scheduleLocPolling method. The scheduleLocPolling
        //resumes it after interval
        [self pauseTracking];
        
        // Close the task when done!
        if (bgTask != UIBackgroundTaskInvalid)
        {
            [app endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"iOS Location Manager Failed: %@", error);

}

- (BOOL)isTracking{
    return isTracking;
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
