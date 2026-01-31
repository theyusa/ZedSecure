package dev.amirzr.flutter_v2ray_client.v2ray.core

import android.util.Log

object FluxTunJNI {
    private const val TAG = "FluxTunJNI"
    
    init {
        try {
            System.loadLibrary("fluxtun")
            Log.d(TAG, "FluxTun JNI library loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "Failed to load FluxTun JNI library", e)
        }
    }
    
    external fun startTunnel(
        fd: Int,
        proxyUrl: String,
        dnsServer: String,
        mtu: Int
    ): Long
    
    external fun stopTunnel()
}
