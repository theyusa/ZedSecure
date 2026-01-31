package dev.amirzr.flutter_v2ray_client.v2ray

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.EventChannel

class V2rayReceiver : BroadcastReceiver() {
    
    companion object {
        @JvmStatic
        var vpnStatusSink: EventChannel.EventSink? = null
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        try {
            val list = ArrayList<String>()
            list.add(intent?.extras?.getString("DURATION") ?: "00:00:00")
            list.add(intent?.getLongExtra("UPLOAD_SPEED", 0).toString())
            list.add(intent?.getLongExtra("DOWNLOAD_SPEED", 0).toString())
            list.add(intent?.getLongExtra("UPLOAD_TRAFFIC", 0).toString())
            list.add(intent?.getLongExtra("DOWNLOAD_TRAFFIC", 0).toString())
            list.add(intent?.extras?.getSerializable("STATE").toString().substring(6))
            vpnStatusSink?.success(list)
        } catch (e: Exception) {
            Log.e("V2rayReceiver", "onReceive failed", e)
        }
    }
}
