//
//  PostAlgo.h
//  geolocation-plugin
//
//  Created by Christopher Ketant on 11/29/13.
//
// Question For Customer: How often should we send the Rider's Location to server
//              i.e. - every 10meters? 20meters? 1min? 2min?
//     Depends if the race is long, short, straight path, complex because if its
//     long then you don't want it as much as if the path was short. Go back to
//      the root of the reason why we are collecting location data for what
//      purposes do we need that data
//
//
// Does it make sense to consider
// the number of current riders as a factor to determine when to send that data to server?
//
// Calculate when to send to server based on
// how much of the race the user has left and how much battery usage per hour
// i.e. - If the user has a long way to go and it looks like user will use all battery
// before he/she finishes then send less frequently data to server
// i.e. - Else send more often
//
//
// Calculating battery usage per hour is in current android algorithm
// Calculating how much of race has left includes the following variables:
//          1. Race End Point - User Current location
//          2. User speed per hour
//          3. Battery Usage per hour
//
//
// What should trigger the algorithm check
// i.e. call the algorithm after x amount of time? After x amount of entries
// in coredata? x amount traveled?
//

#import <Foundation/Foundation.h>

@interface PushAlgorithm : NSObject

@end
