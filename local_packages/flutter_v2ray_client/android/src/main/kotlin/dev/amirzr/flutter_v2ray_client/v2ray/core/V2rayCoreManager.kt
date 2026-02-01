package dev.amirzr.flutter_v2ray_client.v2ray.core

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build
import android.os.CountDownTimer
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import dev.amirzr.flutter_v2ray_client.v2ray.interfaces.V2rayServicesListener
import dev.amirzr.flutter_v2ray_client.v2ray.services.V2rayProxyOnlyService
import dev.amirzr.flutter_v2ray_client.v2ray.services.V2rayVPNService
import dev.amirzr.flutter_v2ray_client.v2ray.utils.AppConfigs
import dev.amirzr.flutter_v2ray_client.v2ray.utils.Utilities
import dev.amirzr.flutter_v2ray_client.v2ray.utils.V2rayConfig
import libv2ray.CoreCallbackHandler
import libv2ray.CoreController
import libv2ray.Libv2ray
import org.json.JSONObject

class V2rayCoreManager private constructor() {
    
    companion object {
        private const val NOTIFICATION_ID = 1
        private const val TAG = "V2rayCoreManager"
        
        @Volatile
        private var INSTANCE: V2rayCoreManager? = null
        
        fun getInstance(): V2rayCoreManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: V2rayCoreManager().also { INSTANCE = it }
            }
        }
    }
    
    var v2rayServicesListener: V2rayServicesListener? = null
    private var coreController: CoreController? = null
    var V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_DISCONNECTED
    private var isLibV2rayCoreInitialized = false
    private var countDownTimer: CountDownTimer? = null
    private var seconds = 0
    private var minutes = 0
    private var hours = 0
    private var totalDownload = 0L
    private var totalUpload = 0L
    private var uploadSpeed = 0L
    private var downloadSpeed = 0L
    private var SERVICE_DURATION = "00:00:00"
    private var currentV2rayConfig: V2rayConfig? = null
    
    private fun makeDurationTimer(context: Context, enableTrafficStatics: Boolean) {
        countDownTimer = object : CountDownTimer(7200, 1000) {
            @RequiresApi(Build.VERSION_CODES.M)
            override fun onTick(millisUntilFinished: Long) {
                seconds++
                if (seconds == 59) {
                    minutes++
                    seconds = 0
                }
                if (minutes == 59) {
                    minutes = 0
                    hours++
                }
                if (hours == 23) {
                    hours = 0
                }
                
                if (enableTrafficStatics) {
                    downloadSpeed = (coreController?.queryStats("block", "downlink") ?: 0) +
                            (coreController?.queryStats("proxy", "downlink") ?: 0)
                    uploadSpeed = (coreController?.queryStats("block", "uplink") ?: 0) +
                            (coreController?.queryStats("proxy", "uplink") ?: 0)
                    totalDownload += downloadSpeed
                    totalUpload += uploadSpeed
                }
                
                SERVICE_DURATION = "${Utilities.convertIntToTwoDigit(hours)}:" +
                        "${Utilities.convertIntToTwoDigit(minutes)}:" +
                        "${Utilities.convertIntToTwoDigit(seconds)}"
                
                val connectionInfoIntent = Intent("V2RAY_CONNECTION_INFO").apply {
                    putExtra("STATE", V2RAY_STATE)
                    putExtra("DURATION", SERVICE_DURATION)
                    putExtra("UPLOAD_SPEED", uploadSpeed)
                    putExtra("DOWNLOAD_SPEED", downloadSpeed)
                    putExtra("UPLOAD_TRAFFIC", totalUpload)
                    putExtra("DOWNLOAD_TRAFFIC", totalDownload)
                }
                context.sendBroadcast(connectionInfoIntent)
                
                updateNotification()
                
                Log.d(TAG, "makeDurationTimer => $SERVICE_DURATION")
            }
            
            override fun onFinish() {
                cancel()
                if (isV2rayCoreRunning) {
                    makeDurationTimer(context, enableTrafficStatics)
                }
            }
        }.start()
    }
    
    fun setUpListener(targetService: Service) {
        try {
            v2rayServicesListener = targetService as V2rayServicesListener
            Libv2ray.initCoreEnv(Utilities.getUserAssetsPath(targetService.applicationContext), "")
            
            coreController = Libv2ray.newCoreController(object : CoreCallbackHandler {
                override fun onEmitStatus(p0: Long, p1: String?): Long {
                    Log.d(TAG, "onEmitStatus => $p0: $p1")
                    return 0
                }
                
                override fun shutdown(): Long {
                    if (v2rayServicesListener == null) {
                        Log.e(TAG, "shutdown failed => can't find initial service.")
                        return -1
                    }
                    return try {
                        v2rayServicesListener?.stopService()
                        v2rayServicesListener = null
                        0
                    } catch (e: Exception) {
                        Log.e(TAG, "shutdown failed =>", e)
                        -1
                    }
                }
                
                override fun startup(): Long {
                    v2rayServicesListener?.let {
                        return try {
                            it.startService()
                            0
                        } catch (e: Exception) {
                            Log.e(TAG, "startup failed => ", e)
                            -1
                        }
                    }
                    return 0
                }
            })
            
            isLibV2rayCoreInitialized = true
            SERVICE_DURATION = "00:00:00"
            seconds = 0
            minutes = 0
            hours = 0
            uploadSpeed = 0
            downloadSpeed = 0
            totalDownload = 0
            totalUpload = 0
            
            Log.e(TAG, "setUpListener => new initialize from ${v2rayServicesListener?.getService()?.javaClass?.simpleName}")
        } catch (e: Exception) {
            Log.e(TAG, "setUpListener failed => ", e)
            isLibV2rayCoreInitialized = false
        }
    }
    
    fun startCore(v2rayConfig: V2rayConfig, tunFd: Int = 0): Boolean {
        currentV2rayConfig = v2rayConfig
        makeDurationTimer(
            v2rayServicesListener?.getService()?.applicationContext ?: return false,
            v2rayConfig.ENABLE_TRAFFIC_STATICS
        )
        V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_CONNECTING
        
        if (!isLibV2rayCoreInitialized) {
            Log.e(TAG, "startCore failed => LibV2rayCore should be initialize before start.")
            return false
        }
        
        if (isV2rayCoreRunning) {
            stopCore()
        }
        
        return try {
            if (coreController == null) {
                Log.e(TAG, "startCore failed => coreController is null.")
                return false
            }
            
            coreController?.startLoop(v2rayConfig.V2RAY_FULL_JSON_CONFIG, tunFd)
            V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_CONNECTED
            
            if (isV2rayCoreRunning) {
                showNotification(v2rayConfig)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "startCore failed =>", e)
            false
        }
    }
    
    fun stopCore() {
        try {
            val notificationManager = v2rayServicesListener?.getService()
                ?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancel(NOTIFICATION_ID)
            
            if (isV2rayCoreRunning) {
                coreController?.stopLoop()
                v2rayServicesListener?.stopService()
                Log.e(TAG, "stopCore success => v2ray core stopped.")
            } else {
                Log.e(TAG, "stopCore failed => v2ray core not running.")
            }
            currentV2rayConfig = null
            sendDisconnectedBroadCast()
        } catch (e: Exception) {
            Log.e(TAG, "stopCore failed =>", e)
        }
    }
    
    private fun sendDisconnectedBroadCast() {
        V2RAY_STATE = AppConfigs.V2RAY_STATES.V2RAY_DISCONNECTED
        SERVICE_DURATION = "00:00:00"
        seconds = 0
        minutes = 0
        hours = 0
        uploadSpeed = 0
        downloadSpeed = 0
        
        v2rayServicesListener?.let {
            val connectionInfoIntent = Intent("V2RAY_CONNECTION_INFO").apply {
                putExtra("STATE", V2RAY_STATE)
                putExtra("DURATION", SERVICE_DURATION)
                putExtra("UPLOAD_SPEED", uploadSpeed)
                putExtra("DOWNLOAD_SPEED", uploadSpeed)
                putExtra("UPLOAD_TRAFFIC", uploadSpeed)
                putExtra("DOWNLOAD_TRAFFIC", uploadSpeed)
            }
            try {
                it.getService().applicationContext.sendBroadcast(connectionInfoIntent)
            } catch (e: Exception) {
            }
        }
        
        countDownTimer?.cancel()
    }
    
    private fun createNotificationChannelID(appName: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = v2rayServicesListener?.getService()
                ?.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            
            val channelId = "A_FLUTTER_V2RAY_SERVICE_CH_ID"
            val channelName = "$appName VPN Service"
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "VPN connection status with traffic statistics"
                lightColor = Color.BLUE
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setShowBadge(false)
            }
            
            notificationManager?.createNotificationChannel(channel)
            return channelId
        }
        return ""
    }
    
    private fun showNotification(v2rayConfig: V2rayConfig) {
        val context = v2rayServicesListener?.getService() ?: return
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
        }
        
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            setAction("FROM_DISCONNECT_BTN")
            setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val notificationContentPendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent, pendingIntentFlags
        )
        
        val stopIntent = when (AppConfigs.V2RAY_CONNECTION_MODE) {
            AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY -> Intent(context, V2rayProxyOnlyService::class.java)
            AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN -> Intent(context, V2rayVPNService::class.java)
            else -> return
        }.apply {
            putExtra("COMMAND", AppConfigs.V2RAY_SERVICE_COMMANDS.STOP_SERVICE)
        }
        
        val stopPendingIntent = PendingIntent.getService(context, 0, stopIntent, pendingIntentFlags)
        
        val notificationChannelID = createNotificationChannelID(v2rayConfig.APPLICATION_NAME ?: "Flutter V2ray")
        
        val uploadSpeed = formatSpeed(uploadSpeed)
        val downloadSpeed = formatSpeed(downloadSpeed)
        val uploadTotal = formatBytes(totalUpload)
        val downloadTotal = formatBytes(totalDownload)
        
        val contentText = "↑ $uploadSpeed  ↓ $downloadSpeed"
        val bigText = "Upload: $uploadSpeed ($uploadTotal)\nDownload: $downloadSpeed ($downloadTotal)\nDuration: $SERVICE_DURATION"
        
        val notificationBuilder = NotificationCompat.Builder(context, notificationChannelID)
            .setSmallIcon(v2rayConfig.APPLICATION_ICON)
            .setContentTitle(v2rayConfig.REMARK)
            .setContentText(contentText)
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText(bigText)
                .setBigContentTitle(v2rayConfig.REMARK)
                .setSummaryText("Connected • Tap to open"))
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                v2rayConfig.NOTIFICATION_DISCONNECT_BUTTON_NAME ?: "Disconnect",
                stopPendingIntent
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setContentIntent(notificationContentPendingIntent)
            .setSilent(true)
            .setOngoing(true)
            .setColor(0xFF007AFF.toInt())
        
        context.startForeground(NOTIFICATION_ID, notificationBuilder.build())
    }
    
    private fun formatSpeed(bytesPerSecond: Long): String {
        return when {
            bytesPerSecond < 1024 -> "${bytesPerSecond} B/s"
            bytesPerSecond < 1024 * 1024 -> String.format("%.1f KB/s", bytesPerSecond / 1024.0)
            bytesPerSecond < 1024 * 1024 * 1024 -> String.format("%.1f MB/s", bytesPerSecond / (1024.0 * 1024.0))
            else -> String.format("%.2f GB/s", bytesPerSecond / (1024.0 * 1024.0 * 1024.0))
        }
    }
    
    private fun formatBytes(bytes: Long): String {
        return when {
            bytes < 1024 -> "${bytes} B"
            bytes < 1024 * 1024 -> String.format("%.1f KB", bytes / 1024.0)
            bytes < 1024 * 1024 * 1024 -> String.format("%.1f MB", bytes / (1024.0 * 1024.0))
            else -> String.format("%.2f GB", bytes / (1024.0 * 1024.0 * 1024.0))
        }
    }
    
    private fun updateNotification() {
        val v2rayConfig = currentV2rayConfig ?: return
        val context = v2rayServicesListener?.getService() ?: return
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
        }
        
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            setAction("FROM_DISCONNECT_BTN")
            setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val notificationContentPendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent, pendingIntentFlags
        )
        
        val stopIntent = when (AppConfigs.V2RAY_CONNECTION_MODE) {
            AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY -> Intent(context, V2rayProxyOnlyService::class.java)
            AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN -> Intent(context, V2rayVPNService::class.java)
            else -> return
        }.apply {
            putExtra("COMMAND", AppConfigs.V2RAY_SERVICE_COMMANDS.STOP_SERVICE)
        }
        
        val stopPendingIntent = PendingIntent.getService(context, 0, stopIntent, pendingIntentFlags)
        
        val notificationChannelID = createNotificationChannelID(v2rayConfig.APPLICATION_NAME ?: "Flutter V2ray")
        
        val uploadSpeedStr = formatSpeed(uploadSpeed)
        val downloadSpeedStr = formatSpeed(downloadSpeed)
        val uploadTotalStr = formatBytes(totalUpload)
        val downloadTotalStr = formatBytes(totalDownload)
        
        val contentText = "↑ $uploadSpeedStr  ↓ $downloadSpeedStr"
        val bigText = "Upload: $uploadSpeedStr ($uploadTotalStr)\nDownload: $downloadSpeedStr ($downloadTotalStr)\nDuration: $SERVICE_DURATION"
        
        val notificationBuilder = NotificationCompat.Builder(context, notificationChannelID)
            .setSmallIcon(v2rayConfig.APPLICATION_ICON)
            .setContentTitle(v2rayConfig.REMARK)
            .setContentText(contentText)
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText(bigText)
                .setBigContentTitle(v2rayConfig.REMARK)
                .setSummaryText("Connected • Tap to open"))
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                v2rayConfig.NOTIFICATION_DISCONNECT_BUTTON_NAME ?: "Disconnect",
                stopPendingIntent
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setContentIntent(notificationContentPendingIntent)
            .setSilent(true)
            .setOngoing(true)
            .setColor(0xFF007AFF.toInt())
        
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.notify(NOTIFICATION_ID, notificationBuilder.build())
    }
    
    val isV2rayCoreRunning: Boolean
        get() = coreController?.isRunning ?: false
    
    val connectedV2rayServerDelay: Long
        get() = try {
            coreController?.measureDelay(AppConfigs.DELAY_URL) ?: -1L
        } catch (e: Exception) {
            -1L
        }
    
    fun getConnectedV2rayServerDelay(url: String): Long {
        return try {
            coreController?.measureDelay(url) ?: -1L
        } catch (e: Exception) {
            -1L
        }
    }
    
    fun getV2rayServerDelay(config: String, url: String): Long {
        return try {
            try {
                val configJson = JSONObject(config)
                val newRoutingJson = configJson.getJSONObject("routing")
                newRoutingJson.remove("rules")
                configJson.remove("routing")
                configJson.put("routing", newRoutingJson)
                Libv2ray.measureOutboundDelay(configJson.toString(), url)
            } catch (jsonError: Exception) {
                Log.e("getV2rayServerDelay", jsonError.toString())
                Libv2ray.measureOutboundDelay(config, url)
            }
        } catch (e: Exception) {
            Log.e("getV2rayServerDelayCore", e.toString())
            -1L
        }
    }
    
    fun measureV2rayOutboundDelay(config: String, url: String): Long {
        return try {
            Libv2ray.measureOutboundDelay(config, url)
        } catch (e: Exception) {
            Log.e("measureV2rayOutboundDelay", e.toString())
            -1L
        }
    }
}
