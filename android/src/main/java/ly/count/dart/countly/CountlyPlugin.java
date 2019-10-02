package ly.count.dart.countly;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import ly.count.android.sdk.Countly;
import ly.count.android.sdk.DeviceId;
import ly.count.android.sdk.RemoteConfig;
//import ly.count.android.sdk.DeviceInfo;
import java.util.HashMap;
import java.util.Map;
import android.app.Activity;
import android.content.Context;
import org.json.JSONArray;
import org.json.JSONException;
import android.util.Log;
import java.util.List;
import java.util.Set;
import java.util.HashSet;
import java.util.Arrays;
import java.util.ArrayList;

/** CountlyPlugin */
public class CountlyPlugin implements MethodCallHandler {
  /** Plugin registration. */
  Context context;
  Activity activity;
    private final Set<String> validConsentFeatureNames = new HashSet<String>(Arrays.asList(
            Countly.CountlyFeatureNames.sessions,
            Countly.CountlyFeatureNames.events,
            Countly.CountlyFeatureNames.views,
            Countly.CountlyFeatureNames.location,
            Countly.CountlyFeatureNames.crashes,
            Countly.CountlyFeatureNames.attribution,
            Countly.CountlyFeatureNames.users,
            Countly.CountlyFeatureNames.push,
            Countly.CountlyFeatureNames.starRating
    ));

  public static void registerWith(Registrar registrar) {
    final Activity __activity  = registrar.activity();
    final Context __context = registrar.context();

    final MethodChannel channel = new MethodChannel(registrar.messenger(), "countly");
    channel.setMethodCallHandler(new CountlyPlugin(__activity, __context));
  }

