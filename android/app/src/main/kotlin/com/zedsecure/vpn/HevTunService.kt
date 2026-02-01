package com.zedsecure.vpn

import android.content.Context
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.File

class HevTunService(
    private val context: Context,
    private val vpnInterface: ParcelFileDescriptor,
    private val socksPort: Int,
    private val mtu: Int,
    private val ipv4Address: String,
    private val ipv6Address: String?,
    private val preferIpv6: Boolean
) {
    companion object {
        private const val TAG = "HevTunService"
        
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
                Log.i(TAG, "hev-socks5-tunnel library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load hev-socks5-tunnel library", e)
            }
        }
    }

    fun start() {
        Log.i(TAG, "Starting HevSocks5Tunnel")

        val configContent = buildConfig()
        val configFile = File(context.filesDir, "hev-socks5-tunnel.yaml").apply {
            writeText(configContent)
        }
        
        Log.d(TAG, "HevSocks5Tunnel Config:\n$configContent")

        try {
            TProxyStartService(configFile.absolutePath, vpnInterface.fd)
            Log.i(TAG, "HevSocks5Tunnel started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start HevSocks5Tunnel", e)
            throw e
        }
    }

    private fun buildConfig(): String {
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
        try {
            Log.i(TAG, "Stopping HevSocks5Tunnel")
            TProxyStopService()
            Log.i(TAG, "HevSocks5Tunnel stopped successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop HevSocks5Tunnel", e)
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
