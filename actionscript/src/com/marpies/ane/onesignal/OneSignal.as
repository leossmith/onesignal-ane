/**
 * Copyright 2016 Marcel Piestansky (http://marpies.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.marpies.ane.onesignal {

    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;
    import flash.system.Capabilities;

    public class OneSignal {

        private static const TAG:String = "[OneSignal]";
        private static const EXTENSION_ID:String = "com.marpies.ane.onesignal";

        private static var mContext:ExtensionContext;

        /* Event codes */
        private static const TOKEN_RECEIVED:String = "tokenReceived";

        /* Callbacks */
        private static var mTokenListeners:Vector.<Function> = new <Function>[];

        /* Misc */
        private static var mInitialized:Boolean;
        private static var mLogEnabled:Boolean;
        private static const iOS:Boolean = Capabilities.manufacturer.indexOf( "iOS" ) > -1;
        private static const ANDROID:Boolean = Capabilities.manufacturer.indexOf( "Android" ) > -1;

        /**
         * @private
         * Do not use. OneSignal is a static class.
         */
        public function OneSignal() {
            throw Error( "OneSignal is static class." );
        }

        /**
         *
         *
         * Public API
         *
         *
         */

        /**
         * Initializes extension context.
         * 
         * @param oneSignalAppID ID of the app created in the OneSignal dashboard.
         * @param autoRegister Set to <code>true</code> to register with notification server immediately after initialization.
         * @param showLogs Set to <code>true</code> to show extension log messages.
         * 
         * @return <code>true</code> if the extension context was created, <code>false</code> otherwise
         */
        public static function init( oneSignalAppID:String, autoRegister:Boolean = false, showLogs:Boolean = false ):Boolean {
            if( !isSupported ) return false;
            if( mInitialized ) return true;

            mLogEnabled = showLogs;

            /* Initialize context */
            if( !initExtensionContext() ) {
                log( "Error creating extension context for " + EXTENSION_ID );
                return false;
            }

            /* Listen for native library events */
            mContext.addEventListener( StatusEvent.STATUS, onStatus );

            /* Call init */
            mContext.call( "init", oneSignalAppID, autoRegister, showLogs );

            mInitialized = true;
            return true;
        }

        /**
         * Adds callback that will be called when user registers for notifications and push token is received.
         * @param callback Function with the following signature:
         * <listing version="3.0">
         * function callback( oneSignalUserId:String, pushToken:String ):void {
         *    // pushToken may be null if there's an error (server side, connection error...)
         * };
         * </listing>
         *
         * @see #removeTokenReceivedCallback
         */
        public static function addTokenReceivedCallback( callback:Function ):void {
            if( !isSupported ) return;

            if( callback === null ) throw new ArgumentError( "Parameter callback cannot be null." );

            if( mTokenListeners.indexOf( callback ) < 0 ) {
                mTokenListeners[mTokenListeners.length] = callback;
            }
        }

        /**
         * Removes callback that was added earlier using <code>OneSignal.addTokenReceivedCallback</code>
         * @param callback Function to remove.
         *
         * @see #addTokenReceivedCallback
         */
        public static function removeTokenReceivedCallback( callback:Function ):void {
            if( !isSupported ) return;

            if( callback === null ) throw new ArgumentError( "Parameter callback cannot be null." );

            var index:int = mTokenListeners.indexOf( callback );
            if( index >= 0 ) {
                mTokenListeners.removeAt( index );
            }
        }

        /**
         * Disposes native extension context.
         */
        public static function dispose():void {
            if( !isSupported ) return;
            validateExtensionContext();

            mContext.removeEventListener( StatusEvent.STATUS, onStatus );

            mContext.dispose();
            mContext = null;
        }

        /**
         *
         *
         * Getters / Setters
         *
         *
         */

        /**
         * Version of the native OneSignal SDK.
         */
        public static function get sdkVersion():String {
            if( !isSupported ) return null;
            if( !mInitialized && !initExtensionContext() ) {
                return null;
            }

            return mContext.call( "sdkVersion" ) as String;
        }

        /**
         * Extension version.
         */
        public static function get version():String {
            return "0.0.2";
        }

        /**
         * Supported on iOS and Android.
         */
        public static function get isSupported():Boolean {
            return iOS || ANDROID;
        }

        /**
         *
         *
         * Private API
         *
         *
         */

        /**
         * Initializes extension context.
         * @return <code>true</code> if initialized successfully, <code>false</code> otherwise.
         */
        private static function initExtensionContext():Boolean {
            if( mContext === null ) {
                mContext = ExtensionContext.createExtensionContext( EXTENSION_ID, null );
            }
            return mContext !== null;
        }

        private static function validateExtensionContext():void {
            if( !mContext ) throw new Error( "OneSignal extension was not initialized. Call init() first." );
        }

        private static function onStatus( event:StatusEvent ):void {
            var responseJSON:Object = null;
            switch( event.code ) {
                case TOKEN_RECEIVED:
                    responseJSON = JSON.parse( event.level );
                    var length:int = mTokenListeners.length;
                    for( var i:int = 0; i < length; ++i ) {
                        mTokenListeners[i]( responseJSON.userId, responseJSON.pushToken );
                    }
                    return;
            }
        }

        private static function log( message:String ):void {
            if( mLogEnabled ) {
                trace( TAG, message );
            }
        }

    }
}