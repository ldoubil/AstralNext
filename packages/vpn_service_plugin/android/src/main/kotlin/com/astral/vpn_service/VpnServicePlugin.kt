package com.astral.vpn_service

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
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
    private var pendingPrepareResult: Result? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val activityResultListener: ActivityResultListener =
        ActivityResultListener { requestCode: Int, resultCode: Int, data: Intent? ->
            onActivityResult(requestCode, resultCode, data)
            requestCode == VPN_REQUEST_CODE
        }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        TauriVpnService.setPlugin(this)
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
            "prepareVpn" -> handlePrepareVpn(result)
            "startVpn" -> handleStartVpn(call, result)
            "stopVpn" -> handleStopVpn(result)
            else -> result.notImplemented()
        }
    }

    private fun handlePrepareVpn(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.success("error_no_activity")
            return
        }

        val intent = VpnService.prepare(currentActivity)
        if (intent == null) {
            result.success("granted")
            return
        }

        pendingPrepareResult = result
        try {
            currentActivity.startActivityForResult(intent, VPN_REQUEST_CODE)
        } catch (e: Exception) {
            pendingPrepareResult = null
            result.success("error_start_activity")
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != VPN_REQUEST_CODE) return

        val result = pendingPrepareResult ?: return
        pendingPrepareResult = null

        if (resultCode == Activity.RESULT_OK) {
            result.success("granted")
        } else {
            result.success("denied")
        }
    }

    private fun handleStartVpn(call: MethodCall, result: Result) {
        val ipv4Addr = call.argument<String>("ipv4Addr") ?: "100.100.100.0/24"
        val mtu = call.argument<Int>("mtu") ?: 1500
        val routes = call.argument<List<String>>("routes")?.toTypedArray() ?: emptyArray()
        val disallowedApplications =
            call.argument<List<String>>("disallowedApplications")?.toTypedArray() ?: emptyArray()
        val intent = Intent(context, TauriVpnService::class.java)
        intent.putExtra("ipv4_addr", ipv4Addr)
        intent.putExtra("mtu", mtu)
        intent.putExtra("routes", routes)
        intent.putExtra("disallowed_applications", disallowedApplications)
        try {
            context?.startService(intent)
            result.success("started")
        } catch (e: Exception) {
            result.success("error_start_service")
        }
    }

    private fun handleStopVpn(result: Result) {
        TauriVpnService.stop(context)
        result.success("stopped")
    }

    fun sendEvent(event: Map<String, Any>) {
        activity?.runOnUiThread {
            eventSink?.success(event)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        TauriVpnService.clearPlugin(this)
        pendingPrepareResult = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addActivityResultListener(activityResultListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(activityResultListener)
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addActivityResultListener(activityResultListener)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(activityResultListener)
        activityBinding = null
        activity = null
    }

    companion object {
        const val VPN_REQUEST_CODE = 24601
    }
}
