package dev.amirzr.flutter_v2ray_client.v2ray.services

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import dev.amirzr.flutter_v2ray_client.v2ray.core.V2rayCoreManager
import dev.amirzr.flutter_v2ray_client.v2ray.interfaces.V2rayServicesListener
import dev.amirzr.flutter_v2ray_client.v2ray.utils.AppConfigs
import dev.amirzr.flutter_v2ray_client.v2ray.utils.V2rayConfig

class V2rayProxyOnlyService : Service(), V2rayServicesListener {
    
    override fun onCreate() {
        super.onCreate()
        V2rayCoreManager.getInstance().setUpListener(this)
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val startCommand = intent?.getSerializableExtra("COMMAND") as? AppConfigs.V2RAY_SERVICE_COMMANDS
        
        when (startCommand) {
            AppConfigs.V2RAY_SERVICE_COMMANDS.START_SERVICE -> {
                val v2rayConfig = intent.getSerializableExtra("V2RAY_CONFIG") as? V2rayConfig
                if (v2rayConfig == null) {
                    onDestroy()
                    return START_NOT_STICKY
                }
                
                if (V2rayCoreManager.getInstance().isV2rayCoreRunning) {
                    V2rayCoreManager.getInstance().stopCore()
                }
                
                if (V2rayCoreManager.getInstance().startCore(v2rayConfig)) {
                    Log.e(V2rayProxyOnlyService::class.java.simpleName, "onStartCommand success => v2ray core started.")
                } else {
                    onDestroy()
                }
            }
            AppConfigs.V2RAY_SERVICE_COMMANDS.STOP_SERVICE -> {
                V2rayCoreManager.getInstance().stopCore()
                AppConfigs.V2RAY_CONFIG = null
                stopService()
            }
            AppConfigs.V2RAY_SERVICE_COMMANDS.MEASURE_DELAY -> {
                Thread({
                    val url = intent?.getStringExtra("URL") ?: "https://www.gstatic.com/generate_204"
                    val delay = V2rayCoreManager.getInstance().getConnectedV2rayServerDelay(url)
                    val sendIntent = Intent("CONNECTED_V2RAY_SERVER_DELAY")
                    sendIntent.putExtra("DELAY", delay.toString())
                    sendBroadcast(sendIntent)
                }, "MEASURE_CONNECTED_V2RAY_SERVER_DELAY").start()
            }
            else -> onDestroy()
        }
        
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onProtect(socket: Int): Boolean {
        return true
    }
    
    override fun getService(): Service {
        return this
    }
    
    override fun startService() {
    }
    
    override fun stopService() {
        try {
            stopSelf()
        } catch (e: Exception) {
        }
    }
}
