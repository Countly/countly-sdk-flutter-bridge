package ly.count.dart.countly_flutter

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.google.android.gms.tasks.OnCompleteListener
import com.google.firebase.FirebaseApp
import com.google.firebase.iid.FirebaseInstanceId
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry
import ly.count.android.sdk.*
import ly.count.android.sdk.Countly.CountlyMessagingMode
import ly.count.android.sdk.ModuleFeedback.*
import ly.count.android.sdk.messaging.CountlyPush
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

//Push Plugin
/**
 * CountlyFlutterPlugin
 */
class CountlyFlutterPlugin : MethodCallHandler, FlutterPlugin, ActivityAware,
    DefaultLifecycleObserver {
    private val COUNTLY_FLUTTER_SDK_VERSION_STRING = "23.2.3"
    private val COUNTLY_FLUTTER_SDK_NAME = "dart-flutterb-android"
    private val COUNTLY_FLUTTER_SDK_NAME_NO_PUSH = "dart-flutterbnp-android"
    private val BUILDING_WITH_PUSH_DISABLED = false

    /**
     * Plugin registration.
     */
    private var pushTokenType = CountlyMessagingMode.PRODUCTION
    private var context: Context? = null
    private var activity: Activity? = null
    private val config = CountlyConfig()
    private var methodChannel: MethodChannel? = null
    private var lifecycle: Lifecycle? = null
    private var isSessionStarted_ = false
    private var manualSessionControlEnabled_ = false
    private var isOnResumeBeforeInit = false
    private var retrievedWidgetList: List<CountlyFeedbackWidget?>? = null
    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        onAttachedToEngineInternal(binding.applicationContext, binding.binaryMessenger)
        log("onAttachedToEngine", LogLevel.INFO)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        context = null
        methodChannel!!.setMethodCallHandler(null)
        methodChannel = null
        log("onDetachedFromEngine", LogLevel.INFO)
    }

    private fun onAttachedToEngineInternal(context: Context, messenger: BinaryMessenger) {
        this.context = context
        methodChannel = MethodChannel(messenger, "countly_flutter")
        methodChannel!!.setMethodCallHandler(this)
        config.enableManualAppLoadedTrigger()
        config.enableManualForegroundBackgroundTriggerAPM()
        log("onAttachedToEngineInternal", LogLevel.INFO)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
        lifecycle!!.addObserver(this)
        log("onAttachedToActivity : Activity attached!", LogLevel.INFO)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        lifecycle!!.removeObserver(this)
        activity = null
        log("onDetachedFromActivityForConfigChanges : Activity is no more valid", LogLevel.INFO)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
        lifecycle!!.addObserver(this)
        log("onReattachedToActivityForConfigChanges : Activity attached!", LogLevel.INFO)
    }

    override fun onDetachedFromActivity() {
        lifecycle!!.removeObserver(this)
        activity = null
        log("onDetachedFromActivity : Activity is no more valid", LogLevel.INFO)
    }

    // DefaultLifecycleObserver callbacks
    override fun onCreate(owner: LifecycleOwner) {
        log("onCreate", LogLevel.INFO)
    }

    override fun onStart(owner: LifecycleOwner) {
        log("onStart", LogLevel.INFO)
        if (Countly.sharedInstance().isInitialized) {
            if (isSessionStarted_ || manualSessionControlEnabled_) {
                Countly.sharedInstance().onStart(activity)
            }
            Countly.sharedInstance().apm().triggerForeground()
        } else {
            isOnResumeBeforeInit = true
        }
    }

    override fun onResume(owner: LifecycleOwner) {
        log("onResume", LogLevel.INFO)
    }

    override fun onPause(owner: LifecycleOwner) {
        log("onPause", LogLevel.INFO)
        if (Countly.sharedInstance().isInitialized) {
            Countly.sharedInstance().apm().triggerBackground()
        }
    }

    override fun onStop(owner: LifecycleOwner) {
        log("onStop", LogLevel.INFO)
        if (isSessionStarted_ || manualSessionControlEnabled_) {
            Countly.sharedInstance().onStop()
        }
    }

    override fun onDestroy(owner: LifecycleOwner) {
        log("onDestroy", LogLevel.INFO)
    }

    init {
        log("CountlyFlutterPlugin", LogLevel.INFO)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        var argsString = call.argument<Any>("data") as String?
        if (argsString == null) {
            argsString = "[]"
        }
        val args: JSONArray
        try {
            Countly.sharedInstance()
            args = JSONArray(argsString)
            log("Method name: " + call.method, LogLevel.INFO)
            log("Method arguments: $argsString", LogLevel.INFO)
            when(call.method){
                Constants.MethodNameConstants.init -> {
                    if (context == null) {
                        log(
                            "valid context is required in Countly init, but was provided 'null'",
                            LogLevel.ERROR
                        )
                        result.error(
                            "init Failed",
                            "valid context is required in Countly init, but was provided 'null'",
                            null
                        )
                        return
                    }
                    val config = args.getJSONObject(0)
                    this.config.setContext(context)
                    populateConfig(config)
                    Countly.sharedInstance().COUNTLY_SDK_NAME =
                        if (BUILDING_WITH_PUSH_DISABLED) COUNTLY_FLUTTER_SDK_NAME_NO_PUSH else COUNTLY_FLUTTER_SDK_NAME
                    Countly.sharedInstance().COUNTLY_SDK_VERSION_STRING =
                        COUNTLY_FLUTTER_SDK_VERSION_STRING
                    if (activity == null) {
                        log("Activity is 'null' during init, cannot set Application", LogLevel.WARNING)
                    } else {
                        this.config.setApplication(activity!!.application)
                    }
                    Countly.sharedInstance().init(this.config)
                    if (isOnResumeBeforeInit) {
                        isOnResumeBeforeInit = false
                        Countly.sharedInstance().apm().triggerForeground()
                    }
                    result.success("initialized!")
                }
                Constants.MethodNameConstants.isInitialized -> {
                    val isInitialized = Countly.sharedInstance().isInitialized
                    if (isInitialized) {
                        result.success("true")
                    } else {
                        result.success("false")
                    }
                }
                Constants.MethodNameConstants.getCurrentDeviceId -> {
                    val deviceID = Countly.sharedInstance().deviceId().id
                    result.success(deviceID)
                }
                Constants.MethodNameConstants.getDeviceIDType -> {
                    val deviceIDType = Countly.sharedInstance().deviceId().type
                    var deviceIDTypeString: String? = null
                    deviceIDTypeString = when (deviceIDType) {
                        DeviceIdType.DEVELOPER_SUPPLIED -> "DS"
                        DeviceIdType.OPEN_UDID, DeviceIdType.ADVERTISING_ID -> "SG"
                        DeviceIdType.TEMPORARY_ID -> "TID"
                        else -> "SG"
                    }
                    result.success(deviceIDTypeString)
                }
                Constants.MethodNameConstants.changeDeviceId -> {
                    val newDeviceID = args.getString(0)
                    val onServerString = args.getString(1)
                    if (newDeviceID == "TemporaryDeviceID") {
                        Countly.sharedInstance().deviceId().enableTemporaryIdMode()
                    } else {
                        if ("1" == onServerString) {
                            Countly.sharedInstance().deviceId().changeWithMerge(newDeviceID)
                        } else {
                            Countly.sharedInstance().deviceId().changeWithoutMerge(newDeviceID)
                        }
                    }
                    result.success("changeDeviceId success!")
                }
                Constants.MethodNameConstants.enableTemporaryIdMode -> {
                    Countly.sharedInstance().deviceId().enableTemporaryIdMode()
                    result.success("enableTemporaryIdMode This method doesn't exists!")
                }
                Constants.MethodNameConstants.setHttpPostForced -> {
                    val isEnabled = args.getBoolean(0)
                    config.setHttpPostForced(isEnabled)
                    result.success("setHttpPostForced")
                }
                Constants.MethodNameConstants.enableParameterTamperingProtection -> {
                    val salt = args.getString(0)
                    config.setParameterTamperingProtectionSalt(salt)
                    result.success("enableParameterTamperingProtection success!")
                }
                Constants.MethodNameConstants.setLocationInit -> {
                    val countryCode = args.getString(0)
                    val city = args.getString(1)
                    val location = args.getString(2)
                    val ipAddress = args.getString(3)
                    config.setLocation(countryCode, city, location, ipAddress)
                    result.success("setLocationInit success!")
                }
                Constants.MethodNameConstants.setLocation -> {
                    val latitude = args.getString(0)
                    val longitude = args.getString(1)
                    if (latitude != "null" && longitude != "null") {
                        val latlng = "$latitude,$longitude"
                        Countly.sharedInstance().location().setLocation(null, null, latlng, null)
                    }
                    result.success("setLocation success!")
                }
                Constants.MethodNameConstants.setUserLocation -> {
                    val location = args.getJSONObject(0)
                    var countryCode: String? = null
                    var city: String? = null
                    var gpsCoordinates: String? = null
                    var ipAddress: String? = null
                    if (location.has("countryCode")) {
                        countryCode = location.getString("countryCode")
                    }
                    if (location.has("city")) {
                        city = location.getString("city")
                    }
                    if (location.has("gpsCoordinates")) {
                        gpsCoordinates = location.getString("gpsCoordinates")
                    }
                    if (location.has("ipAddress")) {
                        ipAddress = location.getString("ipAddress")
                    }
                    Countly.sharedInstance().location()
                        .setLocation(countryCode, city, gpsCoordinates, ipAddress)
                    result.success("setUserLocation success!")
                }
                Constants.MethodNameConstants.enableCrashReporting -> {
                    config.enableCrashReporting()
                    // Countly.sharedInstance().enableCrashReporting();
                    result.success("enableCrashReporting success!")
                }
                Constants.MethodNameConstants.addCrashLog -> {
                    val record = args.getString(0)
                    Countly.sharedInstance().crashes().addCrashBreadcrumb(record)
                    // Countly.sharedInstance().addCrashBreadcrumb(record);
                    result.success("addCrashLog success!")
                }
                Constants.MethodNameConstants.logException -> {
                    val exceptionString = args.getString(0)
                    val fatal = args.getBoolean(1)
                    val exception = Exception(exceptionString)
                    val segments: MutableMap<String, Any> = HashMap()
                    var i = 2
                    val il = args.length()
                    while (i < il) {
                        segments[args.getString(i)] = args.getString(i + 1)
                        i += 2
                    }
                    if (fatal) {
                        Countly.sharedInstance().crashes().recordUnhandledException(exception, segments)
                    } else {
                        Countly.sharedInstance().crashes().recordHandledException(exception, segments)
                    }
                    result.success("logException success!")
                }
                Constants.MethodNameConstants.setCustomCrashSegment -> {
                    val segments: MutableMap<String, Any> = HashMap()
                    var i = 0
                    val il = args.length()
                    while (i < il) {
                        segments[args.getString(i)] = args.getString(i + 1)
                        i += 2
                    }
                    config.setCustomCrashSegment(segments)
                    result.success("setCustomCrashSegment success!")
                }
                Constants.MethodNameConstants.sendPushToken -> {
                    val token = args.getString(0)
                    CountlyPush.onTokenRefresh(token)
                    result.success(" success!")
                }
                Constants.MethodNameConstants.askForNotificationPermission -> {
                    if (activity == null) {
                        log("askForNotificationPermission failed : Activity is null", LogLevel.ERROR)
                        result.error("askForNotificationPermission Failed", "Activity is null", null)
                        return
                    }
                    if (context == null) {
                        log(
                            "valid context is required in askForNotificationPermission, but was provided 'null'",
                            LogLevel.ERROR
                        )
                        result.error(
                            "askForNotificationPermission Failed",
                            "valid context is required in Countly askForNotificationPermission, but was provided 'null'",
                            null
                        )
                        return
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val channelName = "General Notifications"
                        val channelDescription =
                            "Receive notifications about important updates and events."
                        val notificationManager =
                            context!!.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        if (notificationManager != null) {
                            val channel = NotificationChannel(
                                CountlyPush.CHANNEL_ID,
                                channelName,
                                NotificationManager.IMPORTANCE_DEFAULT
                            )
                            channel.description = channelDescription
                            notificationManager.createNotificationChannel(channel)
                        }
                    }
                    CountlyPush.init(activity!!.application, pushTokenType)
                    FirebaseApp.initializeApp(context!!)
                    FirebaseInstanceId.getInstance().instanceId
                        .addOnCompleteListener(OnCompleteListener { task ->
                            if (!task.isSuccessful) {
                                log("getInstanceId failed", task.exception, LogLevel.WARNING)
                                return@OnCompleteListener
                            }
                            val token = task.result!!.token
                            CountlyPush.onTokenRefresh(token)
                        })
                    result.success(" askForNotificationPermission!")
                }
                Constants.MethodNameConstants.pushTokenType -> {
                    val tokenType = args.getString(0)
                    pushTokenType = if ("2" == tokenType) {
                        CountlyMessagingMode.TEST
                    } else {
                        CountlyMessagingMode.PRODUCTION
                    }
                    result.success("pushTokenType!")
                }
                Constants.MethodNameConstants.registerForNotification -> {
                    registerForNotification(args, object : Callback {
                        override fun callback(resultString: String?) {
                            if (activity != null) {
                                activity!!.runOnUiThread { result.success(resultString) }
                            }
                        }
                    })
                }
                Constants.MethodNameConstants.beginSession -> {
                    Countly.sharedInstance().sessions().beginSession()
                    result.success("beginSession!")
                }
                Constants.MethodNameConstants.updateSession -> {
                    Countly.sharedInstance().sessions().updateSession()
                    result.success("updateSession!")
                }
                Constants.MethodNameConstants.endSession -> {
                    Countly.sharedInstance().sessions().endSession()
                    result.success("endSession!")
                }
                Constants.MethodNameConstants.start -> {
                    if (isSessionStarted_) {
                        log("session already started", LogLevel.INFO)
                        result.error("Start Failed", "session already started", null)
                        return
                    }
                    if (activity == null) {
                        log("start failed : Activity is null", LogLevel.ERROR)
                        result.error("Start Failed", "Activity is null", null)
                        return
                    }
                    Countly.sharedInstance().onStart(activity)
                    isSessionStarted_ = true
                    result.success("started!")
                }
                Constants.MethodNameConstants.manualSessionHandling -> {
                    result.success("deafult!")
                }
                Constants.MethodNameConstants.stop -> {
                    if (!isSessionStarted_) {
                        log("must call Start before Stop", LogLevel.INFO)
                        result.error("Stop Failed", "must call Start before Stop", null)
                        return
                    }
                    Countly.sharedInstance().onStop()
                    isSessionStarted_ = false
                    result.success("stoped!")
                }
                Constants.MethodNameConstants.updateSessionPeriod -> {
                    result.success("default!")
                }
                Constants.MethodNameConstants.updateSessionInterval -> {
                    val sessionInterval = args.getString(0).toInt()
                    config.setUpdateSessionTimerDelay(sessionInterval)
                    result.success("updateSessionInterval Success!")
                }
                Constants.MethodNameConstants.eventSendThreshold -> {
                    val queueSize = args.getString(0).toInt()
                    config.setEventQueueSizeToSend(queueSize)
                    result.success("default!")
                }
                Constants.MethodNameConstants.storedRequestsLimit -> {
                    val queueSize = args.getString(0).toInt()
                    result.success("default!")
                }
                Constants.MethodNameConstants.startEvent -> {
                    val startEvent = args.getString(0)
                    Countly.sharedInstance().events().startEvent(startEvent)
                }
                Constants.MethodNameConstants.endEvent -> {
                    val key = args.getString(0)
                    val count = args.getString(1).toInt()
                    val sum = args.getString(2).toFloat() // new Float(args.getString(2)).floatValue();
                    val segmentation = HashMap<String, Any>()
                    if (args.length() > 3) {
                        var i = 3
                        val il = args.length()
                        while (i < il) {
                            segmentation[args.getString(i)] = args.getString(i + 1)
                            i += 2
                        }
                    }
                    Countly.sharedInstance().events().endEvent(key, segmentation, count, sum.toDouble())
                    result.success("endEvent for: $key")
                }
                Constants.MethodNameConstants.recordEvent -> {
                    val key = args.getString(0)
                    val count = args.getString(1).toInt()
                    val sum = args.getString(2).toFloat() // new Float(args.getString(2)).floatValue();
                    val duration = args.getString(3).toInt()
                    val segmentation = HashMap<String, Any>()
                    if (args.length() > 4) {
                        var i = 4
                        val il = args.length()
                        while (i < il) {
                            segmentation[args.getString(i)] = args.getString(i + 1)
                            i += 2
                        }
                    }
                    Countly.sharedInstance().events()
                        .recordEvent(key, segmentation, count, sum.toDouble(), duration.toDouble())
                    result.success("recordEvent for: $key")
                }
                Constants.MethodNameConstants.setLoggingEnabled -> {
                    val loggingEnable = args.getString(0)
                    // Countly.sharedInstance().setLoggingEnabled(true);
                    // Countly.sharedInstance().setLoggingEnabled(false);
                    config.setLoggingEnabled(loggingEnable == "true")
                    result.success("setLoggingEnabled success!")
                }
                Constants.MethodNameConstants.setuserdata -> {
                    val userData = args.getJSONObject(0)
                    val bundle: MutableMap<String, Any> = HashMap()
                    if (userData.has("name")) {
                        bundle["name"] = userData.getString("name")
                    }
                    if (userData.has("username")) {
                        bundle["username"] = userData.getString("username")
                    }
                    if (userData.has("email")) {
                        bundle["email"] = userData.getString("email")
                    }
                    if (userData.has("organization")) {
                        bundle["organization"] = userData.getString("organization")
                    }
                    if (userData.has("phone")) {
                        bundle["phone"] = userData.getString("phone")
                    }
                    if (userData.has("picture")) {
                        bundle["picture"] = userData.getString("picture")
                    }
                    if (userData.has("picturePath")) {
                        bundle["picturePath"] = userData.getString("picturePath")
                    }
                    if (userData.has("gender")) {
                        bundle["gender"] = userData.getString("gender")
                    }
                    if (userData.has("byear")) {
                        bundle["byear"] = userData.getString("byear")
                    }
                    Countly.sharedInstance().userProfile().setProperties(bundle)
                    Countly.sharedInstance().userProfile().save()
                    result.success("setuserdata success")
                }
                Constants.MethodNameConstants.userData_setProperty -> {
                    val keyName = args.getString(0)
                    val keyValue = args.getString(1)
                    Countly.sharedInstance().userProfile().setProperty(keyName, keyValue)
                    Countly.sharedInstance().userProfile().save()
                    result.success("userData_setProperty success!")
                }
                Constants.MethodNameConstants.userData_increment -> {
                    val keyName = args.getString(0)
                    Countly.sharedInstance().userProfile().increment(keyName)
                    Countly.sharedInstance().userProfile().save()
                    result.success("userData_increment success!")
                }
                Constants.MethodNameConstants.userData_incrementBy -> {
                    val keyName = args.getString(0)
                    val keyIncrement = args.getString(1).toInt()
                    Countly.sharedInstance().userProfile().incrementBy(keyName, keyIncrement)
                    Countly.sharedInstance().userProfile().save()
                    result.success("userData_incrementBy success!")
                }
                Constants.MethodNameConstants.userData_multiply -> {
                    val keyName = args.getString(0)
                    val multiplyValue = args.getString(1).toInt()
                    Countly.sharedInstance().userProfile().multiply(keyName, multiplyValue)
                    Countly.sharedInstance().userProfile().save()
                    result.success("userData_multiply success!")
                }
                Constants.MethodNameConstants.userData_saveMax -> {
                    val keyName = args.getString(0)
                    val maxScore = args.getString(1).toInt()
                    Countly.sharedInstance().userProfile().saveMax(keyName, maxScore)
                    Countly.sharedInstance().userProfile().save()
                    result.success("userData_saveMax success!")
                }
                Constants.MethodNameConstants.userData_saveMin -> {
                    val keyName = args.getString(0)
                    val minScore = args.getString(1).toInt()
                    Countly.sharedInstance().userProfile().saveMin(keyName, minScore)
                    Countly.sharedInstance().userProfile().save()
                    result.success("userData_saveMin success!")
                }
                Constants.MethodNameConstants.userData_setOnce -> {
                    val keyName = args.getString(0)
                    val minScore = args.getString(1)
                    Countly.sharedInstance().userProfile().setOnce(keyName, minScore)
                    Countly.sharedInstance().userProfile().save()
                    result.success("userData_setOnce success!")
                }
                Constants.MethodNameConstants.userData_pushUniqueValue -> {
                    val type = args.getString(0)
                    val pushUniqueValue = args.getString(1)
                    Countly.sharedInstance().userProfile().pushUnique(type, pushUniqueValue)
                    Countly.sharedInstance().userProfile().save()
                    result.success("userData_pushUniqueValue success!")
                }
                Constants.MethodNameConstants.userData_pushValue -> {
                    val type = args.getString(0)
                    val pushValue = args.getString(1)
                    Countly.sharedInstance().userProfile().push(type, pushValue)
                    Countly.sharedInstance().userProfile().save()
                    result.success("userData_pushValue success!")
                }
                Constants.MethodNameConstants.userData_pullValue -> {
                    val type = args.getString(0)
                    val pullValue = args.getString(1)
                    Countly.sharedInstance().userProfile().pull(type, pullValue)
                    Countly.sharedInstance().userProfile().save()
                    result.success("userData_pullValue success!")
                }
                Constants.MethodNameConstants.setRequiresConsent -> {
                    val consentFlag = args.getBoolean(0)
                    config.setRequiresConsent(consentFlag)
                    result.success("setRequiresConsent!")
                }
                Constants.MethodNameConstants.giveConsentInit -> {
                    val features = arrayOfNulls<String>(args.length())
                    for (i in 0 until args.length()) {
                        features[i] = args.getString(i)
                    }
                    config.setConsentEnabled(features)
                    result.success("giveConsent!")
                }
                Constants.MethodNameConstants.giveConsent -> {
                    val features = arrayOfNulls<String>(args.length())
                    for (i in 0 until args.length()) {
                        features[i] = args.getString(i)
                    }
                    Countly.sharedInstance().consent().giveConsent(features)
                    result.success("giveConsent!")
                }
                Constants.MethodNameConstants.removeConsent -> {
                    val features = arrayOfNulls<String>(args.length())
                    for (i in 0 until args.length()) {
                        features[i] = args.getString(i)
                    }
                    Countly.sharedInstance().consent().removeConsent(features)
                    result.success("removeConsent!")
                }
                Constants.MethodNameConstants.giveAllConsent -> {
                    Countly.sharedInstance().consent().giveConsentAll()
                    result.success("giveAllConsent!")
                }
                Constants.MethodNameConstants.removeAllConsent -> {
                    Countly.sharedInstance().consent().removeConsentAll()
                    result.success("removeAllConsent!")
                }
                Constants.MethodNameConstants.sendRating -> {
                    val ratingString = args.getString(0)
                    val rating = ratingString.toInt()
                    val segm: MutableMap<String, Any> = HashMap()
                    segm["platform"] = "android"
                    segm["rating"] = "" + rating
                    Countly.sharedInstance().events().recordEvent("[CLY]_star_rating", segm, 1)
                    result.success("sendRating: $ratingString")
                }
                Constants.MethodNameConstants.recordView -> {
                    val viewName = args.getString(0)
                    val segments: MutableMap<String, Any> = HashMap()
                    val il = args.length()
                    if (il > 2) {
                        var i = 1
                        while (i < il) {
                            try {
                                segments[args.getString(i)] = args.getString(i + 1)
                            } catch (exception: Exception) {
                                log(
                                    "recordView, could not parse segments, skipping it. ",
                                    exception,
                                    LogLevel.ERROR
                                )
                            }
                            i += 2
                        }
                    }
                    Countly.sharedInstance().views().recordView(viewName, segments)
                    result.success("View name sent: $viewName")
                }
                Constants.MethodNameConstants.setOptionalParametersForInitialization -> {
                    var city = args.getString(0)
                    var country = args.getString(1)
                    val latitude = args.getString(2)
                    val longitude = args.getString(3)
                    var ipAddress = args.getString(4)
                    var latlng: String? = null
                    if (city!!.length == 0) {
                        city = null
                    }
                    if (country == "null") {
                        country = null
                    }
                    if (latitude != "null" && longitude != "null") {
                        latlng = "$latitude,$longitude"
                    }
                    if (ipAddress == "null") {
                        ipAddress = null
                    }
                    Countly.sharedInstance().location().setLocation(country, city, latlng, ipAddress)
                    result.success("setOptionalParametersForInitialization sent.")
                }
                Constants.MethodNameConstants.setRemoteConfigAutomaticDownload -> {
                    config.setRemoteConfigAutomaticDownload(true, RemoteConfigCallback { error ->
                        if (error == null) {
                            result.success("Success")
                        } else {
                            result.success("Error: $error")
                        }
                    })
                }
                Constants.MethodNameConstants.remoteConfigUpdate -> {
                    Countly.sharedInstance().remoteConfig().update { error ->
                        if (error == null) {
                            result.success("Success")
                        } else {
                            result.success("Error: $error")
                        }
                    }
                }
                Constants.MethodNameConstants.updateRemoteConfigForKeysOnly -> {
                    val keysOnly = arrayOfNulls<String>(args.length())
                    var i = 0
                    val il = args.length()
                    while (i < il) {
                        keysOnly[i] = args.getString(i)
                        i++
                    }
                    Countly.sharedInstance().remoteConfig().updateForKeysOnly(keysOnly) { error ->
                        if (error == null) {
                            result.success("Success")
                        } else {
                            result.success("Error: $error")
                        }
                    }
                }
                Constants.MethodNameConstants.updateRemoteConfigExceptKeys -> {
                    val exceptKeys = arrayOfNulls<String>(args.length())
                    var i = 0
                    val il = args.length()
                    while (i < il) {
                        exceptKeys[i] = args.getString(i)
                        i++
                    }
                    Countly.sharedInstance().remoteConfig().updateExceptKeys(exceptKeys) { error ->
                        if (error == null) {
                            result.success("Success")
                        } else {
                            result.success("Error: $error")
                        }
                    }
                }
                Constants.MethodNameConstants.remoteConfigClearValues -> {
                    Countly.sharedInstance().remoteConfig().clearStoredValues()
                    result.success("remoteConfigClearValues: success")
                }
                Constants.MethodNameConstants.getRemoteConfigValueForKey -> {
                    val key = args.getString(0)
                    var remoteConfigValueForKey = "No value Found against Key :$key"
                    val getRemoteConfigValueForKeyResult =
                        Countly.sharedInstance().remoteConfig().getValueForKey(key)
                    if (getRemoteConfigValueForKeyResult != null) remoteConfigValueForKey =
                        getRemoteConfigValueForKeyResult.toString()
                    result.success(remoteConfigValueForKey)
                }
                Constants.MethodNameConstants.presentRatingWidgetWithID -> {
                    if (activity == null) {
                        log("presentRatingWidgetWithID failed : Activity is null", LogLevel.ERROR)
                        result.error("presentRatingWidgetWithID failed", "Activity is null", null)
                        return
                    }
                    val widgetId = args.getString(0)
                    val closeButtonText = args.getString(1)
                    Countly.sharedInstance().ratings()
                        .presentRatingWidgetWithID(widgetId, closeButtonText, activity) { error ->
                            if (error != null) {
                                result.error(
                                    "presentRatingWidgetWithID failed",
                                    "Error: Encountered error while showing feedback dialog: [$error]",
                                    error
                                )
                            } else {
                                result.success("presentRatingWidgetWithID success.")
                            }
                            methodChannel!!.invokeMethod("ratingWidgetCallback", error)
                        }
                }
                Constants.MethodNameConstants.setStarRatingDialogTexts -> {
                    config.setStarRatingTextTitle(args.getString(0))
                    config.setStarRatingTextMessage(args.getString(1))
                    config.setStarRatingTextDismiss(args.getString(2))
                    result.success("setStarRatingDialogTexts Success")
                }
                Constants.MethodNameConstants.askForStarRating -> {
                    if (activity == null) {
                        log("askForStarRating failed : Activity is null", LogLevel.ERROR)
                        result.error("askForStarRating Failed", "Activity is null", null)
                        return
                    }
                    Countly.sharedInstance().ratings()
                        .showStarRating(activity, object : StarRatingCallback {
                            override fun onRate(rating: Int) {
                                result.success("Rating: $rating")
                            }

                            override fun onDismiss() {
                                result.success("Rating: Modal dismissed.")
                            }
                        })
                }
                Constants.MethodNameConstants.getAvailableFeedbackWidgets -> {
                    Countly.sharedInstance().feedback().getAvailableFeedbackWidgets(
                        RetrieveFeedbackWidgets { retrievedWidgets, error ->
                            if (error != null) {
                                result.error("getAvailableFeedbackWidgets", error, null)
                                return@RetrieveFeedbackWidgets
                            }
                            retrievedWidgetList = retrievedWidgets
                            val retrievedWidgetsArray: MutableList<Map<String, String>> = ArrayList()
                            for (presentableFeedback in retrievedWidgets) {
                                val feedbackWidget: MutableMap<String, String> = HashMap()
                                feedbackWidget["id"] = presentableFeedback.widgetId
                                feedbackWidget["type"] = presentableFeedback.type.name
                                feedbackWidget["name"] = presentableFeedback.name
                                retrievedWidgetsArray.add(feedbackWidget)
                            }
                            result.success(retrievedWidgetsArray)
                        })
                }
                Constants.MethodNameConstants.presentFeedbackWidget -> {
                    if (activity == null) {
                        log("presentFeedbackWidget failed : Activity is null", LogLevel.ERROR)
                        result.error("presentFeedbackWidget Failed", "Activity is null", null)
                        return
                    }
                    val widgetId = args.getString(0)
                    val closeBtnText = args.getString(3)
                    val feedbackWidget = getFeedbackWidget(widgetId)
                    if (feedbackWidget == null) {
                        val errorMessage =
                            "No feedbackWidget is found against widget id : '$widgetId' , always call 'getFeedbackWidgets' to get updated list of feedback widgets."
                        log(errorMessage, LogLevel.WARNING)
                        result.error("presentFeedbackWidget", errorMessage, null)
                    } else {
                        Countly.sharedInstance().feedback().presentFeedbackWidget(
                            feedbackWidget,
                            activity,
                            closeBtnText,
                            object : FeedbackCallback {
                                override fun onFinished(error: String) {
                                    if (error != null) {
                                        result.error("presentFeedbackWidget", error, null)
                                    } else {
                                        methodChannel!!.invokeMethod("widgetShown", null)
                                        result.success("presentFeedbackWidget success")
                                    }
                                }

                                override fun onClosed() {
                                    methodChannel!!.invokeMethod("widgetClosed", null)
                                }
                            })
                    }
                }
                Constants.MethodNameConstants.getFeedbackWidgetData -> {
                    val widgetId = args.getString(0)
                    val feedbackWidget = getFeedbackWidget(widgetId)
                    if (feedbackWidget == null) {
                        val errorMessage =
                            "No feedbackWidget is found against widget id : '$widgetId' , always call 'getFeedbackWidgets' to get updated list of feedback widgets."
                        log(errorMessage, LogLevel.WARNING)
                        result.error("getFeedbackWidgetData", errorMessage, null)
                        feedbackWidgetDataCallback(null, errorMessage)
                    } else {
                        Countly.sharedInstance().feedback()
                            .getFeedbackWidgetData(feedbackWidget) { retrievedWidgetData, error ->
                                if (error != null) {
                                    result.error("getFeedbackWidgetData", error, null)
                                    feedbackWidgetDataCallback(null, error)
                                } else {
                                    try {
                                        result.success(toMap(retrievedWidgetData))
                                        feedbackWidgetDataCallback(toMap(retrievedWidgetData), null)
                                    } catch (e: JSONException) {
                                        result.error("getFeedbackWidgetData", e.message, null)
                                        feedbackWidgetDataCallback(null, e.message)
                                    }
                                }
                            }
                    }
                }
                Constants.MethodNameConstants.reportFeedbackWidgetManually -> {
                    val widgetInfo = args.getJSONArray(0)
                    val widgetData = args.getJSONObject(1)
                    val widgetResult = args.getJSONObject(2)
                    var widgetResultMap: Map<String, Any>? = null
                    if (widgetResult != null && widgetResult.length() > 0) {
                        widgetResultMap = toMap(widgetResult)
                    }
                    val widgetId = widgetInfo.getString(0)
                    val feedbackWidget = getFeedbackWidget(widgetId)
                    if (feedbackWidget == null) {
                        val errorMessage =
                            "No feedbackWidget is found against widget id : '$widgetId' , always call 'getFeedbackWidgets' to get updated list of feedback widgets."
                        log(errorMessage, LogLevel.WARNING)
                        result.error("reportFeedbackWidgetManually", errorMessage, null)
                    } else {
                        Countly.sharedInstance().feedback()
                            .reportFeedbackWidgetManually(feedbackWidget, widgetData, widgetResultMap)
                        result.success("reportFeedbackWidgetManually success")
                    }
                }
                Constants.MethodNameConstants.replaceAllAppKeysInQueueWithCurrentAppKey -> {
                    Countly.sharedInstance().requestQueue().overwriteAppKeys()
                    result.success("replaceAllAppKeysInQueueWithCurrentAppKey Success")
                }
                Constants.MethodNameConstants.removeDifferentAppKeysFromQueue -> {
                    Countly.sharedInstance().requestQueue().eraseWrongAppKeyRequests()
                    result.success("removeDifferentAppKeysFromQueue Success")
                }
                Constants.MethodNameConstants.startTrace -> {
                    val traceKey = args.getString(0)
                    Countly.sharedInstance().apm().startTrace(traceKey)
                    result.success("startTrace: success")
                }
                Constants.MethodNameConstants.cancelTrace -> {
                    val traceKey = args.getString(0)
                    Countly.sharedInstance().apm().cancelTrace(traceKey)
                    result.success("cancelTrace: success")
                }
                Constants.MethodNameConstants.clearAllTraces -> {
                    Countly.sharedInstance().apm().cancelAllTraces()
                    result.success("clearAllTraces: success")
                }
                Constants.MethodNameConstants.endTrace -> {
                    val traceKey = args.getString(0)
                    val customMetric = HashMap<String, Int>()
                    var i = 1
                    val il = args.length()
                    while (i < il) {
                        try {
                            customMetric[args.getString(i)] = args.getString(i + 1).toInt()
                        } catch (exception: Exception) {
                            log(
                                "endTrace, could not parse metric, skipping it. ",
                                exception,
                                LogLevel.ERROR
                            )
                        }
                        i += 2
                    }
                    Countly.sharedInstance().apm().endTrace(traceKey, customMetric)
                    result.success("endTrace: success")
                }
                Constants.MethodNameConstants.recordNetworkTrace -> {
                    try {
                        val networkTraceKey = args.getString(0)
                        val responseCode = args.getString(1).toInt()
                        val requestPayloadSize = args.getString(2).toInt()
                        val responsePayloadSize = args.getString(3).toInt()
                        val startTime = args.getString(4).toLong()
                        val endTime = args.getString(5).toLong()
                        Countly.sharedInstance().apm().recordNetworkTrace(
                            networkTraceKey,
                            responseCode,
                            requestPayloadSize,
                            responsePayloadSize,
                            startTime,
                            endTime
                        )
                    } catch (exception: Exception) {
                        log(
                            "Exception occurred at recordNetworkTrace method: ",
                            exception,
                            LogLevel.ERROR
                        )
                    }
                    result.success("recordNetworkTrace: success")
                }
                Constants.MethodNameConstants.enableApm -> {
                    config.setRecordAppStartTime(true)
                    result.success("enableApm: success")
                }
                Constants.MethodNameConstants.throwNativeException -> {
                    throw IllegalStateException("Native Exception Crashhh!")
                }
                Constants.MethodNameConstants.recordIndirectAttribution -> {
                    val attributionValues = args.getJSONObject(0)
                    if (attributionValues != null && attributionValues.length() > 0) {
                        val attributionMap = toMapString(attributionValues)
                        Countly.sharedInstance().attribution().recordIndirectAttribution(attributionMap)
                        result.success("recordIndirectAttribution: success")
                    } else {
                        result.error(
                            "iaAttributionFailed",
                            "recordIndirectAttribution: failure, no attribution values provided",
                            null
                        )
                    }
                }
                Constants.MethodNameConstants.recordDirectAttribution -> {
                    val campaignType = args.getString(0)
                    val campaignData = args.getString(1)
                    Countly.sharedInstance().attribution()
                        .recordDirectAttribution(campaignType, campaignData)
                    result.success("recordIndirectAttribution: success")
                }
                Constants.MethodNameConstants.appLoadingFinished -> {
                    Countly.sharedInstance().apm().setAppIsLoaded()
                    result.success("appLoadingFinished: success")
                }
            }
        } catch (jsonException: JSONException) {
            result.success(jsonException.toString())
        }
    }

    fun getFeedbackWidget(widgetId: String): CountlyFeedbackWidget? {
        if (retrievedWidgetList == null) {
            return null
        }
        for (feedbackWidget in retrievedWidgetList!!) {
            if (feedbackWidget!!.widgetId == widgetId) {
                return feedbackWidget
            }
        }
        return null
    }

    private fun feedbackWidgetDataCallback(widgetData: Map<String, Any>?, error: String?) {
        val feedbackWidgetData: MutableMap<String, Any> = HashMap()
        if (widgetData != null) {
            feedbackWidgetData["widgetData"] = widgetData
        }
        if (error != null) {
            feedbackWidgetData["error"] = error
        }
        methodChannel!!.invokeMethod("feedbackWidgetDataCallback", feedbackWidgetData)
    }

    fun registerForNotification(args: JSONArray?, theCallback: Callback): String {
        notificationListener = theCallback
        if (Countly.sharedInstance().isLoggingEnabled) {
            log("registerForNotification theCallback", LogLevel.INFO)
        }
        if (lastStoredNotification != null) {
            theCallback.callback(lastStoredNotification)
            lastStoredNotification = null
        }
        return "pushTokenType: success"
    }

    interface Callback {
        fun callback(result: String?)
    }

    enum class LogLevel {
        INFO, DEBUG, VERBOSE, WARNING, ERROR
    }

    private fun enableManualSessionControl() {
        manualSessionControlEnabled_ = true
        config.enableManualSessionControl()
    }

    @Throws(JSONException::class)
    private fun populateConfig(_config: JSONObject) {
        if (_config.has("serverURL")) {
            config.setServerURL(_config.getString("serverURL"))
        }
        if (_config.has("appKey")) {
            config.setAppKey(_config.getString("appKey"))
        }
        if (_config.has("deviceID")) {
            val deviceID = _config.getString("deviceID")
            if (deviceID == "TemporaryDeviceID") {
                config.enableTemporaryDeviceIdMode()
            } else {
                config.setDeviceId(deviceID)
            }
        }
        if (_config.has("loggingEnabled")) {
            config.setLoggingEnabled(_config.getBoolean("loggingEnabled"))
        }
        if (_config.has("httpPostForced")) {
            config.setHttpPostForced(_config.getBoolean("httpPostForced"))
        }
        if (_config.has("shouldRequireConsent")) {
            config.setRequiresConsent(_config.getBoolean("shouldRequireConsent"))
        }
        if (_config.has("tamperingProtectionSalt")) {
            config.setParameterTamperingProtectionSalt(_config.getString("tamperingProtectionSalt"))
        }
        if (_config.has("eventQueueSizeThreshold")) {
            config.setEventQueueSizeToSend(_config.getInt("eventQueueSizeThreshold"))
        }
        if (_config.has("sessionUpdateTimerDelay")) {
            config.setUpdateSessionTimerDelay(_config.getInt("sessionUpdateTimerDelay"))
        }
        if (_config.has("customCrashSegment")) {
            val customCrashSegment = toMap(_config.getJSONObject("customCrashSegment"))
            config.setCustomCrashSegment(customCrashSegment)
        }
        if (_config.has("providedUserProperties")) {
            val providedUserProperties = toMap(_config.getJSONObject("providedUserProperties"))
            config.setUserProperties(providedUserProperties)
        }
        if (_config.has("consents")) {
            val consents = toStringArray(_config.getJSONArray("consents"))
            config.setConsentEnabled(consents)
        }
        if (_config.has("starRatingTextTitle")) {
            config.setStarRatingTextTitle(_config.getString("starRatingTextTitle"))
        }
        if (_config.has("starRatingTextMessage")) {
            config.setStarRatingTextMessage(_config.getString("starRatingTextMessage"))
        }
        if (_config.has("starRatingTextDismiss")) {
            config.setStarRatingTextDismiss(_config.getString("starRatingTextDismiss"))
        }
        if (_config.has("recordAppStartTime")) {
            config.setRecordAppStartTime(_config.getBoolean("recordAppStartTime"))
        }
        if (_config.has("enableUnhandledCrashReporting") && _config.getBoolean("enableUnhandledCrashReporting")) {
            config.enableCrashReporting()
        }
        if (_config.has("maxRequestQueueSize")) {
            config.setMaxRequestQueueSize(_config.getInt("maxRequestQueueSize"))
        }
        if (_config.has("manualSessionEnabled") && _config.getBoolean("manualSessionEnabled")) {
            enableManualSessionControl()
        }
        if (_config.has("enableRemoteConfigAutomaticDownload")) {
            val enableRemoteConfigAutomaticDownload =
                _config.getBoolean("enableRemoteConfigAutomaticDownload")
            config.setRemoteConfigAutomaticDownload(
                enableRemoteConfigAutomaticDownload,
                RemoteConfigCallback { error ->
                    methodChannel!!.invokeMethod(
                        "remoteConfigCallback",
                        error
                    )
                })
        }
        var countryCode: String? = null
        var city: String? = null
        var gpsCoordinates: String? = null
        var ipAddress: String? = null
        if (_config.has("locationCountryCode")) {
            countryCode = _config.getString("locationCountryCode")
        }
        if (_config.has("locationCity")) {
            city = _config.getString("locationCity")
        }
        if (_config.has("locationGpsCoordinates")) {
            gpsCoordinates = _config.getString("locationGpsCoordinates")
        }
        if (_config.has("locationIpAddress")) {
            ipAddress = _config.getString("locationIpAddress")
        }
        if (city != null || countryCode != null || gpsCoordinates != null || ipAddress != null) {
            config.setLocation(countryCode, city, gpsCoordinates, ipAddress)
        }
        if (_config.has("campaignType")) {
            val campaignType = _config.getString("campaignType")
            val campaignData = _config.getString("campaignData")
            config.setDirectAttribution(campaignType, campaignData)
        }
        if (_config.has("attributionValues")) {
            val attributionValues = _config.getJSONObject("attributionValues")
            config.setIndirectAttribution(toMapString(attributionValues))
        }
    }

    companion object {
        private const val TAG = "CountlyFlutterPlugin"
        private const val isDebug = false
        private var notificationListener: Callback? = null
        private var lastStoredNotification: String? = null
        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            val instance = CountlyFlutterPlugin()
            instance.activity = registrar.activity()
            val __context = registrar.context()
            instance.onAttachedToEngineInternal(__context, registrar.messenger())
            log("registerWith", LogLevel.INFO)
        }

        fun onNotification(notification: Map<String?, String?>?) {
            val json = JSONObject(notification)
            val notificationString = json.toString()
            log(notificationString, LogLevel.INFO)
            if (notificationListener != null) {
                notificationListener!!.callback(notificationString)
            } else {
                lastStoredNotification = notificationString
            }
        }

        fun log(message: String?, logLevel: LogLevel?) {
            log(message, null, logLevel)
        }

        fun log(message: String?, tr: Throwable?, logLevel: LogLevel?) {
            if (!isDebug && !Countly.sharedInstance().isLoggingEnabled) {
                return
            }
            when (logLevel) {
                LogLevel.INFO -> Log.i(TAG, message, tr)
                LogLevel.DEBUG -> Log.d(TAG, message, tr)
                LogLevel.WARNING -> Log.w(TAG, message, tr)
                LogLevel.ERROR -> Log.e(TAG, message, tr)
                LogLevel.VERBOSE -> Log.v(TAG, message, tr)
                else -> {}
            }
        }

        @Throws(JSONException::class)
        fun toMap(jsonobj: JSONObject): Map<String, Any> {
            val map: MutableMap<String, Any> = HashMap()
            val keys = jsonobj.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                var value = jsonobj[key]
                if (value is JSONArray) {
                    value = toList(value)
                } else if (value is JSONObject) {
                    value = toMap(value)
                }
                map[key] = value
            }
            return map
        }

        fun toMapString(jsonobj: JSONObject): Map<String, String> {
            val map: MutableMap<String, String> = HashMap()
            try {
                val keys = jsonobj.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val value = jsonobj[key]
                    if (value is String) {
                        map[key] = value
                    }
                }
            } catch (e: JSONException) {
                log("Exception occurred at 'toMapString' method: ", e, LogLevel.ERROR)
            }
            return map
        }

        @Throws(JSONException::class)
        fun toList(array: JSONArray): List<Any> {
            val list: MutableList<Any> = ArrayList()
            for (i in 0 until array.length()) {
                var value = array[i]
                if (value is JSONArray) {
                    value = toList(value)
                } else if (value is JSONObject) {
                    value = toMap(value)
                }
                list.add(value)
            }
            return list
        }

        fun toStringArray(array: JSONArray?): Array<String?>? {
            if (array == null) return null
            val size = array.length()
            val stringArray = arrayOfNulls<String>(size)
            for (i in 0 until size) {
                stringArray[i] = array.optString(i)
            }
            return stringArray
        }
    }
}