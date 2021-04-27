package com.virgilsecurity.virgil_e3kit

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*

class VirgilE3kitPlugin: FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context
    private lateinit var activity: Activity
    private lateinit var messenger: BinaryMessenger
    private lateinit var ethreeWrappers: MutableMap<String, EThreeWrapper>

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.virgilsecurity/ethree")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        messenger = flutterPluginBinding.binaryMessenger
        ethreeWrappers = mutableMapOf()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        try {
            when (call.method) {
                "init" -> initEThree(call, result)
                else -> result.error("0", "Method is not implemented", call.method)
            }
        } catch (e: Throwable) {
            result.error("-1", e.message, call.method)
        }
    }

    private fun initEThree(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        val identity: String = call.argument<String>("identity") as String
        val channelID: String = call.argument<String>("channelID") as String
        try {
            val ethree = EThreeWrapper(identity, channelID, this.messenger, this.context, this.activity)
            this.ethreeWrappers.put(channelID, ethree)
            result.success(true)
        } catch(e: Throwable) {
            result.error("-1", e.message, call.method)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onDetachedFromActivity() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.getActivity()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }
}