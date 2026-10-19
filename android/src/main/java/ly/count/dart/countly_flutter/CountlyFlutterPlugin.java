package ly.count.dart.countly_flutter;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
// import io.flutter.plugin.common.PluginRegistry.Registrar;

import ly.count.android.sdk.Countly;
import ly.count.android.sdk.CountlyConfig;
import ly.count.android.sdk.CountlyStore;
import ly.count.android.sdk.ModuleLog;
import ly.count.android.sdk.ExperimentInformation;
import ly.count.android.sdk.FeedbackRatingCallback;
import ly.count.android.sdk.ModuleFeedback.*;
import ly.count.android.sdk.DeviceIdType;
import ly.count.android.sdk.ContentCallback;
import ly.count.android.sdk.ContentStatus;
import ly.count.android.sdk.WebViewDisplayOption;

import java.util.ArrayDeque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Arrays;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

import java.util.List;
import java.util.ArrayList;

//Push Plugin
import android.os.Build;
import android.app.NotificationManager;
import android.app.NotificationChannel;

import androidx.annotation.NonNull;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;

import ly.count.android.sdk.RCData;
import ly.count.android.sdk.RCDownloadCallback;
import ly.count.android.sdk.RCVariantCallback;
import ly.count.android.sdk.RequestResult;
import ly.count.android.sdk.StarRatingCallback;
import ly.count.android.sdk.messaging.CountlyConfigPush;
import ly.count.android.sdk.messaging.CountlyPush;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.firebase.FirebaseApp;

/**
 * CountlyFlutterPlugin
 */
public class CountlyFlutterPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware, DefaultLifecycleObserver {
    private static final String TAG = "CountlyFlutterPlugin";
    private final String COUNTLY_FLUTTER_SDK_VERSION_STRING = "26.1.1";
    private final String COUNTLY_FLUTTER_SDK_NAME = "dart-flutterb-android";
    private final String COUNTLY_FLUTTER_SDK_NAME_NO_PUSH = "dart-flutterbnp-android";

    private final boolean BUILDING_WITH_PUSH_DISABLED = false;
    private static final int DATA_SCHEMA_VERSIONS = 4;
    private static final int MAX_PENDING_NOTIFICATIONS = 50;
    private static final String POST_NOTIFICATIONS_PERMISSION = "android.permission.POST_NOTIFICATIONS";
    private static final int NOTIFICATION_PERMISSION_REQUEST_CODE = 4119;
    private static final ArrayDeque<String> pendingNotifications = new ArrayDeque<>();
    private static final String PREFERENCES_NAME = "ly.count.dart.countly_flutter";
    private static final String PUSH_ALLOWED_INTENT_SCHEMES_KEY = "pushAllowedIntentSchemes";
    /** The URI schemes push notification links may open, from the last init, or null for the SDK default. */
    private static volatile List<String> pushAllowedIntentSchemes = null;

    public void notifyPublicChannelRCDL(RequestResult downloadResult, String error, boolean fullValueUpdate, Map<String, RCData> downloadedValues, Integer requestID) {
        Map<String, Object> data = new HashMap<>();
        data.put("error", error);
        data.put("requestResult", resultResponder(downloadResult));
        data.put("downloadedValues", transformMapIntoSendableForm(downloadedValues));
        data.put("fullValueUpdate", fullValueUpdate);
        if (requestID != null) {
            data.put("id", requestID);
        }
        log("notifyPublicChannelRCDL, downloaded values: " + downloadedValues + ", error: " + error + ", fullValueUpdate: " + fullValueUpdate + ", requestID: " + requestID, LogLevel.VERBOSE);
        safeInvokeMethod("remoteConfigDownloadCallback", data);
    }

    private void safeInvokeMethod(String method, Object arguments) {
        // Native callbacks outlive the engine that registered them, so they use the bound callback channel.
        MethodChannel mc = sharedChannel;
        if (mc == null) {
            log("safeInvokeMethod: no live channel, dropping '" + method + "'. The Flutter engine is detached.", LogLevel.WARNING);
            return;
        }
        try {
            mc.invokeMethod(method, arguments);
        } catch (Exception e) {
            log("safeInvokeMethod: invoke failed for '" + method + "'", e, LogLevel.WARNING);
        }
    }

    public final Map<String, Object> transformMapIntoSendableForm(Map<String, RCData> map) {
        if (map == null) {
            return new HashMap<>();
        }
        Map<String, Object> newMap = new HashMap<>();
        for (Map.Entry<String, RCData> entry : map.entrySet()) {
            newMap.put(entry.getKey(), transformRCDataIntoSendableForm(entry.getValue()));
        }
        return newMap;
    }

    public final Map<String, Object> transformRCDataIntoSendableForm(RCData data) {
        Map<String, Object> map = new HashMap<>();
        try {
            if (data.value instanceof JSONArray) {
                map.put("value", toList((JSONArray) data.value));
            } else if (data.value instanceof JSONObject) {
                map.put("value", toMap((JSONObject) data.value));
            } else {
                map.put("value", data.value);
            }
        } catch (Exception e) {
            log("'transformRCDataIntoSendableForm' failed while transforming data", LogLevel.INFO);
        }
        map.put("isCurrentUsersData", data.isCurrentUsersData);
        return map;
    }

    public final int resultResponder(RequestResult rResult) {
        int response = 2;
        if (rResult == RequestResult.Success) {
            response = 0;
        } else if (rResult == RequestResult.NetworkIssue) {
            response = 1;
        }
        return response;
    }

    private Context context;
    private Activity activity;
    private static Boolean isDebug = false;
    private final CountlyConfig config = new CountlyConfig();
    private static Callback notificationListener = null;
    private MethodChannel methodChannel;
    // Channel of the engine that receives native SDK callbacks, chosen by bindCallbackChannel.
    private static volatile MethodChannel sharedChannel;
    private Lifecycle lifecycle;
    static final int requestIDNoCallback = -1;
    static final int requestIDGlobalCallback = -2;

    List<CountlyFeedbackWidget> retrievedWidgetList = null;

    //----------PLUGIN REGISTRATION (FlutterPlugin)-------------------
    
    // Required for pre Flutter 1.12 projects
    // public static void registerWith(Registrar registrar) {
    //     final CountlyFlutterPlugin instance = new CountlyFlutterPlugin();
    //     instance.activity = registrar.activity();
    //     final Context __context = registrar.context();
    //     instance.onAttachedToEngineInternal(__context, registrar.messenger());
    //     log("registerWith", LogLevel.INFO);
    // }

