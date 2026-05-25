package com.belvix.app

import android.content.Context

import io.flutter.plugin.common.EventChannel

import io.flutter.plugin.common.MethodCall

import io.flutter.plugin.common.MethodChannel

class CgmSdkBridge(
    private val context: Context,
    private val eventSink:
        EventChannel.EventSink?
) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {

        when (call.method) {

            "init" -> {

                result.success(true)
            }

            else -> {

                result.notImplemented()
            }
        }
    }
}