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
import io.flutter.plugin.common.PluginRegistry.Registrar;

import ly.count.android.sdk.Countly;
import ly.count.android.sdk.CountlyConfig;
import ly.count.android.sdk.FeedbackRatingCallback;
import ly.count.android.sdk.ModuleFeedback.*;
import ly.count.android.sdk.DeviceIdType;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import android.app.Activity;
import android.content.Context;

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

import ly.count.android.sdk.RemoteConfigCallback;
import ly.count.android.sdk.StarRatingCallback;
import ly.count.android.sdk.messaging.CountlyPush;

import com.google.firebase.iid.FirebaseInstanceId;
import com.google.firebase.iid.InstanceIdResult;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.firebase.FirebaseApp;

/**
 * CountlyFlutterPlugin
 */
public class CountlyFlutterPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware, DefaultLifecycleObserver {
    private static final String TAG = "CountlyFlutterPlugin";
    private final String COUNTLY_FLUTTER_SDK_VERSION_STRING = "23.2.3";
    private final String COUNTLY_FLUTTER_SDK_NAME = "dart-flutterb-android";
    private final String COUNTLY_FLUTTER_SDK_NAME_NO_PUSH = "dart-flutterbnp-android";

    private final boolean BUILDING_WITH_PUSH_DISABLED = false;

    /**
     * Plugin registration.
     */
    private Countly.CountlyMessagingMode pushTokenType = Countly.CountlyMessagingMode.PRODUCTION;
    private Context context;
    private Activity activity;
    private static Boolean isDebug = false;
    private final CountlyConfig config = new CountlyConfig();
    private static Callback notificationListener = null;
    private static String lastStoredNotification = null;
    private MethodChannel methodChannel;
    private Lifecycle lifecycle;
    private Boolean isSessionStarted_ = false;
    private Boolean manualSessionControlEnabled_ = false;

    private boolean isOnResumeBeforeInit = false;

    List<CountlyFeedbackWidget> retrievedWidgetList = null;

    public static void registerWith(Registrar registrar) {
        final CountlyFlutterPlugin instance = new CountlyFlutterPlugin();
        instance.activity = registrar.activity();
        final Context __context = registrar.context();
        instance.onAttachedToEngineInternal(__context, registrar.messenger());
        log("registerWith", LogLevel.INFO);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        onAttachedToEngineInternal(binding.getApplicationContext(), binding.getBinaryMessenger());
        log("onAttachedToEngine", LogLevel.INFO);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        context = null;
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
        log("onDetachedFromEngine", LogLevel.INFO);
    }

