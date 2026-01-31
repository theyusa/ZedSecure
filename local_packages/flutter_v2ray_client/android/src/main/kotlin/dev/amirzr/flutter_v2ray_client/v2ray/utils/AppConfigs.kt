package dev.amirzr.flutter_v2ray_client.v2ray.utils

object AppConfigs {
    
    var V2RAY_CONNECTION_MODE = V2RAY_CONNECTION_MODES.VPN_TUN
    var APPLICATION_NAME: String? = null
    var APPLICATION_ICON: Int = 0
    var V2RAY_CONFIG: V2rayConfig? = null
    var V2RAY_STATE = V2RAY_STATES.V2RAY_DISCONNECTED
    var ENABLE_TRAFFIC_AND_SPEED_STATICS = true
    var DELAY_URL: String? = null
    var NOTIFICATION_DISCONNECT_BUTTON_NAME: String? = null
    
    enum class V2RAY_SERVICE_COMMANDS {
        START_SERVICE,
        STOP_SERVICE,
        MEASURE_DELAY
    }
    
    enum class V2RAY_STATES {
        V2RAY_CONNECTED,
        V2RAY_DISCONNECTED,
        V2RAY_CONNECTING
    }
    
    enum class V2RAY_CONNECTION_MODES {
        VPN_TUN,
        PROXY_ONLY
    }
}
