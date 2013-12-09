geolocation-noapp
=================

This is the repo from which the Sencha app (dev-cycle-mobile-app) <https://github.com/tofferrosen/devcycle-mobile-app/tree/master/cordova/plugins/com.tourtrak.geoplugin> pulls from. Every time a change is made to the iOS plugin. This is a temporary repository until the application is complete. Once the plugin is complete the repository will become unnecessary, since it will be in a final state used for the TourTrak application.The plugin uses CoreLocation and CoreData to record location data in a local app database, then sends the location data to DCS. This repo gets updated from the main iOS-development repo <https://github.com/rculp/geolocation-plugin.git>. 

BUG REPORT & WORK AROUND:
When this repo is pulled from the Sencha app (dev-cycle-mobile-app) whenever changes are made to the iOS plugin and when it is built an error occurs in the DevCycleMobile-Info.plist that causes the app to crash. This error is due to Cordova and issue is listed here (https://issues.apache.org/jira/browse/CB-5262) and is fixed in the newest version of Cordova build. 
The workaround to this bug is that after you build the Sencha app before you run the app on the simulator:

`1. Open up the DevCycleMobile-Info.plist`

`2. Look for the "NSMainNibFile" key`

`3. Remove the space from the "String" value`

`4. Repeat for any other keys with spaces in their String values`
