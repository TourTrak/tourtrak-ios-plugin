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

@property (nonatomic, retain) NSString * time;
@property (nonatomic, retain) NSString * latitude;
@property (nonatomic, retain) NSString * longitude;
@property (nonatomic, retain) NSString * accuracy;
@property (nonatomic, retain) NSString * speed;
@property (nonatomic, retain) NSString * bearing;
@property (nonatomic, retain) NSString * provider;
@property (nonatomic, retain) NSString * battery;

@end
