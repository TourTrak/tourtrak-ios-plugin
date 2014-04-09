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
/*
 * Server Polling Rate
 */
@property double serverPollRate;
/*
 * Location Polling Rate
 */
@property double locPollRate;
/*
 * Server Polling Range
 */
@property double serverPollRange;

/*
 * Server poll rate + range
 */
@property double finalServerPollRate;

/*
 * States of the Race and Beta Race
 */
@property (nonatomic) BOOL isRaceStart, isRaceEnd, isBetaRaceStart, isBetaRaceEnd;

/*
 * DateTime Race starts/started, ends/ended
 */
@property (nonatomic) NSDate *startDateTime, *endDateTime, *betaStartDateTime, *betaEndDateTime;



#pragma-
#pragma mark - Initialize Functions

/**
 * Initialize the plugin and start tracking
 * The CDVInokedUrlCommand will contain a
 * json and command will have a size of
 * one. The json will have the following:
 *      dcsUrl,
 *      startBetaTime
 *      startTime
 *      endBetaTime
 *      endTime
 *      tourId
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

-(NSDate *)getCurrRaceStart;

- (BOOL)isRaceStarted:(NSDate *)locStartDate;

- (BOOL)isRaceEnded:(NSDate *)locEndDate;

/**
 * The task to be run
 * when we hit the polling rate
 * time. Send the Location data we
 * we have currently stored.
 **/
-(void)pushLocationUpdates;


#pragma -
#pragma mark - Update State 
/**
 * Updating the Polling rate for sending to
 * server check in the server 
 * LocationUpdateResponse
 * for a changed polling rate, if changed
 * then update timer
 *
 * @param- Boolean, did the rate change
 *
 **/
- (BOOL)updateServerPollRate: (int)nServerPollRate;

/**
 * Updating the Location Polling rate
 * from the Location Manager
 * check in the server LocationUpdateResponse
 * for a changed polling rate, if changed
 * then update timer
 *
 * @param- Boolean, did the rate change
 *
 **/
- (BOOL)updateLocationPollRate: (int)nLocPollRate;

/**
 * Updatint the polling range for sending to
 * server. The range will be added to the
 * server polling rate. The exact number
 * chosen within the range will be at random
 * so that every device does not push to 
 * server at same time
 *
 * @param - Boolean, did the range change. 
 *
 **/
- (BOOL)updateServerPollRange: (int)nServerPollRange;



@end
