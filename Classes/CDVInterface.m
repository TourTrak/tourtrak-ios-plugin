//
//  CDVInterface.m
//  geolocation-plugin
//
//  Created by Christopher Ketant on 11/14/13.
//
// Currently does not have an algorithm for sending
// the location stored in the local database.
// TO-DO: Implement Algorithm
//
//

#import "CDVInterface.h"



@interface CDVInterface ()

@property (nonatomic) int locCount;
@property (nonatomic) NSString *DCSUrl, *tourConfigId, *riderId;
@property (nonatomic) NSString *startTime, *endTime;


/**
 * This is a temp function
 * used to determine when to
 * send the locations stored
 * in the db.
 *
 **/
-(void) checkDB;

@end


@implementation CDVInterface
@synthesize dbHelper, locTracking, connector;
@synthesize DCSUrl, startTime, endTime, tourConfigId, riderId;



#pragma mark - Sencha Interface Functions
-(void) start:(CDVInvokedUrlCommand *)command{
    
    //First check if we initilized already
    if(self.dbHelper == nil && self.locTracking == nil && self.connector == nil){
        [self initCDVInterface];
    }
    
    
    
    
    //Second get the args in the command
    CDVPluginResult* pluginResult = nil;
    NSString* javascript = nil;
    
    @try {
        //The args we are expecting
        DCSUrl = [command.arguments objectAtIndex:0];
        startTime = [command.arguments objectAtIndex:1];
        endTime = [command.arguments objectAtIndex:2];
        tourConfigId = [command.arguments objectAtIndex:3];
        riderId = [command.arguments objectAtIndex:4];
        
        if(DCSUrl != nil
           && startTime != nil
           && endTime != nil
           && tourConfigId != nil
           && riderId != nil){
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            javascript = [pluginResult toSuccessCallbackString:command.callbackId];
            
        }else{//If all the arguments are nil then set them to empty string
            DCSUrl = startTime = endTime = tourConfigId = riderId = @"";
        }
    }
    @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION
                                         messageAsString:[exception reason]];
        javascript = [pluginResult toErrorCallbackString:command.callbackId];
        
    }@finally {
        [self writeJavascript:javascript];
    }
    
    
    
}

-(void) resumeTracking:(CDVInvokedUrlCommand *)command{ [self.locTracking resumeTracking]; }

-(void) pauseTracking:(CDVInvokedUrlCommand *)command{ [self.locTracking pauseTracking]; }


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
                                                               :riderId];
    
    //Set Current Device Battery Monitoring in order to get Battery percentage
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
}

#pragma mark - Module Interface functions
-(void) insertCurrLocation:(CLLocation *)location{
    
    //statically send location to server here
    //[self.connector postLocations:location];
    self.locCount++;
    [self.dbHelper insertLocation:(location)];
    [self checkDB];
    
    
}

-(NSArray*) getAllLocations{
    return [self.dbHelper getAllLocations];
}

-(NSArray*) getLocations:(NSUInteger)size{
    return [self.dbHelper getLocations:(size)];
}

-(void) clearLocations{
    [self.dbHelper clearLocations];
}

#pragma mark - Utility Function

-(void) checkDB{
    if(self.locCount > 7){
        [self.connector postLocations:[self getAllLocations]];
        [self clearLocations];
    }
}

@end
