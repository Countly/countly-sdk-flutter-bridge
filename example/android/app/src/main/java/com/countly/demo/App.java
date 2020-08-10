package com.countly.demo;

import android.app.Application;
import ly.count.android.sdk.Countly;

public class App extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        Countly.applicationOnCreate();
    }
}