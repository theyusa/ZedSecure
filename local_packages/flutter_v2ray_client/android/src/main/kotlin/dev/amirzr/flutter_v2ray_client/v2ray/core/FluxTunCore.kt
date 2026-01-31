package dev.amirzr.flutter_v2ray_client.v2ray.core

import android.net.VpnService
import android.util.Log

object FluxTunCore {
    private const val TAG = "FluxTunCore"
    
    init {
        try {
            System.loadLibrary("fluxtun")
            Log.d(TAG, "FluxTun library loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "Failed to load FluxTun library", e)
        }
    }
    
    external fun start(
        fd: Int,
        socksHost: String,
        socksPort: Int,
        mtu: Int,
        vpnService: VpnService
    ): Boolean
    
    external fun stop()
    
    external fun isRunning(): Boolean
    
    external fun getTxBytes(): Long
    
    external fun getRxBytes(): Long
}
