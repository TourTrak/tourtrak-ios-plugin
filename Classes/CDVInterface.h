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

//handle circular dependency
@class ServiceConnector;

@interface CDVInterface : CDVPlugin

@property (retain, nonatomic) LocationDBOpenHelper *dbHelper;
@property (retain, nonatomic) BGLocationTracking *locTracking;
@property (retain, nonatomic) ServiceConnector *connector;
@property long pollingRate;

#pragma-
#pragma mark - Initialize Functions

/**
 * Initialize the plugin and start tracking
 * The CDVInokedUrlCommand will contain a
 * json and command will have a size of
 * one. The json will have the following:
 *      dcsUrl
 *      startTime
 *      endTime
 *      tourConfigId
 *      riderId
 *
 *
 * @param - Json
 **/
- (void)start:(CDVInvokedUrlCommand *)command;


#pragma-
#pragma mark - Sencha interface functions

/**
 * Resume Tracking assuming,
 * tracking has been paused
 *
 **/
- (void)resumeTracking:(CDVInvokedUrlCommand *)command;

/**
 * Pause Tracking assuming,
 * tracking has started or resumed
 *
 **/
- (void)pauseTracking:(CDVInvokedUrlCommand *)command;


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
#pragma -
#pragma mark - Update State 
/**
 * Updating the Polling rate
 * check in the server LocationUpdateResponse
 * for a changed polling rate, if changed
 * then update timer
 *
 * @param- Boolean, did the rate change
 *
 **/
- (BOOL)updatePollingRate: (int)rate;



@end
