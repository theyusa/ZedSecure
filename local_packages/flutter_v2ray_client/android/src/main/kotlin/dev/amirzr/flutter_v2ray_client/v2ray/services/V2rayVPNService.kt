package dev.amirzr.flutter_v2ray_client.v2ray.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import dev.amirzr.flutter_v2ray_client.v2ray.core.HevTunCore
import dev.amirzr.flutter_v2ray_client.v2ray.core.V2rayCoreManager
import dev.amirzr.flutter_v2ray_client.v2ray.interfaces.V2rayServicesListener
import dev.amirzr.flutter_v2ray_client.v2ray.utils.AppConfigs
import dev.amirzr.flutter_v2ray_client.v2ray.utils.V2rayConfig
import org.json.JSONArray
import org.json.JSONObject
import java.net.InetAddress

class V2rayVPNService : VpnService(), V2rayServicesListener {
    
    companion object {
        private const val TAG = "V2rayVPNService"
        private const val CHANNEL_ID = "V2rayVPNChannel"
        private const val NOTIFICATION_ID = 1
    }
    
    private var mInterface: ParcelFileDescriptor? = null
    private var v2rayConfig: V2rayConfig? = null
    private var isRunning = false
    
    override fun onCreate() {
        super.onCreate()
        V2rayCoreManager.getInstance().setUpListener(this)
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val startCommand = intent?.getSerializableExtra("COMMAND") as? AppConfigs.V2RAY_SERVICE_COMMANDS
        
        when (startCommand) {
            AppConfigs.V2RAY_SERVICE_COMMANDS.START_SERVICE -> {
                v2rayConfig = intent.getSerializableExtra("V2RAY_CONFIG") as? V2rayConfig
                if (v2rayConfig == null) {
                    onDestroy()
                    return START_NOT_STICKY
                }
                
                if (V2rayCoreManager.getInstance().isV2rayCoreRunning) {
                    V2rayCoreManager.getInstance().stopCore()
                }
                
                setup()
                
                v2rayConfig?.let { config ->
                    val tunFd = 0
                    if (V2rayCoreManager.getInstance().startCore(config, tunFd)) {
                        Log.d(TAG, "V2ray core started successfully with tunFd=$tunFd (hevTun mode)")
                        startHevTun()
                    } else {
                        onDestroy()
                    }
                }
            }
            AppConfigs.V2RAY_SERVICE_COMMANDS.STOP_SERVICE -> {
                V2rayCoreManager.getInstance().stopCore()
                AppConfigs.V2RAY_CONFIG = null
                stopAllProcess()
            }
            AppConfigs.V2RAY_SERVICE_COMMANDS.MEASURE_DELAY -> {
                Thread {
                    val url = intent?.getStringExtra("URL") ?: "https://www.gstatic.com/generate_204"
                    Log.d(TAG, "MEASURE_DELAY => measuring with url: $url")
                    val delay = V2rayCoreManager.getInstance().getConnectedV2rayServerDelay(url)
                    Log.d(TAG, "MEASURE_DELAY => result: $delay ms")
                    val sendIntent = Intent("CONNECTED_V2RAY_SERVER_DELAY")
                    sendIntent.putExtra("DELAY", delay.toString())
                    sendBroadcast(sendIntent)
                }.start()
            }
            else -> onDestroy()
        }
        
        return START_STICKY
    }
    
    private fun stopAllProcess() {
        stopForeground(true)
        isRunning = false
        
        HevTunCore.stop()
        V2rayCoreManager.getInstance().stopCore()
        
        try {
            stopSelf()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop self", e)
        }
        
        try {
            mInterface?.close()
            mInterface = null
        } catch (e: Exception) {
            Log.e(TAG, "Failed to close interface", e)
        }
    }
    
