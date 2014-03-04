//
//  CDVInterface.m
//  geolocation-plugin
//
//  Created by Christopher Ketant on 11/14/13.
//
//

#import "CDVInterface.h"
#import "ServiceConnector.h"



@interface CDVInterface ()

@property (nonatomic) int locCount;
@property (nonatomic) NSString *DCSUrl, *tourConfigId, *riderId;
@property (nonatomic) NSNumber *startTime, *endTime;
@property (nonatomic, retain) NSTimer *startTimer, *endTimer, *pollRateTimer;

/**
 * Initialize
 * the sub-components
 * to the system. Called
 * by the start function
 **/
- (void)initCDVInterface;

/**
 * Set-up the Automatic start
 * and end time for the current
 * race.
 *
 **/
- (void)scheduleStartEndTime;


/**
 * Schedule the polling rate
 * with the default time of
 * '600,000ms' or 10min
 *
 **/
- (void)schedulePollingRate;

/**
 * The task to be run
 * when we hit the automatic
 * start time for the race
 *
 **/
- (void)runStartTimeTask;

/**
 * The task to be run
 * when we hit the automatic
 * end time for the race
 **/
- (void)runEndTimeTask;


/**
 * The task to be run
 * when we hit the polling rate
 * time. Send the Location data we
 * we have currently stored.
 **/
-(void)postLocationUpdateRequestTask;

@end


@implementation CDVInterface
@synthesize dbHelper, locTracking, connector, pollingRate;
@synthesize DCSUrl, startTime, endTime, tourConfigId, riderId;
@synthesize startTimer, endTimer, pollRateTimer;

/**
 * Represents the polling rate currently
 * implemented by the plugin sent to by
 * server. Rate is in Milliseconds
 **/


#pragma mark - Initialize
-(void)initCDVInterface{
    
    //set up db here
    self.dbHelper = [[LocationDBOpenHelper alloc]init];
    
    //begins tracking on init
    self.locTracking = [[BGLocationTracking alloc]initWithCDVInterface: self];
    
    //set up service connector
    self.connector = [[ServiceConnector alloc]initWithParams   :DCSUrl
                                                               :startTime
                                                               :endTime
                                                               :tourConfigId
                                                               :riderId
                                                               :self];
    
    //Set Current Device Battery Monitoring in order to get Battery percentage
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    

    
    
}


#pragma mark - Sencha Interface Functions
-(void) start:(CDVInvokedUrlCommand *)command{
    
    //First check if we are already initialized
    if(self.dbHelper == nil && self.locTracking == nil && self.connector == nil){
        [self initCDVInterface];
    }
    
    self.pollingRate = 600;//default polling rate 600seconds = 10min

    //Second get the args in the command
    CDVPluginResult* pluginResult = nil;
    NSString* javascript = nil;
    
    @try {
        //The args we are expecting
        DCSUrl = [[command.arguments objectAtIndex:0]  objectForKey:@"dcsUrl"];
        startTime = [[command.arguments objectAtIndex:0]  objectForKey:@"startTime"];
        endTime = [[command.arguments objectAtIndex:0]  objectForKey:@"endTime"];
        tourConfigId = [[command.arguments objectAtIndex:0]  objectForKey:@"tourId"];
        riderId = [[command.arguments objectAtIndex:0]  objectForKey:@"riderId"];

        if(DCSUrl != nil
           && startTime != nil
           && endTime != nil
           && tourConfigId != nil
           && riderId != nil){
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            javascript = [pluginResult toSuccessCallbackString:command.callbackId];
            
            
            //Schedule the Automatic Start/End Timers
            [self scheduleStartEndTime];
            
            //Schedule the Polling Timer
            [self schedulePollingRate];
            
        }else{//If all the arguments are nil then set them to empty string
            DCSUrl = tourConfigId = riderId = @"";
            startTime = endTime = 0;
        }
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION
                                         messageAsString:[exception reason]];
        javascript = [pluginResult toErrorCallbackString:command.callbackId];
        
    }@finally {//Callback to Javascript
        [self writeJavascript:javascript];
    }
    
    
}

