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

#define DEFAULT_SERVER_POLL_RATE 600
#define DEFAULT_LOC_POLL_RATE 45
#define DEFAULT_SERVER_POLL_RANGE 8

@property (nonatomic) NSString *DCSUrl, *tourConfigId, *riderId;
@property (nonatomic) NSNumber *startTime, *endTime, *startBetaTime, *endBetaTime;
@property BOOL isBetaRace, isActualRace;
@property (nonatomic) AppDelegate *appDelegate;



/**
 * Set default values for
 * the rates for the
 * server and location
 * polling rate
 **/
-(void)initValues;

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

-(BOOL)compareDates:(NSDate *)date1
                   :(NSDate *)date2;


@end


@implementation CDVInterface

@synthesize dbHelper, locTracking, connector;
@synthesize appDelegate;
@synthesize DCSUrl, startBetaTime, startTime, endBetaTime, endTime, tourConfigId, riderId;
@synthesize serverPollRate, locPollRate, finalServerPollRate;
@synthesize startDateTime, endDateTime, betaStartDateTime, betaEndDateTime;
@synthesize isRaceEnd, isRaceStart, isBetaRaceStart, isBetaRaceEnd;
@synthesize isActualRace, isBetaRace;

/**
 * Represents the polling rate currently
 * implemented by the plugin sent to by
 * server. Rate is in Milliseconds
 **/

-(void)initValues{
    //Set up Rates
    self.serverPollRate = DEFAULT_SERVER_POLL_RATE;
    self.locPollRate = DEFAULT_LOC_POLL_RATE;
    self.serverPollRange = DEFAULT_SERVER_POLL_RANGE;
    [self setFinalServerPollRate];
    
    //initialize Start/End states
    isRaceStart = isRaceEnd = isBetaRaceStart = isBetaRaceEnd = isBetaRace = isActualRace = false;
    
    //set-up Start/End states
    
    
    //set-up start/end times
    //Make sure to see if locale time is factored in or not
    double startUnix = [startTime doubleValue];
    double endUnix = [endTime doubleValue];
    double betaStartUnix = [startBetaTime doubleValue];
    double betaEndUnix = [endBetaTime doubleValue];
    
    startDateTime = [NSDate dateWithTimeIntervalSince1970:startUnix];
    endDateTime = [NSDate dateWithTimeIntervalSince1970:endUnix];
    betaStartDateTime = [NSDate dateWithTimeIntervalSince1970:betaStartUnix];
    betaEndDateTime = [NSDate dateWithTimeIntervalSince1970:betaEndUnix];
}


