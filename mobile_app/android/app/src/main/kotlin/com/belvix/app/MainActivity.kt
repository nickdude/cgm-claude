package com.belvix.app

import io.flutter.embedding.android.FlutterActivity

import io.flutter.embedding.engine.FlutterEngine

import io.flutter.plugin.common.EventChannel

import io.flutter.plugin.common.MethodChannel

class MainActivity :
    FlutterActivity() {

    private val METHOD_CHANNEL =
        "cgm_sdk/method"

    private val EVENT_CHANNEL =
        "cgm_sdk/events"

    private var eventSink:
            EventChannel.EventSink? =
        null

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {

        super.configureFlutterEngine(
            flutterEngine
        )

        EventChannel(
            flutterEngine.dartExecutor
                .binaryMessenger,

            EVENT_CHANNEL
        ).setStreamHandler(
            object :
                EventChannel.StreamHandler {

                override fun onListen(
                    arguments: Any?,
                    events:
                        EventChannel.EventSink?
                ) {

                    eventSink = events
                }

                override fun onCancel(
                    arguments: Any?
                ) {

                    eventSink = null
                }
            }
        )

        MethodChannel(
            flutterEngine.dartExecutor
                .binaryMessenger,

            METHOD_CHANNEL
        ).setMethodCallHandler(

            CgmSdkBridge(
                this,
                eventSink
            )
        )
    }
}