package com.vanta.speech.feature.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.vanta.speech.core.auth.AuthenticationManager
import com.vanta.speech.core.auth.model.UserSession
import com.vanta.speech.core.data.local.prefs.PreferencesManager
import com.vanta.speech.core.domain.repository.RecordingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val authManager: AuthenticationManager,
    private val recordingRepository: RecordingRepository,
    private val preferencesManager: PreferencesManager
) : ViewModel() {

    val currentSession: StateFlow<UserSession?> = authManager.currentSession

    // Theme: "system", "light", or "dark"
    val appTheme: StateFlow<String> = preferencesManager.appTheme
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), "system")

    // Enabled presets
    val enabledPresets: StateFlow<Set<String>> = preferencesManager.enabledPresets
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptySet())

    // Realtime settings
    val realtimePauseThreshold: StateFlow<Float> = preferencesManager.realtimePauseThreshold
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 3.0f)

    val realtimeMinChunk: StateFlow<Int> = preferencesManager.realtimeMinChunk
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 10)

    val realtimeMaxChunk: StateFlow<Int> = preferencesManager.realtimeMaxChunk
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 60)

    fun logout() {
        authManager.logout()
    }

    fun deleteAllRecordings() {
        viewModelScope.launch {
            recordingRepository.deleteAllRecordings()
        }
    }

    fun setAppTheme(theme: String) {
        viewModelScope.launch {
            preferencesManager.setAppTheme(theme)
        }
    }

    fun setPresetEnabled(presetId: String, enabled: Boolean) {
        viewModelScope.launch {
            preferencesManager.setPresetEnabled(presetId, enabled)
        }
    }

    fun setRealtimePauseThreshold(seconds: Float) {
        viewModelScope.launch {
            preferencesManager.setRealtimePauseThreshold(seconds)
        }
    }

    fun setRealtimeMinChunk(seconds: Int) {
        viewModelScope.launch {
            preferencesManager.setRealtimeMinChunk(seconds)
        }
    }

    fun setRealtimeMaxChunk(seconds: Int) {
        viewModelScope.launch {
            preferencesManager.setRealtimeMaxChunk(seconds)
        }
    }
}
