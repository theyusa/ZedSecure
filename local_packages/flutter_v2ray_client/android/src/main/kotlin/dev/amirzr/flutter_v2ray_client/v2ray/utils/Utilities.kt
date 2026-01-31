package dev.amirzr.flutter_v2ray_client.v2ray.utils

import android.content.Context
import android.util.Log
import dev.amirzr.flutter_v2ray_client.v2ray.core.V2rayCoreManager
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream

object Utilities {
    
    @Throws(IOException::class)
    fun copyFiles(src: InputStream, dst: File) {
        FileOutputStream(dst).use { out ->
            val buf = ByteArray(1024)
            var len: Int
            while (src.read(buf).also { len = it } > 0) {
                out.write(buf, 0, len)
            }
        }
    }
    
    fun getUserAssetsPath(context: Context): String {
        val extDir = context.getExternalFilesDir("assets")
        return if (extDir == null || !extDir.exists()) {
            context.getDir("assets", 0).absolutePath
        } else {
            extDir.absolutePath
        }
    }
    
    fun copyAssets(context: Context) {
        val extFolder = getUserAssetsPath(context)
        try {
            val geo = "geosite.dat,geoip.dat"
            context.assets.list("")?.forEach { assetsObj ->
                if (geo.contains(assetsObj)) {
                    copyFiles(context.assets.open(assetsObj), File(extFolder, assetsObj))
                }
            }
        } catch (e: Exception) {
            Log.e("Utilities", "copyAssets failed=>", e)
        }
    }
    
    fun convertIntToTwoDigit(value: Int): String {
        return if (value < 10) "0$value" else value.toString()
    }
    
    fun parseV2rayJsonFile(
        remark: String?,
        config: String?,
        blockedApplication: ArrayList<String>?,
        bypassSubnets: ArrayList<String>?
    ): V2rayConfig? {
        val v2rayConfig = V2rayConfig()
        v2rayConfig.REMARK = remark ?: ""
        v2rayConfig.BLOCKED_APPS = blockedApplication
        v2rayConfig.BYPASS_SUBNETS = bypassSubnets
        v2rayConfig.APPLICATION_ICON = AppConfigs.APPLICATION_ICON
        v2rayConfig.APPLICATION_NAME = AppConfigs.APPLICATION_NAME
        v2rayConfig.NOTIFICATION_DISCONNECT_BUTTON_NAME = AppConfigs.NOTIFICATION_DISCONNECT_BUTTON_NAME
        
        try {
            val configJson = JSONObject(config ?: "")
            
            try {
                val inbounds = configJson.getJSONArray("inbounds")
                for (i in 0 until inbounds.length()) {
                    try {
                        val inbound = inbounds.getJSONObject(i)
                        when (inbound.getString("protocol")) {
                            "socks" -> v2rayConfig.LOCAL_SOCKS5_PORT = inbound.getInt("port")
                            "http" -> v2rayConfig.LOCAL_HTTP_PORT = inbound.getInt("port")
                        }
                    } catch (e: Exception) {
                    }
                }
            } catch (e: Exception) {
                Log.w(V2rayCoreManager::class.java.simpleName, "startCore warn => can't find inbound port of socks5 or http.")
                return null
            }
            
            try {
                val firstOutbound = configJson.getJSONArray("outbounds").getJSONObject(0)
                val protocol = firstOutbound.getString("protocol")
                
                when (protocol) {
                    "vmess", "vless" -> {
                        val vnext = firstOutbound.getJSONObject("settings")
                            .getJSONArray("vnext").getJSONObject(0)
                        v2rayConfig.CONNECTED_V2RAY_SERVER_ADDRESS = vnext.getString("address")
                        v2rayConfig.CONNECTED_V2RAY_SERVER_PORT = vnext.getString("port")
                    }
                    "shadowsocks", "socks", "trojan" -> {
                        val servers = firstOutbound.getJSONObject("settings")
                            .getJSONArray("servers").getJSONObject(0)
                        v2rayConfig.CONNECTED_V2RAY_SERVER_ADDRESS = servers.getString("address")
                        v2rayConfig.CONNECTED_V2RAY_SERVER_PORT = servers.getString("port")
                    }
                }
            } catch (e: Exception) {
                Log.w(V2rayCoreManager::class.java.simpleName, "startCore warn => can't parse server address and port.", e)
                v2rayConfig.CONNECTED_V2RAY_SERVER_ADDRESS = ""
                v2rayConfig.CONNECTED_V2RAY_SERVER_PORT = ""
            }
            
            try {
                if (configJson.has("policy")) {
                    configJson.remove("policy")
                }
                if (configJson.has("stats")) {
                    configJson.remove("stats")
                }
            } catch (ignoreError: Exception) {
            }
            
            var finalConfig = config
            if (AppConfigs.ENABLE_TRAFFIC_AND_SPEED_STATICS) {
                try {
                    val policy = JSONObject()
                    val levels = JSONObject()
                    levels.put("8", JSONObject()
                        .put("connIdle", 300)
                        .put("downlinkOnly", 1)
                        .put("handshake", 4)
                        .put("uplinkOnly", 1))
                    val system = JSONObject()
                        .put("statsOutboundUplink", true)
                        .put("statsOutboundDownlink", true)
                    policy.put("levels", levels)
                    policy.put("system", system)
                    configJson.put("policy", policy)
                    configJson.put("stats", JSONObject())
                    finalConfig = configJson.toString()
                    v2rayConfig.ENABLE_TRAFFIC_STATICS = true
                } catch (e: Exception) {
                }
            }
            
            v2rayConfig.V2RAY_FULL_JSON_CONFIG = finalConfig
        } catch (e: Exception) {
            Log.e(Utilities::class.java.name, "parseV2rayJsonFile failed => ", e)
            return null
        }
        
        return v2rayConfig
    }
}
