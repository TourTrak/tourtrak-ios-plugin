//
//  CDVInterface.h
//  geolocation-plugin
//
// The main class used to interface
// with the plugin from the Javascript
//
//  Created by Christopher Ketant on 11/14/13.
//
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "LocationDBOpenHelper.h"
#import "BGLocationTracking.h"
#import "ServiceConnector.h"

@interface CDVInterface : CDVPlugin

@property (retain, nonatomic) LocationDBOpenHelper *dbHelper;
@property (retain, nonatomic) BGLocationTracking *locTracking;
@property (retain, nonatomic) ServiceConnector *connector;


#pragma-
#pragma mark - Sencha interface functions

/**
 * Start Getting the current
 * Location, called from JavaScript
 *
 *@param - Cordova Function to Call
 **/
- (void)startUpdatingLocation:(CDVInvokedUrlCommand *)command;



#pragma-
#pragma mark - CoreData interface functions


/**
 * Insert Location into the
 * CoreData database
 *
 *@param - current location
 **/
- (void)insertCurrLocation: (CLLocation *)location;
/**
 *
 * Get all the locations
 * stored in core data
 *
 *@return - Array of locations
 * stored in coredata
 **/
-(NSArray*)getAllLocations;
/**
 * Get locations
 * in the amount of
 * size specified
 *
 * @param - size
 *
 **/
- (NSArray*)getLocations: (NSUInteger)size;
/**
 * Clear all the locations
 * that are in the coredata
 * emtpy them
 *
 * @param - size
 * @return - Array of locationsw
 *
 **/
- (void) clearLocations;


@end