  public CountlyPlugin(Activity _activity, Context _context){
    this.activity = _activity;
    this.context= _context;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
      String argsString = (String)call.argument("data");
      if(argsString == null){
        argsString = "[]";
      }
      Log.w("Nicolson", call.method);
      Log.w("Nicolson", argsString);
      JSONArray args = null;
      try{
      args = new JSONArray(argsString);


      if ("init".equals(call.method)) {

        String serverUrl = args.getString(0);
        String appKey = args.getString(1);
        Log.i("Nicolson", serverUrl);
        Log.i("Nicolson", appKey);
        if(args.length() == 2){
            Countly.sharedInstance().init(context, serverUrl, appKey,null,DeviceId.Type.OPEN_UDID);
        }else if(args.length() == 3){
            String yourDeviceID = args.getString(2);
            Countly.sharedInstance()
                .init(context, serverUrl, appKey,yourDeviceID,null);
        }else{
            Countly.sharedInstance()
                .init(context, serverUrl, appKey,null,DeviceId.Type.ADVERTISING_ID);
        }

        Countly.sharedInstance().onStart(activity);
        result.success("initialized!");
    }


    else if ("changeDeviceId".equals(call.method)){
        String newDeviceID = args.getString(0);
        String onServerString = args.getString(1);
        if("1".equals(onServerString)){
            Countly.sharedInstance().changeDeviceId(newDeviceID);
        }else{
            Countly.sharedInstance().changeDeviceId(DeviceId.Type.DEVELOPER_SUPPLIED, newDeviceID);
        }
        result.success("changeDeviceId success!");
    }
    else if ("setHttpPostForced".equals(call.method)){
        int isEnabled = Integer.parseInt(args.getString(0));
        if(isEnabled == 1){
            Countly.sharedInstance().setHttpPostForced(true);
        }else{
            Countly.sharedInstance().setHttpPostForced(false);
        }
        result.success("setHttpPostForced This method doesn't exists!");
    }else if("enableParameterTamperingProtection".equals(call.method)){
        String salt = args.getString(0);
        Countly.sharedInstance().enableParameterTamperingProtection(salt);
        result.success("enableParameterTamperingProtection success!");
    }else if("setLocation".equals(call.method)){
        String latitude = args.getString(0);
        String longitude = args.getString(1);
        String latlng = (latitude +"," +longitude);
        Countly.sharedInstance().setLocation(null, null, latlng, null);
        result.success("setLocation success!");
    }else if("enableCrashReporting".equals(call.method)){
        Countly.sharedInstance().enableCrashReporting();
        result.success("enableCrashReporting success!");
    }else if("addCrashLog".equals(call.method)){
        String record = args.getString(0);
        Countly.sharedInstance().addCrashLog(record);
        result.success("addCrashLog success!");
    }else if("logException".equals(call.method)){
        String exceptionString = args.getString(0);
        Exception exception = new Exception(exceptionString);

        Boolean nonfatal = args.getBoolean(1);

        HashMap<String, String> segments = new HashMap<String, String>();
        for(int i=2,il=args.length();i<il;i+=2){
            segments.put(args.getString(i), args.getString(i+1));
        }
        segments.put("nonfatal", nonfatal.toString());
        Countly.sharedInstance().setCustomCrashSegments(segments);

        Countly.sharedInstance().logException(exception);

        result.success("logException success!");
    }else if ("sendPushToken".equals(call.method)) {
        String token = args.getString(0);
        int messagingMode = Integer.parseInt(args.getString(1));
        if(messagingMode == 0){
            // Countly.sharedInstance().sendPushToken(token, Countly.CountlyMessagingMode.PRODUCTION);
        }else{
            // Countly.sharedInstance().sendPushToken(token, Countly.CountlyMessagingMode.TEST);
        }
        result.success(" success!");
    }


    else if ("start".equals(call.method)) {
        Countly.sharedInstance().onStart(activity);
        result.success("started!");
    }
    else if ("stop".equals(call.method)) {
        Countly.sharedInstance().onStop();
        result.success("stoped!");
    }else if("startEvent".equals(call.method)){
        String startEvent = args.getString(0);
        Countly.sharedInstance().startEvent(startEvent);
    }else if("endEvent".equals(call.method)){
        String key = args.getString(0);
        int count = Integer.parseInt(args.getString(1));
        float sum = new Float(args.getString(2)).floatValue();
        HashMap<String, String> segmentation = new HashMap<String, String>();
        if(args.length() > 3){
            for(int i=3,il=args.length();i<il;i+=2){
                segmentation.put(args.getString(i), args.getString(i+1));
            }
        }
        Countly.sharedInstance().endEvent(key, segmentation, count, sum);
        result.success("endEvent for: "+key);

        // if("event".equals(eventType)){
        //     String eventName = args.getString(1);
        //     Countly.sharedInstance().endEvent(eventName);
        //     result.success("event sent");
        // }
        // else if ("eventWithSegment".equals(eventType)) {
        //     String eventName = args.getString(1);
        //     HashMap<String, String> segmentation = new HashMap<String, String>();
        //     for(int i=3,il=args.length();i<il;i+=2){
        //         segmentation.put(args.getString(i), args.getString(i+1));
        //     }
        //     Countly.sharedInstance().endEvent(eventName, segmentation, 1,0);
        //     result.success("eventWithSumSegment sent");
        // }
        // else if ("eventWithSum".equals(eventType)) {
        //     String eventName = args.getString(1);
        //     int eventCount= Integer.parseInt(args.getString(2));
        //     float eventSum= new Float(args.getString(3)).floatValue();
        //     HashMap<String, String> segmentation = new HashMap<String, String>();
        //     for(int i=4,il=args.length();i<il;i+=2){
        //         segmentation.put(args.getString(i), args.getString(i+1));
        //     }
        //     Countly.sharedInstance().endEvent(eventName, segmentation, eventCount,eventSum);
        //     result.success("eventWithSumSegment sent");
        // }
        // else if ("eventWithSumSegment".equals(eventType)) {
        //     String eventName = args.getString(1);
        //     int eventCount= Integer.parseInt(args.getString(2));
        //     float eventSum= new Float(args.getString(3)).floatValue();
        //     HashMap<String, String> segmentation = new HashMap<String, String>();
        //     for(int i=4,il=args.length();i<il;i+=2){
        //         segmentation.put(args.getString(i), args.getString(i+1));
        //     }
        //     Countly.sharedInstance().endEvent(eventName, segmentation, eventCount,eventSum);
        //     result.success("eventWithSumSegment sent");
        // }
        // else{
        //     result.success("event sent");
        // }
    }
    else if ("recordEvent".equals(call.method)) {
        String key = args.getString(0);
        int count = Integer.parseInt(args.getString(1));
        float sum = new Float(args.getString(2)).floatValue();
        HashMap<String, String> segmentation = new HashMap<String, String>();
        if(args.length() > 3){
            for(int i=3,il=args.length();i<il;i+=2){
                segmentation.put(args.getString(i), args.getString(i+1));
            }
        }
        Countly.sharedInstance().recordEvent(key, segmentation, count, sum);
        result.success("recordEvent for: "+key);

        // String eventType = args.getString(0);
        // if("event".equals(eventType)){
        //     String eventName = args.getString(1);
        //     int eventCount= Integer.parseInt(args.getString(2));
        //     Countly.sharedInstance().recordEvent(eventName, eventCount);
        //     result.success("event sent");
        // }
        // else if ("eventWithSum".equals(eventType)) {
        //     String eventName = args.getString(1);
        //     int eventCount= Integer.parseInt(args.getString(2));
        //     float eventSum= new Float(args.getString(3)).floatValue();
        //     Countly.sharedInstance().recordEvent(eventName, eventCount, eventSum);
        //     result.success("eventWithSum sent");
        // }
        // else if ("eventWithSegment".equals(eventType)) {
        //     String eventName = args.getString(1);
        //     int eventCount= Integer.parseInt(args.getString(2));
        //     HashMap<String, String> segmentation = new HashMap<String, String>();
        //     for(int i=3,il=args.length();i<il;i+=2){
        //         segmentation.put(args.getString(i), args.getString(i+1));
        //     }
        //     Countly.sharedInstance().recordEvent(eventName, segmentation, eventCount);
        //     result.success("eventWithSegment sent");
        // }
        // else if ("eventWithSumSegment".equals(eventType)) {
        //     String eventName = args.getString(1);
        //     int eventCount= Integer.parseInt(args.getString(2));
        //     float eventSum= new Float(args.getString(3)).floatValue();
        //     HashMap<String, String> segmentation = new HashMap<String, String>();
        //     for(int i=4,il=args.length();i<il;i+=2){
        //         segmentation.put(args.getString(i), args.getString(i+1));
        //     }
        //     Countly.sharedInstance().recordEvent(eventName, segmentation, eventCount,eventSum);
        //     result.success("eventWithSumSegment sent");
        // }
        // else{
        //     result.success("event sent");
        // }
    }
    else if ("setloggingenabled".equals(call.method)) {
        Countly.sharedInstance().setLoggingEnabled(true);
        result.success("setloggingenabled success!");
    }


    else if ("setuserdata".equals(call.method)) {
        // Bundle bundle = new Bundle();

        Map<String, String> bundle = new HashMap<String, String>();

        bundle.put("name", args.getString(0));
        bundle.put("username", args.getString(1));
        bundle.put("email", args.getString(2));
        bundle.put("organization", args.getString(3));
        bundle.put("phone", args.getString(4));
        bundle.put("picture", args.getString(5));
        bundle.put("picturePath", args.getString(6));
        bundle.put("gender", args.getString(7));
        bundle.put("byear", String.valueOf(args.getInt(8)));

        Countly.userData.setUserData(bundle);
        Countly.userData.save();

        result.success("setuserdata success");
    }
    else if ("userData_setProperty".equals(call.method)) {
        String keyName = args.getString(0);
        String keyValue = args.getString(1);
        Countly.userData.setProperty(keyName, keyValue);
        Countly.userData.save();
        result.success("userData_setProperty success!");
    }
    else if ("userData_increment".equals(call.method)) {
        String keyName = args.getString(0);
        Countly.userData.increment(keyName);
        Countly.userData.save();
        result.success("userData_increment success!");
    }
    else if ("userData_incrementBy".equals(call.method)) {
        String keyName = args.getString(0);
        int keyIncrement = Integer.parseInt(args.getString(1));
        Countly.userData.incrementBy(keyName, keyIncrement);
        Countly.userData.save();
        result.success("userData_incrementBy success!");
    }
    else if ("userData_multiply".equals(call.method)) {
        String keyName = args.getString(0);
        int multiplyValue = Integer.parseInt(args.getString(1));
        Countly.userData.multiply(keyName, multiplyValue);
        Countly.userData.save();
        result.success("userData_multiply success!");
    }
    else if ("userData_saveMax".equals(call.method)) {
        String keyName = args.getString(0);
        int maxScore = Integer.parseInt(args.getString(1));
        Countly.userData.saveMax(keyName, maxScore);
        Countly.userData.save();
        result.success("userData_saveMax success!");
    }
    else if ("userData_saveMin".equals(call.method)) {
        String keyName = args.getString(0);
        int minScore = Integer.parseInt(args.getString(1));
        Countly.userData.saveMin(keyName, minScore);
        Countly.userData.save();
        result.success("userData_saveMin success!");
    }
    else if ("userData_setOnce".equals(call.method)) {
        String keyName = args.getString(0);
        String minScore = args.getString(1);
        Countly.userData.setOnce(keyName, minScore);
        Countly.userData.save();
        result.success("userData_setOnce success!");
    }
    else if ("userData_pushUniqueValue".equals(call.method)) {
        String type = args.getString(0);
        String pushUniqueValue = args.getString(1);
        Countly.userData.pushUniqueValue(type, pushUniqueValue);
        Countly.userData.save();
        result.success("userData_pushUniqueValue success!");
    }
    else if ("userData_pushValue".equals(call.method)) {
        String type = args.getString(0);
        String pushValue = args.getString(1);
        Countly.userData.pushValue(type, pushValue);
        Countly.userData.save();
        result.success("userData_pushValue success!");
    }
    else if ("userData_pullValue".equals(call.method)) {
        String type = args.getString(0);
        String pullValue = args.getString(1);
        Countly.userData.pullValue(type, pullValue);
        Countly.userData.save();
        result.success("userData_pullValue success!");
    }
//setRequiresConsent
    else if ("setRequiresConsent".equals(call.method)) {
        Boolean consentFlag = args.getBoolean(0);
        Countly.sharedInstance().setRequiresConsent(consentFlag);
        result.success("setRequiresConsent!");
    }
     else if ("giveConsent".equals(call.method)) {
         List<String> features = new ArrayList<>();
         for (int i = 0; i < args.length(); i++) {
             String featureName = args.getString(i);
             if (validConsentFeatureNames.contains(featureName)) {
                features.add(featureName);
             }
             else {
                Log.d(Countly.TAG, "Not a valid consent feature to add: " + featureName);
             }
         }
         Countly.sharedInstance().giveConsent(features.toArray(new String[features.size()]));
         result.success("giveConsent!");
     }
     else if ("removeConsent".equals(call.method)) {
         List<String> features = new ArrayList<>();
         for (int i = 0; i < args.length(); i++) {
             String featureName = args.getString(i);
             if (validConsentFeatureNames.contains(featureName)) {
                features.add(featureName);
             }
             else {
                Log.d(Countly.TAG, "Not a valid consent feature to remove: " + featureName);
             }
         }
         Countly.sharedInstance().removeConsent(features.toArray(new String[features.size()]));
         result.success("removeConsent!");
     }
     else if ("giveAllConsent".equals(call.method)) {
         Countly.sharedInstance().giveConsent(validConsentFeatureNames.toArray(new String[validConsentFeatureNames.size()]));
         result.success("giveAllConsent!");
     }
     else if ("removeAllConsent".equals(call.method)) {
         Countly.sharedInstance().removeConsent(validConsentFeatureNames.toArray(new String[validConsentFeatureNames.size()]));
         result.success("removeAllConsent!");
     }


    else if("getDeviceID".equals(call.method)){
        result.success(Countly.sharedInstance().getDeviceID());
    }
    else if("sendRating".equals(call.method)){
        String ratingString = args.getString(0);
        int rating = Integer.parseInt(ratingString);

        Map<String, String> segm = new HashMap<>();
        segm.put("platform", "android");
        // segm.put("app_version", DeviceInfo.getAppVersion(context));
        segm.put("rating", "" + rating);

        Countly.sharedInstance().recordEvent("[CLY]_star_rating", segm, 1);
        result.success("sendRating: "+ratingString);
    }
    else if("recordView".equals(call.method)){
        String viewName = args.getString(0);
        Countly.sharedInstance().recordView(viewName);
        result.success("View name sent: "+viewName);
    }
    else if("setOptionalParametersForInitialization".equals(call.method)){
        String city = args.getString(0);
        String country = args.getString(1);
        String latitude = args.getString(2);
        String longitude = args.getString(3);
        String ipAddress = args.getString(4);

        Countly.sharedInstance().setLocation(country, city, latitude +"," +longitude, ipAddress);

        result.success("setOptionalParametersForInitialization sent.");
    }
    else if("setRemoteConfigAutomaticDownload".equals(call.method)){
        Countly.sharedInstance().setRemoteConfigAutomaticDownload(true, new RemoteConfig.RemoteConfigCallback() {
            @Override
            public void callback(String error) {
                if(error == null) {
                    // result.success("Success");
                } else {
                    // callbackContext.error(error);
                }
            }
        });

    }
    else if("remoteConfigUpdate".equals(call.method)){
        Countly.sharedInstance().remoteConfigUpdate(new RemoteConfig.RemoteConfigCallback() {
            @Override
            public void callback(String error) {
                if(error == null) {
                    // result.success("Success");
                } else {
                    // callbackContext.error(error);
                }
            }
        });
    }
    else if("updateRemoteConfigForKeysOnly".equals(call.method)){
        String[] keysOnly =  new String[ args.length() ];
        for(int i=0,il=args.length();i<il;i++){
            keysOnly[i] = args.getString(i);;
        }

        Countly.sharedInstance().updateRemoteConfigForKeysOnly(keysOnly, new RemoteConfig.RemoteConfigCallback() {
            @Override
            public void callback(String error) {
                if(error == null) {
                    // result.success("Success");
                } else {
                    // callbackContext.error(error);
                }
            }
        });
    }
    else if("updateRemoteConfigExceptKeys".equals(call.method)){
        String[] exceptKeys =  new String[ args.length() ];
        for(int i=0,il=args.length();i<il;i++){
            exceptKeys[i] = args.getString(i);;
        }

        Countly.sharedInstance().updateRemoteConfigExceptKeys(exceptKeys, new RemoteConfig.RemoteConfigCallback() {
            @Override
            public void callback(String error) {
                if(error == null) {
                    // result.success("Success");
                } else {
                    // callbackContext.error(error);
                }
            }
        });
    }
    else if("remoteConfigClearValues".equals(call.method)){
        Countly.sharedInstance().remoteConfigClearValues();
        result.success("Success");
    }
    else if("getRemoteConfigValueForKey".equals(call.method)){
        String getRemoteConfigValueForKeyResult = (String)Countly.sharedInstance().getRemoteConfigValueForKey(args.getString(0));
        result.success(result);
    }
    else if("askForFeedback".equals(call.method)){
        String widgetId = args.getString(0);
        // result.success(Countly.sharedInstance().getFeedbackWidget(widgetId));
    }else if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }
    else{
        result.notImplemented();
    }

    // if (call.method.equals("getPlatformVersion")) {
    //   result.success("Android " + android.os.Build.VERSION.RELEASE);
    // } else {
    //   result.notImplemented();
    // }
    }catch (JSONException jsonException){
        result.success(jsonException.toString());
    }
  }
}
