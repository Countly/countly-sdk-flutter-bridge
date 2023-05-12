package ly.count.dart.countly_flutter

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import ly.count.android.sdk.Countly
import ly.count.android.sdk.messaging.CountlyPush

class CountlyMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "got new token: $token")
        if (Countly.sharedInstance().isInitialized) {
            CountlyPush.onTokenRefresh(token)
        }
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "got new message: " + remoteMessage.data)
        if (!Countly.sharedInstance().isInitialized) {
            val application = application
            if (application == null) {
                Log.d(
                    Countly.TAG,
                    "[CountlyMessagingService] getApplication() returns null: application must be non-null to init CountlyPush"
                )
            } else {
                val mode = CountlyPush.getLastMessagingMethod(this)
                if (mode == 0) {
                    CountlyPush.init(application, Countly.CountlyMessagingMode.TEST)
                } else if (mode == 1) {
                    CountlyPush.init(application, Countly.CountlyMessagingMode.PRODUCTION)
                }
            }
        }


        // decode message data and extract meaningful information from it: title, body, badge, etc.
        val message = CountlyPush.decodeMessage(remoteMessage.data)

//        if (message != null && message.has("typ")) {
//            // custom handling only for messages with specific "typ" keys
//            message.recordAction(getApplicationContext());
//            return;
//        }
        val context = applicationContext
        if (context == null) {
            Log.d(
                Countly.TAG,
                "[CountlyMessagingService] getApplicationContext() returns null: context must be non-null to displayNotification"
            )
            return
        }
        val result =
            CountlyPush.displayNotification(context, message, context.applicationInfo.icon, null)
        if (result == null) {
            Log.i(
                TAG,
                "Message wasn't sent from Countly server, so it cannot be handled by Countly SDK"
            )
        } else if (result) {
            Log.i(TAG, "Message was handled by Countly SDK")
        } else {
            Log.i(
                TAG,
                "Message wasn't handled by Countly SDK because API level is too low for Notification support or because currentActivity is null (not enough lifecycle method calls)"
            )
        }

        // 'onNotification' should be called at the end of 'onMessageReceived'. This is due to an unknown issue that prevents showing notifications from the "killed" state for some app/hardware configurations
        CountlyFlutterPlugin.onNotification(remoteMessage.data)
    }

    override fun onDeletedMessages() {
        super.onDeletedMessages()
    }

    companion object {
        private const val TAG = "CountlyMessagingService"
    }
}