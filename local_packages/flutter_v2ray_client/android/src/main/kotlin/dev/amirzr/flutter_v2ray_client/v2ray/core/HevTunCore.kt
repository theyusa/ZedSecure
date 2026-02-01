package dev.amirzr.flutter_v2ray_client.v2ray.core

import android.content.Context
import android.os.ParcelFileDescriptor
import android.util.Log
import dev.amirzr.flutter_v2ray_client.v2ray.interfaces.V2rayServicesListener
import java.io.File

object HevTunCore {
    private const val TAG = "HevTunCore"
    
    @Volatile
    private var isRunning = false
    
    @JvmStatic
    @Suppress("FunctionName")
    private external fun TProxyStartService(configPath: String, fd: Int)
    
    @JvmStatic
    @Suppress("FunctionName")
    private external fun TProxyStopService()
    
    @JvmStatic
    @Suppress("FunctionName")
    private external fun TProxyGetStats(): LongArray?
    
    init {
        try {
            System.loadLibrary("hev-socks5-tunnel")
            Log.d(TAG, "hev-socks5-tunnel library loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "Failed to load hev-socks5-tunnel library", e)
        }
    }
    
    fun start(
        context: Context,
        vpnInterface: ParcelFileDescriptor,
        socksPort: Int,
        mtu: Int,
        ipv4Address: String,
        ipv6Address: String?,
        preferIpv6: Boolean,
        listener: V2rayServicesListener?
    ): Boolean {
        if (isRunning) {
            Log.w(TAG, "HevTun already running")
            return false
        }
        
        try {
            Log.d(TAG, "Starting HevTun")
            Log.d(TAG, "FD: ${vpnInterface.fd}")
            Log.d(TAG, "SOCKS: 127.0.0.1:$socksPort")
            Log.d(TAG, "MTU: $mtu")
            Log.d(TAG, "IPv4: $ipv4Address")
            
            val configContent = buildConfig(socksPort, mtu, ipv4Address, ipv6Address, preferIpv6)
            val configFile = File(context.filesDir, "hev-socks5-tunnel.yaml").apply {
                writeText(configContent)
            }
            
            Log.d(TAG, "Config:\n$configContent")
            
            TProxyStartService(configFile.absolutePath, vpnInterface.fd)
            isRunning = true
            
            Log.i(TAG, "HevTun started successfully")
            return true
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start HevTun", e)
            return false
        }
    }
    
    private fun buildConfig(
        socksPort: Int,
        mtu: Int,
        ipv4Address: String,
        ipv6Address: String?,
        preferIpv6: Boolean
    ): String {
        return buildString {
            appendLine("tunnel:")
            appendLine("  mtu: $mtu")
            appendLine("  ipv4: $ipv4Address")
            
            if (preferIpv6 && ipv6Address != null) {
                appendLine("  ipv6: '$ipv6Address'")
            }
            
            appendLine("socks5:")
            appendLine("  port: $socksPort")
            appendLine("  address: 127.0.0.1")
            appendLine("  udp: 'udp'")
            
            appendLine("misc:")
            appendLine("  tcp-read-write-timeout: 300000")
            appendLine("  udp-read-write-timeout: 60000")
            appendLine("  log-level: warn")
        }
    }
    
    fun stop() {
        if (!isRunning) {
            Log.w(TAG, "HevTun not running")
            return
        }
        
        try {
            Log.d(TAG, "Stopping HevTun")
            TProxyStopService()
            isRunning = false
            Log.i(TAG, "HevTun stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop HevTun", e)
        }
    }
    
    fun getStats(): LongArray? {
        return try {
            TProxyGetStats()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get stats", e)
            null
        }
    }
}

