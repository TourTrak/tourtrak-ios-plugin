//
//  CDVInterface.js
//
//
//  Created by Stas Gorodnichenko on 20/08/13.
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
         * parameters. Add parameters into the array.
         *
         * @param- DCSUrl
         * @param- startTime
         * @param- endTime
         * @param- tourConfigId
         * @param- riderId
         **/
        start: function( callbackSuccess , callbackError ) {
            cordova.exec( callbackSuccess, callbackError, "CDVInterface", "start", [] );
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