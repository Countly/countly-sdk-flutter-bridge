package ly.count.dart.countly_flutter;

import org.json.JSONObject;
public class CountlyTestState {
 static Boolean isAppStartTimeTracked = false;
 static Boolean isForegroundBackgroundEnabled = false;
 static Boolean isManualAppLoadedTriggerEnabled = false;
 static Boolean isStartTSOverridden = false;
 static JSONObject initConfig = null;

 JSONObject getState() {
  JSONObject state = new JSONObject();
  try {
   state.put("isAppStartTimeTracked", isAppStartTimeTracked);
   state.put("isForegroundBackgroundEnabled", isForegroundBackgroundEnabled);
   state.put("isManualAppLoadedTriggerEnabled", isManualAppLoadedTriggerEnabled);
   state.put("isStartTSOverridden", isStartTSOverridden);
   state.put("initConfig", initConfig);
  } catch (Exception e) {
   e.printStackTrace();
  }
  return state;
 }
}
