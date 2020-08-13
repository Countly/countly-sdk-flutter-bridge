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
import ly.count.android.sdk.DeviceId;
import ly.count.android.sdk.FeedbackRatingCallback;
import ly.count.android.sdk.RemoteConfig;
import java.util.HashMap;
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

/** CountlyFlutterPlugin */
public class CountlyFlutterPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware, DefaultLifecycleObserver {
    private String COUNTLY_FLUTTER_SDK_VERSION_STRING = "20.04.1";
    private String COUNTLY_FLUTTER_SDK_NAME = "dart-flutterb-android";

    /** Plugin registration. */
    private Countly.CountlyMessagingMode pushTokenType = Countly.CountlyMessagingMode.PRODUCTION;
    private Context context;
    private Activity activity;
    private Boolean isDebug = false;
    private CountlyConfig config = null;
    private static Callback notificationListener = null;
    private static String lastStoredNotification = null;
    private MethodChannel methodChannel;
    private Lifecycle lifecycle;
    private Boolean isSessionStarted_ = false;

    public static void registerWith(Registrar registrar) {
        final CountlyFlutterPlugin instance = new CountlyFlutterPlugin();
        instance.activity  = registrar.activity();
        final Context __context = registrar.context();
        instance.onAttachedToEngineInternal(__context, registrar.messenger());
        if(instance.isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] registerWith");
        }
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        onAttachedToEngineInternal(binding.getApplicationContext(), binding.getBinaryMessenger());
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onAttachedToEngine");
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        context = null;
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onDetachedFromEngine");
        }
    }

    private void onAttachedToEngineInternal(Context context, BinaryMessenger messenger) {
        this.context = context;
        methodChannel = new MethodChannel(messenger, "countly_flutter");
        methodChannel.setMethodCallHandler(this);
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onAttachedToEngineInternal");
        }
    }


    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
        lifecycle.addObserver(this);
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onAttachedToActivity : Activity attached!");
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        lifecycle.removeObserver(this);
        this.activity = null;
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onDetachedFromActivityForConfigChanges : Activity is no more valid");
        }
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
        lifecycle.addObserver(this);
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onReattachedToActivityForConfigChanges : Activity attached!");
        }
    }

    @Override
    public void onDetachedFromActivity() {
        lifecycle.removeObserver(this);
        this.activity = null;
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onDetachedFromActivity : Activity is no more valid");
        }
    }

    // DefaultLifecycleObserver callbacks

    @Override
    public void onCreate(@NonNull LifecycleOwner owner) {
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onCreate");
        }

    }

    @Override
    public void onStart(@NonNull LifecycleOwner owner) {
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onStart");
        }
        if(isSessionStarted_) {
            Countly.sharedInstance().onStart(activity);
        }
    }

    @Override
    public void onResume(@NonNull LifecycleOwner owner) {
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onResume");
        }
    }

    @Override
    public void onPause(@NonNull LifecycleOwner owner) {
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onPause");
        }
    }

    @Override
    public void onStop(@NonNull LifecycleOwner owner) {
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onStop");
        }
        if(isSessionStarted_) {
            Countly.sharedInstance().onStop();
        }
    }

    @Override
    public void onDestroy(@NonNull LifecycleOwner owner) {
        if(isDebug || Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] onDestroy");
        }
    }

  private void setConfig(){
      if(this.config == null){
          this.config = new CountlyConfig();
      }
  }

  public CountlyFlutterPlugin() {

  }
  @Override
  public void onMethodCall(MethodCall call, final Result result) {
    String argsString = (String) call.argument("data");
      if (argsString == null) {
          argsString = "[]";
      }
      JSONArray args = null;
      try {
          args = new JSONArray(argsString);

          if (isDebug) {
              Log.i(Countly.TAG, "[CountlyFlutterPlugin] Method name: " + call.method);
              Log.i(Countly.TAG, "[CountlyFlutterPlugin] Method arguments: " + argsString);
          }

          if ("init".equals(call.method)) {
              if(context == null) {
                  if(Countly.sharedInstance().isLoggingEnabled()) {
                      Log.e(Countly.TAG, "[CountlyFlutterPlugin] valid context is required in Countly init, but was provided 'null'");
                  }
                  result.error("init Failed", "valid context is required in Countly init, but was provided 'null'", null);
                  return;
              }
              String serverUrl = args.getString(0);
              String appKey = args.getString(1);
              this.setConfig();
              this.config.setContext(context);
              this.config.setServerURL(serverUrl);
              this.config.setAppKey(appKey);
              Countly.sharedInstance().COUNTLY_SDK_NAME = COUNTLY_FLUTTER_SDK_NAME;
              Countly.sharedInstance().COUNTLY_SDK_VERSION_STRING = COUNTLY_FLUTTER_SDK_VERSION_STRING;

              if (args.length() == 2) {
                  this.config.setIdMode(DeviceId.Type.OPEN_UDID);

              } else if (args.length() == 3) {
                  String yourDeviceID = args.getString(2);
                  if (yourDeviceID.equals("TemporaryDeviceID")) {
                      this.config.enableTemporaryDeviceIdMode();
                  } else {
                      this.config.setDeviceId(yourDeviceID);
                  }
              } else {
                  this.config.setIdMode(DeviceId.Type.ADVERTISING_ID);
              }
              Countly.sharedInstance().init(this.config);
              result.success("initialized!");
        } else if ("isInitialized".equals(call.method)) {
            Boolean isInitialized = Countly.sharedInstance().isInitialized();
            if(isInitialized){
                result.success("true");

            }else{
                result.success("false");
            }
        }else if ("changeDeviceId".equals(call.method)) {
              String newDeviceID = args.getString(0);
              String onServerString = args.getString(1);
              if(newDeviceID.equals("TemporaryDeviceID")){
                Countly.sharedInstance().enableTemporaryIdMode();
              }else{
                if ("1".equals(onServerString)) {
                    Countly.sharedInstance().changeDeviceIdWithMerge(newDeviceID);
                } else {
                    Countly.sharedInstance().changeDeviceIdWithoutMerge(DeviceId.Type.DEVELOPER_SUPPLIED, newDeviceID);
                }
              }
              result.success("changeDeviceId success!");
          } else if ("enableTemporaryIdMode".equals(call.method)) {
              Countly.sharedInstance().enableTemporaryIdMode();
              result.success("enableTemporaryIdMode This method doesn't exists!");
          } else if ("setHttpPostForced".equals(call.method)) {
              int isEnabled = Integer.parseInt(args.getString(0));
              this.setConfig();
              if (isEnabled == 1) {
                  this.config.setHttpPostForced(true);
              } else {
                  this.config.setHttpPostForced(false);
              }
              result.success("setHttpPostForced");
          } else if ("enableParameterTamperingProtection".equals(call.method)) {
              String salt = args.getString(0);
              this.setConfig();
              this.config.setParameterTamperingProtectionSalt(salt);
              result.success("enableParameterTamperingProtection success!");
          } else if ("setLocation".equals(call.method)) {
              String latitude = args.getString(0);
              String longitude = args.getString(1);
              if(!latitude.equals("null") && !longitude.equals("null")) {
                String latlng = latitude + "," + longitude;
                Countly.sharedInstance().setLocation(null, null, latlng, null);
              }
              result.success("setLocation success!");
          } else if ("enableCrashReporting".equals(call.method)) {
              this.setConfig();
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
              Boolean fatal = args.getBoolean(1);
              Exception exception = new Exception(exceptionString);
              if(fatal) {
                  Countly.sharedInstance().crashes().recordUnhandledException(exception);
              } else {
                  Countly.sharedInstance().crashes().recordHandledException(exception);
              }

              result.success("logException success!");
          } else if ("sendPushToken".equals(call.method)) {
              String token = args.getString(0);
              int messagingMode = Integer.parseInt(args.getString(1));
              if (messagingMode == 0) {
                  // Countly.sharedInstance().sendPushToken(token, Countly.CountlyMessagingMode.PRODUCTION);
              } else {
                  // Countly.sharedInstance().sendPushToken(token, Countly.CountlyMessagingMode.TEST);
              }
              result.success(" success!");
          } else if ("askForNotificationPermission".equals(call.method)) {
              if (activity == null) {
                  if(Countly.sharedInstance().isLoggingEnabled()) {
                      Log.e(Countly.TAG, "[CountlyFlutterPlugin] askForNotificationPermission failed : Activity is null");
                  }
                  result.error("askForNotificationPermission Failed", "Activity is null", null);
                  return;
              }
              if(context == null) {
                  if(Countly.sharedInstance().isLoggingEnabled()) {
                      Log.e(Countly.TAG, "[CountlyFlutterPlugin] valid context is required in askForNotificationPermission, but was provided 'null'");
                  }
                  result.error("askForNotificationPermission Failed", "valid context is required in Countly askForNotificationPermission, but was provided 'null'", null);
                  return;
              }
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                  String channelName = "Default Name";
                  String channelDescription = "Default Description";
                  NotificationManager notificationManager = (NotificationManager) context.getSystemService(context.NOTIFICATION_SERVICE);
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
                          public void onComplete(Task<InstanceIdResult> task) {
                              if (!task.isSuccessful()) {
                                  if (Countly.sharedInstance().isLoggingEnabled()) {
                                      Log.w(Countly.TAG, "[CountlyFlutterPlugin] getInstanceId failed", task.getException());
                                  }
                                  return;
                              }
                              String token = task.getResult().getToken();
                              CountlyPush.onTokenRefresh(token);
                          }
                      });
              result.success(" askForNotificationPermission!");
          } else if ("pushTokenType".equals(call.method)) {
              String tokenType = args.getString(0);
              if("2".equals(tokenType)){
                  pushTokenType = Countly.CountlyMessagingMode.TEST;
              }else{
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
          } else if ("start".equals(call.method)) {
              if (activity == null) {
                  if(Countly.sharedInstance().isLoggingEnabled()) {
                      Log.e(Countly.TAG, "[CountlyFlutterPlugin] start failed : Activity is null");
                  }
                  result.error("Start Failed", "Activity is null", null);
                  return;
              }
              Countly.sharedInstance().onStart(activity);
              isSessionStarted_ = true;
              result.success("started!");
          } else if ("manualSessionHandling".equals(call.method)) {
              result.success("deafult!");

          } else if ("stop".equals(call.method)) {
              Countly.sharedInstance().onStop();
              isSessionStarted_ = false;
              result.success("stoped!");

          } else if ("updateSessionPeriod".equals(call.method)) {
              result.success("default!");

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
              float sum = Float.valueOf(args.getString(2)); // new Float(args.getString(2)).floatValue();
              HashMap<String, Object> segmentation = new HashMap<String, Object>();
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
              float sum = Float.valueOf(args.getString(2)); // new Float(args.getString(2)).floatValue();
              int duration = Integer.parseInt(args.getString(3));
              HashMap<String, Object> segmentation = new HashMap<String, Object>();
              if (args.length() > 4) {
                  for (int i = 4, il = args.length(); i < il; i += 2) {
                      segmentation.put(args.getString(i), args.getString(i + 1));
                  }
              }
              Countly.sharedInstance().events().recordEvent(key, segmentation, count, sum, duration);
              result.success("recordEvent for: " + key);
          } else if ("setLoggingEnabled".equals(call.method)) {
              String loggingEnable = args.getString(0);
              this.setConfig();
              if (loggingEnable.equals("true")) {
                  this.config.setLoggingEnabled(true);
                  // Countly.sharedInstance().setLoggingEnabled(true);
              } else {
                  this.config.setLoggingEnabled(false);
                  // Countly.sharedInstance().setLoggingEnabled(false);
              }
              result.success("setLoggingEnabled success!");
          } else if ("setuserdata".equals(call.method)) {
              Map<String, String> bundle = new HashMap<String, String>();

              bundle.put("name", args.getString(0));
              bundle.put("username", args.getString(1));
              bundle.put("email", args.getString(2));
              bundle.put("organization", args.getString(3));
              bundle.put("phone", args.getString(4));
              bundle.put("picture", args.getString(5));
              bundle.put("picturePath", args.getString(6));
              bundle.put("gender", args.getString(7));
              bundle.put("byear", args.getString(8));

              Countly.userData.setUserData(bundle);
              Countly.userData.save();

              result.success("setuserdata success");
          } else if ("userData_setProperty".equals(call.method)) {
              String keyName = args.getString(0);
              String keyValue = args.getString(1);
              Countly.userData.setProperty(keyName, keyValue);
              Countly.userData.save();
              result.success("userData_setProperty success!");
          } else if ("userData_increment".equals(call.method)) {
              String keyName = args.getString(0);
              Countly.userData.increment(keyName);
              Countly.userData.save();
              result.success("userData_increment success!");
          } else if ("userData_incrementBy".equals(call.method)) {
              String keyName = args.getString(0);
              int keyIncrement = Integer.parseInt(args.getString(1));
              Countly.userData.incrementBy(keyName, keyIncrement);
              Countly.userData.save();
              result.success("userData_incrementBy success!");
          } else if ("userData_multiply".equals(call.method)) {
              String keyName = args.getString(0);
              int multiplyValue = Integer.parseInt(args.getString(1));
              Countly.userData.multiply(keyName, multiplyValue);
              Countly.userData.save();
              result.success("userData_multiply success!");
          } else if ("userData_saveMax".equals(call.method)) {
              String keyName = args.getString(0);
              int maxScore = Integer.parseInt(args.getString(1));
              Countly.userData.saveMax(keyName, maxScore);
              Countly.userData.save();
              result.success("userData_saveMax success!");
          } else if ("userData_saveMin".equals(call.method)) {
              String keyName = args.getString(0);
              int minScore = Integer.parseInt(args.getString(1));
              Countly.userData.saveMin(keyName, minScore);
              Countly.userData.save();
              result.success("userData_saveMin success!");
          } else if ("userData_setOnce".equals(call.method)) {
              String keyName = args.getString(0);
              String minScore = args.getString(1);
              Countly.userData.setOnce(keyName, minScore);
              Countly.userData.save();
              result.success("userData_setOnce success!");
          } else if ("userData_pushUniqueValue".equals(call.method)) {
              String type = args.getString(0);
              String pushUniqueValue = args.getString(1);
              Countly.userData.pushUniqueValue(type, pushUniqueValue);
              Countly.userData.save();
              result.success("userData_pushUniqueValue success!");
          } else if ("userData_pushValue".equals(call.method)) {
              String type = args.getString(0);
              String pushValue = args.getString(1);
              Countly.userData.pushValue(type, pushValue);
              Countly.userData.save();
              result.success("userData_pushValue success!");
          } else if ("userData_pullValue".equals(call.method)) {
              String type = args.getString(0);
              String pullValue = args.getString(1);
              Countly.userData.pullValue(type, pullValue);
              Countly.userData.save();
              result.success("userData_pullValue success!");
          }

          //setRequiresConsent
          else if ("setRequiresConsent".equals(call.method)) {
              Boolean consentFlag = args.getBoolean(0);
              this.setConfig();
              this.config.setRequiresConsent(consentFlag);
              result.success("setRequiresConsent!");
          } else if ("giveConsent".equals(call.method)) {
              List<String> features = new ArrayList<>();
              for (int i = 0; i < args.length(); i++) {
                  String theConsent = args.getString(i);
                  if (theConsent.equals("sessions")) {
                      Countly.sharedInstance().consent().giveConsent(new String[]{Countly.CountlyFeatureNames.sessions});
                  }
                  if (theConsent.equals("events")) {
                      Countly.sharedInstance().consent().giveConsent(new String[]{Countly.CountlyFeatureNames.events});
                  }
                  if (theConsent.equals("views")) {
                      Countly.sharedInstance().consent().giveConsent(new String[]{Countly.CountlyFeatureNames.views});
                  }
                  if (theConsent.equals("location")) {
                      Countly.sharedInstance().consent().giveConsent(new String[]{Countly.CountlyFeatureNames.location});
                  }
                  if (theConsent.equals("crashes")) {
                      Countly.sharedInstance().consent().giveConsent(new String[]{Countly.CountlyFeatureNames.crashes});
                  }
                  if (theConsent.equals("attribution")) {
                      Countly.sharedInstance().consent().giveConsent(new String[]{Countly.CountlyFeatureNames.attribution});
                  }
                  if (theConsent.equals("users")) {
                      Countly.sharedInstance().consent().giveConsent(new String[]{Countly.CountlyFeatureNames.users});
                  }
                  if (theConsent.equals("push")) {
                      Countly.sharedInstance().consent().giveConsent(new String[]{Countly.CountlyFeatureNames.push});
                  }
                  if (theConsent.equals("starRating")) {
                      Countly.sharedInstance().consent().giveConsent(new String[]{Countly.CountlyFeatureNames.starRating});
                  }
              }
              result.success("giveConsent!");

          } else if ("removeConsent".equals(call.method)) {
              List<String> features = new ArrayList<>();
              for (int i = 0; i < args.length(); i++) {
                  String theConsent = args.getString(i);
                  if (theConsent.equals("sessions")) {
                      Countly.sharedInstance().consent().removeConsent(new String[]{Countly.CountlyFeatureNames.sessions});
                  }
                  if (theConsent.equals("events")) {
                      Countly.sharedInstance().consent().removeConsent(new String[]{Countly.CountlyFeatureNames.events});
                  }
                  if (theConsent.equals("views")) {
                      Countly.sharedInstance().consent().removeConsent(new String[]{Countly.CountlyFeatureNames.views});
                  }
                  if (theConsent.equals("location")) {
                      Countly.sharedInstance().consent().removeConsent(new String[]{Countly.CountlyFeatureNames.location});
                  }
                  if (theConsent.equals("crashes")) {
                      Countly.sharedInstance().consent().removeConsent(new String[]{Countly.CountlyFeatureNames.crashes});
                  }
                  if (theConsent.equals("attribution")) {
                      Countly.sharedInstance().consent().removeConsent(new String[]{Countly.CountlyFeatureNames.attribution});
                  }
                  if (theConsent.equals("users")) {
                      Countly.sharedInstance().consent().removeConsent(new String[]{Countly.CountlyFeatureNames.users});
                  }
                  if (theConsent.equals("push")) {
                      Countly.sharedInstance().consent().removeConsent(new String[]{Countly.CountlyFeatureNames.push});
                  }
                  if (theConsent.equals("starRating")) {
                      Countly.sharedInstance().consent().removeConsent(new String[]{Countly.CountlyFeatureNames.starRating});
                  }
              }
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
              Map<String, Object> segments = new HashMap<String, Object>();
              int il = args.length();
              if (il > 2) {
                  for (int i = 1; i < il; i += 2) {
                      try{
                          segments.put(args.getString(i), args.getString(i + 1));
                      }catch(Exception exception){
                          if(Countly.sharedInstance().isLoggingEnabled()) {
                              Log.e(Countly.TAG, "[CountlyReactNative] recordView, could not parse segments, skipping it. ");
                          }
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
              if(city.length() == 0){
                  city = null;
              }
              if(country.equals("null")){
                  country = null;
              }
              if(!latitude.equals("null") && !longitude.equals("null")) {
                latlng = latitude + "," + longitude;
              }
              if(ipAddress.equals("null")){
                  ipAddress = null;
              }
              Countly.sharedInstance().setLocation(country, city, latlng, ipAddress);

              result.success("setOptionalParametersForInitialization sent.");
          } else if ("setRemoteConfigAutomaticDownload".equals(call.method)) {
              this.setConfig();
              this.config.setRemoteConfigAutomaticDownload(true, new RemoteConfig.RemoteConfigCallback() {
                  @Override
                  public void callback(String error) {
                      if (error == null) {
                          result.success("Success");
                      } else {
                          result.success("Error: " + error.toString());
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
                          result.success("Error: " + error.toString());
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
                          result.success("Error: " + error.toString());
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
                          result.success("Error: " + error.toString());
                      }
                  }
              });
          } else if ("remoteConfigClearValues".equals(call.method)) {
              Countly.sharedInstance().remoteConfig().clearStoredValues();
              result.success("remoteConfigClearValues: success");
          } else if ("getRemoteConfigValueForKey".equals(call.method)) {
              String getRemoteConfigValueForKeyResult = Countly.sharedInstance().remoteConfig().getValueForKey(args.getString(0)).toString();
              result.success(getRemoteConfigValueForKeyResult);
          } else if ("askForFeedback".equals(call.method)) {
              if (activity == null) {
                  if(Countly.sharedInstance().isLoggingEnabled()) {
                      Log.e(Countly.TAG, "[CountlyFlutterPlugin] askForFeedback failed : Activity is null");
                  }
                  result.error("askForFeedback Failed", "Activity is null", null);
                  return;
              }
              String widgetId = args.getString(0);
              String closeButtonText = args.getString(1);
              Countly.sharedInstance().ratings().showFeedbackPopup(widgetId, closeButtonText, activity, new FeedbackRatingCallback() {
                  @Override
                  public void callback(String error) {
                      if (error != null) {
                          result.success("Error: Encountered error while showing feedback dialog: [" + error + "]");
                      } else {
                          result.success("Feedback submitted.");
                      }
                  }
              });
          } else if (call.method.equals("askForStarRating")) {
              if (activity == null) {
                  if(Countly.sharedInstance().isLoggingEnabled()) {
                      Log.e(Countly.TAG, "[CountlyFlutterPlugin] askForStarRating failed : Activity is null");
                  }
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
          } else if ("throwNativeException".equals(call.method)) {
              throw new IllegalStateException("Native Exception Crashhh!");
//            throw new RuntimeException("Native Exception Crash!");

          } else if ("enableAttribution".equals(call.method)) {
              this.setConfig();
              this.config.setEnableAttribution(true);
              result.success("enableAttribution: success");
          } else {
              result.notImplemented();
          }

      } catch (JSONException jsonException) {
          result.success(jsonException.toString());
      }
  }
    public String registerForNotification(JSONArray args, final Callback theCallback){
        notificationListener = theCallback;
        if(Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] registerForNotification theCallback");
        }
        if(lastStoredNotification != null){
            theCallback.callback(lastStoredNotification);
            lastStoredNotification = null;
        }
        return "pushTokenType: success";
    }
    public static void onNotification(Map<String, String>  notification){
        JSONObject json = new JSONObject(notification);
        String notificationString = json.toString();
        if(Countly.sharedInstance().isLoggingEnabled()) {
            Log.i(Countly.TAG, "[CountlyFlutterPlugin] " + notificationString);
        }
        if(notificationListener != null){
            notificationListener.callback(notificationString);
        }else{
            lastStoredNotification = notificationString;
        }
    }
    public interface Callback {
        void callback(String result);
    }
}
