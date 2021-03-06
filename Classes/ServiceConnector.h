//
//  ServiceConnector.h
//  geolocation-plugin
//
// Sends the Location Data to the Server
//
//  Created by Christopher Ketant on 11/28/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LocationUpdates.h"

#define LOCATION_UPDATE_PATH @"/location_update/"

//handle circular dependency
@class CDVInterface;

/**
 * The Delegate for the POST request
 *
 **/
@protocol ServiceConnectorDelegate <NSObject>

-(void)requestReturnedData:(NSData *)data;

@end



@interface ServiceConnector : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (strong,nonatomic) id <ServiceConnectorDelegate> delegate;

/**
 * Initialize the ServiceConnector with
 * the parameters needed to post to
 * the DCS Server
 * @param - DCSUrl
 * @param - Start Time
 * @param - End Time
 * @param - Tour Configuration ID
 * @param - Rider's ID
 * @param - CDVInterface
 *
 **/
-(id) initWithParams:(NSString *)vDCSUrl
                    :(NSNumber *)vStartTime
                    :(NSNumber *)vEndTime
                    :(NSString *)vTourConfigId
                    :(NSString *)vRiderId
                    :(CDVInterface *)vCDVInterface;

/**
 * Post the Location to the Server
 *
 * CDVInterface calls getAllLocations or getLocations(size) 
 * and the return object is passed to this method
 *
 * The 'location_update' path is expecting and 
 * returning the following
 *
 * REQUEST
 * {
 *   "rider_id": "%uuid%",
 *   "tour_id" : ""
 *   "locations": [
 *       {
 *           "latitude": 43.083958,
 *           "longitude": -77.679734,
 *           "accuracy": 1,
 *           "speed": 0,
 *           "bearing": 37.444657,
 *           "time": 1359488523,
 *           "provider": "GPS"
 *       },
 *       }
 *           .
 *           .
 *           .
 *       }
 * ],
 * "battery": 0.5
 * }
 *
 *
 * RESPONSE
 * {
 * "server_polling_rate" : int,
 * "location_polling_rate" : int
 * }
 * @param- Array of Locations
 **/
-(void)postLocations: (NSArray *)dbLocations;

@end
