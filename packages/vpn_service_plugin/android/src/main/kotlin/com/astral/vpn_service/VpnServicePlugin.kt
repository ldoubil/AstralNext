package com.astral.vpn_service

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class VpnServicePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var context: Context? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "vpn_service")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "vpn_service_events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "prepareVpn" -> {
                val intent = VpnService.prepare(activity)
                if (intent != null) {
                    activity?.startActivityForResult(intent, VPN_REQUEST_CODE)
                    result.success(false)
                } else {
                    result.success(true)
                }
            }
            "startVpn" -> {
                val ipv4Addr = call.argument<String>("ipv4Addr") ?: "100.100.100.0/24"
                val mtu = call.argument<Int>("mtu") ?: 1500
                val intent = Intent(context, TauriVpnService::class.java)
                intent.putExtra("ipv4_addr", ipv4Addr)
                intent.putExtra("mtu", mtu)
                context?.startService(intent)
                result.success(null)
            }
            "stopVpn" -> {
                TauriVpnService.stop(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun sendEvent(event: Map<String, Any>) {
        activity?.runOnUiThread {
            eventSink?.success(event)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    companion object {
        const val VPN_REQUEST_CODE = 24601
    }
}