    // Called from Android embedding v2
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        onAttachedToEngineInternal(binding.getApplicationContext(), binding.getBinaryMessenger());
        log("onAttachedToEngine", LogLevel.INFO);
    }

    // the plugin is being removed from the Flutter experience and should cleanup
    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        context = null;
        MethodChannel mc = methodChannel;
        if (mc != null) {
            mc.setMethodCallHandler(null);
        }
        methodChannel = null;
        // Only clear the static if it still points at this plugin's channel — a newer engine
        // may have already attached and taken over the slot.
        synchronized (CountlyFlutterPlugin.class) {
            if (sharedChannel == mc) {
                sharedChannel = null;
            }
        }
        log("onDetachedFromEngine", LogLevel.INFO);
    }

    // Internal common plugin initialization function that would be shared with the old and new plugin flow
    private void onAttachedToEngineInternal(Context context, BinaryMessenger messenger) {
        this.context = context;
        methodChannel = new MethodChannel(messenger, "countly_flutter");
        methodChannel.setMethodCallHandler(this);
        bindCallbackChannel();
        log("onAttachedToEngineInternal", LogLevel.INFO);
    }

    /**
     * Makes this engine's channel the target of native SDK callbacks. An engine attached to an Activity
     * always takes it; an engine without one, such as a background isolate, takes it only when no
     * engine holds it, so a background engine cannot pull callbacks away from the UI. Runs on engine
     * attach, Activity attach and init, so an engine that replaced a torn down one gets the callbacks
     * even when it skips init because the SDK is already initialized.
     */
    private void bindCallbackChannel() {
        synchronized (CountlyFlutterPlugin.class) {
            if (methodChannel != null && (sharedChannel == null || activity != null)) {
                sharedChannel = methodChannel;
            }
        }
    }

    /**
     * Runs the given task on the main thread, the only thread Flutter accepts method call replies on.
     */
    private static void runOnMainThread(Runnable task) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            task.run();
        } else {
            new Handler(Looper.getMainLooper()).post(task);
        }
    }

    //----------PLUGIN REGISTRATION OVER-------------

    //----------ACTIVITY AWARE STUFF-----------------
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
        lifecycle.addObserver(this);
        bindCallbackChannel();
        log("onAttachedToActivity : Activity attached!", LogLevel.INFO);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        lifecycle.removeObserver(this);
        this.activity = null;
        log("onDetachedFromActivityForConfigChanges : Activity is no more valid", LogLevel.INFO);
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
        lifecycle.addObserver(this);
        bindCallbackChannel();
        log("onReattachedToActivityForConfigChanges : Activity attached!", LogLevel.INFO);
    }

    @Override
    public void onDetachedFromActivity() {
        lifecycle.removeObserver(this);
        this.activity = null;
        log("onDetachedFromActivity : Activity is no more valid", LogLevel.INFO);
    }

    //----------ACTIVITY AWARE STUFF OVER-----------------

    //----------DefaultLifecycleObserver------------------

    @Override
    public void onCreate(@NonNull LifecycleOwner owner) {
        log("onCreate", LogLevel.INFO);

    }

    @Override
    public void onStart(@NonNull LifecycleOwner owner) {
        log("onStart", LogLevel.INFO);
    }

    @Override
    public void onResume(@NonNull LifecycleOwner owner) {
        log("onResume", LogLevel.INFO);
    }

    @Override
    public void onPause(@NonNull LifecycleOwner owner) {
        log("onPause", LogLevel.INFO);
    }

    @Override
    public void onStop(@NonNull LifecycleOwner owner) {
        log("onStop", LogLevel.INFO);
    }

    @Override
    public void onDestroy(@NonNull LifecycleOwner owner) {
        log("onDestroy", LogLevel.INFO);
    }

    //----------DefaultLifecycleObserver over------------------

    public CountlyFlutterPlugin() {
        log("CountlyFlutterPlugin", LogLevel.INFO);
    }

    //-------------METHOD CALL HANDLER------------------
    @Override
    public void onMethodCall(MethodCall call, final Result result) {
        String argsString = (String) call.argument("data");
        if (argsString == null) {
            argsString = "[]";
        }
        JSONArray args;
        try {
            Countly.sharedInstance();
            args = new JSONArray(argsString);
            log("Method name: " + call.method, LogLevel.INFO);
            log("Method arguments: " + argumentsForLog(call.method, argsString), LogLevel.INFO);

            if ("init".equals(call.method)) {
                if (context == null) {
                    log("valid context is required in Countly init, but was provided 'null'", LogLevel.ERROR);
                    result.error("init Failed", "valid context is required in Countly init, but was provided 'null'", null);
                    return;
                }

                JSONObject config = args.getJSONObject(0);
                this.config.setContext(context);
                populateConfig(config);
                Countly.sharedInstance().COUNTLY_SDK_NAME = BUILDING_WITH_PUSH_DISABLED ? COUNTLY_FLUTTER_SDK_NAME_NO_PUSH : COUNTLY_FLUTTER_SDK_NAME;
                Countly.sharedInstance().COUNTLY_SDK_VERSION_STRING = COUNTLY_FLUTTER_SDK_VERSION_STRING;

                this.config.RemoteConfigRegisterGlobalCallback(new RCDownloadCallback() {
                    @Override
                    public void callback(RequestResult downloadResult, String error, boolean fullValueUpdate, Map<String, RCData> downloadedValues) {
                        notifyPublicChannelRCDL(downloadResult, error, fullValueUpdate, downloadedValues, requestIDGlobalCallback);
                    }
                });

                Context applicationContext = context.getApplicationContext();
                if (applicationContext instanceof Application) {
                    this.config.setApplication((Application) applicationContext);
                } else {
                    log("init, the application context is not an Application, automatic session tracking will not work", LogLevel.WARNING);
                }
                if (activity != null) {
                    this.config.setInitialActivity(activity);
                }
                bindCallbackChannel();
                Countly.sharedInstance().init(this.config);
                if (pushAllowedIntentSchemes != null && applicationContext instanceof Application) {
                    // Notifications that arrive before "askForNotificationPermission" is called follow the allowed schemes too.
                    CountlyPush.init(pushConfig((Application) applicationContext));
                }
                result.success("initialized!");
            } else if ("isInitialized".equals(call.method)) {
                boolean isInitialized = Countly.sharedInstance().isInitialized();
                if (isInitialized) {
                    result.success("true");

                } else {
                    result.success("false");
                }
            } 

            // START DEVICE ID METHODS
            else if ("getID".equals(call.method)) {
                String deviceID = Countly.sharedInstance().deviceId().getID();
                result.success(deviceID);
            } else if ("getIDType".equals(call.method)) {
                DeviceIdType deviceIDType = Countly.sharedInstance().deviceId().getType();
                String deviceIDTypeString = null;
                switch (deviceIDType) {
                    case DEVELOPER_SUPPLIED:
                        deviceIDTypeString = "DS";
                        break;
                    case TEMPORARY_ID:
                        deviceIDTypeString = "TID";
                        break;
                    default:
                        // OPEN_UDID is also SDK_GENERATED SG
                        deviceIDTypeString = "SG";
                        break;
                }
                result.success(deviceIDTypeString);
            } else if ("setID".equals(call.method)) {
                String newDeviceID = args.getString(0);
                Countly.sharedInstance().deviceId().setID(newDeviceID);
                result.success("SetID success!");
            } else if ("changeWithMerge".equals(call.method)) {
                String newDeviceID = args.getString(0);
                Countly.sharedInstance().deviceId().changeWithMerge(newDeviceID);
                result.success("changeWithMerge success!");
            } else if ("changeWithoutMerge".equals(call.method)) {
                String newDeviceID = args.getString(0);
                Countly.sharedInstance().deviceId().changeWithoutMerge(newDeviceID);
                result.success("changeWithoutMerge success!");
            } else if ("enableTemporaryIDMode".equals(call.method)) {
                Countly.sharedInstance().deviceId().enableTemporaryIdMode();
                result.success("enableTemporaryIDMode success");
            } // END DEVICE ID METHODS
            else if ("attemptToSendStoredRequests".equals(call.method)) {
                Countly.sharedInstance().requestQueue().attemptToSendStoredRequests();
                result.success("attemptToSendStoredRequests success!");
            } else if ("addCustomNetworkRequestHeaders".equals(call.method)) {
                Map<String, String> customHeaderValues = toMapString(args.getJSONObject(0));
                Countly.sharedInstance().requestQueue().addCustomNetworkRequestHeaders(customHeaderValues);
                result.success("addCustomNetworkRequestHeaders success!");
            } else if ("recordMetrics".equals(call.method)) {
                Map<String, String> metricsOverride = toMapString(args.getJSONObject(0));
                Countly.sharedInstance().requestQueue().recordMetrics(metricsOverride);
                result.success("recordMetrics success!");
            } else if ("setHttpPostForced".equals(call.method)) {
                boolean isEnabled = args.getBoolean(0);
                this.config.setHttpPostForced(isEnabled);
                result.success("setHttpPostForced");
            } else if ("enableParameterTamperingProtection".equals(call.method)) {
                String salt = args.getString(0);
                this.config.setParameterTamperingProtectionSalt(salt);
                result.success("enableParameterTamperingProtection success!");
            } else if ("setLocationInit".equals(call.method)) {
                String countryCode = args.getString(0);
                String city = args.getString(1);
                String location = args.getString(2);
                String ipAddress = args.getString(3);
                this.config.setLocation(countryCode, city, location, ipAddress);

                result.success("setLocationInit success!");
            } else if ("setLocation".equals(call.method)) {
                String latitude = args.getString(0);
                String longitude = args.getString(1);
                if (!latitude.equals("null") && !longitude.equals("null")) {
                    String latlng = latitude + "," + longitude;
                    Countly.sharedInstance().location().setLocation(null, null, latlng, null);
                }
                result.success("setLocation success!");
            } else if ("setUserLocation".equals(call.method)) {
                JSONObject location = args.getJSONObject(0);
                String countryCode = optNullableString(location, "countryCode");
                String city = optNullableString(location, "city");
                String gpsCoordinates = optNullableString(location, "gpsCoordinates");
                String ipAddress = optNullableString(location, "ipAddress");

                Countly.sharedInstance().location().setLocation(countryCode, city, gpsCoordinates, ipAddress);
                result.success("setUserLocation success!");
            } else if ("disableLocation".equals(call.method)) {
                Countly.sharedInstance().location().disableLocation();
                result.success("disableLocation success!");
            } else if ("addCrashLog".equals(call.method)) {
                String record = args.getString(0);
                Countly.sharedInstance().crashes().addCrashBreadcrumb(record);
                result.success("addCrashLog success!");
            } else if ("logException".equals(call.method)) {
                String exceptionString = args.getString(0);
                boolean nonfatal = args.getBoolean(1);
                Exception exception = new Exception(exceptionString);
                Map<String, Object> segments = new HashMap<>();
                for (int i = 2, il = args.length(); i < il; i += 2) {
                    segments.put(args.getString(i), args.getString(i + 1));
                }
                if (nonfatal) {
                    Countly.sharedInstance().crashes().recordHandledException(exception, segments);
                } else {
                    Countly.sharedInstance().crashes().recordUnhandledException(exception, segments);
                }

                result.success("logException success!");
            } else if ("sendPushToken".equals(call.method)) {
                String token = args.getString(0);
                CountlyPush.onTokenRefresh(token);
                result.success("success!");
            } else if ("askForNotificationPermission".equals(call.method)) {
                if (activity == null) {
                    log("askForNotificationPermission failed : Activity is null", LogLevel.ERROR);
                    result.error("askForNotificationPermission Failed", "Activity is null", null);
                    return;
                }
                if (context == null) {
                    log("valid context is required in askForNotificationPermission, but was provided 'null'", LogLevel.ERROR);
                    result.error("askForNotificationPermission Failed", "valid context is required in Countly askForNotificationPermission, but was provided 'null'", null);
                    return;
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    String channelName = "General Notifications";
                    String channelDescription = "Receive notifications about important updates and events.";
                    NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                    if (notificationManager != null) {
                        NotificationChannel channel = new NotificationChannel(CountlyPush.CHANNEL_ID, channelName, NotificationManager.IMPORTANCE_DEFAULT);
                        channel.setDescription(channelDescription);
                        notificationManager.createNotificationChannel(channel);
                    }
                }
                requestNotificationPermission();
                CountlyPush.init(pushConfig(activity.getApplication()));
                FirebaseApp.initializeApp(context);
                FirebaseMessaging.getInstance().getToken().addOnCompleteListener(new OnCompleteListener<String>() {
                    @Override
                    public void onComplete(@NonNull Task<String> task) {
                        if (!task.isSuccessful()) {
                            log("[askForNotificationPermission], Fetching FCM registration token failed", task.getException(), LogLevel.WARNING);
                            return;
                        }

                        String token = task.getResult();
                        log("FCM Token: " + token, LogLevel.INFO);
                        CountlyPush.onTokenRefresh(token);
                    }
                });
                result.success("askForNotificationPermission!");
            } else if ("pushTokenType".equals(call.method)) {
                log("pushTokenType has no effect on Android, where the messaging mode is no longer used", LogLevel.DEBUG);
                result.success("pushTokenType!");
            } else if ("registerForNotification".equals(call.method)) {
                registerForNotification(args, new Callback() {
                    @Override
                    public void callback(final String resultString) {
                        runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                result.success(resultString);
                            }
                        });
                    }
                });
            } else if ("beginSession".equals(call.method)) {
                Countly.sharedInstance().sessions().beginSession();
                result.success("beginSession!");

            } else if ("updateSession".equals(call.method)) {
                Countly.sharedInstance().sessions().updateSession();
                result.success("updateSession!");

            } else if ("endSession".equals(call.method)) {
                Countly.sharedInstance().sessions().endSession();
                result.success("endSession!");

            } else if ("manualSessionHandling".equals(call.method)) {
                result.success("manualSessionHandling!");

            } else if ("updateSessionPeriod".equals(call.method)) {
                result.success("updateSessionPeriod!");

            } else if ("updateSessionInterval".equals(call.method)) {
                int sessionInterval = Integer.parseInt(args.getString(0));
                this.config.setUpdateSessionTimerDelay(sessionInterval);
                result.success("updateSessionInterval Success!");

            } else if ("eventSendThreshold".equals(call.method)) {
                int queueSize = Integer.parseInt(args.getString(0));
                this.config.setEventQueueSizeToSend(queueSize);
                result.success("eventSendThreshold!");

            } else if ("storedRequestsLimit".equals(call.method)) {
                log("storedRequestsLimit is deprecated and has no effect, use 'setMaxRequestQueueSize' of CountlyConfig instead", LogLevel.WARNING);
                result.success("storedRequestsLimit: deprecated, no effect");

            } else if ("startEvent".equals(call.method)) {
                String startEvent = args.getString(0);
                Countly.sharedInstance().events().startEvent(startEvent);
                result.success("startEvent for: " + startEvent);
            } else if ("cancelEvent".equals(call.method)) {
                String cancelEvent = args.getString(0);
                Countly.sharedInstance().events().cancelEvent(cancelEvent);
                result.success("cancelEvent for: " + cancelEvent);
            } else if ("endEvent".equals(call.method)) {
                String key = args.getString(0);
                int count = Integer.parseInt(args.getString(1));
                double sum = Double.parseDouble(args.getString(2));
                Map<String, Object> segmentation;
                if (args.length() > 3) {
                    segmentation = toMap(args.getJSONObject(3));
                } else {
                    segmentation = null;
                }
                // Map<String, Object> segmentation = toMap(args.getJSONObject(4));
                
                Countly.sharedInstance().events().endEvent(key, segmentation, count, sum);
                result.success("endEvent for: " + key);
            } else if ("recordEvent".equals(call.method)) {
                String key = args.getString(0);
                int count = Integer.parseInt(args.getString(1));
                double sum = Double.parseDouble(args.getString(2));
                int duration = Integer.parseInt(args.getString(3));
                Map<String, Object> segmentation;
                if (args.length() > 4) {
                    segmentation = toMap(args.getJSONObject(4));
                } else {
                    segmentation = null;
                }
                // Map<String, Object> segmentation = toMap(args.getJSONObject(4));
                
                Countly.sharedInstance().events().recordEvent(key, segmentation, count, sum, duration);
                result.success("recordEvent for: " + key);
            } else if ("setLoggingEnabled".equals(call.method)) {
                String loggingEnable = args.getString(0);
                this.config.setLoggingEnabled(loggingEnable.equals("true"));
                result.success("setLoggingEnabled success!");
            } else if ("setuserdata".equals(call.method)) {
                JSONObject userData = args.getJSONObject(0);
                Map<String, Object> bundle = new HashMap<>();

                if (userData.has("name")) {
                    bundle.put("name", userData.getString("name"));
                }
                if (userData.has("username")) {
                    bundle.put("username", userData.getString("username"));
                }
                if (userData.has("email")) {
                    bundle.put("email", userData.getString("email"));
                }
                if (userData.has("organization")) {
                    bundle.put("organization", userData.getString("organization"));
                }
                if (userData.has("phone")) {
                    bundle.put("phone", userData.getString("phone"));
                }
                if (userData.has("picture")) {
                    bundle.put("picture", userData.getString("picture"));
                }
                if (userData.has("picturePath")) {
                    bundle.put("picturePath", userData.getString("picturePath"));
                }
                if (userData.has("gender")) {
                    bundle.put("gender", userData.getString("gender"));
                }
                if (userData.has("byear")) {
                    bundle.put("byear", userData.getString("byear"));
                }

                Countly.sharedInstance().userProfile().setProperties(bundle);
                Countly.sharedInstance().userProfile().save();

                result.success("setuserdata success");
            } else if ("userData_setProperty".equals(call.method)) {
                String keyName = args.getString(0);
                String keyValue = args.getString(1);
                Countly.sharedInstance().userProfile().setProperty(keyName, keyValue);
                Countly.sharedInstance().userProfile().save();
                result.success("userData_setProperty success!");
            } else if ("userData_increment".equals(call.method)) {
                String keyName = args.getString(0);
                Countly.sharedInstance().userProfile().increment(keyName);
                Countly.sharedInstance().userProfile().save();
                result.success("userData_increment success!");
            } else if ("userData_incrementBy".equals(call.method)) {
                String keyName = args.getString(0);
                int keyIncrement = Integer.parseInt(args.getString(1));
                Countly.sharedInstance().userProfile().incrementBy(keyName, keyIncrement);
                Countly.sharedInstance().userProfile().save();
                result.success("userData_incrementBy success!");
            } else if ("userData_multiply".equals(call.method)) {
                String keyName = args.getString(0);
                int multiplyValue = Integer.parseInt(args.getString(1));
                Countly.sharedInstance().userProfile().multiply(keyName, multiplyValue);
                Countly.sharedInstance().userProfile().save();
                result.success("userData_multiply success!");
            } else if ("userData_saveMax".equals(call.method)) {
                String keyName = args.getString(0);
                int maxScore = Integer.parseInt(args.getString(1));
                Countly.sharedInstance().userProfile().saveMax(keyName, maxScore);
                Countly.sharedInstance().userProfile().save();
                result.success("userData_saveMax success!");
            } else if ("userData_saveMin".equals(call.method)) {
                String keyName = args.getString(0);
                int minScore = Integer.parseInt(args.getString(1));
                Countly.sharedInstance().userProfile().saveMin(keyName, minScore);
                Countly.sharedInstance().userProfile().save();
                result.success("userData_saveMin success!");
            } else if ("userData_setOnce".equals(call.method)) {
                String keyName = args.getString(0);
                String minScore = args.getString(1);
                Countly.sharedInstance().userProfile().setOnce(keyName, minScore);
                Countly.sharedInstance().userProfile().save();
                result.success("userData_setOnce success!");
            } else if ("userData_pushUniqueValue".equals(call.method)) {
                String type = args.getString(0);
                String pushUniqueValue = args.getString(1);
                Countly.sharedInstance().userProfile().pushUnique(type, pushUniqueValue);
                Countly.sharedInstance().userProfile().save();
                result.success("userData_pushUniqueValue success!");
            } else if ("userData_pushValue".equals(call.method)) {
                String type = args.getString(0);
                String pushValue = args.getString(1);
                Countly.sharedInstance().userProfile().push(type, pushValue);
                Countly.sharedInstance().userProfile().save();
                result.success("userData_pushValue success!");
            } else if ("userData_pullValue".equals(call.method)) {
                String type = args.getString(0);
                String pullValue = args.getString(1);
                Countly.sharedInstance().userProfile().pull(type, pullValue);
                Countly.sharedInstance().userProfile().save();
                result.success("userData_pullValue success!");
            }

            else if ("userProfile_setProperties".equals(call.method)) {
                JSONObject properties = args.getJSONObject(0);
                Map<String, Object> propertiesMap = toMap(properties);
                Countly.sharedInstance().userProfile().setProperties(propertiesMap);
                result.success(null);
            } else if ("userProfile_setProperty".equals(call.method)) {
                String key = args.getString(0);
                Object value = args.get(1);
                if (!(value instanceof String || value instanceof Number || value instanceof Boolean)) {
                    value = String.valueOf(value);
                }
                Countly.sharedInstance().userProfile().setProperty(key, value);
                result.success(null);
            } else if ("userProfile_increment".equals(call.method)) {
                String key = args.getString(0);
                Countly.sharedInstance().userProfile().increment(key);
                result.success(null);
            } else if ("userProfile_incrementBy".equals(call.method)) {
                String key = args.getString(0);
                int value = args.getInt(1);
                Countly.sharedInstance().userProfile().incrementBy(key, value);
                result.success(null);
            } else if ("userProfile_multiply".equals(call.method)) {
                String key = args.getString(0);
                int value = args.getInt(1);
                Countly.sharedInstance().userProfile().multiply(key, value);
                result.success(null);
            } else if ("userProfile_saveMax".equals(call.method)) {
                String key = args.getString(0);
                int value = args.getInt(1);
                Countly.sharedInstance().userProfile().saveMax(key, value);
                result.success(null);
            } else if ("userProfile_saveMin".equals(call.method)) {
                String key = args.getString(0);
                int value = args.getInt(1);
                Countly.sharedInstance().userProfile().saveMin(key, value);
                result.success(null);
            } else if ("userProfile_setOnce".equals(call.method)) {
                String key = args.getString(0);
                String value = args.getString(1);
                Countly.sharedInstance().userProfile().setOnce(key, value);
                result.success(null);
            } else if ("userProfile_pushUnique".equals(call.method)) {
                String key = args.getString(0);
                String value = args.getString(1);
                Countly.sharedInstance().userProfile().pushUnique(key, value);
                result.success(null);
            } else if ("userProfile_push".equals(call.method)) {
                String key = args.getString(0);
                String value = args.getString(1);
                Countly.sharedInstance().userProfile().push(key, value);
                result.success(null);
            } else if ("userProfile_pull".equals(call.method)) {
                String key = args.getString(0);
                String value = args.getString(1);
                Countly.sharedInstance().userProfile().pull(key, value);
                result.success(null);
            } else if ("userProfile_save".equals(call.method)) {
                Countly.sharedInstance().userProfile().save();
                result.success(null);
            } else if ("userProfile_clear".equals(call.method)) {
                Countly.sharedInstance().userProfile().clear();
                result.success(null);
            } else if ("setRequiresConsent".equals(call.method)) {
                boolean consentFlag = args.getBoolean(0);
                this.config.setRequiresConsent(consentFlag);
                result.success("setRequiresConsent!");
            } else if ("giveConsentInit".equals(call.method)) {
                String[] features = new String[args.length()];
                for (int i = 0; i < args.length(); i++) {
                    features[i] = args.getString(i);
                }
                this.config.setConsentEnabled(features);
                result.success("giveConsentInit!");

            } else if ("giveConsent".equals(call.method)) {
                String[] features = new String[args.length()];
                for (int i = 0; i < args.length(); i++) {
                    features[i] = args.getString(i);
                }
                Countly.sharedInstance().consent().giveConsent(features);
                result.success("giveConsent!");

            } else if ("removeConsent".equals(call.method)) {
                String[] features = new String[args.length()];
                for (int i = 0; i < args.length(); i++) {
                    features[i] = args.getString(i);
                }
                Countly.sharedInstance().consent().removeConsent(features);
                result.success("removeConsent!");

            } else if ("giveAllConsent".equals(call.method)) {
                Countly.sharedInstance().consent().giveConsentAll();
                result.success("giveAllConsent!");
            } else if ("removeAllConsent".equals(call.method)) {
                Countly.sharedInstance().consent().removeConsentAll();
                result.success("removeAllConsent!");
            } else if ("sendRating".equals(call.method)) {
                String ratingString = args.getString(0);
                int rating = Integer.parseInt(ratingString);

                Map<String, Object> segm = new HashMap<>();
                segm.put("platform", "android");
                segm.put("rating", "" + rating);
                Countly.sharedInstance().events().recordEvent("[CLY]_star_rating", segm, 1);
                result.success("sendRating: " + ratingString);
            } else if ("setOptionalParametersForInitialization".equals(call.method)) {
                String city = args.getString(0);
                String country = args.getString(1);
                String latitude = args.getString(2);
                String longitude = args.getString(3);
                String ipAddress = args.getString(4);
                String latlng = null;
                if (city.length() == 0 || city.equals("null")) {
                    city = null;
                }
                if (country.equals("null")) {
                    country = null;
                }
                if (!latitude.equals("null") && !longitude.equals("null")) {
                    latlng = latitude + "," + longitude;
                }
                if (ipAddress.equals("null")) {
                    ipAddress = null;
                }
                Countly.sharedInstance().location().setLocation(country, city, latlng, ipAddress);

                result.success("setOptionalParametersForInitialization sent.");
            } else if ("remoteConfigDownloadValues".equals(call.method)) {
                int requestID = args.getInt(0);
                Countly.sharedInstance().remoteConfig().downloadAllKeys(new RCDownloadCallback() {
                    @Override
                    public void callback(RequestResult downloadResult, String error, boolean fullValueUpdate, Map<String, RCData> downloadedValues) {
                        if (requestID == requestIDNoCallback) {
                            return;
                        }
                        notifyPublicChannelRCDL(downloadResult, error, fullValueUpdate, downloadedValues, requestID);
                    }
                });

                result.success(null);
            } else if ("remoteConfigDownloadSpecificValue".equals(call.method)) {
                int requestID = args.getInt(0);
                JSONArray jArr = args.getJSONArray(1);

                String[] keysOnly = new String[jArr.length()];
                for (int i = 0, il = jArr.length(); i < il; i++) {
                    keysOnly[i] = jArr.getString(i);
                }

                log("remoteConfigDownloadSpecificValue TEST, " + requestID + " , " + keysOnly, LogLevel.WARNING);

                Countly.sharedInstance().remoteConfig().downloadSpecificKeys(keysOnly, new RCDownloadCallback() {
                    @Override
                    public void callback(RequestResult downloadResult, String error, boolean fullValueUpdate, Map<String, RCData> downloadedValues) {
                        if (requestID == requestIDNoCallback) {
                            return;
                        }
                        notifyPublicChannelRCDL(downloadResult, error, fullValueUpdate, downloadedValues, requestID);
                    }
                });

                result.success(null);
            } else if ("remoteConfigDownloadOmittingValues".equals(call.method)) {
                int requestID = args.getInt(0);
                JSONArray jArr = args.getJSONArray(1);

                String[] omitedKeys = new String[jArr.length()];
                for (int i = 0, il = jArr.length(); i < il; i++) {
                    omitedKeys[i] = jArr.getString(i);
                }

                log("remoteConfigDownloadOmittingValues TEST, " + requestID + " , " + omitedKeys, LogLevel.WARNING);

                Countly.sharedInstance().remoteConfig().downloadOmittingKeys(omitedKeys, new RCDownloadCallback() {
                    @Override
                    public void callback(RequestResult downloadResult, String error, boolean fullValueUpdate, Map<String, RCData> downloadedValues) {
                        if (requestID == requestIDNoCallback) {
                            return;
                        }
                        notifyPublicChannelRCDL(downloadResult, error, fullValueUpdate, downloadedValues, requestID);
                    }
                });

                result.success(null);
            } else if ("remoteConfigGetAllValues".equals(call.method)) {
                log("remoteConfigGetAllValues", LogLevel.WARNING);

                Map<String, RCData> rawDownloadedValues = Countly.sharedInstance().remoteConfig().getValues();

                Map<String, Object> transformedDownloadedValues = transformMapIntoSendableForm(rawDownloadedValues);
                result.success(transformedDownloadedValues);
            } else if ("remoteConfigGetValue".equals(call.method)) {
                String key = args.getString(0);
                log("remoteConfigGetValue, " + key, LogLevel.WARNING);

                RCData data = Countly.sharedInstance().remoteConfig().getValue(key);
                Map<String, Object> transData = transformRCDataIntoSendableForm(data);

                result.success(transData);
            } else if ("remoteConfigGetValueAndEnroll".equals(call.method)) {
                String key = args.getString(0);
                log("remoteConfigGetValueAndEnroll, " + key, LogLevel.INFO);

                RCData data = Countly.sharedInstance().remoteConfig().getValueAndEnroll(key);
                Map<String, Object> transData = transformRCDataIntoSendableForm(data);

                result.success(transData);
            } else if ("remoteConfigGetAllValuesAndEnroll".equals(call.method)) {
                log("remoteConfigGetAllValuesAndEnroll", LogLevel.INFO);

                Map<String, RCData> rawDownloadedValues = Countly.sharedInstance().remoteConfig().getAllValuesAndEnroll();

                Map<String, Object> transformedDownloadedValues = transformMapIntoSendableForm(rawDownloadedValues);
                result.success(transformedDownloadedValues);
            } else if ("remoteConfigClearAllValues".equals(call.method)) {
                log("remoteConfigClearAllValues", LogLevel.WARNING);

                Countly.sharedInstance().remoteConfig().clearAll();

                result.success(null);
            } else if ("remoteConfigEnrollIntoABTestsForKeys".equals(call.method)) {
                JSONArray jArr = args.getJSONArray(0);

                String[] keys = new String[jArr.length()];
                for (int i = 0, il = jArr.length(); i < il; i++) {
                    keys[i] = jArr.getString(i);
                }

                log("remoteConfigEnrollIntoABTestsForKeys, " + keys, LogLevel.WARNING);

                Countly.sharedInstance().remoteConfig().enrollIntoABTestsForKeys(keys);

                result.success(null);
            } else if ("remoteConfigExitABTestsForKeys".equals(call.method)) {
                JSONArray jArr = args.getJSONArray(0);

                String[] keys = new String[jArr.length()];
                for (int i = 0, il = jArr.length(); i < il; i++) {
                    keys[i] = jArr.getString(i);
                }

                log("remoteConfigExitABTestsForKeys, " + keys, LogLevel.WARNING);

                Countly.sharedInstance().remoteConfig().exitABTestsForKeys(keys);

                result.success(null);
            } else if ("remoteConfigTestingGetVariantsForKey".equals(call.method)) {
                String key = args.getString(0);
                log("remoteConfigTestingGetVariantsForKey", LogLevel.WARNING);

                String[] variants = Countly.sharedInstance().remoteConfig().testingGetVariantsForKey(key);

                List<String> convertedVariants = null;
                if (variants != null) {
                    convertedVariants = Arrays.asList(variants);
                }

                result.success(convertedVariants);
            } else if ("remoteConfigTestingGetAllVariants".equals(call.method)) {
                log("remoteConfigTestingGetAllVariants", LogLevel.WARNING);

                Map<String, String[]> variants = Countly.sharedInstance().remoteConfig().testingGetAllVariants();

                Map<String, List<String>> convertedVariants = new HashMap<>();
                for (Map.Entry<String, String[]> entry : variants.entrySet()) {
                    convertedVariants.put(entry.getKey(), Arrays.asList(entry.getValue()));
                } // TODO: Make better
            
                result.success(convertedVariants);
            } else if ("remoteConfigTestingDownloadVariantInformation".equals(call.method)) {
                int requestID = args.getInt(0);

                log("remoteConfigTestingDownloadVariantInformation", LogLevel.WARNING);

                Countly.sharedInstance().remoteConfig().testingDownloadVariantInformation((rResult, error) -> {
                    if (requestID == requestIDNoCallback) {
                        return;
                    }
                    Map<String, Object> data = new HashMap<>();
                    data.put("error", error);
                    data.put("requestResult", resultResponder(rResult));
                    data.put("id", requestID);
                    safeInvokeMethod("remoteConfigVariantCallback", data);
                });

                result.success(null);
            }
            else if ("testingDownloadExperimentInformation".equals(call.method)) {
                int requestID = args.getInt(0);

                log("testingDownloadExperimentInformation", LogLevel.WARNING);

                Countly.sharedInstance().remoteConfig().testingDownloadExperimentInformation((rResult, error) -> {
                    if (requestID == requestIDNoCallback) {
                        return;
                    }
                    Map<String, Object> data = new HashMap<>();
                    data.put("error", error);
                    data.put("requestResult", resultResponder(rResult));
                    data.put("id", requestID);
                    safeInvokeMethod("remoteConfigVariantCallback", data);
                });

                result.success(null);
            }
            else if ("testingGetAllExperimentInfo".equals(call.method)) {
                Map<String, ExperimentInformation> experimentInfoMap = Countly.sharedInstance().remoteConfig().testingGetAllExperimentInfo();
                List<Map<String, Object>> experimentInfoArray = new ArrayList<>();
                for (Map.Entry<String, ExperimentInformation> entry : experimentInfoMap.entrySet()) {
                    ExperimentInformation experimentInfo = entry.getValue();
                    Map<String, Object> experimentInfoValue = new HashMap<>();
                    experimentInfoValue.put("experimentID", experimentInfo.experimentID);
                    experimentInfoValue.put("experimentName", experimentInfo.experimentName);
                    experimentInfoValue.put("experimentDescription", experimentInfo.experimentDescription);
                    experimentInfoValue.put("currentVariant", experimentInfo.currentVariant == "null" ? "" : experimentInfo.currentVariant ); // equating to iOS behavior
                    experimentInfoValue.put("variants", experimentInfo.variants);
                    experimentInfoArray.add(experimentInfoValue);
                }
                result.success(experimentInfoArray);
            }
            else if ("remoteConfigTestingEnrollIntoVariant".equals(call.method)) {
                int requestID = args.getInt(0);
                String key = args.getString(1);
                String variant = args.getString(2);
                log("remoteConfigTestingEnrollIntoVariant", LogLevel.WARNING);

                Countly.sharedInstance().remoteConfig().testingEnrollIntoVariant(key, variant, (rResult, error) -> {
                    if (requestID == requestIDNoCallback) {
                        return;
                    }
                    Map<String, Object> data = new HashMap<>();
                    data.put("error", error);
                    data.put("requestResult", resultResponder(rResult));
                    data.put("id", requestID);
                    safeInvokeMethod("remoteConfigVariantCallback", data);
                });

                result.success(null);
            } else if ("presentRatingWidgetWithID".equals(call.method)) {
                if (activity == null) {
                    log("presentRatingWidgetWithID failed : Activity is null", LogLevel.ERROR);
                    result.error("presentRatingWidgetWithID failed", "Activity is null", null);
                    return;
                }
                String widgetId = args.getString(0);
                String closeButtonText = args.getString(1);
                Countly.sharedInstance().ratings().presentRatingWidgetWithID(widgetId, closeButtonText, activity, new FeedbackRatingCallback() {
                    @Override
                    public void callback(String error) {
                        if (error != null) {
                            result.error("presentRatingWidgetWithID failed", "Error: Encountered error while showing feedback dialog: [" + error + "]", error);
                        } else {
                            result.success("presentRatingWidgetWithID success.");
                        }
                        safeInvokeMethod("ratingWidgetCallback", error);
                    }
                });
            } else if (call.method.equals("setStarRatingDialogTexts")) {
                this.config.setStarRatingTextTitle(args.getString(0));
                this.config.setStarRatingTextMessage(args.getString(1));
                this.config.setStarRatingTextDismiss(args.getString(2));

                result.success("setStarRatingDialogTexts Success");
            } else if (call.method.equals("askForStarRating")) {
                if (activity == null) {
                    log("askForStarRating failed : Activity is null", LogLevel.ERROR);
                    result.error("askForStarRating Failed", "Activity is null", null);
                    return;
                }
                // The SDK skips the dialog without calling back when the consent is missing.
                if (!Countly.sharedInstance().consent().getConsent(Countly.CountlyFeatureNames.starRating)) {
                    log("askForStarRating failed : star-rating consent is not given", LogLevel.WARNING);
                    result.success("askForStarRating failed: star-rating consent is not given");
                    return;
                }
                Countly.sharedInstance().ratings().showStarRating(activity, new StarRatingCallback() {
                    @Override
                    public void onRate(int rating) {
                        result.success("Rating: " + rating);
                    }

                    @Override
                    public void onDismiss() {
                        result.success("Rating: Modal dismissed.");
                    }
                });
            } else if ("getAvailableFeedbackWidgets".equals(call.method)) {
                Countly.sharedInstance().feedback().getAvailableFeedbackWidgets(new RetrieveFeedbackWidgets() {
                    @Override
                    public void onFinished(List<CountlyFeedbackWidget> retrievedWidgets, String error) {
                        if (error != null) {
                            result.error("getAvailableFeedbackWidgets", error, null);
                            return;
                        }
                        retrievedWidgetList = new ArrayList(retrievedWidgets);
                        List<Map<String, String>> retrievedWidgetsArray = new ArrayList<>();
                        for (CountlyFeedbackWidget presentableFeedback : retrievedWidgets) {
                            Map<String, String> feedbackWidget = new HashMap<>();
                            feedbackWidget.put("id", presentableFeedback.widgetId);
                            feedbackWidget.put("type", presentableFeedback.type.name());
                            feedbackWidget.put("name", presentableFeedback.name);
                            retrievedWidgetsArray.add(feedbackWidget);
                        }
                        result.success(retrievedWidgetsArray);
                    }
                });
            } else if ("presentFeedbackWidget".equals(call.method)) {
                if (activity == null) {
                    log("presentFeedbackWidget failed : Activity is null", LogLevel.ERROR);
                    result.error("presentFeedbackWidget Failed", "Activity is null", null);
                    return;
                }
                String widgetId = args.getString(0);
                String closeBtnText = args.getString(3);

                CountlyFeedbackWidget feedbackWidget = getFeedbackWidget(widgetId);
                if (feedbackWidget == null) {
                    String errorMessage = "[presentFeedbackWidget], No feedbackWidget is found against widget id : '" + widgetId + "' , always call 'getFeedbackWidgets' to get updated list of feedback widgets.";
                    log(errorMessage, LogLevel.WARNING);
                    result.error("presentFeedbackWidget", errorMessage, null);
                } else {
                    // Versioned widgets report only onClosed, so whichever callback comes first answers the call.
                    final AtomicBoolean replied = new AtomicBoolean(false);
                    // The deprecated overload is the only one that sets the close button text of widgets without a version.
                    Countly.sharedInstance().feedback().presentFeedbackWidget(feedbackWidget, activity, closeBtnText, new FeedbackCallback() {
                        @Override
                        public void onFinished(final String error) {
                            if (error == null) {
                                safeInvokeMethod("widgetShown", null);
                            }
                            if (!replied.compareAndSet(false, true)) {
                                return;
                            }
                            runOnMainThread(new Runnable() {
                                @Override
                                public void run() {
                                    if (error != null) {
                                        result.error("presentFeedbackWidget", error, null);
                                    } else {
                                        result.success("presentFeedbackWidget success");
                                    }
                                }
                            });
                        }

                        @Override
                        public void onClosed() {
                            safeInvokeMethod("widgetClosed", null);
                            if (!replied.compareAndSet(false, true)) {
                                return;
                            }
                            runOnMainThread(new Runnable() {
                                @Override
                                public void run() {
                                    result.success("presentFeedbackWidget closed");
                                }
                            });
                        }
                    });
                }
            } else if ("presentNPS".equals(call.method) || "presentSurvey".equals(call.method) || "presentRating".equals(call.method)) {
                if (activity == null) {
                    log(call.method + " failed : Activity is null", LogLevel.ERROR);
                    safeInvokeMethod("feedbackCallback_onFinished", "Activity is null");
                    result.success(null);
                    return;
                }
                String nameIDorTag = args.optString(0, "");
                FeedbackCallback feedbackCallback = new FeedbackCallback() {
                    @Override
                    public void onFinished(String error) {
                        safeInvokeMethod("feedbackCallback_onFinished", error);
                    }

                    @Override
                    public void onClosed() {
                        safeInvokeMethod("feedbackCallback_onClosed", null);
                    }
                };

                if ("presentNPS".equals(call.method)) {
                    Countly.sharedInstance().feedback().presentNPS(activity, nameIDorTag, feedbackCallback);
                } else if ("presentSurvey".equals(call.method)) {
                    Countly.sharedInstance().feedback().presentSurvey(activity, nameIDorTag, feedbackCallback);
                } else {
                    Countly.sharedInstance().feedback().presentRating(activity, nameIDorTag, feedbackCallback);
                }
                result.success(null);
            }
            else if ("getFeedbackWidgetData".equals(call.method)) {
                String widgetId = args.getString(0);
                CountlyFeedbackWidget feedbackWidget = getFeedbackWidget(widgetId);
                if (feedbackWidget == null) {
                    String errorMessage = "[getFeedbackWidgetData], No feedbackWidget is found against widget id : '" + widgetId + "' , always call 'getFeedbackWidgets' to get updated list of feedback widgets.";
                    log(errorMessage, LogLevel.WARNING);
                    result.error("getFeedbackWidgetData", errorMessage, null);
                    feedbackWidgetDataCallback(null, errorMessage);
                } else {
                    Countly.sharedInstance().feedback().getFeedbackWidgetData(feedbackWidget, new RetrieveFeedbackWidgetData() {
                        @Override
                        public void onFinished(JSONObject retrievedWidgetData, String error) {
                            if (error != null) {
                                result.error("getFeedbackWidgetData", error, null);
                                feedbackWidgetDataCallback(null, error);
                            } else {
                                try {
                                    result.success(toMap(retrievedWidgetData));
                                    feedbackWidgetDataCallback(toMap(retrievedWidgetData), null);

                                } catch (JSONException e) {
                                    result.error("getFeedbackWidgetData", e.getMessage(), null);
                                    feedbackWidgetDataCallback(null, e.getMessage());
                                }
                            }
                        }
                    });
                }
            } else if ("reportFeedbackWidgetManually".equals(call.method)) {
                JSONArray widgetInfo = args.getJSONArray(0);
                JSONObject widgetData = args.getJSONObject(1);
                JSONObject widgetResult = args.getJSONObject(2);
                Map<String, Object> widgetResultMap = null;
                if (widgetResult != null && widgetResult.length() > 0) {
                    widgetResultMap = toMap(widgetResult);
                }

                String widgetId = widgetInfo.getString(0);

                // TODO: for testing purposes we might want to bypass this check as it prevents us from using reportFeedbackWidgetManually directly
                CountlyFeedbackWidget feedbackWidget = getFeedbackWidget(widgetId);
                if (feedbackWidget == null) {
                    String errorMessage = "[reportFeedbackWidgetManually], No feedbackWidget is found against widget id : '" + widgetId + "' , always call 'getFeedbackWidgets' to get updated list of feedback widgets.";
                    log(errorMessage, LogLevel.WARNING);
                    result.error("reportFeedbackWidgetManually", errorMessage, null);
                } else {
                    Countly.sharedInstance().feedback().reportFeedbackWidgetManually(feedbackWidget, widgetData, widgetResultMap);
                    result.success("reportFeedbackWidgetManually success");
                }
            } else if ("replaceAllAppKeysInQueueWithCurrentAppKey".equals(call.method)) {
                Countly.sharedInstance().requestQueue().overwriteAppKeys();
                result.success("replaceAllAppKeysInQueueWithCurrentAppKey Success");
            } else if ("removeDifferentAppKeysFromQueue".equals(call.method)) {
                Countly.sharedInstance().requestQueue().eraseWrongAppKeyRequests();
                result.success("removeDifferentAppKeysFromQueue Success");
            } else if ("startTrace".equals(call.method)) {
                String traceKey = args.getString(0);
                Countly.sharedInstance().apm().startTrace(traceKey);
                result.success("startTrace: success");
            } else if ("cancelTrace".equals(call.method)) {
                String traceKey = args.getString(0);
                Countly.sharedInstance().apm().cancelTrace(traceKey);
                result.success("cancelTrace: success");
            } else if ("clearAllTraces".equals(call.method)) {
                Countly.sharedInstance().apm().cancelAllTraces();
                result.success("clearAllTraces: success");
            } else if ("endTrace".equals(call.method)) {
                String traceKey = args.getString(0);
                HashMap<String, Integer> customMetric = new HashMap<>();
                for (int i = 1, il = args.length(); i < il; i += 2) {
                    try {
                        customMetric.put(args.getString(i), Integer.parseInt(args.getString(i + 1)));
                    } catch (Exception exception) {
                        log("endTrace, could not parse metric, skipping it. ", exception, LogLevel.ERROR);
                    }
                }
                Countly.sharedInstance().apm().endTrace(traceKey, customMetric);
                result.success("endTrace: success");
            } else if ("recordNetworkTrace".equals(call.method)) {
                try {
                    String networkTraceKey = args.getString(0);
                    int responseCode = Integer.parseInt(args.getString(1));
                    int requestPayloadSize = Integer.parseInt(args.getString(2));
                    int responsePayloadSize = Integer.parseInt(args.getString(3));
                    long startTime = Long.parseLong(args.getString(4));
                    long endTime = Long.parseLong(args.getString(5));
                    Countly.sharedInstance().apm().recordNetworkTrace(networkTraceKey, responseCode, requestPayloadSize, responsePayloadSize, startTime, endTime);
                } catch (Exception exception) {
                    log("Exception occurred at recordNetworkTrace method: ", exception, LogLevel.ERROR);
                }
                result.success("recordNetworkTrace: success");
            } else if ("throwNativeException".equals(call.method)) {
                triggerOverflow();
            } else if ("recordIndirectAttribution".equals(call.method)) {
                JSONObject attributionValues = args.getJSONObject(0);
                if (attributionValues != null && attributionValues.length() > 0) {
                    Map<String, String> attributionMap = toMapString(attributionValues);
                    Countly.sharedInstance().attribution().recordIndirectAttribution(attributionMap);
                    result.success("recordIndirectAttribution: success");
                } else {
                    result.error("recordIndirectAttribution Failed", "No attribution values provided", null);
                }
            } else if ("recordDirectAttribution".equals(call.method)) {
                String campaignType = args.getString(0);
                String campaignData = args.getString(1);

                Countly.sharedInstance().attribution().recordDirectAttribution(campaignType, campaignData);
                result.success("recordDirectAttribution: success");
            } else if ("stopViewWithID".equals(call.method)) {
                String viewId = args.getString(0);
                Map<String, Object> segmentation = toMap(args.getJSONObject(1));

                Countly.sharedInstance().views().stopViewWithID(viewId, segmentation);
                result.success(null);
            } else if ("stopViewWithName".equals(call.method)) {
                String viewName = args.getString(0);
                Map<String, Object> segmentation = toMap(args.getJSONObject(1));

                Countly.sharedInstance().views().stopViewWithName(viewName, segmentation);
                result.success(null);
            } else if ("pauseViewWithID".equals(call.method)) {
                String viewId = args.getString(0);
                Map<String, Object> segmentation = toMap(args.getJSONObject(1));

                Countly.sharedInstance().views().pauseViewWithID(viewId);
                result.success(null);
            } else if ("resumeViewWithID".equals(call.method)) {
                String viewId = args.getString(0);
                Map<String, Object> segmentation = toMap(args.getJSONObject(1));

                Countly.sharedInstance().views().resumeViewWithID(viewId);
                result.success(null);
            } else if ("startView".equals(call.method)) {
                String viewName = args.getString(0);
                Map<String, Object> segmentation = toMap(args.getJSONObject(1));

                String viewId = Countly.sharedInstance().views().startView(viewName, segmentation);
                result.success(viewId);
            } else if ("setGlobalViewSegmentation".equals(call.method)) {
                Map<String, Object> segmentation = toMap(args.getJSONObject(0));

                Countly.sharedInstance().views().setGlobalViewSegmentation(segmentation);
                result.success(null);
            } else if ("updateGlobalViewSegmentation".equals(call.method)) {
                Map<String, Object> segmentation = toMap(args.getJSONObject(0));

                Countly.sharedInstance().views().updateGlobalViewSegmentation(segmentation);
                result.success(null);
            } else if ("stopAllViews".equals(call.method)) {
                Map<String, Object> segmentation = toMap(args.getJSONObject(0));

                Countly.sharedInstance().views().stopAllViews(segmentation);
                result.success(null);
            } else if ("addSegmentationToViewWithID".equals(call.method)) {
                String viewId = args.getString(0);
                Map<String, Object> segmentation = toMap(args.getJSONObject(1));

                Countly.sharedInstance().views().addSegmentationToViewWithID(viewId, segmentation);
                result.success(null);
            } else if ("addSegmentationToViewWithName".equals(call.method)) {
                String viewName = args.getString(0);
                Map<String, Object> segmentation = toMap(args.getJSONObject(1));

                Countly.sharedInstance().views().addSegmentationToViewWithName(viewName, segmentation);
                result.success(null);
            } else if ("startAutoStoppedView".equals(call.method)) {
                String viewName = args.getString(0);
                Map<String, Object> segmentation = toMap(args.getJSONObject(1));

                String viewId = Countly.sharedInstance().views().startAutoStoppedView(viewName, segmentation);
                result.success(viewId);
            } else if ("appLoadingFinished".equals(call.method)) {
                Countly.sharedInstance().apm().setAppIsLoaded();
                result.success("appLoadingFinished: success");
            } 
            
            //--------------Test Methods-------------------------------
            else if ("getRequestQueue".equals(call.method)) {
                CountlyStore countlyStore = new CountlyStore(context, new ModuleLog());
                result.success(Arrays.asList(countlyStore.getRequests()));
            } else if ("getEventQueue".equals(call.method)) {
                CountlyStore countlyStore = new CountlyStore(context, new ModuleLog());
                result.success(Arrays.asList(countlyStore.getEvents()));
            } else if ("storeRequest".equals(call.method)) {
                CountlyStore countlyStore = new CountlyStore(context, new ModuleLog());
                countlyStore.addRequest(args.getString(0), true);
                result.success("storeRequest: success");
            } else if ("setServerConfig".equals(call.method)) {
                CountlyStore countlyStore = new CountlyStore(context, new ModuleLog());
                JSONObject jsonObject = args.getJSONObject(0);
                countlyStore.setServerConfig(jsonObject.toString());
                // Why this added here, it is that because when it is set something in storage
                // sdk assumes that it is an older version so it start migrations that needs to be done
                // but in this case we only want to use setting server config and do not want migrations
                // to mess up our process flow. So in here we are setting it to latest known to get away with it.
                // Normally in a fresh install migrations are first to run and they run once.
                countlyStore.setDataSchemaVersion(DATA_SCHEMA_VERSIONS);
                result.success("setServerConfig: success");
            } else if ("getServerConfig".equals(call.method)) {
                CountlyStore countlyStore = new CountlyStore(context, new ModuleLog());
                String sc = countlyStore.getServerConfig();
                Map<String, Object> serverConfigMap = new HashMap<>();
                try {
                    serverConfigMap = toMap(new JSONObject(sc));
                } catch (JSONException ignored) {
                }
                result.success(serverConfigMap);
            } else if ("addDirectRequest".equals(call.method)) {
                JSONObject jsonObject = args.getJSONObject(0);
                Map<String, String> requestMap = new HashMap<>();
                for (Iterator<String> it = jsonObject.keys(); it.hasNext(); ) {
                    String key = it.next();
                    requestMap.put(key, jsonObject.get(key).toString());
                }
                Countly.sharedInstance().requestQueue().addDirectRequest(requestMap);
                result.success("addDirectRequest: success");
            } else if ("halt".equals(call.method)) {
                Countly.sharedInstance().halt();
                result.success("halt: success");
            } else if ("testOnNotification".equals(call.method)) {
                JSONArray payloads = args.getJSONArray(0);
                for (int i = 0; i < payloads.length(); i++) {
                    JSONObject payload = payloads.getJSONObject(i);
                    Map<String, String> notification = new HashMap<>();
                    Iterator<String> keys = payload.keys();
                    while (keys.hasNext()) {
                        String key = keys.next();
                        notification.put(key, payload.optString(key));
                    }
                    onNotification(notification);
                }
                result.success(null);
            }
            //------------------End------------------------------------

            else if ("enterContentZone".equals(call.method)) {
                Countly.sharedInstance().contents().enterContentZone();
                result.success(null);
            } else if ("exitContentZone".equals(call.method)) {
                Countly.sharedInstance().contents().exitContentZone();
                result.success(null);
            } else if ("refreshContentZone".equals(call.method)) {
                Countly.sharedInstance().contents().refreshContentZone();
                result.success(null);
            } else if ("previewContent".equals(call.method)) {
                String contentId = call.argument("contentId");
                Countly.sharedInstance().contents().previewContent(contentId);
                result.success(null);
            }

            else {
                result.notImplemented();
            }

        } catch (JSONException jsonException) {
            result.success(jsonException.toString());
        }
    }

    void triggerOverflow() {
        triggerOverflow1();
    }

    void triggerOverflow1() {
        triggerOverflow();
    }

    CountlyFeedbackWidget getFeedbackWidget(String widgetId) {
        if (retrievedWidgetList == null) {
            return null;
        }
        for (CountlyFeedbackWidget feedbackWidget : retrievedWidgetList) {
            if (feedbackWidget.widgetId.equals(widgetId)) {
                return feedbackWidget;
            }
        }
        return null;
    }

    private void feedbackWidgetDataCallback(Map<String, Object> widgetData, String error) {
        Map<String, Object> feedbackWidgetData = new HashMap<>();
        if (widgetData != null) {
            feedbackWidgetData.put("widgetData", widgetData);
        }
        if (error != null) {
            feedbackWidgetData.put("error", error);
        }
        safeInvokeMethod("feedbackWidgetDataCallback", feedbackWidgetData);
    }

    /**
     * Hands the next push notification to a one-shot listener that answers a single Dart request.
     * A notification that arrived while no listener was waiting is delivered right away; otherwise
     * the listener waits for the next one.
     *
     * @param args unused
     * @param theCallback the listener, called at most once
     * @return a status message
     */
    public String registerForNotification(JSONArray args, final Callback theCallback) {
        log("registerForNotification theCallback", LogLevel.INFO);
        String pendingNotification;
        synchronized (pendingNotifications) {
            pendingNotification = pendingNotifications.poll();
            if (pendingNotification == null) {
                notificationListener = theCallback;
            }
        }
        if (pendingNotification != null) {
            theCallback.callback(pendingNotification);
        }
        return "pushTokenType: success";
    }

    /**
     * Delivers a received push notification to the waiting listener, or queues it until Dart asks
     * for the next one. The listener is consumed, so a Dart request is never answered twice; the
     * queue keeps the newest {@value #MAX_PENDING_NOTIFICATIONS} notifications.
     *
     * @param notification the notification payload
     */
    public static void onNotification(Map<String, String> notification) {
        JSONObject json = new JSONObject(notification);
        String notificationString = json.toString();
        log(notificationString, LogLevel.INFO);
        Callback listener;
        synchronized (pendingNotifications) {
            listener = notificationListener;
            notificationListener = null;
            if (listener == null) {
                if (pendingNotifications.size() >= MAX_PENDING_NOTIFICATIONS) {
                    pendingNotifications.poll();
                }
                pendingNotifications.add(notificationString);
            }
        }
        if (listener != null) {
            listener.callback(notificationString);
        }
    }

    /**
     * Asks for the runtime notification permission that Android 13 (API level 33) and newer
     * require before notifications can be shown. Does nothing when it is already granted.
     */
    private void requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < 33 || activity == null) {
            return;
        }
        if (activity.checkSelfPermission(POST_NOTIFICATIONS_PERMISSION) == PackageManager.PERMISSION_GRANTED) {
            return;
        }
        log("requestNotificationPermission, asking for the notification permission", LogLevel.INFO);
        activity.requestPermissions(new String[] { POST_NOTIFICATIONS_PERMISSION }, NOTIFICATION_PERMISSION_REQUEST_CODE);
    }

    /**
     * Reads a string value, treating a missing key and a JSON null alike as null.
     *
     * @param object the object to read from
     * @param key the key to read
     * @return the value, or null
     */
    static String optNullableString(JSONObject object, String key) {
        if (object.isNull(key)) {
            return null;
        }
        return object.optString(key, null);
    }

    /**
     * Returns a Countly Push configuration with the URI schemes push notification links may open. While
     * the SDK is not initialized, as when a notification wakes a closed app, they come from storage.
     *
     * @param application the application to initialize Countly Push with
     * @return the push configuration
     */
    static CountlyConfigPush pushConfig(Application application) {
        CountlyConfigPush pushConfig = new CountlyConfigPush(application);
        List<String> schemes = pushAllowedIntentSchemes;
        if (!Countly.sharedInstance().isInitialized()) {
            schemes = storedPushAllowedIntentSchemes(application);
        }
        if (schemes != null) {
            pushConfig.setAllowedIntentSchemes(schemes);
        }
        return pushConfig;
    }

    /**
     * Stores the URI schemes push notification links may open, for notifications that arrive while
     * the SDK is not initialized, or removes them when none are set.
     *
     * @param context any context of the app
     * @param schemes the allowed schemes, or null for the SDK default
     */
    private static void storePushAllowedIntentSchemes(Context context, List<String> schemes) {
        SharedPreferences.Editor editor = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE).edit();
        if (schemes == null) {
            editor.remove(PUSH_ALLOWED_INTENT_SCHEMES_KEY);
        } else {
            editor.putStringSet(PUSH_ALLOWED_INTENT_SCHEMES_KEY, new HashSet<>(schemes));
        }
        editor.apply();
    }

    /**
     * Returns the URI schemes push notification links may open, as stored at the last init.
     *
     * @param context any context of the app
     * @return the allowed schemes, or null when none were set
     */
    private static List<String> storedPushAllowedIntentSchemes(Context context) {
        Set<String> stored = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE).getStringSet(PUSH_ALLOWED_INTENT_SCHEMES_KEY, null);
        if (stored == null) {
            return null;
        }
        return new ArrayList<>(stored);
    }

    /**
     * Returns the strings of a JSON array.
     *
     * @param array the array to read
     * @return its values as strings
     * @throws JSONException when a value cannot be read
     */
    static List<String> toStringList(JSONArray array) throws JSONException {
        List<String> strings = new ArrayList<>();
        for (int i = 0; i < array.length(); i++) {
            strings.add(array.getString(i));
        }
        return strings;
    }

    /**
     * Returns the method arguments as they may appear in logs. The tamper protection salt and custom
     * header values are masked, and initial user properties are reduced to their keys.
     *
     * @param method the method name
     * @param argsString the JSON encoded arguments
     * @return the arguments, safe to log
     */
    static String argumentsForLog(String method, String argsString) {
        if ("enableParameterTamperingProtection".equals(method) || "addCustomNetworkRequestHeaders".equals(method)) {
            return "[masked]";
        }
        if (!"init".equals(method)) {
            return argsString;
        }
        try {
            JSONArray array = new JSONArray(argsString);
            JSONObject initConfig = array.optJSONObject(0);
            if (initConfig == null) {
                return argsString;
            }
            if (initConfig.has("tamperingProtectionSalt")) {
                initConfig.put("tamperingProtectionSalt", "[masked]");
            }
            JSONObject headers = initConfig.optJSONObject("customNetworkRequestHeaders");
            if (headers != null) {
                JSONObject maskedHeaders = new JSONObject();
                Iterator<String> headerKeys = headers.keys();
                while (headerKeys.hasNext()) {
                    maskedHeaders.put(headerKeys.next(), "[masked]");
                }
                initConfig.put("customNetworkRequestHeaders", maskedHeaders);
            }
            JSONObject userProperties = initConfig.optJSONObject("providedUserProperties");
            if (userProperties != null) {
                initConfig.put("providedUserProperties", userProperties.names());
            }
            return array.toString();
        } catch (JSONException exception) {
            return "[unreadable]";
        }
    }

    public interface Callback {
        void callback(String result);
    }

    enum LogLevel {INFO, DEBUG, VERBOSE, WARNING, ERROR}

    static void log(String message, LogLevel logLevel) {
        log(message, null, logLevel);
    }

    static void log(String message, Throwable tr, LogLevel logLevel) {
        if (!isDebug && !Countly.sharedInstance().isLoggingEnabled()) {
            return;
        }
        switch (logLevel) {
            case INFO:
                Log.i(TAG, message, tr);
                break;
            case DEBUG:
                Log.d(TAG, message, tr);
                break;
            case WARNING:
                Log.w(TAG, message, tr);
                break;
            case ERROR:
                Log.e(TAG, message, tr);
                break;
            case VERBOSE:
                Log.v(TAG, message, tr);
                break;
        }
    }

    public static Map<String, Object> toMap(JSONObject jsonobj) throws JSONException {
        Map<String, Object> map = new HashMap<>();
        Iterator<String> keys = jsonobj.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            Object value = jsonobj.get(key);
            if (value instanceof JSONArray) {
                value = toList((JSONArray) value);
            } else if (value instanceof JSONObject) {
                value = toMap((JSONObject) value);
            }
            map.put(key, value);
        }
        return map;
    }

    public static Map<String, String> toMapString(JSONObject jsonobj) {
        Map<String, String> map = new HashMap<>();
        try {
            Iterator<String> keys = jsonobj.keys();
            while (keys.hasNext()) {
                String key = keys.next();
                Object value = jsonobj.get(key);
                if (value instanceof String) {
                    map.put(key, (String) value);
                }
            }
        } catch (JSONException e) {
            log("Exception occurred at 'toMapString' method: ", e, LogLevel.ERROR);
        }
        return map;
    }

    public static List<Object> toList(JSONArray array) throws JSONException {
        List<Object> list = new ArrayList<>();
        for (int i = 0; i < array.length(); i++) {
            Object value = array.get(i);
            if (value instanceof JSONArray) {
                value = toList((JSONArray) value);
            } else if (value instanceof JSONObject) {
                value = toMap((JSONObject) value);
            }
            list.add(value);
        }
        return list;
    }

    public static String[] toStringArray(JSONArray array) {
        if (array == null)
            return null;

        int size = array.length();
        String[] stringArray = new String[size];
        for (int i = 0; i < size; i++) {
            stringArray[i] = array.optString(i);
        }
        return stringArray;
    }

    private void enableManualSessionControl() {
        this.config.enableManualSessionControl();
    }

    private void populateConfig(JSONObject _config) throws JSONException {
        if (_config.has("serverURL")) {
            this.config.setServerURL(_config.getString("serverURL"));
        }
        if (_config.has("appKey")) {
            this.config.setAppKey(_config.getString("appKey"));
        }
        if (_config.has("deviceID")) {
            String deviceID = _config.getString("deviceID");
            if (deviceID.equals("CLYTemporaryDeviceID")) {
                this.config.enableTemporaryDeviceIdMode();
            } else {
                this.config.setDeviceId(deviceID);
            }
        }
        if (_config.has("loggingEnabled")) {
            this.config.setLoggingEnabled(_config.getBoolean("loggingEnabled"));
        }
        if (_config.has("locationDisabled") && _config.getBoolean("locationDisabled")) {
            this.config.setDisableLocation();
        }
        if (_config.has("httpPostForced")) {
            this.config.setHttpPostForced(_config.getBoolean("httpPostForced"));
        }
        if (_config.has("customNetworkRequestHeaders")) {
            JSONObject customHeaderValues = _config.getJSONObject("customNetworkRequestHeaders");
            Map<String, String> customHeaderValuesMap = toMapString(customHeaderValues);
            this.config.addCustomNetworkRequestHeaders(customHeaderValuesMap);
        }
        if (_config.has("shouldRequireConsent")) {
            this.config.setRequiresConsent(_config.getBoolean("shouldRequireConsent"));
        }
        if (_config.has("tamperingProtectionSalt")) {
            this.config.setParameterTamperingProtectionSalt(_config.getString("tamperingProtectionSalt"));
        }
        if (_config.has("eventQueueSizeThreshold")) {
            this.config.setEventQueueSizeToSend(_config.getInt("eventQueueSizeThreshold"));
        }
        if (_config.has("sessionUpdateTimerDelay")) {
            this.config.setUpdateSessionTimerDelay(_config.getInt("sessionUpdateTimerDelay"));
        }

        if (_config.has("customCrashSegment")) {
            Map<String, Object> customCrashSegment = toMap(_config.getJSONObject("customCrashSegment"));
            this.config.crashes.setCustomCrashSegmentation(customCrashSegment);
        }
        if (_config.has("providedUserProperties")) {
            Map<String, Object> providedUserProperties = toMap(_config.getJSONObject("providedUserProperties"));
            this.config.setUserProperties(providedUserProperties);
        }

        if (_config.has("consents")) {
            String[] consents = toStringArray(_config.getJSONArray("consents"));
            this.config.setConsentEnabled(consents);
        }
        if (_config.has("starRatingTextTitle")) {
            this.config.setStarRatingTextTitle(_config.getString("starRatingTextTitle"));
        }
        if (_config.has("starRatingTextMessage")) {
            this.config.setStarRatingTextMessage(_config.getString("starRatingTextMessage"));
        }
        if (_config.has("starRatingTextDismiss")) {
            this.config.setStarRatingTextDismiss(_config.getString("starRatingTextDismiss"));
        }
        
        if (_config.has("sdkBehaviorSettings")) {
            this.config.setSDKBehaviorSettings(_config.getString("sdkBehaviorSettings"));
        }

        if (_config.has("sdkBehaviorSettingsUpdatesDisabled")) {
            this.config.disableSDKBehaviorSettingsUpdates();
        }

        if (_config.optBoolean("backoffMechanismDisabled", false)) {
            this.config.disableBackoffMechanism();
        }

        if (_config.has("disableStoringDefaultPushConsent")) {
            this.config.disableStoringDefaultPushConsent();
        }

        // APM ------------------------------------------------
        if (_config.has("trackAppStartTime")) {
            this.config.apm.enableAppStartTimeTracking();
        }
        if (_config.has("enableForegroundBackground")) {
            this.config.apm.enableForegroundBackgroundTracking();
        }
        if (_config.has("enableManualAppLoaded")) {
            this.config.apm.enableManualAppLoadedTrigger();
        }
        if (_config.has("startTSOverride")) {
            this.config.apm.setAppStartTimestampOverride(_config.getLong("startTSOverride"));
        }
        // APM END --------------------------------------------
        // Internal Limits ------------------------------------
        if (_config.has("maxKeyLength")) {
            this.config.sdkInternalLimits.setMaxKeyLength(_config.getInt("maxKeyLength"));
        }
        if (_config.has("maxValueSize")) {
            this.config.sdkInternalLimits.setMaxValueSize(_config.getInt("maxValueSize"));
        }
        if (_config.has("maxSegmentationValues")) {
            this.config.sdkInternalLimits.setMaxSegmentationValues(_config.getInt("maxSegmentationValues"));
        }
        if (_config.has("maxBreadcrumbCount")) {
            this.config.sdkInternalLimits.setMaxBreadcrumbCount(_config.getInt("maxBreadcrumbCount"));
        }
        if (_config.has("maxStackTraceLineLength")) {
            this.config.sdkInternalLimits.setMaxStackTraceLineLength(_config.getInt("maxStackTraceLineLength"));
        }
        if (_config.has("maxStackTraceLinesPerThread")) {
            this.config.sdkInternalLimits.setMaxStackTraceLinesPerThread(_config.getInt("maxStackTraceLinesPerThread"));
        }        
        // Internal Limits END --------------------------------

        if (_config.has("enableUnhandledCrashReporting") && _config.getBoolean("enableUnhandledCrashReporting")) {
            this.config.crashes.enableCrashReporting();
        }

        if (_config.has("maxRequestQueueSize")) {
            this.config.setMaxRequestQueueSize(_config.getInt("maxRequestQueueSize"));
        }

        if (_config.has("requestDropAgeHours")) {
            this.config.setRequestDropAgeHours(_config.getInt("requestDropAgeHours"));
        }

        if (_config.has("requestTimeoutDuration")) {
            this.config.setRequestTimeoutDuration(_config.getInt("requestTimeoutDuration"));
        }

        if (_config.has("manualSessionEnabled") && _config.getBoolean("manualSessionEnabled")) {
            enableManualSessionControl();
        }

        String countryCode = null;
        String city = null;
        String gpsCoordinates = null;
        String ipAddress = null;

        if (_config.has("locationCountryCode")) {
            countryCode = _config.getString("locationCountryCode");
        }
        if (_config.has("locationCity")) {
            city = _config.getString("locationCity");
        }
        if (_config.has("locationGpsCoordinates")) {
            gpsCoordinates = _config.getString("locationGpsCoordinates");
        }
        if (_config.has("locationIpAddress")) {
            ipAddress = _config.getString("locationIpAddress");
        }
        if (city != null || countryCode != null || gpsCoordinates != null || ipAddress != null) {
            this.config.setLocation(countryCode, city, gpsCoordinates, ipAddress);
        }

        if (_config.has("campaignType")) {
            String campaignType = _config.getString("campaignType");
            String campaignData = _config.getString("campaignData");
            this.config.setDirectAttribution(campaignType, campaignData);
        }

        if (_config.has("attributionValues")) {
            JSONObject attributionValues = _config.getJSONObject("attributionValues");
            this.config.setIndirectAttribution(toMapString(attributionValues));
        }

        if (_config.has("remoteConfigAutomaticTriggers")) {
            boolean remoteConfigAutomaticTriggers = _config.getBoolean("remoteConfigAutomaticTriggers");
            if (remoteConfigAutomaticTriggers) {
                this.config.enableRemoteConfigAutomaticTriggers();
            }
        }

        if (_config.has("remoteConfigValueCaching")) {
            boolean remoteConfigValueCaching = _config.getBoolean("remoteConfigValueCaching");
            if (remoteConfigValueCaching) {
                this.config.enableRemoteConfigValueCaching();
            }
        }

        if (_config.has("globalViewSegmentation")) {
            JSONObject globalViewSegmentation = _config.getJSONObject("globalViewSegmentation");
            this.config.setGlobalViewSegmentation(toMap(globalViewSegmentation));
        }

        if (_config.has("disableViewRestartForManualRecording") && _config.getBoolean("disableViewRestartForManualRecording")) {
            this.config.disableViewRestartForManualRecording();
        }

        if (_config.has("enableAllConsents") && _config.getBoolean("enableAllConsents")) {
             this.config.giveAllConsents();
        }

        if (_config.has("autoEnrollABOnDownload") && _config.getBoolean("autoEnrollABOnDownload")) {
             this.config.enrollABOnRCDownload();
        }

        if (_config.has("visibilityTracking")) {
            this.config.experimental.enableVisibilityTracking();
        }

        if (_config.has("previousNameRecording")) {
            this.config.experimental.enablePreviousNameRecording();
        }

        if (_config.has("zoneTimerInterval")) {
            this.config.content.setZoneTimerInterval(_config.getInt("zoneTimerInterval"));
        }

        if (_config.has("webviewDisplayOption")) {
            String option = _config.getString("webviewDisplayOption");
            if ("IMMERSIVE".equals(option)) {
                this.config.setWebviewDisplayOption(WebViewDisplayOption.IMMERSIVE);
            } else if ("SAFE_AREA".equals(option)) {
                this.config.setWebviewDisplayOption(WebViewDisplayOption.SAFE_AREA);
            }
        }

        if (_config.has("contentAllowedIntentSchemes")) {
            this.config.content.setAllowedIntentSchemes(toStringList(_config.getJSONArray("contentAllowedIntentSchemes")));
        }

        pushAllowedIntentSchemes = null;
        if (_config.has("pushAllowedIntentSchemes")) {
            pushAllowedIntentSchemes = toStringList(_config.getJSONArray("pushAllowedIntentSchemes"));
        }
        storePushAllowedIntentSchemes(context, pushAllowedIntentSchemes);

        this.config.content.setGlobalContentCallback(new ContentCallback() {
            @Override 
            public void onContentCallback(ContentStatus contentStatus, Map<String, Object> contentData) {
                Map<String, Object> contentCallbackData = new HashMap<>();
                int contentResult = 0; // COMPLETED = 0, CLOSED = 1
                if(contentStatus.equals(ContentStatus.CLOSED)){
                    contentResult = 1;
                }
                contentCallbackData.put("contentResult", contentResult);
                contentCallbackData.put("contentData", contentData);
                
                safeInvokeMethod("contentCallback", contentCallbackData);
            }
        });
    }
}
