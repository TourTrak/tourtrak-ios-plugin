//
//  ServiceConnector.m
//  geolocation-plugin
//
//  Created by Christopher Ketant on 11/28/13.
//
//

#import "ServiceConnector.h"
#import "CDVInterface.h"


@interface ServiceConnector()

@property (nonatomic) NSData* receivedData;
@property (nonatomic) CDVInterface *cordInterface;
@property (nonatomic) NSString *DCSUrl, *tourConfigId, *riderId, *pushId;
@property (nonatomic) NSNumber *startTime, *endTime;



/**
 * Convert the Location into a Dictonary
 * in order to be sent via JSON
 *
 * @param- Location
 * @return- Dictonary
 **/
-(NSDictionary*)getDict:(CLLocation*)loc;

/**
 * Get all the locations in proper format
 *
 * @param- Array of Locations from LocationDBOpenHelper
 * @return- Array of Dictionaries
 **/
-(NSArray *)getLocations:(NSArray*)dbLocs;

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

-(void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end


@implementation ServiceConnector
@synthesize DCSUrl, startTime, endTime, tourConfigId, riderId;

/*
 * URL to the SERVER
 *
 */
static NSString *SERVER_LOCATION_UPDATE_URL = @"/location_update/";

#pragma mark - Init Function

-(id) initWithParams:(NSString *)vDCSUrl
                    :(NSNumber *)vStartTime
                    :(NSNumber *)vEndTime
                    :(NSString *)vTourConfigId
                    :(NSString *)vRiderId{
    
    self = [super init];
    if(self){
        
        self.DCSUrl = vDCSUrl;
        self.startTime = vStartTime;
        self.endTime = vEndTime;
        self.tourConfigId = vTourConfigId;
        self.riderId = vRiderId;
    }
    return self;
}

#pragma mark - Utility Functions

-(NSDictionary*)getDict:(LocationUpdates *)loc{
    
    
    //dictionaryWithObjectsAndKeys takes the values first
    //then the keys
    NSDictionary *locDic = [[NSDictionary alloc] initWithObjectsAndKeys:
                            loc.time, @"time",
                            loc.latitude, @"latitude",
                            loc.longitude, @"longitude",
                            loc.speed, @"speed",
                            loc.accuracy, @"accuracy",
                            loc.bearing, @"bearing", //will get this from the locaiton stored in db
                            loc.provider, @"provider",
                            nil];
    
    return locDic;
    
    
    
    
    
    
}

-(NSArray*)getLocations:(NSArray *)dbLocs{
    
    //Array of the locations to send
    NSMutableArray *locations = [[NSMutableArray alloc]init];
    

    
    int size = [dbLocs count];
    
    if(size > 0){
    
        for (int index=0; index<size; index++) {
        
            //create the dictionary object that will be sent as json
            NSDictionary *dict = [self getDict: [dbLocs objectAtIndex:index] ];
        
            //add the location dictionary
            //to the locations array
            [locations addObject:dict];
        }
    }
    
    return locations;
}

#pragma mark - Post

-(void)postLocations:(NSArray *)dbLocations{
    
    
    //get all the locations in the proper format
    //in dictionaries all within an array
    NSArray *locations = [self getLocations:dbLocations];
    NSNumber *battery = [[NSNumber alloc]initWithFloat:[[UIDevice currentDevice] batteryLevel]];
    NSString *rId = ([riderId length] == 0 ) ? @"TcH4FR09ROSA4b42WJX6i+SFbTpuzcr06gszd9lHA4c=" : riderId;//this is temporary until its integrated with sencha
    
    NSMutableDictionary *json = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                 rId, @"rider_id", //rider's id //hard coded for now
                                 locations, @"locations",//locations array full of locations
                                 battery, @"battery",//current battery level
                                 nil];
    
    NSError *writeError = nil;
    
    //serialize the dictionary into json
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&writeError];
    
    if(!data){
        NSLog(@"Got an Error: %@", writeError);
    }else{
        NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //NSLog(@"The JSON: %@", jsonStr);
        
    }
    
    
    //build up request url
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:
                                    [NSURL URLWithString:@"http://devcycle.se.rit.edu/location_update/"]];//must update
    //add Method
    [request setHTTPMethod:@"POST"];
    
    //set data as the POST body
    [request setHTTPBody:data];
    
    //set the content type to JSON
    [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    
    //set accept
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    
    //add Value to the header
    [request addValue:[NSString stringWithFormat:@"%d",data.length] forHTTPHeaderField:@"Content-Length"];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(!connection){
        NSLog(@"Connection Failed");
    }

    
}

#pragma mark - ServiceConnectorDelegate -

-(void)requestReturnedData:(NSData *)data{
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    //NSLog(@"The Server Returned: %@", json);
}



#pragma mark - Data connection delegate -

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    _receivedData = data;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"Connection failed with error: %@", error.localizedDescription);
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    NSLog(@"Request Complete, received %d bytes of data", _receivedData.length);
    
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:_receivedData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    //NSLog(@"The Server Returned: %@", json);

    
    //send the data to the delegate
    [self.delegate requestReturnedData:_receivedData];
}


@end
