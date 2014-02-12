//
//  LocationDBOpenHelper.h
//  geolocation-plugin
//
//  Created by Christopher Ketant on 11/14/13.
// This file replicates the needed functions found in
// the Android Application's file titled LocationDBOpenHelper.java
// found on the Android Mobile App Tour Trak Project
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LocationUpdates.h"

@interface LocationDBOpenHelper : NSObject {
    @private
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}
    
    @property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
    @property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
    @property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
/**
 * Get all the locations
 * in coredata
 * @return - Locations
 *
 **/
- (NSArray*) getAllLocations;
/**
 * Get locations in total of
 * size parameter
 *
 * @param - size
 * @return - Array of locations of size, size
 **/
- (NSArray*) getLocations: (NSUInteger) size;
/**
 * Clear all the Locations
 * stored in coredata
 *
 **/
- (void) clearLocations;
/**
 * Insert a Location into
 * the Coredata db
 *
 * @param - location
 **/
- (void) insertLocation: (CLLocation *) location;

    
    
    @end
