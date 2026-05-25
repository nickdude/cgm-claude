package com.belvix.app

import android.app.Application
import android.util.Log

import com.eaglenos.blehealth.cgm.CgmDeviceManager

class BelvixApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        try {
            CgmDeviceManager.getInstance().init(this)
            Log.i(TAG, "CgmDeviceManager initialized")
        } catch (t: Throwable) {
            // Init can fail on emulators / unsupported devices.
            // Swallow so the app still boots; the bridge surfaces
            // a clear error to Dart on the next SDK call.
            Log.e(TAG, "CgmDeviceManager init failed", t)
        }
    }

    companion object {
        private const val TAG = "BelvixApplication"
    }
}
