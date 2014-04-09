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
@property NSDate *prevDateTime;


@end


@implementation BGLocationTracking

@synthesize locationManager, cordInterface;
@synthesize successCB, errorCB;
@synthesize locationManagerCreationDate;
@synthesize isTracking, bgTask;
@synthesize prevDateTime;


- (id) initWithCDVInterface:(CDVInterface*)cordova{
    self = [super init];
    
    if(self){
        
        //set-up Cordova Interface
        self.cordInterface = cordova;
        prevDateTime = [cordInterface getCurrRaceStart];
        
        //set-up location manager
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManagerCreationDate = [NSDate date];
        [self.locationManager setDelegate:self];
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        locationManager.distanceFilter = DISTANCE_FILTER_IN_METERS;
        locationManager.activityType = CLActivityTypeFitness;
        
        //initial state of Tracking
        isTracking=false;
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
    
    NSLog(@"Time: %f | Polled New Location: %@", [[NSDate date] timeIntervalSince1970], [newLocation description]);
    
    [self stateMachine:newLocation];
    
     //Close the task when done!
    if (bgTask != UIBackgroundTaskInvalid)
    {
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }

}



//State Machine
- (void)stateMachine:(CLLocation *)currLocation{
    NSDate *currDateTime = currLocation.timestamp;
    
    //Race has not started and not ended
    if(![cordInterface isRaceStarted:currDateTime] &&
       ![cordInterface isRaceEnded:currDateTime]){
        //do nothing
    }
    
    //Race has started and not ended
    if([cordInterface isRaceStarted:currDateTime] &&
       ![cordInterface isRaceEnded:currDateTime]){
        
        //Check for null of initial Start/Date
        if(prevDateTime != NULL){
            
            //Is diff in prev time and curr loc time greater than Geo-Sampling Rate
            double diff1 = [currDateTime timeIntervalSinceDate:prevDateTime];
            
            //If the difference is greater than loc poll rate
            if(diff1 >= cordInterface.locPollRate){
                
                //Add to DB
                [cordInterface insertCurrLocation:currLocation];
            }
        
            NSLog(@"Geo Sample Rate: %f sec", cordInterface.locPollRate);
            NSLog(@"Curr Time: %@", currDateTime);
            NSLog(@"Initial Time: %@", prevDateTime);
            NSLog(@"Difference in Times: %f", diff1);
            
            //Is diff in prev time and curr loc time greater than server poll rate
            double diff2 = [currDateTime timeIntervalSinceDate:prevDateTime];
            
            //if the diff greater than server poll rate
            if (diff2 >= cordInterface.finalServerPollRate) {
                
                //push to server
                [cordInterface pushLocationUpdates];
            }
            
        }
        //update Previous time
        prevDateTime = currDateTime;
        
        
    }
    
    //Race has started and ended
    if([cordInterface isRaceStarted:currDateTime] &&
       [cordInterface isRaceEnded:currDateTime]){
        
        //Stop Tracking Since Race Over
        [self pauseTracking];
    };
    
    
    
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
