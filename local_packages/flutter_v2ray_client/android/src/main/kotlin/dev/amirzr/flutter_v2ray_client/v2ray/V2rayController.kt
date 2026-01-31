package dev.amirzr.flutter_v2ray_client.v2ray

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import dev.amirzr.flutter_v2ray_client.v2ray.core.V2rayCoreManager
import dev.amirzr.flutter_v2ray_client.v2ray.services.V2rayProxyOnlyService
import dev.amirzr.flutter_v2ray_client.v2ray.services.V2rayVPNService
import dev.amirzr.flutter_v2ray_client.v2ray.utils.AppConfigs
import dev.amirzr.flutter_v2ray_client.v2ray.utils.Utilities
import libv2ray.Libv2ray
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

object V2rayController {
    
    fun init(context: Context, appIcon: Int, appName: String) {
        Utilities.copyAssets(context)
        AppConfigs.APPLICATION_ICON = appIcon
        AppConfigs.APPLICATION_NAME = appName
        
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                AppConfigs.V2RAY_STATE = intent?.extras?.getSerializable("STATE") as? AppConfigs.V2RAY_STATES
                    ?: AppConfigs.V2RAY_STATES.V2RAY_DISCONNECTED
            }
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, IntentFilter("V2RAY_CONNECTION_INFO"), Context.RECEIVER_EXPORTED)
        } else {
            context.registerReceiver(receiver, IntentFilter("V2RAY_CONNECTION_INFO"))
        }
    }
    
    fun changeConnectionMode(connectionMode: AppConfigs.V2RAY_CONNECTION_MODES) {
        if (getConnectionState() == AppConfigs.V2RAY_STATES.V2RAY_DISCONNECTED) {
            AppConfigs.V2RAY_CONNECTION_MODE = connectionMode
        }
    }
    
    fun startV2ray(
        context: Context,
        remark: String?,
        config: String?,
        blockedApps: ArrayList<String>?,
        bypassSubnets: ArrayList<String>?
    ) {
        AppConfigs.V2RAY_CONFIG = Utilities.parseV2rayJsonFile(remark, config, blockedApps, bypassSubnets)
            ?: return
        
        val startIntent = when (AppConfigs.V2RAY_CONNECTION_MODE) {
            AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY -> Intent(context, V2rayProxyOnlyService::class.java)
            AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN -> Intent(context, V2rayVPNService::class.java)
            else -> return
        }
        
        startIntent.putExtra("COMMAND", AppConfigs.V2RAY_SERVICE_COMMANDS.START_SERVICE)
        startIntent.putExtra("V2RAY_CONFIG", AppConfigs.V2RAY_CONFIG)
        
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.N_MR1) {
            context.startForegroundService(startIntent)
        } else {
            context.startService(startIntent)
        }
    }
    
    fun stopV2ray(context: Context) {
        val stopIntent = when (AppConfigs.V2RAY_CONNECTION_MODE) {
            AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY -> Intent(context, V2rayProxyOnlyService::class.java)
            AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN -> Intent(context, V2rayVPNService::class.java)
            else -> return
        }
        
        stopIntent.putExtra("COMMAND", AppConfigs.V2RAY_SERVICE_COMMANDS.STOP_SERVICE)
        context.startService(stopIntent)
        AppConfigs.V2RAY_CONFIG = null
    }
    
    fun getConnectedV2rayServerDelay(context: Context): Long {
        if (getConnectionState() != AppConfigs.V2RAY_STATES.V2RAY_CONNECTED) {
            return -1
        }
        
        val checkDelay = when (AppConfigs.V2RAY_CONNECTION_MODE) {
            AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY -> Intent(context, V2rayProxyOnlyService::class.java)
            AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN -> Intent(context, V2rayVPNService::class.java)
            else -> return -1
        }
        
        val delay = longArrayOf(-1)
        val latch = CountDownLatch(1)
        
        checkDelay.putExtra("COMMAND", AppConfigs.V2RAY_SERVICE_COMMANDS.MEASURE_DELAY)
        context.startService(checkDelay)
        
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val delayString = intent?.extras?.getString("DELAY")
                delay[0] = delayString?.toLongOrNull() ?: -1
                context?.unregisterReceiver(this)
                latch.countDown()
            }
        }
        
        val delayIntentFilter = IntentFilter("CONNECTED_V2RAY_SERVER_DELAY")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.registerReceiver(receiver, delayIntentFilter, Context.RECEIVER_EXPORTED)
        } else {
            context.registerReceiver(receiver, delayIntentFilter)
        }
        
        return try {
            val received = latch.await(3000, TimeUnit.MILLISECONDS)
            if (!received) -1 else delay[0]
        } catch (e: InterruptedException) {
            e.printStackTrace()
            -1
        }
    }
    
    fun getConnectedV2rayServerDelayDirect(url: String?): Long {
        if (getConnectionState() != AppConfigs.V2RAY_STATES.V2RAY_CONNECTED) {
            return -1
        }
        return try {
            V2rayCoreManager.getInstance().getConnectedV2rayServerDelay(url ?: "")
        } catch (e: Exception) {
            -1
        }
    }
    
    fun getV2rayServerDelay(config: String?, url: String?): Long {
        return V2rayCoreManager.getInstance().getV2rayServerDelay(config ?: "", url ?: "")
    }
    
    fun getConnectionMode(): AppConfigs.V2RAY_CONNECTION_MODES {
        return AppConfigs.V2RAY_CONNECTION_MODE
    }
    
    fun getConnectionState(): AppConfigs.V2RAY_STATES {
        return AppConfigs.V2RAY_STATE
    }
    
    fun getCoreVersion(): String {
        return Libv2ray.checkVersionX()
    }
}
