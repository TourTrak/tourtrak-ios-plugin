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

#define DISTANCE_FILTER_IN_METERS 3.0 //meters

@interface BGLocationTracking ()

@property (strong, nonatomic) CDVInvokedUrlCommand *successCB;
@property (strong, nonatomic) CDVInvokedUrlCommand *errorCB;
@property (strong, nonatomic) NSDate *locationManagerCreationDate;
@property (nonatomic)  BOOL isTracking;
@property UIBackgroundTaskIdentifier bgTask;
@property NSDate *prevServDateTime, *prevLocPollDateTime;


@end


@implementation BGLocationTracking

@synthesize locationManager, cordInterface;
@synthesize successCB, errorCB;
@synthesize locationManagerCreationDate;
@synthesize isTracking, bgTask;
@synthesize prevServDateTime, prevLocPollDateTime;


- (id) initWithCDVInterface:(CDVInterface*)cordova{
    self = [super init];
    
    if(self){
        
        //set-up Cordova Interface
        self.cordInterface = cordova;
        prevServDateTime = prevLocPollDateTime = [cordInterface getCurrRaceStart];
        
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
    
    NSLog(@"Polled New Location: %@",[newLocation description]);
    
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
        NSLog(@"Beta & Actual Race has not started and not Ended");
    }
    
    //Race has started and not ended
    if([cordInterface isRaceStarted:currDateTime] &&
       ![cordInterface isRaceEnded:currDateTime]){
        
        NSLog(@"%@ has Started", [cordInterface getTypeofRace]);
        
        //Check for null of initial Start/Date
        if(prevServDateTime != NULL){
            
            //Is diff in prev time and curr loc time greater than Geo-Sampling Rate
            double diff1 = [currDateTime timeIntervalSinceDate:prevLocPollDateTime];
            
            NSLog(@"Difference in time between Current Time and the Previous Location Time: %f", diff1);
            NSLog(@"Location Poll Rate: %f", cordInterface.locPollRate);
            
            //If the difference is greater than loc poll rate
            if(diff1 >= cordInterface.locPollRate){
                
                NSLog(@"Location is in Poll Rate Range so store it");
                
                //Add to DB
                [cordInterface insertCurrLocation:currLocation];
                
                //Update the Previous Location Poll Rate Date/Time
                prevLocPollDateTime = currDateTime;
            }
            
            //Is diff in prev time and curr loc time greater than server poll rate
            double diff2 = [currDateTime timeIntervalSinceDate:prevServDateTime];
            
            NSLog(@"Difference in time between Current Time and the Previous Location Time: %f", diff1);
            NSLog(@"Final Server Poll Rate: %f", cordInterface.finalServerPollRate);
            
            //if the diff greater than server poll rate
            if (diff2 >= cordInterface.finalServerPollRate) {
                
                NSLog(@"Pushing to Server");
                
                //push to server
                [cordInterface pushLocationUpdates];
                
                //update Previous time
                prevServDateTime = currDateTime;
            }
            
        }
        
        
    }
    
    //Race has started and ended
    if([cordInterface isRaceStarted:currDateTime] &&
       [cordInterface isRaceEnded:currDateTime]){
        
        NSLog(@"Races have ended, STOP TRACKING NOW");
        
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
