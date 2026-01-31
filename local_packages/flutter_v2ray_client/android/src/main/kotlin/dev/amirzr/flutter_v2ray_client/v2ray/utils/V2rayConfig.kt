package dev.amirzr.flutter_v2ray_client.v2ray.utils

import java.io.Serializable

data class V2rayConfig(
    var CONNECTED_V2RAY_SERVER_ADDRESS: String = "",
    var CONNECTED_V2RAY_SERVER_PORT: String = "",
    var LOCAL_SOCKS5_PORT: Int = 10808,
    var LOCAL_HTTP_PORT: Int = 10809,
    var BLOCKED_APPS: ArrayList<String>? = null,
    var BYPASS_SUBNETS: ArrayList<String>? = null,
    var V2RAY_FULL_JSON_CONFIG: String? = null,
    var ENABLE_TRAFFIC_STATICS: Boolean = false,
    var REMARK: String = "",
    var APPLICATION_NAME: String? = null,
    var NOTIFICATION_DISCONNECT_BUTTON_NAME: String? = null,
    var APPLICATION_ICON: Int = 0
) : Serializable
