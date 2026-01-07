package com.vanta.speech.core.domain.model

import com.vanta.speech.R

enum class RecordingMode(val labelResId: Int) {
    STANDARD(R.string.mode_standard),
    REALTIME(R.string.mode_realtime),
    IMPORT(R.string.mode_import)
}