#pragma mark - Sencha Interface Functions
-(void) start:(CDVInvokedUrlCommand *)command{

    
    //Second get the args in the command
    CDVPluginResult* pluginResult = nil;
    NSString* javascript = nil;
    
    @try {
        //The args we are expecting
        DCSUrl = [[command.arguments objectAtIndex:0]  objectForKey:@"dcsUrl"];
        startBetaTime = [[command.arguments objectAtIndex:0]  objectForKey:@"startBetaTime"];
        startTime = [[command.arguments objectAtIndex:0]  objectForKey:@"startTime"];
        endBetaTime = [[command.arguments objectAtIndex:0]  objectForKey:@"endBetaTime"];
        endTime = [[command.arguments objectAtIndex:0]  objectForKey:@"endTime"];
        tourConfigId = [[command.arguments objectAtIndex:0]  objectForKey:@"tourId"];
        riderId = [[command.arguments objectAtIndex:0]  objectForKey:@"riderId"];
        
        //All must be present in order to
        //be successful or can't POST
        if(DCSUrl != nil
           && startTime != nil
           && endTime != nil
           && tourConfigId != nil
           && riderId != nil){
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            javascript = [pluginResult toSuccessCallbackString:command.callbackId];
            
            //Set-up values
            [self initValues];
            
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
            
            
            //Add to Appdelegate
            self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [self.appDelegate addCDVInterface:self];
            
            //Start Tracking immediately
            [self.locTracking resumeTracking];
            

            
            
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
}


-(void) pauseTracking:(CDVInvokedUrlCommand *)command{
    [self.locTracking pauseTracking];
}


-(void)pushLocationUpdates{
    //get all the Locations we collected
    [self.connector postLocations: [self getAllLocations]];
    //clear out the internal storage
    [self clearLocations];
}


#pragma mark - Update Rates

-(BOOL)updateServerPollRate:(int)nServerPollRate{
    
    //check if the polling rate sent by server different
    //from the current poll rate
    if(self.serverPollRate != nServerPollRate && (nServerPollRate != 0)){
        
        //if poll rate different, update the polling rate
        self.serverPollRate = nServerPollRate;
    }
    
    //Did not update poll rate
    return FALSE;
    
    
}

-(BOOL)updateLocationPollRate:(int)nLocPollRate{
    
    //check if the polling rate sent by server different
    //from current location polling rate
    if(self.locPollRate != nLocPollRate && (nLocPollRate != 0)){
        
        //if loc poll rate different, update the rate
        self.locPollRate = nLocPollRate;

        return TRUE;
    }
    
    //Did not update rate
    return FALSE;
    
    
}

-(BOOL)updateServerPollRange:(int)nServerPollRange{
    //check if the polling range sent by server different
    //from current location polling range
    if(self.serverPollRange != nServerPollRange && (nServerPollRange != 0)){
        
        //if server poll range different, update the range
        self.serverPollRange = nServerPollRange;
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

-(NSDate *)getCurrRaceStart{
    //pass in current date/time
    [self updateRaceState:[NSDate date]];
    
    if(isBetaRace) return betaStartDateTime;
    
    if(isActualRace) return startDateTime;
    
    return nil;
}

-(BOOL)isRaceStarted:(NSDate *)locStartDate{
    [self updateRaceState:locStartDate];
    
    if(isBetaRace) return isBetaRaceStart;
    if(isActualRace) return isRaceStart;
    return NO;
    
    
}

-(BOOL)isRaceEnded:(NSDate *)locEndDate{
    [self updateRaceState:locEndDate];
    
    if(isBetaRace) return isBetaRaceEnd;
    if(isActualRace) return isRaceEnd;
    return NO;
    
    
}

//function assumes Beta Race Comes before Actual Race in Date/Time
-(void)updateRaceState :(NSDate *)currDateTime{
    //For Beta Race
    if([self compareDates :currDateTime :betaStartDateTime]){
        isBetaRaceStart = YES;
    }
    
    //For actual Race
    if([self compareDates :currDateTime :startDateTime]){
        isRaceStart = YES;
    }
    
    //For Beta Race
    if([self compareDates :currDateTime :betaEndDateTime ]){
        isBetaRaceEnd = YES;
    }
    
    //For actual Race
    if([self compareDates :currDateTime :endDateTime ]){
        isRaceEnd = YES;
    }
    
    //The Application has 6 States
    //1- Beta Race has not started and Actual Race has not started
    //2- Beta Race has started but not finished
    //3- Beta Race has started and Finished
    //4- Actual Race has not started and not ended but we are not in BetaRace
    //5- Actual Race Started but not finished
    //6- Actual Race has started and finished
    
    //if No Races Started yet, then we are in Beta
    if(!isBetaRaceStart && !isBetaRaceEnd && !isActualRace) isBetaRace=YES;
    
    //if Beta Race Started but not finished
    if(isBetaRaceStart && !isBetaRaceEnd) isBetaRace=YES;
    
    //if Beta Race has started and Ended
    if(isBetaRaceStart && isBetaRaceEnd) isBetaRace=NO;
    
    if(!isRaceStart && !isRaceEnd && !isBetaRace) isActualRace=YES;
    
    //if Actual Race started but not finished
    if(isRaceStart && !isRaceEnd) isActualRace=YES;
    
    //if Actual Race started and finished
    if(isRaceStart && isRaceEnd) isActualRace=NO;
    
    
    
}

-(BOOL)compareDates:(NSDate *)date1
                   :(NSDate *)date2{
    switch ([date1 compare:date2]) {
        case NSOrderedAscending:
            // date1 is earlier in time than date2
            return NO;
            break;
            
        case NSOrderedSame:
            // The dates are the same
            return YES;
            break;
        case NSOrderedDescending:
            // date1 is older in time than date2
            return YES;
            break;
    }
}




@end
