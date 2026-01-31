package dev.amirzr.flutter_v2ray_client.v2ray.core

import android.content.Context
import android.net.VpnService
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

object FluxTunProcess {
    private const val TAG = "FluxTunProcess"
    
    private val isRunning = AtomicBoolean(false)
    
    fun start(
        context: Context,
        fd: Int,
        proxyUrl: String,
        dnsServer: String,
        mtu: Int,
        vpnService: VpnService
    ): Boolean {
        if (isRunning.get()) {
            Log.w(TAG, "FluxTun already running")
            return false
        }
        
        try {
            Log.d(TAG, "Starting FluxTun via JNI")
            Log.d(TAG, "FD: $fd")
            Log.d(TAG, "Proxy: $proxyUrl")
            Log.d(TAG, "DNS: $dnsServer")
            Log.d(TAG, "MTU: $mtu")
            
            val result = FluxTunJNI.startTunnel(fd, proxyUrl, dnsServer, mtu)
            
            if (result > 0) {
                isRunning.set(true)
                Log.i(TAG, "FluxTun started successfully")
                return true
            } else {
                Log.e(TAG, "FluxTun failed to start")
                return false
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start FluxTun", e)
            return false
        }
    }
    
    fun stop() {
        Log.d(TAG, "Stopping FluxTun")
        
        if (!isRunning.get()) {
            Log.w(TAG, "FluxTun not running")
            return
        }
        
        try {
            FluxTunJNI.stopTunnel()
            isRunning.set(false)
            Log.i(TAG, "FluxTun stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping FluxTun", e)
        }
    }
    
    fun isRunning(): Boolean = isRunning.get()
}
