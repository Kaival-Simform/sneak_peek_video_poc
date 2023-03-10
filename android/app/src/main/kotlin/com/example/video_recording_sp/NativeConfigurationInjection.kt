package com.example.video_recording_sp

import android.os.Parcel
import ly.img.android.pesdk.kotlin_extension.parcelableCreator
import ly.img.android.pesdk.ui.model.state.UiConfigMainMenu

class NativeConfigurationInjection @JvmOverloads constructor(parcel: Parcel? = null): UiConfigMainMenu(parcel) {
  override fun onCreate() {
    super.onCreate()

    setInitialTool("imgly_tool_trim")
  }

  companion object {
    @JvmField val CREATOR = parcelableCreator(::NativeConfigurationInjection)
  }
}