package ly.count.dart.countly_flutter;

import android.app.Application;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.util.Log;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import ly.count.android.sdk.messaging.CountlyConfigPush;
import ly.count.android.sdk.messaging.CountlyPush;
import ly.count.android.sdk.Countly;

public class CountlyMessagingService extends FirebaseMessagingService {
    private static final String TAG = "CountlyMessagingService";
    private static final String DEFAULT_NOTIFICATION_ICON_KEY = "com.google.firebase.messaging.default_notification_icon";

    /**
     * Returns the small icon for notifications: the one the app declares for Firebase Messaging in its
     * manifest meta-data, or the launcher icon when it declares none.
     *
     * @param context the application context
     * @return the icon resource id
     */
    static int notificationSmallIcon(Context context) {
        int icon = context.getApplicationInfo().icon;
        try {
            ApplicationInfo appInfo = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
            if (appInfo.metaData != null) {
                int declaredIcon = appInfo.metaData.getInt(DEFAULT_NOTIFICATION_ICON_KEY, 0);
                if (declaredIcon != 0) {
                    icon = declaredIcon;
                }
            }
        } catch (PackageManager.NameNotFoundException exception) {
            Log.w(TAG, "Could not read the notification icon meta-data, using the launcher icon", exception);
        }
        return icon;
    }

    @Override
    public void onNewToken(String token) {
        super.onNewToken(token);
        Log.d(TAG, "got new token: " + token);
        if (Countly.sharedInstance().isInitialized()) {
            CountlyPush.onTokenRefresh(token);
        }
    }

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);
        Log.d(TAG, "got new message: " + remoteMessage.getData());

        if (!Countly.sharedInstance().isInitialized()) {
            Application application = getApplication();
            if(application == null){
                Log.d(Countly.TAG, "[CountlyMessagingService] getApplication() returns null: application must be non-null to init CountlyPush");
            }
            else {
                CountlyPush.init(new CountlyConfigPush(application));
            }
        }


        // decode message data and extract meaningful information from it: title, body, badge, etc.
        CountlyPush.Message message = CountlyPush.decodeMessage(remoteMessage.getData());

//        if (message != null && message.has("typ")) {
//            // custom handling only for messages with specific "typ" keys
//            message.recordAction(getApplicationContext());
//            return;
//        }

        Context context = getApplicationContext();
        if(context == null){
            Log.d(Countly.TAG, "[CountlyMessagingService] getApplicationContext() returns null: context must be non-null to displayNotification");
            return;
        }
        Boolean result = CountlyPush.displayNotification(context, message, notificationSmallIcon(context), null);
        if (result == null) {
            Log.i(TAG, "Message wasn't sent from Countly server, so it cannot be handled by Countly SDK");
        } else if (result) {
            Log.i(TAG, "Message was handled by Countly SDK");
        } else {
            Log.i(TAG, "Message wasn't handled by Countly SDK because API level is too low for Notification support or because currentActivity is null (not enough lifecycle method calls)");
        }

        // 'onNotification' should be called at the end of 'onMessageReceived'. This is due to an unknown issue that prevents showing notifications from the "killed" state for some app/hardware configurations
        CountlyFlutterPlugin.onNotification(remoteMessage.getData());
    }

    @Override
    public void onDeletedMessages() {
        super.onDeletedMessages();
    }
}