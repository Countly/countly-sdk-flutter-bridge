package com.countly.demo;

import android.app.Activity;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.FirebaseApp;
import com.google.firebase.iid.FirebaseInstanceId;
import com.google.firebase.iid.InstanceIdResult;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import ly.count.android.sdk.Countly;
import ly.count.android.sdk.messaging.CountlyPush;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    /*
    Activity activity = this;
    Context context = activity.getApplicationContext();
    Countly.CountlyMessagingMode pushTokenType = Countly.CountlyMessagingMode.TEST;

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
                  Log.w("Tag", "getInstanceId failed", task.getException());
                  return;
                }
                String token = task.getResult().getToken();
                CountlyPush.onTokenRefresh(token);
              }
            });

     */

  }
}
