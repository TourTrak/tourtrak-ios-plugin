//
//  LocationUpdates.h
//  CoreDataPlugin
//
//  Created by Christopher Ketant on 11/4/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LocationUpdates : NSManagedObject

@property (nonatomic, retain) NSNumber * time; // unix time epoch in MS
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * accuracy;
@property (nonatomic, retain) NSNumber * speed;
@property (nonatomic, retain) NSNumber * bearing;
@property (nonatomic, retain) NSNumber * battery;
@property (nonatomic, retain) NSString * provider;

@end
