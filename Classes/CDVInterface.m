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

#define DEFAULT_SERVER_POLL_RATE 15//600
#define DEFAULT_LOC_POLL_RATE 8 //45
#define DEFAULT_SERVER_POLL_RANGE 8

@property (nonatomic) int locCount;
@property (nonatomic) NSString *DCSUrl, *tourConfigId, *riderId;
@property (nonatomic) NSNumber *startTime, *endTime;
@property (nonatomic, retain) NSTimer *startTimer, *endTimer, *serverPollRateTimer, *locPollRateTimer;
@property double finalServerPollRate;

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
 * Schedule the polling
 * with the default time of
 * 600s
 *
 **/
- (void)scheduleServerPolling;

/**
 * Schedule the location
 * polling with default time
 * of 45s
 **/
- (void)scheduleLocPolling;

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

/**
 * Set default values for
 * the rates for the
 * server and location
 * polling rate
 **/
-(void)setDefaultRates;

/**
 * Choose a random number in range of
 * serverPollRange -/+
 * @return - random int in range
 **/
-(int)randomizeRange;

/**
 * Set the Final ServerPollRate
 * which is, serverPollRange + serverPollRate
 *
 **/
-(void)setFinalServerPollRate;

@end


@implementation CDVInterface
@synthesize dbHelper, locTracking, connector, serverPollRate, locPollRate;
@synthesize DCSUrl, startTime, endTime, tourConfigId, riderId;
@synthesize startTimer, endTimer, serverPollRateTimer, locPollRateTimer;

/**
 * Represents the polling rate currently
 * implemented by the plugin sent to by
 * server. Rate is in Milliseconds
 **/


#pragma mark - Initialize
-(void)initCDVInterface{


}

-(void)setDefaultRates{
    self.serverPollRate = DEFAULT_SERVER_POLL_RATE;
    self.locPollRate = DEFAULT_LOC_POLL_RATE;
    self.serverPollRange = DEFAULT_SERVER_POLL_RANGE;
    [self setFinalServerPollRate];

}


#pragma mark - Sencha Interface Functions
-(void) start:(CDVInvokedUrlCommand *)command{

    //First check if we are already initialized
    if(self.dbHelper == nil && self.locTracking == nil && self.connector == nil){
        [self initCDVInterface];
    }


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



            //Set default values
            [self setDefaultRates];

            //Schedule the Automatic Start/End Timers
            [self scheduleStartEndTime];


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

-(void) resumeTracking:(CDVInvokedUrlCommand *)command{
    [self.locTracking resumeTracking];

    //Restart the Location Pollling
    //Timer
    [self scheduleLocPolling];

    //Restart the Server Polling
    //Timer
    [self scheduleServerPolling];

}


-(void) pauseTracking:(CDVInvokedUrlCommand *)command{
    [self.locTracking pauseTracking];

    //Kill The Location
    //Polling Timer
    [self killLocTimer];

    //kill the Server
    //Polling Timer b/c
    //we don't want to
    //push to server w/
    //no data
    [self killServerTimer];

}


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

-(void)scheduleServerPolling{

    //Set Timer
    serverPollRateTimer = [NSTimer scheduledTimerWithTimeInterval:self.finalServerPollRate
                                                     target:self
                                                   selector:@selector(postLocationUpdateRequestTask)
                                                   userInfo:self
                                                    repeats:YES];
    //Need to add poll Rate Timer to main loop
    //in order for it to execute
    [[NSRunLoop currentRunLoop] addTimer:serverPollRateTimer forMode:NSRunLoopCommonModes];
}

-(void)scheduleLocPolling{

    NSLog(@"Scheduling Location Polling with Rate of %f", self.locPollRate);

    //Set Timer
    locPollRateTimer = [NSTimer scheduledTimerWithTimeInterval:self.locPollRate
                                                        target:self.locTracking
                                                      selector:@selector(resumeTracking)
                                                      userInfo:self
                                                       repeats:YES];

    //Need to add poll Rate Timer to main loop
    //in order for it to execute
    [[NSRunLoop currentRunLoop] addTimer:locPollRateTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - Timer Tasks

-(void)runStartTimeTask{
    //get the current location immediately
    //on start up
    [self.locTracking resumeTracking];

    //Schedule the Location Polling Timer
    [self scheduleLocPolling];

    //Schedule the Server Polling Timer
    [self scheduleServerPolling];

}

-(void)runEndTimeTask{
    /*stops tracking*/
    [self.locTracking pauseTracking];

    //If the timer was already
    //initialized, need to
    //cancel the last one
    if(serverPollRateTimer != NULL){
        [serverPollRateTimer invalidate];
        serverPollRateTimer = nil;
    }
}

-(void)postLocationUpdateRequestTask{
    //get all the Locations we collected
    [self.connector postLocations: [self getAllLocations]];
    //clear out the internal storage
    [self clearLocations];
}


#pragma mark - Update Rates

-(BOOL)updateServerPollRate:(int)nServerPollRate{

    //check if the polling rate sent by server different
    //from the current poll rate
    if(self.serverPollRate != nServerPollRate){

        //if poll rate different, update the polling rate
        self.serverPollRate = nServerPollRate;

        [self killServerTimer];


        //Set Timer
        [self scheduleServerPolling];
    }

    //Did not update poll rate
    return FALSE;


}

-(BOOL)updateLocationPollRate:(int)nLocPollRate{

    //check if the polling rate sent by server different
    //from current location polling rate
    if(self.locPollRate != nLocPollRate){

        //if loc poll rate different, update the rate
        self.locPollRate = nLocPollRate;

        [self killLocTimer];

        NSLog(@"Updating Location Polling Rate");

        //If we are in a paused state
        //then we do not want to
        //init the location polling timer
        //but if we are in a resume state
        //then update the timer
        if([self.locTracking isTracking]){
            //Set Timer
            [self scheduleLocPolling];
        }
        return TRUE;
    }

    //Did not update rate
    return FALSE;


}

-(BOOL)updateServerPollRange:(int)nServerPollRange{
    //check if the polling range sent by server different
    //from current location polling range
    if(self.serverPollRange != nServerPollRange){

        //if server poll range different, update the range
        self.serverPollRange = nServerPollRange;
        [self setFinalServerPollRate];
    }

    //Did not update range
    return FALSE;

}

#pragma mark - Sub Module Interface functions

-(void) insertCurrLocation:(CLLocation *)location{ [self.dbHelper insertLocation:(location)]; }

-(NSArray*) getAllLocations{ return [self.dbHelper getAllLocations]; }

-(NSArray*) getLocations:(NSUInteger)size{ return [self.dbHelper getLocations:(size)]; }

-(void) clearLocations{ [self.dbHelper clearLocations]; }



#pragma mark - Utility Functions

-(int)randomizeRange{
    int max = (int)self.serverPollRange;
    int min = (int)(self.serverPollRange *= -1);

    return arc4random() % ((max - min) + 1) + (min);
}

-(void)setFinalServerPollRate{
    self.finalServerPollRate = self.serverPollRate + [self randomizeRange];
    NSLog(@"Final Server Poll Rate: %f", self.finalServerPollRate);
}

-(void)killLocTimer{
    //If the timer was already
    //initialized, need to
    //cancel the last one
    if(locPollRateTimer != NULL){
        [locPollRateTimer invalidate];
        locPollRateTimer = nil;
    }
}

-(void)killServerTimer{
    //If the timer was already
    //initialized, need to
    //cancel the last one
    if(serverPollRateTimer != NULL){
        [serverPollRateTimer invalidate];
        serverPollRateTimer = nil;
    }
}





@end
