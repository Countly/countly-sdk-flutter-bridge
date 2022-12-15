package com.countly.demo;

import android.app.Application;
import android.util.Log;

import io.flutter.app.FlutterApplication;
import ly.count.android.sdk.Countly;

public class App extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        Log.i("App", "applicationOnCreate");
        Countly.applicationOnCreate();
    }
}