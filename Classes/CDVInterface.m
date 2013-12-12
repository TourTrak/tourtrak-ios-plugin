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

@property (strong, nonatomic) NSDictionary *json;
@property (nonatomic) int locCount;

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



#pragma mark - start function
-(void) startUpdatingLocation:(CDVInvokedUrlCommand *)command{
    
    
    if(self.dbHelper == nil && self.locTracking == nil && self.connector == nil){
        [self initCDVInterface];
    }
    /*NSError* error;
    
    /* NSData *jsonData = [NSKeyedArchiver
                    archivedDataWithRootObject:command];
    
    //Get the json here
    self.json = [NSJSONSerialization
                 JSONObjectWithData:jsonData
                 options:kNilOptions
                 error:&error];*/
    
    
}


#pragma mark - Initialize
-(void)initCDVInterface{
    
    //set up db here
    self.dbHelper = [[LocationDBOpenHelper alloc]init];
    
    //begins tracking on init
    self.locTracking = [[BGLocationTracking alloc]initWithCDVInterface: self];
    
    //set up service connector
    self.connector = [[ServiceConnector alloc]initWithDCSParams:self.json];
    
}

#pragma mark - Interface functions
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
    if(self.locCount > 10){
        [self.connector postLocations:[self getAllLocations]];
        [self clearLocations];
    }
}

@end