-(void) resumeTracking:(CDVInvokedUrlCommand *)command{ [self.locTracking resumeTracking]; }

-(void) pauseTracking:(CDVInvokedUrlCommand *)command{ [self.locTracking pauseTracking]; }


#pragma mark - Timer Schedulings
-(void)scheduleStartEndTime{
    
    
    //Set up the formatter we will be using
    NSDateFormatter *f = [[NSDateFormatter alloc]init];
    [f setLocale:[NSLocale currentLocale]];
    [f setDateFormat:@"dd.MM.yyyy"];
    
    //Convert the start time to NSDate
    NSTimeInterval startInterval = [startTime doubleValue];
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970: startInterval];//proper conversion from unixtimestamp
    
    //Convert the end time to NSDate
    NSTimeInterval endInterval = [endTime doubleValue];
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970: endInterval]; //proper conversion from unixtimestamp
    
    //Set the Fire Date for the Start Timer
    startTimer = [[NSTimer alloc]initWithFireDate:startDate
                                         interval:0.0
                                           target:self
                                         selector:@selector(runStartTimeTask)
                                         userInfo:self
                                          repeats:NO];
    
    //Set the Fire Date for the End Timer
    endTimer = [[NSTimer alloc]initWithFireDate:endDate
                                       interval:0.0
                                         target:self
                                       selector:@selector(runEndTimeTask)
                                       userInfo:self
                                        repeats:NO];
    
    //Need to add Timers to main Loop
    //in order for it execute
    [[NSRunLoop currentRunLoop] addTimer:startTimer forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] addTimer:endTimer forMode:NSRunLoopCommonModes];
    
}

-(void)schedulePollingRate{
    
    //Set Interval
    NSTimeInterval rateInterval = (self.pollingRate);//seconds

    //Set Timer
    pollRateTimer = [NSTimer scheduledTimerWithTimeInterval:rateInterval
                                                     target:self
                                                   selector:@selector(postLocationUpdateRequestTask)
                                                   userInfo:self
                                                    repeats:YES];
    //Need to add poll Rate Timer to main loop
    //in order for it to execute
    [[NSRunLoop currentRunLoop] addTimer:pollRateTimer forMode:NSRunLoopCommonModes];
}



-(BOOL)updatePollingRate:(int)serverPollRate{

    
    //check if the polling rate sent by server different
    //from the current poll rate
    if(self.pollingRate != serverPollRate){
        
        //if poll rate different, update the polling rate
        self.pollingRate = serverPollRate;
        
        //Set Interval
        NSTimeInterval rateInterval = (self.pollingRate);//seconds
        
        //If the timer was already
        //initialized, need to
        //cancel the last one
        if(pollRateTimer != NULL){
            [pollRateTimer invalidate];
            pollRateTimer = nil;
        }
        
        //Set Timer
        pollRateTimer = [NSTimer scheduledTimerWithTimeInterval:rateInterval
                                                         target:self
                                                       selector:@selector(postLocationUpdateRequestTask)
                                                       userInfo:self
                                                        repeats:YES];
        //Need to add poll Rate Timer to main loop
        //in order for it to execute
        [[NSRunLoop currentRunLoop] addTimer:pollRateTimer forMode:NSRunLoopCommonModes];
        return TRUE;
    }
    
    //Did not update poll rate
    return FALSE;
    
    
}

-(void)runStartTimeTask{[self.locTracking resumeTracking];/*starts tracking*/}

-(void)runEndTimeTask{[self.locTracking pauseTracking];/*stops tracking*/}

-(void)postLocationUpdateRequestTask{
    //get all the Locations we collected
    [self.connector postLocations: [self getAllLocations]];
    //clear out the internal storage
    [self clearLocations];
}



#pragma mark - Sub Module Interface functions

-(void) insertCurrLocation:(CLLocation *)location{ [self.dbHelper insertLocation:(location)]; }

-(NSArray*) getAllLocations{ return [self.dbHelper getAllLocations]; }

-(NSArray*) getLocations:(NSUInteger)size{ return [self.dbHelper getLocations:(size)]; }

-(void) clearLocations{ [self.dbHelper clearLocations]; }

@end
