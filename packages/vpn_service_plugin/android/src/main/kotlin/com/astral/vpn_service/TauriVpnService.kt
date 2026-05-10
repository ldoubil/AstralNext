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
        val routes = intent?.getStringArrayExtra("routes") ?: emptyArray()
        val disallowedApplications =
            intent?.getStringArrayExtra("disallowed_applications") ?: emptyArray()
        createNotificationChannel()
        startForeground(1, createNotification())
        createVpnInterface(ipv4Addr, mtu, routes, disallowedApplications)
        return START_STICKY
    }

    private fun createVpnInterface(
        ipv4Addr: String,
        mtu: Int,
        routes: Array<String>,
        disallowedApplications: Array<String>
    ) {
        val parts = ipv4Addr.split("/")
        val addr = parts[0]
        val prefixLen = if (parts.size > 1) parts[1].toIntOrNull() ?: 24 else 24
        val octets = addr.split(".")
        val networkCidr = if (octets.size == 4) {
            "${octets[0]}.${octets[1]}.${octets[2]}.0/$prefixLen"
        } else {
            "$addr/$prefixLen"
        }

        val builder = Builder()
        builder.setSession("Astral VPN")
        builder.addAddress(addr, prefixLen)
        addRoute(builder, networkCidr)
        addRoute(builder, "224.0.0.0/4")
        addRoute(builder, "255.255.255.255/32")
        for (route in routes) {
            addRoute(builder, route)
        }
        for (app in disallowedApplications) {
            builder.addDisallowedApplication(app)
        }
        builder.setMtu(mtu)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }

        vpnInterface = builder.establish()

        vpnInterface?.let { fd ->
            val event = HashMap<String, Any>()
            event["type"] = "vpn_service_start"
            event["fd"] = fd.detachFd()
            pluginInstance?.sendEvent(event)
        }
    }

    private fun addRoute(builder: Builder, route: String) {
        val parts = route.split("/")
        if (parts.size != 2) return
        val prefixLen = parts[1].toIntOrNull() ?: return
        builder.addRoute(parts[0], prefixLen)
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

        fun clearPlugin(plugin: VpnServicePlugin) {
            if (pluginInstance == plugin) {
                pluginInstance = null
            }
        }

        fun stop(context: Context?) {
            context?.stopService(Intent(context, TauriVpnService::class.java))
        }
    }
}
