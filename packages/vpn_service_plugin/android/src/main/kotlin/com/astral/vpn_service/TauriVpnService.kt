package com.astral.vpn_service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log

class TauriVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val ipv4Addr = intent?.getStringExtra("ipv4_addr") ?: "100.100.100.0/24"
        val mtu = intent?.getIntExtra("mtu", 1500) ?: 1500
        createNotificationChannel()
        startForeground(1, createNotification())
        createVpnInterface(ipv4Addr, mtu)
        return START_STICKY
    }

    private fun createVpnInterface(ipv4Addr: String, mtu: Int) {
        val parts = ipv4Addr.split("/")
        val addr = parts[0]
        val prefixLen = if (parts.size > 1) parts[1].toIntOrNull() ?: 24 else 24

        val builder = Builder()
        builder.setSession("Astral VPN")
        builder.addAddress(addr, prefixLen)
        builder.addRoute("0.0.0.0", 0)
        builder.addRoute("::", 0)
        builder.setMtu(mtu)
        builder.setMetered(false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }

        vpnInterface = builder.establish()

        vpnInterface?.let { fd ->
            val plugin = VpnServicePlugin()
            val event = HashMap<String, Any>()
            event["type"] = "vpn_service_start"
            event["fd"] = fd.detachFd()
            // Send event via static reference
            pluginInstance?.sendEvent(event)
        }
    }

    override fun onDestroy() {
        disconnect()
        super.onDestroy()
    }

    override fun onRevoke() {
        disconnect()
        super.onRevoke()
    }

    private fun disconnect() {
        try {
            vpnInterface?.close()
            vpnInterface = null
            val event = HashMap<String, Any>()
            event["type"] = "vpn_service_stop"
            pluginInstance?.sendEvent(event)
        } catch (e: Exception) {
            Log.e("TauriVpnService", "Error disconnecting VPN", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Astral VPN",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Astral VPN")
                .setContentText("VPN is running")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Astral VPN")
                .setContentText("VPN is running")
                .setSmallIcon(android.R.drawable.ic_lock_lock)
                .build()
        }
    }

    companion object {
        private const val CHANNEL_ID = "astral_vpn"
        private var pluginInstance: VpnServicePlugin? = null

        fun setPlugin(plugin: VpnServicePlugin) {
            pluginInstance = plugin
        }

        fun stop(context: Context?) {
            context?.stopService(Intent(context, TauriVpnService::class.java))
        }
    }
}
