package com.zedsecure.vpn

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class AppListMethodChannel(private val context: Context) : MethodCallHandler {
    companion object {
        const val CHANNEL = "com.zedsecure.vpn/app_list"

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler(AppListMethodChannel(context))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getInstalledApps" -> {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val packageManager = context.packageManager
                        val installedPackages = packageManager.getInstalledPackages(
                            PackageManager.GET_META_DATA or PackageManager.MATCH_UNINSTALLED_PACKAGES
                        )
                        
                        val appList = mutableListOf<Map<String, Any>>()
                        
                        for (pkg in installedPackages) {
                            try {
                                val appInfo = pkg.applicationInfo ?: continue
                                
                                if (appInfo.packageName == context.packageName) {
                                    continue
                                }
                                
                                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                                val isUpdatedSystemApp = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
                                
                                val appName = try {
                                    packageManager.getApplicationLabel(appInfo).toString()
                                } catch (e: Exception) {
                                    appInfo.packageName
                                }
                                
                                val packageName = appInfo.packageName
                                
                                appList.add(mapOf(
                                    "name" to appName,
                                    "packageName" to packageName,
                                    "isSystemApp" to (isSystemApp && !isUpdatedSystemApp)
                                ))
                            } catch (e: Exception) {
                                continue
                            }
                        }
                        
                        val sortedAppList = appList.sortedWith(
                            compareBy<Map<String, Any>> { it["isSystemApp"] as Boolean }
                                .thenBy { (it["name"] as? String)?.lowercase() ?: "" }
                        )
                        
                        withContext(Dispatchers.Main) {
                            result.success(sortedAppList)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("APP_LIST_ERROR", "Failed to get installed apps", e.message)
                        }
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}

