package com.example.video_recording_sp
import io.flutter.embedding.android.FlutterActivity
import com.example.video_recording_sp.NativeConfigurationInjection
import ly.img.android.pesdk.backend.model.state.manager.StateHandler
import ly.img.android.pesdk.ui.model.state.UiConfigMainMenu

class MainActivity: FlutterActivity() {
    companion object {
        init {
            StateHandler.replaceStateClass(UiConfigMainMenu::class.java, NativeConfigurationInjection::class.java)
        }
    }
}