    private void onAttachedToEngineInternal(Context context, BinaryMessenger messenger) {
        this.context = context;
        methodChannel = new MethodChannel(messenger, "countly_flutter");
        methodChannel.setMethodCallHandler(this);

        this.config.enableManualAppLoadedTrigger();
        this.config.enableManualForegroundBackgroundTriggerAPM();

        log("onAttachedToEngineInternal", LogLevel.INFO);
    }


    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
        lifecycle.addObserver(this);
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
        log("onReattachedToActivityForConfigChanges : Activity attached!", LogLevel.INFO);
    }

    @Override
    public void onDetachedFromActivity() {
        lifecycle.removeObserver(this);
        this.activity = null;
        log("onDetachedFromActivity : Activity is no more valid", LogLevel.INFO);
    }

    // DefaultLifecycleObserver callbacks

    @Override
    public void onCreate(@NonNull LifecycleOwner owner) {
        log("onCreate", LogLevel.INFO);

    }

    @Override
    public void onStart(@NonNull LifecycleOwner owner) {
        log("onStart", LogLevel.INFO);
        if (Countly.sharedInstance().isInitialized()) {
            if (isSessionStarted_ || manualSessionControlEnabled_) {
                Countly.sharedInstance().onStart(activity);
            }
            Countly.sharedInstance().apm().triggerForeground();
        } else {
            isOnResumeBeforeInit = true;
        }
    }

    @Override
    public void onResume(@NonNull LifecycleOwner owner) {
        log("onResume", LogLevel.INFO);
    }

    @Override
    public void onPause(@NonNull LifecycleOwner owner) {
        log("onPause", LogLevel.INFO);
        if (Countly.sharedInstance().isInitialized()) {
            Countly.sharedInstance().apm().triggerBackground();
        }
    }

    @Override
    public void onStop(@NonNull LifecycleOwner owner) {
        log("onStop", LogLevel.INFO);
        if (isSessionStarted_ || manualSessionControlEnabled_) {
            Countly.sharedInstance().onStop();
        }
    }

    @Override
    public void onDestroy(@NonNull LifecycleOwner owner) {
        log("onDestroy", LogLevel.INFO);
    }

    public CountlyFlutterPlugin() {
        log("CountlyFlutterPlugin", LogLevel.INFO);
    }

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
            log("Method arguments: " + argsString, LogLevel.INFO);

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

                if (activity == null) {
                    log("Activity is 'null' during init, cannot set Application", LogLevel.WARNING);
                } else {
                    this.config.setApplication(activity.getApplication());
                }
                Countly.sharedInstance().init(this.config);
                if (isOnResumeBeforeInit) {
                    isOnResumeBeforeInit = false;
                    Countly.sharedInstance().apm().triggerForeground();
                }
                result.success("initialized!");
            } else if ("isInitialized".equals(call.method)) {
                boolean isInitialized = Countly.sharedInstance().isInitialized();
                if (isInitialized) {
                    result.success("true");

                } else {
                    result.success("false");
                }
            } else if ("getCurrentDeviceId".equals(call.method)) {
                String deviceID = Countly.sharedInstance().deviceId().getID();
                result.success(deviceID);
            } else if ("getDeviceIDType".equals(call.method)) {
                DeviceIdType deviceIDType = Countly.sharedInstance().deviceId().getType();
                String deviceIDTypeString = null;
                switch (deviceIDType) {
                    case DEVELOPER_SUPPLIED:
                        deviceIDTypeString = "DS";
                        break;
                    case OPEN_UDID:
                    case ADVERTISING_ID:
                    default:
                        deviceIDTypeString = "SG";
                        break;
                    case TEMPORARY_ID:
                        deviceIDTypeString = "TID";
                        break;
                }
                result.success(deviceIDTypeString);
            } else if ("changeDeviceId".equals(call.method)) {
                String newDeviceID = args.getString(0);
                String onServerString = args.getString(1);
                if (newDeviceID.equals("TemporaryDeviceID")) {
                    Countly.sharedInstance().deviceId().enableTemporaryIdMode();
                } else {
                    if ("1".equals(onServerString)) {
                        Countly.sharedInstance().deviceId().changeWithMerge(newDeviceID);
                    } else {
                        Countly.sharedInstance().deviceId().changeWithoutMerge(newDeviceID);
                    }
                }
                result.success("changeDeviceId success!");
            } else if ("enableTemporaryIdMode".equals(call.method)) {
                Countly.sharedInstance().deviceId().enableTemporaryIdMode();
                result.success("enableTemporaryIdMode This method doesn't exists!");
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
                String countryCode = null;
                String city = null;
                String gpsCoordinates = null;
                String ipAddress = null;

                if (location.has("countryCode")) {
                    countryCode = location.getString("countryCode");
                }
                if (location.has("city")) {
                    city = location.getString("city");
                }
                if (location.has("gpsCoordinates")) {
                    gpsCoordinates = location.getString("gpsCoordinates");
                }
                if (location.has("ipAddress")) {
                    ipAddress = location.getString("ipAddress");
                }

                Countly.sharedInstance().location().setLocation(countryCode, city, gpsCoordinates, ipAddress);
                result.success("setUserLocation success!");
            } else if ("enableCrashReporting".equals(call.method)) {
                this.config.enableCrashReporting();
                // Countly.sharedInstance().enableCrashReporting();
                result.success("enableCrashReporting success!");
            } else if ("addCrashLog".equals(call.method)) {
                String record = args.getString(0);
                Countly.sharedInstance().crashes().addCrashBreadcrumb(record);
                // Countly.sharedInstance().addCrashBreadcrumb(record);
                result.success("addCrashLog success!");
            } else if ("logException".equals(call.method)) {
                String exceptionString = args.getString(0);
                boolean fatal = args.getBoolean(1);
                Exception exception = new Exception(exceptionString);
                Map<String, Object> segments = new HashMap<>();
                for (int i = 2, il = args.length(); i < il; i += 2) {
                    segments.put(args.getString(i), args.getString(i + 1));
                }
                if (fatal) {
                    Countly.sharedInstance().crashes().recordUnhandledException(exception, segments);
                } else {
                    Countly.sharedInstance().crashes().recordHandledException(exception, segments);
                }

                result.success("logException success!");
            } else if ("setCustomCrashSegment".equals(call.method)) {
                Map<String, Object> segments = new HashMap<>();
                for (int i = 0, il = args.length(); i < il; i += 2) {
                    segments.put(args.getString(i), args.getString(i + 1));
                }
                this.config.setCustomCrashSegment(segments);

                result.success("setCustomCrashSegment success!");
            } else if ("sendPushToken".equals(call.method)) {
                String token = args.getString(0);
                CountlyPush.onTokenRefresh(token);
                result.success(" success!");
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
                CountlyPush.init(activity.getApplication(), pushTokenType);
                FirebaseApp.initializeApp(context);
                FirebaseInstanceId.getInstance().getInstanceId()
                        .addOnCompleteListener(new OnCompleteListener<InstanceIdResult>() {
                            @Override
                            public void onComplete(@NonNull Task<InstanceIdResult> task) {
                                if (!task.isSuccessful()) {
                                    log("getInstanceId failed", task.getException(), LogLevel.WARNING);
                                    return;
                                }
                                String token = task.getResult().getToken();
                                CountlyPush.onTokenRefresh(token);
                            }
                        });
                result.success(" askForNotificationPermission!");
            } else if ("pushTokenType".equals(call.method)) {
                String tokenType = args.getString(0);
                if ("2".equals(tokenType)) {
                    pushTokenType = Countly.CountlyMessagingMode.TEST;
                } else {
                    pushTokenType = Countly.CountlyMessagingMode.PRODUCTION;
                }
                result.success("pushTokenType!");
            } else if ("registerForNotification".equals(call.method)) {
                registerForNotification(args, new Callback() {
                    @Override
                    public void callback(final String resultString) {
                        if (activity != null) {
                            activity.runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    result.success(resultString);
                                }
                            });
                        }
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

            } else if ("start".equals(call.method)) {
                if (isSessionStarted_) {
                    log("session already started", LogLevel.INFO);
                    result.error("Start Failed", "session already started", null);
                    return;
                }
                if (activity == null) {
                    log("start failed : Activity is null", LogLevel.ERROR);
                    result.error("Start Failed", "Activity is null", null);
                    return;
                }
                Countly.sharedInstance().onStart(activity);
                isSessionStarted_ = true;
                result.success("started!");
            } else if ("manualSessionHandling".equals(call.method)) {
                result.success("deafult!");

            } else if ("stop".equals(call.method)) {
                if (!isSessionStarted_) {
                    log("must call Start before Stop", LogLevel.INFO);
                    result.error("Stop Failed", "must call Start before Stop", null);
                    return;
                }
                Countly.sharedInstance().onStop();
                isSessionStarted_ = false;
                result.success("stoped!");

            } else if ("updateSessionPeriod".equals(call.method)) {
                result.success("default!");

            } else if ("updateSessionInterval".equals(call.method)) {
                int sessionInterval = Integer.parseInt(args.getString(0));
                this.config.setUpdateSessionTimerDelay(sessionInterval);
                result.success("updateSessionInterval Success!");

            } else if ("eventSendThreshold".equals(call.method)) {
                int queueSize = Integer.parseInt(args.getString(0));
                this.config.setEventQueueSizeToSend(queueSize);
                result.success("default!");

            } else if ("storedRequestsLimit".equals(call.method)) {
                int queueSize = Integer.parseInt(args.getString(0));
                result.success("default!");

            } else if ("startEvent".equals(call.method)) {
                String startEvent = args.getString(0);
                Countly.sharedInstance().events().startEvent(startEvent);
            } else if ("endEvent".equals(call.method)) {
                String key = args.getString(0);
                int count = Integer.parseInt(args.getString(1));
                float sum = Float.parseFloat(args.getString(2)); // new Float(args.getString(2)).floatValue();
                HashMap<String, Object> segmentation = new HashMap<>();
                if (args.length() > 3) {
                    for (int i = 3, il = args.length(); i < il; i += 2) {
                        segmentation.put(args.getString(i), args.getString(i + 1));
                    }
                }
                Countly.sharedInstance().events().endEvent(key, segmentation, count, sum);
                result.success("endEvent for: " + key);
            } else if ("recordEvent".equals(call.method)) {
                String key = args.getString(0);
                int count = Integer.parseInt(args.getString(1));
                float sum = Float.parseFloat(args.getString(2)); // new Float(args.getString(2)).floatValue();
                int duration = Integer.parseInt(args.getString(3));
                HashMap<String, Object> segmentation = new HashMap<>();
                if (args.length() > 4) {
                    for (int i = 4, il = args.length(); i < il; i += 2) {
                        segmentation.put(args.getString(i), args.getString(i + 1));
                    }
                }
                Countly.sharedInstance().events().recordEvent(key, segmentation, count, sum, duration);
                result.success("recordEvent for: " + key);
            } else if ("setLoggingEnabled".equals(call.method)) {
                String loggingEnable = args.getString(0);
                // Countly.sharedInstance().setLoggingEnabled(true);
                // Countly.sharedInstance().setLoggingEnabled(false);
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

            //setRequiresConsent
            else if ("setRequiresConsent".equals(call.method)) {
                boolean consentFlag = args.getBoolean(0);
                this.config.setRequiresConsent(consentFlag);
                result.success("setRequiresConsent!");
            } else if ("giveConsentInit".equals(call.method)) {
                String[] features = new String[args.length()];
                for (int i = 0; i < args.length(); i++) {
                    features[i] = args.getString(i);
                }
                this.config.setConsentEnabled(features);
                result.success("giveConsent!");

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
            } else if ("recordView".equals(call.method)) {
                String viewName = args.getString(0);
                Map<String, Object> segments = new HashMap<>();
                int il = args.length();
                if (il > 2) {
                    for (int i = 1; i < il; i += 2) {
                        try {
                            segments.put(args.getString(i), args.getString(i + 1));
                        } catch (Exception exception) {
                            log("recordView, could not parse segments, skipping it. ", exception, LogLevel.ERROR);
                        }
                    }
                }
                Countly.sharedInstance().views().recordView(viewName, segments);
                result.success("View name sent: " + viewName);
            } else if ("setOptionalParametersForInitialization".equals(call.method)) {
                String city = args.getString(0);
                String country = args.getString(1);
                String latitude = args.getString(2);
                String longitude = args.getString(3);
                String ipAddress = args.getString(4);
                String latlng = null;
                if (city.length() == 0) {
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
            } else if ("setRemoteConfigAutomaticDownload".equals(call.method)) {
                this.config.setRemoteConfigAutomaticDownload(true, new RemoteConfigCallback() {
                    @Override
                    public void callback(String error) {
                        if (error == null) {
                            result.success("Success");
                        } else {
                            result.success("Error: " + error);
                        }
                    }
                });

            } else if ("remoteConfigUpdate".equals(call.method)) {
                Countly.sharedInstance().remoteConfig().update(new RemoteConfigCallback() {
                    @Override
                    public void callback(String error) {
                        if (error == null) {
                            result.success("Success");
                        } else {
                            result.success("Error: " + error);
                        }
                    }
                });
            } else if ("updateRemoteConfigForKeysOnly".equals(call.method)) {
                String[] keysOnly = new String[args.length()];
                for (int i = 0, il = args.length(); i < il; i++) {
                    keysOnly[i] = args.getString(i);
                }

                Countly.sharedInstance().remoteConfig().updateForKeysOnly(keysOnly, new RemoteConfigCallback() {
                    @Override
                    public void callback(String error) {
                        if (error == null) {
                            result.success("Success");
                        } else {
                            result.success("Error: " + error);
                        }
                    }
                });
            } else if ("updateRemoteConfigExceptKeys".equals(call.method)) {
                String[] exceptKeys = new String[args.length()];
                for (int i = 0, il = args.length(); i < il; i++) {
                    exceptKeys[i] = args.getString(i);
                }

                Countly.sharedInstance().remoteConfig().updateExceptKeys(exceptKeys, new RemoteConfigCallback() {
                    @Override
                    public void callback(String error) {
                        if (error == null) {
                            result.success("Success");
                        } else {
                            result.success("Error: " + error);
                        }
                    }
                });
            } else if ("remoteConfigClearValues".equals(call.method)) {
                Countly.sharedInstance().remoteConfig().clearStoredValues();
                result.success("remoteConfigClearValues: success");
            } else if ("getRemoteConfigValueForKey".equals(call.method)) {
                String key = args.getString(0);
                String remoteConfigValueForKey = "No value Found against Key :" + key;
                Object getRemoteConfigValueForKeyResult = Countly.sharedInstance().remoteConfig().getValueForKey(key);
                if (getRemoteConfigValueForKeyResult != null)
                    remoteConfigValueForKey = getRemoteConfigValueForKeyResult.toString();
                result.success(remoteConfigValueForKey);
            } else if ("remoteConfigDownloadValues".equals(call.method)) {
                int requestID = args.getInt(0);

                //todo native implementation

                log("remoteConfigDownloadValues TEST, " + requestID, LogLevel.WARNING);

                result.success(null);
            } else if ("remoteConfigDownloadSpecificValue".equals(call.method)) {
                int requestID = args.getInt(0);
                JSONArray jArr = args.getJSONArray(1);

                String[] keysOnly = new String[jArr.length()];
                for (int i = 0, il = jArr.length(); i < il; i++) {
                    keysOnly[i] = jArr.getString(i);
                }

                log("remoteConfigDownloadSpecificValue TEST, " + requestID + " , " + keysOnly, LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigDownloadOmittingValues".equals(call.method)) {
                int requestID = args.getInt(0);
                JSONArray jArr = args.getJSONArray(1);

                String[] omitedKeys = new String[jArr.length()];
                for (int i = 0, il = jArr.length(); i < il; i++) {
                    omitedKeys[i] = jArr.getString(i);
                }

                log("remoteConfigDownloadOmittingValues TEST, " + requestID + " , " + omitedKeys, LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigGetAllValues".equals(call.method)) {
                log("remoteConfigGetAllValues TEST", LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigGetValue".equals(call.method)) {
                String key = args.getString(0);
                log("remoteConfigGetValue TEST, " + key, LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigClearAllValues".equals(call.method)) {
                log("remoteConfigClearAllValues", LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigEnrollIntoABTestsForKeys".equals(call.method)) {
                JSONArray keys = args;

                log("remoteConfigEnrollIntoABTestsForKeys TEST, " + keys, LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigExitABTestsForKeys".equals(call.method)) {
                JSONArray keys = args;

                log("remoteConfigExitABTestsForKeys TEST, " + keys, LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigGetVariantsForKey".equals(call.method)) {
                String key = args.getString(0);
                log("remoteConfigGetVariantsForKey TEST, " + key, LogLevel.WARNING);

                //todo native implementation

                result.success(null); //
            } else if ("remoteConfigTestingGetVariantsForKey".equals(call.method)) {
                log("remoteConfigTestingGetVariantsForKey", LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigTestingGetAllVariants".equals(call.method)) {
                log("remoteConfigTestingGetAllVariants", LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigTestingDownloadVariantInformation".equals(call.method)) {
                log("remoteConfigTestingDownloadVariantInformation", LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigTestingEnrollIntoVariant".equals(call.method)) {
                log("remoteConfigTestingEnrollIntoVariant", LogLevel.WARNING);

                //todo native implementation

                result.success(null);
            } else if ("remoteConfigGetAllVariants".equals(call.method)) {
                log("remoteConfigGetAllVariants TEST, ", LogLevel.WARNING);

                //todo native implementation

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
                        methodChannel.invokeMethod("ratingWidgetCallback", error);
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
                    String errorMessage = "No feedbackWidget is found against widget id : '" + widgetId + "' , always call 'getFeedbackWidgets' to get updated list of feedback widgets.";
                    log(errorMessage, LogLevel.WARNING);
                    result.error("presentFeedbackWidget", errorMessage, null);
                } else {
                    Countly.sharedInstance().feedback().presentFeedbackWidget(feedbackWidget, activity, closeBtnText, new FeedbackCallback() {
                        @Override
                        public void onFinished(String error) {
                            if (error != null) {
                                result.error("presentFeedbackWidget", error, null);
                            } else {
                                methodChannel.invokeMethod("widgetShown", null);
                                result.success("presentFeedbackWidget success");
                            }
                        }

                        @Override
                        public void onClosed() {
                            methodChannel.invokeMethod("widgetClosed", null);
                        }
                    });
                }
            } else if ("getFeedbackWidgetData".equals(call.method)) {
                String widgetId = args.getString(0);
                CountlyFeedbackWidget feedbackWidget = getFeedbackWidget(widgetId);
                if (feedbackWidget == null) {
                    String errorMessage = "No feedbackWidget is found against widget id : '" + widgetId + "' , always call 'getFeedbackWidgets' to get updated list of feedback widgets.";
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

                CountlyFeedbackWidget feedbackWidget = getFeedbackWidget(widgetId);
                if (feedbackWidget == null) {
                    String errorMessage = "No feedbackWidget is found against widget id : '" + widgetId + "' , always call 'getFeedbackWidgets' to get updated list of feedback widgets.";
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
            } else if ("enableApm".equals(call.method)) {
                this.config.setRecordAppStartTime(true);
                result.success("enableApm: success");
            } else if ("throwNativeException".equals(call.method)) {
                throw new IllegalStateException("Native Exception Crashhh!");
//            throw new RuntimeException("Native Exception Crash!");

            } else if ("recordIndirectAttribution".equals(call.method)) {
                JSONObject attributionValues = args.getJSONObject(0);
                if (attributionValues != null && attributionValues.length() > 0) {
                    Map<String, String> attributionMap = toMapString(attributionValues);
                    Countly.sharedInstance().attribution().recordIndirectAttribution(attributionMap);
                    result.success("recordIndirectAttribution: success");
                } else {
                    result.error("iaAttributionFailed", "recordIndirectAttribution: failure, no attribution values provided", null);
                }
            } else if ("recordDirectAttribution".equals(call.method)) {
                String campaignType = args.getString(0);
                String campaignData = args.getString(1);

                Countly.sharedInstance().attribution().recordDirectAttribution(campaignType, campaignData);
                result.success("recordIndirectAttribution: success");
            } else if ("appLoadingFinished".equals(call.method)) {
                Countly.sharedInstance().apm().setAppIsLoaded();
                result.success("appLoadingFinished: success");
            } else {
                result.notImplemented();
            }

        } catch (JSONException jsonException) {
            result.success(jsonException.toString());
        }
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
        methodChannel.invokeMethod("feedbackWidgetDataCallback", feedbackWidgetData);
    }

    public String registerForNotification(JSONArray args, final Callback theCallback) {
        notificationListener = theCallback;
        if (Countly.sharedInstance().isLoggingEnabled()) {
            log("registerForNotification theCallback", LogLevel.INFO);
        }
        if (lastStoredNotification != null) {
            theCallback.callback(lastStoredNotification);
            lastStoredNotification = null;
        }
        return "pushTokenType: success";
    }

    public static void onNotification(Map<String, String> notification) {
        JSONObject json = new JSONObject(notification);
        String notificationString = json.toString();
        log(notificationString, LogLevel.INFO);
        if (notificationListener != null) {
            notificationListener.callback(notificationString);
        } else {
            lastStoredNotification = notificationString;
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
        manualSessionControlEnabled_ = true;
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
            if (deviceID.equals("TemporaryDeviceID")) {
                this.config.enableTemporaryDeviceIdMode();

            } else {
                this.config.setDeviceId(deviceID);
            }
        }
        if (_config.has("loggingEnabled")) {
            this.config.setLoggingEnabled(_config.getBoolean("loggingEnabled"));
        }
        if (_config.has("httpPostForced")) {
            this.config.setHttpPostForced(_config.getBoolean("httpPostForced"));
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
            this.config.setCustomCrashSegment(customCrashSegment);
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
        if (_config.has("recordAppStartTime")) {
            this.config.setRecordAppStartTime(_config.getBoolean("recordAppStartTime"));
        }
        if (_config.has("enableUnhandledCrashReporting") && _config.getBoolean("enableUnhandledCrashReporting")) {
            this.config.enableCrashReporting();
        }

        if (_config.has("maxRequestQueueSize")) {
            this.config.setMaxRequestQueueSize(_config.getInt("maxRequestQueueSize"));
        }

        if (_config.has("manualSessionEnabled") && _config.getBoolean("manualSessionEnabled")) {
            enableManualSessionControl();
        }

        if (_config.has("enableRemoteConfigAutomaticDownload")) {
            boolean enableRemoteConfigAutomaticDownload = _config.getBoolean("enableRemoteConfigAutomaticDownload");
            this.config.setRemoteConfigAutomaticDownload(enableRemoteConfigAutomaticDownload, new RemoteConfigCallback() {
                @Override
                public void callback(String error) {
                    methodChannel.invokeMethod("remoteConfigCallback", error);
                }
            });
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


    }
}
