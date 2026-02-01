package dev.amirzr.flutter_v2ray_client

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import androidx.core.app.ActivityCompat
import dev.amirzr.flutter_v2ray_client.v2ray.V2rayController
import dev.amirzr.flutter_v2ray_client.v2ray.V2rayReceiver
import dev.amirzr.flutter_v2ray_client.v2ray.utils.AppConfigs
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class FlutterV2rayPlugin : FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {
    
    companion object {
        private const val REQUEST_CODE_VPN_PERMISSION = 24
        private const val REQUEST_CODE_POST_NOTIFICATIONS = 1
    }
    
    private val executor: ExecutorService = Executors.newFixedThreadPool(16)
    private var vpnControlMethod: MethodChannel? = null
    private var vpnStatusEvent: EventChannel? = null
    private var vpnStatusSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var appContext: Context? = null
    private var v2rayBroadCastReceiver: BroadcastReceiver? = null
    private var pendingResult: MethodChannel.Result? = null
    
    @SuppressLint("DiscouragedApi")
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        vpnControlMethod = MethodChannel(binding.binaryMessenger, "flutter_v2ray_client")
        vpnStatusEvent = EventChannel(binding.binaryMessenger, "flutter_v2ray_client/status")
        
        vpnStatusEvent?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                vpnStatusSink = events
                V2rayReceiver.vpnStatusSink = vpnStatusSink
                
                if (v2rayBroadCastReceiver == null) {
                    v2rayBroadCastReceiver = V2rayReceiver()
                }
                val filter = IntentFilter("V2RAY_CONNECTION_INFO")
                
                val contextToUse = activity ?: appContext
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    contextToUse?.registerReceiver(v2rayBroadCastReceiver, filter, Context.RECEIVER_EXPORTED)
                } else {
                    contextToUse?.registerReceiver(v2rayBroadCastReceiver, filter)
                }
            }
            
            override fun onCancel(arguments: Any?) {
                vpnStatusSink?.endOfStream()
                
                v2rayBroadCastReceiver?.let {
                    val contextToUse = activity ?: appContext
                    try {
                        contextToUse?.unregisterReceiver(it)
                    } catch (e: IllegalArgumentException) {
                    }
                    v2rayBroadCastReceiver = null
                }
            }
        })
        
        vpnControlMethod?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startV2Ray" -> {
                    AppConfigs.NOTIFICATION_DISCONNECT_BUTTON_NAME = call.argument("notificationDisconnectButtonName")
                    if (call.argument<Boolean>("proxy_only") == true) {
                        V2rayController.changeConnectionMode(AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY)
                    }
                    V2rayController.startV2ray(
                        binding.applicationContext,
                        call.argument("remark"),
                        call.argument("config"),
                        call.argument("blocked_apps"),
                        call.argument("bypass_subnets")
                    )
                    result.success(null)
                }
                "stopV2Ray" -> {
                    V2rayController.stopV2ray(binding.applicationContext)
                    result.success(null)
                }
                "initializeV2Ray" -> {
                    val iconResourceName: String? = call.argument("notificationIconResourceName")
                    val iconResourceType: String? = call.argument("notificationIconResourceType")
                    V2rayController.init(
                        binding.applicationContext,
                        binding.applicationContext.resources.getIdentifier(
                            iconResourceName,
                            iconResourceType,
                            binding.applicationContext.packageName
                        ),
                        "Flutter V2ray"
                    )
                    result.success(null)
                }
                "getServerDelay" -> {
                    executor.submit {
                        try {
                            result.success(
                                V2rayController.getV2rayServerDelay(
                                    call.argument("config"),
                                    call.argument("url")
                                )
                            )
                        } catch (e: Exception) {
                            result.success(-1)
                        }
                    }
                }
                "measureOutboundDelay" -> {
                    executor.submit {
                        try {
                            result.success(
                                V2rayController.measureV2rayOutboundDelay(
                                    call.argument("config"),
                                    call.argument("url")
                                )
                            )
                        } catch (e: Exception) {
                            result.success(-1)
                        }
                    }
                }
                "getConnectedServerDelay" -> {
                    executor.submit {
                        try {
                            val url: String? = call.argument("url")
                            result.success(V2rayController.getConnectedV2rayServerDelayDirect(url))
                        } catch (e: Exception) {
                            result.success(-1)
                        }
                    }
                }
                "getCoreVersion" -> {
                    result.success(V2rayController.getCoreVersion())
                }
                "requestPermission" -> {
                    if (activity == null) {
                        result.error("NO_ACTIVITY", "Activity is not available for permission request", null)
                        return@setMethodCallHandler
                    }
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ActivityCompat.checkSelfPermission(
                                activity!!,
                                Manifest.permission.POST_NOTIFICATIONS
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            ActivityCompat.requestPermissions(
                                activity!!,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                REQUEST_CODE_POST_NOTIFICATIONS
                            )
                        }
                    }
                    val request = VpnService.prepare(activity)
                    if (request != null) {
                        pendingResult = result
                        activity?.startActivityForResult(request, REQUEST_CODE_VPN_PERMISSION)
                    } else {
                        result.success(true)
                    }
                }
            }
        }
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        v2rayBroadCastReceiver?.let {
            val contextToUse = activity ?: appContext
            try {
                contextToUse?.unregisterReceiver(it)
            } catch (e: IllegalArgumentException) {
            }
            v2rayBroadCastReceiver = null
        }
        vpnControlMethod?.setMethodCallHandler(null)
        vpnStatusEvent?.setStreamHandler(null)
        executor.shutdown()
    }
    
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        
        if (vpnStatusSink != null) {
            V2rayReceiver.vpnStatusSink = vpnStatusSink
            if (v2rayBroadCastReceiver == null) {
                v2rayBroadCastReceiver = V2rayReceiver()
            }
            val filter = IntentFilter("V2RAY_CONNECTION_INFO")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity?.registerReceiver(v2rayBroadCastReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                activity?.registerReceiver(v2rayBroadCastReceiver, filter)
            }
        }
    }
    
    override fun onDetachedFromActivityForConfigChanges() {
    }
    
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        
        if (vpnStatusSink != null) {
            V2rayReceiver.vpnStatusSink = vpnStatusSink
            if (v2rayBroadCastReceiver == null) {
                v2rayBroadCastReceiver = V2rayReceiver()
            }
            val filter = IntentFilter("V2RAY_CONNECTION_INFO")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity?.registerReceiver(v2rayBroadCastReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                activity?.registerReceiver(v2rayBroadCastReceiver, filter)
            }
        }
    }
    
    override fun onDetachedFromActivity() {
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_VPN_PERMISSION) {
            pendingResult?.success(resultCode == Activity.RESULT_OK)
            pendingResult = null
        }
        return true
    }
}
