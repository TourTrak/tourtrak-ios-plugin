//
//  CDVInterface.js
//
//
//  Created by Stas Gorodnichenko on 20/08/13.
//  Modified by Christopher Ketant & Christoffer Rosen
//  MIT Licensed
//

var successCallBackFunction,
    errorCallBackFunction,
    successCallBackName = 'yourCallBack',
    errorCallBackName = 'yourErrorCallBack',
    CDVInterface = {
        
        /**
         * Starts the plugin
         * Initializes the plugin with the following required
         * parameters as a JSON array: dcsUrl (string), startTime (unix time),
         * endTime (unix time), tourId (string), riderId (string - encrypted).
         * 
         * Usage: cordova.exec( callbackSuccessFn, callbackErrorFn, 'CDVInterface', 'start', [{
         *                  "dcsUrl": http://devcycle.se.rit.edu",
         *                  "startTime": 138652600,
         *                  "endTime": 1389114000,
         *                  "tourId": "toffer",
         *                  "riderId": [An encrypted rider id]
         *          }]);
         **/
        start: function( callbackSuccess , callbackError, arguments ) {
            cordova.exec( callbackSuccess, callbackError, "CDVInterface", "start", JSON.stringify(arguments) );
        },
        
        /**
         * Resume Tracking
         *
         *
         **/
        resumeTracking: function( callbackStop, callbackError ) {
            cordova.exec( callbackStop, callbackError, "CDVInterface", "resumeTracking", [] );
        },
        
        /**
         * Pause Tracking
         *
         *
         **/
        pauseTracking: function( callbackStop, callbackError ) {
            cordova.exec( callbackStop, callbackError, "CDVInterface", "pauseTracking", [] );
        }
    
};