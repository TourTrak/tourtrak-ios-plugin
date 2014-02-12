//
//  LocationDBOpenHelper.m
//  geolocation-plugin
//
//  Created by Christopher Ketant on 11/14/13.
//
//

#import "LocationDBOpenHelper.h"
#import "LocationUpdates.h"

#define RadiansToDegrees(radians)(radians * 180.0/M_PI)
#define DegreesToRadians(degrees)(degrees * M_PI/180.0)

@interface LocationDBOpenHelper ()

@property (nonatomic) float bearing;
@property (nonatomic, strong) CLLocation *olderLoc, *newerLoc;
@property (nonatomic) int toggleLoc;

/**
 * Gets the Application Directory
 * for the Current App
 *
 * @return - path
 **/
- (NSString *)applicationDocDir;

/**
 * Get the Bearing for the
 * current location
 *
 * @return - bearing
 **/
- (float)getBearing;

/**
 * Store the Old and new Locations
 * in order to calculate the Bearings
 *
 *@param- current location
 **/
- (void)storeLocs: (CLLocation *)loc;

@end

@implementation LocationDBOpenHelper

#pragma mark -
#pragma mark Helper Functions

- (float) getBearing{
    if(_olderLoc != nil && _newerLoc != nil){
        float lat1 = DegreesToRadians(_olderLoc.coordinate.latitude);
        float lon1 = DegreesToRadians(_olderLoc.coordinate.longitude);
    
        float lat2 = DegreesToRadians(_newerLoc.coordinate.latitude);
        float lon2 = DegreesToRadians(_newerLoc.coordinate.longitude);
    
        float dLon = lon2 - lon1;
    
        float y = sin(dLon) * cos(lat2);
        float x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        float radiansBearing = atan2(y, x);
        if(radiansBearing < 0.0)
        {
            radiansBearing += 2*M_PI;
        }
    
        return radiansBearing;
    }else return 0;
}


- (void) storeLocs:(CLLocation *)loc{
    
    if(_olderLoc == nil || _toggleLoc == 1){
        _olderLoc = loc;
        _toggleLoc = 0;
    }else if (_newerLoc == nil || _toggleLoc == 0){
        _newerLoc = loc;
        _toggleLoc = 1;
    }

}

#pragma mark -
#pragma mark DB Interface Functions
    
- (void) clearLocations{
    //Prepare our fetch request
    NSFetchRequest *allLocations = [[NSFetchRequest alloc] initWithEntityName:@"LocationUpdates"];
    
    NSError *error = nil;
    
    NSArray *results = [self.managedObjectContext executeFetchRequest:allLocations error:&error];
    
    //loop through and delete all the rows
    for(NSManagedObject *row in results){
        [self.managedObjectContext deleteObject:row];
    }
    
    [self.managedObjectContext save:&error];
    
}
    
    
    

- (NSArray*)getAllLocations{
    
    //Setup our Fetch Request
    NSFetchRequest *allLocations = [[NSFetchRequest alloc]initWithEntityName:@"LocationUpdates"];
    
    //set up error variable
    NSError *error = nil;
    
    //results
    NSArray *results = [self.managedObjectContext executeFetchRequest:allLocations error:&error];
    
    //return array of all the rows returned
    return results;
    
}
    

- (NSArray*)getLocations:(NSUInteger) size {
    
    //Set up our fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"LocationUpdates"];
    //Set up our Descriptor for sorting it
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
    //sort it
    [request setSortDescriptors:@[sort]];
    //get the size of the fetch we want
    [request setFetchLimit:size];
    NSError *error = nil;
    
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    return results;
}
    

-(void)insertLocation:(CLLocation *) location{
    
    //Grab context
    NSManagedObjectContext *context = [self managedObjectContext];
    
    //Grab LocationUpdates Entity
    LocationUpdates *loc = [NSEntityDescription insertNewObjectForEntityForName:@"LocationUpdates" inManagedObjectContext:context];
    
    //Grab device battery level and set it.
    loc.battery = [[NSNumber alloc]initWithFloat:[[UIDevice currentDevice] batteryLevel]];
    
    //set time - unix time since epoch in ms
    NSNumber *epochInMs = [[NSNumber alloc]initWithLongLong:(location.timestamp.timeIntervalSince1970 * 1000)];
    loc.time = epochInMs;
    
    //set latitude
    loc.latitude = [[NSNumber alloc]initWithDouble:location.coordinate.latitude];
    
    //set latitude
    loc.longitude = [[NSNumber alloc]initWithDouble:location.coordinate.longitude];
    
    //set speed
    loc.speed = [[NSNumber alloc]initWithDouble:location.speed];
    
    //set accuracy
    loc.accuracy = [[NSNumber alloc]initWithDouble:location.horizontalAccuracy];
    
    //set bearing
    loc.bearing = [[NSNumber alloc]initWithFloat:[self getBearing]];
    
    // set provider
    // altitude is undefned if it doesn't have GPS lock
    if (location.altitude < 0){
        loc.provider = @"NETWORK";
    } else {
        loc.provider = @"GPS";
    }
    
    NSError *error;
    if(![context save:&error]){
        NSLog(@"Failed to save - error: %@", [error localizedDescription]);
    }
    

}
    
#pragma mark -
#pragma mark Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    if(managedObjectContext_ != nil){
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if(coordinator != nil){
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext_;
}
    

- (NSManagedObjectModel *)managedObjectModel{
    if(managedObjectModel_ != nil){
        return managedObjectModel_;
    }
    managedObjectModel_ = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel_;
}
    

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator{
    
    if(persistentStoreCoordinator_ != nil){
        return persistentStoreCoordinator_;
    }
    
    NSURL *storageURL = [NSURL fileURLWithPath:[[self applicationDocDir]
                                                stringByAppendingPathComponent: @"LocationUpdates.sqlite"]];
    NSError *errorCoor = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc]
                                   initWithManagedObjectModel:[self managedObjectModel]];
    //specifies to store in sqlite versus the .sqlite-wal files
    NSDictionary *options = @{ NSSQLitePragmasOption : @{@"journal_mode" : @"DELETE"}};
    if(![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storageURL options:options error:&errorCoor]){
        
        NSLog(@"Unresolved error %@, %@", errorCoor, [errorCoor userInfo]);
        abort();
    }
    
    
    return persistentStoreCoordinator_;
}
    

- (NSString *)applicationDocDir{
    return [NSSearchPathForDirectoriesInDomains
            (NSDocumentDirectory, NSUserDomainMask, YES)
            lastObject];
}
    
    
    
    @end
