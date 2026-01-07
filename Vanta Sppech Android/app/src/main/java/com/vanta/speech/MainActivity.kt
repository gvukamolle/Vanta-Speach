package com.vanta.speech

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import com.vanta.speech.core.data.local.prefs.PreferencesManager
import com.vanta.speech.ui.navigation.VantaNavHost
import com.vanta.speech.ui.theme.VantaSpeechTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var preferencesManager: PreferencesManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val appTheme by preferencesManager.appTheme.collectAsState(initial = "system")
            val systemDarkTheme = isSystemInDarkTheme()

            val darkTheme = when (appTheme) {
                "light" -> false
                "dark" -> true
                else -> systemDarkTheme
            }

            VantaSpeechTheme(darkTheme = darkTheme) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    VantaNavHost()
                }
            }
        }
    }
}