    private fun setup() {
        Log.d(TAG, "setup() called")
        
        val prepareIntent = prepare(this)
        if (prepareIntent != null) {
            Log.e(TAG, "VPN permission not granted! Need to request permission.")
            stopAllProcess()
            return
        }
        
        Log.d(TAG, "VPN permission granted, starting foreground service")
        startForegroundService()
        
        val builder = Builder()
        val config = v2rayConfig ?: return
        
        Log.d(TAG, "Building VPN interface for: ${config.REMARK}")
        builder.setSession(config.REMARK)
        builder.setMtu(1500)
        builder.addAddress("10.1.0.2", 24)
        
        val proxyServerIp = extractProxyServerIp()
        
        val bypassSubnets = config.BYPASS_SUBNETS
        if (bypassSubnets.isNullOrEmpty()) {
            if (proxyServerIp != null) {
                val routes = excludeIpFromRoutes("0.0.0.0/0", proxyServerIp)
                routes.forEach { route ->
                    val parts = route.split("/")
                    if (parts.size == 2) {
                        builder.addRoute(parts[0], parts[1].toInt())
                    }
                }
            } else {
                builder.addRoute("0.0.0.0", 0)
            }
        } else {
            bypassSubnets.forEach { subnet ->
                val parts = subnet.split("/")
                if (parts.size == 2) {
                    builder.addRoute(parts[0], parts[1].toInt())
                }
            }
        }
        
        try {
            builder.addDisallowedApplication(packageName)
            Log.d(TAG, "Excluded self from VPN: $packageName")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to exclude self from VPN", e)
        }
        
        config.BLOCKED_APPS?.forEach { app ->
            try {
                builder.addDisallowedApplication(app)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to exclude app: $app", e)
            }
        }
        
        try {
            val json = JSONObject(config.V2RAY_FULL_JSON_CONFIG)
            if (json.has("dns")) {
                val dnsObject = json.getJSONObject("dns")
                if (dnsObject.has("servers")) {
                    val serversArray = dnsObject.getJSONArray("servers")
                    for (i in 0 until serversArray.length()) {
                        try {
                            when (val entry = serversArray.get(i)) {
                                is String -> builder.addDnsServer(entry)
                                is JSONObject -> {
                                    if (entry.has("address")) {
                                        builder.addDnsServer(entry.getString("address"))
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            Log.w(TAG, "Failed to add DNS server", e)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            try { builder.addDnsServer("8.8.8.8") } catch (e: Exception) {}
            try { builder.addDnsServer("8.8.4.4") } catch (e: Exception) {}
        }
        
        try {
            mInterface?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to close previous interface", e)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }
        
        Log.d(TAG, "Establishing VPN interface...")
        try {
            mInterface = builder.establish()
            if (mInterface == null) {
                Log.e(TAG, "Failed to establish VPN interface - builder.establish() returned null")
                stopAllProcess()
                return
            }
            Log.d(TAG, "VPN interface established successfully with FD: ${mInterface?.fd}")
            isRunning = true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to establish VPN interface", e)
            stopAllProcess()
        }
    }
    
    private fun startHevTun() {
        val vpnInterface = mInterface ?: return
        val config = v2rayConfig ?: return
        val socksPort = config.LOCAL_SOCKS5_PORT
        val mtu = 1500
        val ipv4Address = "10.1.0.1"
        val ipv6Address = "fc00::1"
        val preferIpv6 = false
        
        Log.d(TAG, "Starting HevTun with fd=${vpnInterface.fd}, socks=127.0.0.1:$socksPort")
        
        val started = HevTunCore.start(
            context = this,
            vpnInterface = vpnInterface,
            socksPort = socksPort,
            mtu = mtu,
            ipv4Address = ipv4Address,
            ipv6Address = ipv6Address,
            preferIpv6 = preferIpv6,
            listener = this
        )
        
        if (!started) {
            Log.e(TAG, "Failed to start HevTun")
            stopAllProcess()
        } else {
            Log.d(TAG, "HevTun started successfully")
        }
    }
    
    private fun extractProxyServerIp(): String? {
        val config = v2rayConfig ?: return null
        try {
            val json = JSONObject(config.V2RAY_FULL_JSON_CONFIG)
            if (json.has("outbounds")) {
                val outbounds = json.getJSONArray("outbounds")
                for (i in 0 until outbounds.length()) {
                    val outbound = outbounds.getJSONObject(i)
                    if (outbound.has("settings")) {
                        val settings = outbound.getJSONObject("settings")
                        
                        if (settings.has("vnext")) {
                            val vnext = settings.getJSONArray("vnext")
                            if (vnext.length() > 0) {
                                val server = vnext.getJSONObject(0)
                                if (server.has("address")) {
                                    val address = server.getString("address")
                                    if (isValidIpv4(address)) {
                                        return address
                                    }
                                }
                            }
                        }
                        
                        if (settings.has("servers")) {
                            val servers = settings.getJSONArray("servers")
                            if (servers.length() > 0) {
                                val server = servers.getJSONObject(0)
                                if (server.has("address")) {
                                    val address = server.getString("address")
                                    if (isValidIpv4(address)) {
                                        return address
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to extract proxy server IP", e)
        }
        return null
    }
    
    private fun isValidIpv4(ip: String): Boolean {
        val parts = ip.split(".")
        if (parts.size != 4) return false
        return parts.all { 
            try {
                val num = it.toInt()
                num in 0..255
            } catch (e: Exception) {
                false
            }
        }
    }
    
    private fun excludeIpFromRoutes(cidr: String, excludeIp: String): List<String> {
        val routes = mutableListOf<String>()
        try {
            val parts = cidr.split("/")
            val baseIp = parts[0]
            val prefix = parts[1].toInt()
            
            val baseIpLong = ipToLong(baseIp)
            val excludeIpLong = ipToLong(excludeIp)
            val mask = (0xFFFFFFFFL shl (32 - prefix)) and 0xFFFFFFFFL
            val networkStart = baseIpLong and mask
            val networkEnd = networkStart or (mask.inv() and 0xFFFFFFFFL)
            
            if (excludeIpLong < networkStart || excludeIpLong > networkEnd) {
                routes.add(cidr)
                return routes
            }
            
            if (prefix >= 31) {
                return routes
            }
            
            var currentStart = networkStart
            var currentPrefix = prefix
            
            while (currentStart < excludeIpLong) {
                while (currentPrefix < 32) {
                    val testMask = (0xFFFFFFFFL shl (32 - (currentPrefix + 1))) and 0xFFFFFFFFL
                    val testStart = currentStart and testMask
                    val testEnd = testStart or (testMask.inv() and 0xFFFFFFFFL)
                    
                    if (testStart == currentStart && testEnd < excludeIpLong) {
                        routes.add("${longToIp(currentStart)}/${currentPrefix + 1}")
                        currentStart = testEnd + 1
                        currentPrefix = prefix
                        break
                    }
                    currentPrefix++
                }
                if (currentPrefix >= 32) break
            }
            
            currentStart = excludeIpLong + 1
            currentPrefix = prefix
            
            while (currentStart <= networkEnd) {
                while (currentPrefix < 32) {
                    val testMask = (0xFFFFFFFFL shl (32 - (currentPrefix + 1))) and 0xFFFFFFFFL
                    val testStart = currentStart and testMask
                    val testEnd = testStart or (testMask.inv() and 0xFFFFFFFFL)
                    
                    if (testStart == currentStart && testEnd <= networkEnd) {
                        routes.add("${longToIp(currentStart)}/${currentPrefix + 1}")
                        currentStart = testEnd + 1
                        currentPrefix = prefix
                        break
                    }
                    currentPrefix++
                }
                if (currentPrefix >= 32) break
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to exclude IP from routes", e)
            routes.add(cidr)
        }
        return routes
    }
    
    private fun ipToLong(ip: String): Long {
        val cleanIp = ip.split("%")[0]
        val parts = cleanIp.split(".")
        if (parts.size != 4) {
            throw IllegalArgumentException("Invalid IP address: $ip")
        }
        var result = 0L
        for (i in 0..3) {
            result = result or (parts[i].toLong() shl (24 - (i * 8)))
        }
        return result and 0xFFFFFFFFL
    }
    
    private fun longToIp(ip: Long): String {
        return "${(ip shr 24) and 0xFF}.${(ip shr 16) and 0xFF}.${(ip shr 8) and 0xFF}.${ip and 0xFF}"
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "VPN connection status"
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
    
    private fun startForegroundService() {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        
        builder.setContentTitle("VPN Connected")
            .setContentText("Secure connection active")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
        
        val notification = builder.build()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
    }
    
    override fun onRevoke() {
        stopAllProcess()
    }
    
    override fun onProtect(socket: Int): Boolean {
        return protect(socket)
    }
    
    override fun getService(): Service {
        return this
    }
    
    override fun startService() {
        setup()
    }
    
    override fun stopService() {
        stopAllProcess()
    }
}
