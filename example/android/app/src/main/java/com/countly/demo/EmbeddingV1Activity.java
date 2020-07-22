package com.countly.demo;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import ly.count.dart.countly_flutter.CountlyFlutterPlugin;

public class EmbeddingV1Activity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        CountlyFlutterPlugin.registerWith(registrarFor("ly.count.dart.countly_flutter.CountlyFlutterPlugin"));
    }
}