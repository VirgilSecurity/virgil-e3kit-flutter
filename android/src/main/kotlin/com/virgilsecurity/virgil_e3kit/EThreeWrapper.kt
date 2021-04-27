package com.virgilsecurity.virgil_e3kit

import androidx.annotation.NonNull

import android.app.Activity
import android.content.Context
import android.os.AsyncTask
import com.virgilsecurity.android.common.callback.OnGetTokenCallback
import com.virgilsecurity.android.common.exception.FindUsersException
import com.virgilsecurity.android.common.model.FindUsersResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.virgilsecurity.android.ethree.interaction.EThree
import com.virgilsecurity.common.callback.OnCompleteListener
import com.virgilsecurity.common.callback.OnResultListener
import com.virgilsecurity.crypto.pythia.Pythia.cleanup
import com.virgilsecurity.sdk.cards.Card
import io.flutter.plugin.common.BinaryMessenger
import java.io.*
import java.util.concurrent.Semaphore

class EThreeWrapper: MethodChannel.MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private lateinit var activity: Activity
  private lateinit var ethree: EThree

  constructor(identity: String, channelID: String, messenger: BinaryMessenger, context: Context, activity: Activity) {
    val ethree = EThree(identity = identity.toString(), tokenCallback = object : OnGetTokenCallback {
      override fun onGetToken(): String {
        var error: Error? = null
        var token: String? = null
        val semaphore = Semaphore(0)

        val callback = object: MethodChannel.Result{
          override fun success(param: Any?) {
            token = param as String?
            semaphore.release()
          }

          override fun error(code: String?, message: String?, details: Any?) {
            error = Error(message)
            semaphore.release()
          }

          override fun notImplemented() {
            semaphore.release()
          }
        }

        activity.runOnUiThread {
          channel.invokeMethod("tokenCallback", null, callback)
        }

        semaphore.acquire()
        return token ?: throw Error(error)
      }
    }, context = context)

    this.ethree = ethree
    this.activity = activity
    this.context = context
    this.channel = MethodChannel(messenger, channelID)
    this.channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    try {
      when (call.method) {
        "getIdentity" -> getIdentity(call, result)
        "register" -> register(call, result)
        "unregister" -> unregister(call, result)
        "backupPrivateKey" -> backupPrivateKey(call, result)
        "changePassword" -> changePassword(call, result)
        "resetPrivateKeyBackup" -> resetPrivateKeyBackup(call, result)
        "restorePrivateKey" -> restorePrivateKey(call, result)
        "rotatePrivateKey" -> rotatePrivateKey(call, result)
        "hasLocalPrivateKey" -> hasLocalPrivateKey(call, result)
        "cleanup" -> cleanup(call, result)
        "findCachedUser" -> findCachedUser(call, result)
        "findCachedUsers" -> findCachedUsers(call, result)
        "updateCachedUsers" -> updateCachedUsers(call, result)
        "findUser" -> findUser(call, result)
        "findUsers" -> findUsers(call, result)
        "authEncrypt" -> authEncrypt(call, result)
        "authDecrypt" -> authDecrypt(call, result)
        "authEncryptStream" -> authEncryptFile(call, result)
        "authDecryptStream" -> authDecryptFile(call, result)
        else -> result.error("0", "Method is not implemented", call.method)
      }
    } catch (e: Throwable) {
      result.error("-1", e.message, call.method)
    }
  }

  fun getIdentity(@NonNull call: MethodCall, @NonNull result: Result) {
    result.success(this.ethree.identity)
  }

  fun register(@NonNull call: MethodCall, @NonNull result: Result) {
    this.ethree.register().addCallback(completeCallback("2000", result))
  }

  fun unregister(@NonNull call: MethodCall, @NonNull result: Result) {
    this.ethree.unregister().addCallback(completeCallback("2001", result))
  }

  fun backupPrivateKey(@NonNull call: MethodCall, @NonNull result: Result) {
    val password: String = call.argument<String>("password") as String

    this.ethree.backupPrivateKey(password).addCallback(completeCallback("2002", result))
  }

  fun changePassword(@NonNull call: MethodCall, @NonNull result: Result) {
    val oldPassword: String = call.argument<String>("oldPassword") as String
    val newPassword: String = call.argument<String>("newPassword") as String

    this.ethree.changePassword(oldPassword, newPassword).addCallback(completeCallback("2003", result))
  }

  fun resetPrivateKeyBackup(@NonNull call: MethodCall, @NonNull result: Result) {
    this.ethree.resetPrivateKeyBackup().addCallback(completeCallback("2004", result))
  }

  fun restorePrivateKey(@NonNull call: MethodCall, @NonNull result: Result) {
    val password: String = call.argument<String>("password") as String

    this.ethree.restorePrivateKey(password).addCallback(completeCallback("2005", result))
  }

  fun rotatePrivateKey(@NonNull call: MethodCall, @NonNull result: Result) {
    this.ethree.rotatePrivateKey().addCallback(completeCallback("2006", result))
  }

  fun hasLocalPrivateKey(@NonNull call: MethodCall, @NonNull result: Result) {
    var res: Boolean = this.ethree.hasLocalPrivateKey()

    result.success(res)
  }

  fun cleanup(@NonNull call: MethodCall, @NonNull result: Result) {
    AsyncTask.execute {
      try {
        var res: Unit = this.ethree.cleanup()
        activity.runOnUiThread {
          result.success(true)
        }
      } catch(e: Throwable) {
        activity.runOnUiThread {
          result.error("2007", e.message, null)
        }

        return@execute
      }
    }
  }

  fun findUser(@NonNull call: MethodCall, @NonNull result: Result) {
    val identity: String = call.argument<String>("identity") as String

    this.ethree.findUser(identity).addCallback(object : OnResultListener<Card> {
      override fun onSuccess(card: Card) {
        activity.runOnUiThread {
          result.success(card.rawCard.exportAsBase64String())
        }
      }

      override fun onError(throwable: Throwable) {
        returnError("2007", throwable, result)
      }
    })
  }

  fun findUsers(@NonNull call: MethodCall, @NonNull result: Result) {
    val identities: List<String> = call.argument<List<String>>("identities") as List<String>
    val forceReload: Boolean = call.argument<Boolean>("forceReload") as Boolean

    this.ethree.findUsers(identities, forceReload).addCallback(object : OnResultListener<FindUsersResult> {
      override fun onSuccess(res: FindUsersResult) {
        val users = res.mapValues {
          it.value.rawCard.exportAsBase64String()!!
        }

        activity.runOnUiThread {
          result.success(users)
        }
      }

      override fun onError(throwable: Throwable) {
        returnError("2008", throwable, result)
      }
    })
  }

  fun findCachedUser(@NonNull call: MethodCall, @NonNull result: Result) {
    val identity: String = call.argument<String>("identity") as String

    this.ethree.findCachedUser(identity).addCallback(object : OnResultListener<Card?> {
      override fun onSuccess(card: Card?) {
        activity.runOnUiThread {
          if (card == null) returnError("2011", Error("card was not found"), result)
          else result.success(card.rawCard.exportAsBase64String())
        }
      }

      override fun onError(throwable: Throwable) {
        returnError("2009", throwable, result)
      }
    })
  }

  fun findCachedUsers(@NonNull call: MethodCall, @NonNull result: Result) {
    val identities: List<String> = call.argument<List<String>>("identities") as List<String>
    val checkResult: Boolean = call.argument<Boolean>("checkResult") as Boolean

    this.ethree.findCachedUsers(identities, checkResult).addCallback(object : OnResultListener<FindUsersResult> {
      override fun onSuccess(res: FindUsersResult) {
        val users = res.mapValues {
          it.value.rawCard.exportAsBase64String()!!
        }

        activity.runOnUiThread {
          result.success(users)
        }
      }

      override fun onError(throwable: Throwable) {
        returnError("2010", throwable, result)
      }
    })
  }

  fun updateCachedUsers(@NonNull call: MethodCall, @NonNull result: Result) {
    this.ethree.updateCachedUsers().addCallback(completeCallback("2012", result))
  }

  fun authEncrypt(@NonNull call: MethodCall, @NonNull result: Result) {
    val users: HashMap<String, String> = call.argument<HashMap<String, String>>("users") as HashMap<String, String>
    val data: String = call.argument<String>("data") as String

    val cards = users.mapValues {
      this.ethree.cardManager.importCardAsString(it.value)!!
    }

    val res: String = this.ethree.authEncrypt(data, FindUsersResult(cards))

    result.success(res)
  }

  fun authDecrypt(@NonNull call: MethodCall, @NonNull result: Result) {
    val card: String = call.argument<String>("card") as String
    val data: String = call.argument<String>("data") as String

    val res: String = this.ethree.authDecrypt(data, this.ethree.cardManager.importCardAsString(card))

    result.success(res)
  }

  fun authEncryptFile(@NonNull call: MethodCall, @NonNull result: Result) {
    val users: HashMap<String, String> = call.argument<HashMap<String, String>>("users") as HashMap<String, String>
    val inputPath: String = call.argument<String>("inputPath") as String
    val outputPath: String = call.argument<String>("outputPath") as String

    val cards = users.mapValues {
      this.ethree.cardManager.importCardAsString(it.value)!!
    }

    val inputFile: File = File(inputPath)
    val input: InputStream = FileInputStream(inputFile)
    val output: OutputStream = FileOutputStream(outputPath)

    val res: Unit = this.ethree.authEncrypt(input, inputFile.length() as Int, output, FindUsersResult(cards))

    activity.runOnUiThread {
      result.success(res)
    }
  }

  fun authDecryptFile(@NonNull call: MethodCall, @NonNull result: Result) {
    val card: String = call.argument<String>("card") as String
    val inputPath: String = call.argument<String>("inputPath") as String
    val outputPath: String = call.argument<String>("outputPath") as String

    val inputFile: File = File(inputPath)
    val input: InputStream = FileInputStream(inputFile)
    val output: OutputStream = FileOutputStream(outputPath)

    val res: Unit = this.ethree.authDecrypt(input, output, this.ethree.cardManager.importCardAsString(card))

    activity.runOnUiThread {
      result.success(res)
    }
  }

  fun completeCallback(code: String, result: Result): OnCompleteListener {
    return object : OnCompleteListener {
      override fun onSuccess() {
        activity.runOnUiThread {
          result.success(true)
        }
      }

      override fun onError(throwable: Throwable) {
        returnError(code, throwable, result)
      }
    }
  }

  fun returnError(code: String, throwable: Throwable, result: Result) {
    activity.runOnUiThread {
      result.error(code, throwable.message, null)
    }
  }
}

