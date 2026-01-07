package com.vanta.speech.core.data.local.prefs

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.vanta.speech.core.domain.model.RecordingPreset
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "vanta_settings")

class PreferencesManager(private val context: Context) {

    companion object {
        private val KEY_DARK_THEME = booleanPreferencesKey("dark_theme")
        private val KEY_APP_THEME = stringPreferencesKey("app_theme") // "system" | "light" | "dark"
        private val KEY_DEFAULT_PRESET = stringPreferencesKey("default_preset")
        private val KEY_ENABLED_PRESETS = stringSetPreferencesKey("enabled_presets")
        private val KEY_AUDIO_QUALITY = intPreferencesKey("audio_quality")
        private val KEY_REALTIME_PAUSE_THRESHOLD = floatPreferencesKey("realtime_pause_threshold")
        private val KEY_REALTIME_MIN_CHUNK = intPreferencesKey("realtime_min_chunk")
        private val KEY_REALTIME_MAX_CHUNK = intPreferencesKey("realtime_max_chunk")
        private val KEY_VAD_SILENCE_THRESHOLD = floatPreferencesKey("vad_silence_threshold")
    }

    val darkTheme: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[KEY_DARK_THEME] ?: true
    }

    // App theme: "system", "light", or "dark"
    val appTheme: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[KEY_APP_THEME] ?: "system"
    }

    val defaultPreset: Flow<String?> = context.dataStore.data.map { prefs ->
        prefs[KEY_DEFAULT_PRESET]
    }

    // Enabled presets (all enabled by default)
    val enabledPresets: Flow<Set<String>> = context.dataStore.data.map { prefs ->
        prefs[KEY_ENABLED_PRESETS] ?: RecordingPreset.entries.map { it.id }.toSet()
    }

    val audioQuality: Flow<Int> = context.dataStore.data.map { prefs ->
        prefs[KEY_AUDIO_QUALITY] ?: 64000 // Default 64kbps
    }

    val realtimePauseThreshold: Flow<Float> = context.dataStore.data.map { prefs ->
        prefs[KEY_REALTIME_PAUSE_THRESHOLD] ?: 3.0f // Default 3 seconds
    }

    val realtimeMinChunk: Flow<Int> = context.dataStore.data.map { prefs ->
        prefs[KEY_REALTIME_MIN_CHUNK] ?: 10 // Default 10 seconds
    }

    val realtimeMaxChunk: Flow<Int> = context.dataStore.data.map { prefs ->
        prefs[KEY_REALTIME_MAX_CHUNK] ?: 60 // Default 60 seconds
    }

    val vadSilenceThreshold: Flow<Float> = context.dataStore.data.map { prefs ->
        prefs[KEY_VAD_SILENCE_THRESHOLD] ?: 0.08f // Default 0.08
    }

    suspend fun setDarkTheme(enabled: Boolean) {
        context.dataStore.edit { prefs ->
            prefs[KEY_DARK_THEME] = enabled
        }
    }

    suspend fun setAppTheme(theme: String) {
        context.dataStore.edit { prefs ->
            prefs[KEY_APP_THEME] = theme
        }
    }

    suspend fun setDefaultPreset(presetId: String) {
        context.dataStore.edit { prefs ->
            prefs[KEY_DEFAULT_PRESET] = presetId
        }
    }

    suspend fun setPresetEnabled(presetId: String, enabled: Boolean) {
        context.dataStore.edit { prefs ->
            val currentSet = prefs[KEY_ENABLED_PRESETS]?.toMutableSet()
                ?: RecordingPreset.entries.map { it.id }.toMutableSet()
            if (enabled) {
                currentSet.add(presetId)
            } else {
                currentSet.remove(presetId)
            }
            prefs[KEY_ENABLED_PRESETS] = currentSet
        }
    }

    suspend fun setAudioQuality(bitrate: Int) {
        context.dataStore.edit { prefs ->
            prefs[KEY_AUDIO_QUALITY] = bitrate
        }
    }

    suspend fun setRealtimePauseThreshold(seconds: Float) {
        context.dataStore.edit { prefs ->
            prefs[KEY_REALTIME_PAUSE_THRESHOLD] = seconds
        }
    }

    suspend fun setRealtimeMinChunk(seconds: Int) {
        context.dataStore.edit { prefs ->
            prefs[KEY_REALTIME_MIN_CHUNK] = seconds
        }
    }

    suspend fun setRealtimeMaxChunk(seconds: Int) {
        context.dataStore.edit { prefs ->
            prefs[KEY_REALTIME_MAX_CHUNK] = seconds
        }
    }

    suspend fun setVadSilenceThreshold(threshold: Float) {
        context.dataStore.edit { prefs ->
            prefs[KEY_VAD_SILENCE_THRESHOLD] = threshold
        }
    }
}
