package com.vanta.speech.feature.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vanta.speech.ui.components.VantaBackground
import com.vanta.speech.ui.theme.VantaColors
import kotlin.math.roundToInt

@Composable
fun RealtimeSettingsScreen(
    onBack: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val pauseThreshold by viewModel.realtimePauseThreshold.collectAsStateWithLifecycle()
    val minChunk by viewModel.realtimeMinChunk.collectAsStateWithLifecycle()
    val maxChunk by viewModel.realtimeMaxChunk.collectAsStateWithLifecycle()

    VantaBackground {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 16.dp)
        ) {
            // Top bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = onBack) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Назад",
                        tint = VantaColors.White
                    )
                }

                Text(
                    text = "Настройки Real-time",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = VantaColors.White
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp)
            ) {
                // Description
                Text(
                    text = "Настройки для режима live транскрипции. Эти параметры влияют на качество и скорость обработки речи.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = VantaColors.DarkTextSecondary,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 8.dp)
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Settings card
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(VantaColors.DarkSurfaceElevated)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        // Pause Threshold
                        SliderSetting(
                            title = "Пауза для отправки",
                            description = "Длительность паузы в речи, после которой чанк отправляется на обработку",
                            value = pauseThreshold,
                            valueRange = 1f..10f,
                            valueFormatter = { "${it.roundToInt()} сек" },
                            onValueChange = { viewModel.setRealtimePauseThreshold(it) }
                        )

                        Spacer(modifier = Modifier.height(8.dp))
                        Divider()
                        Spacer(modifier = Modifier.height(8.dp))

                        // Min Chunk Duration
                        SliderSetting(
                            title = "Мин. длина чанка",
                            description = "Минимальная длительность аудио-фрагмента для отправки",
                            value = minChunk.toFloat(),
                            valueRange = 5f..30f,
                            valueFormatter = { "${it.roundToInt()} сек" },
                            onValueChange = { viewModel.setRealtimeMinChunk(it.roundToInt()) }
                        )

                        Spacer(modifier = Modifier.height(8.dp))
                        Divider()
                        Spacer(modifier = Modifier.height(8.dp))

                        // Max Chunk Duration
                        SliderSetting(
                            title = "Макс. длина чанка",
                            description = "Максимальная длительность аудио-фрагмента (принудительная отправка)",
                            value = maxChunk.toFloat(),
                            valueRange = 30f..120f,
                            valueFormatter = { "${it.roundToInt()} сек" },
                            onValueChange = { viewModel.setRealtimeMaxChunk(it.roundToInt()) }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Footer note
                Text(
                    text = "Меньшие значения дают более быстрый отклик, но могут снизить качество транскрипции. Рекомендуемые значения: пауза 3 сек, мин. 10 сек, макс. 60 сек.",
                    style = MaterialTheme.typography.bodySmall,
                    color = VantaColors.DarkTextSecondary.copy(alpha = 0.7f),
                    modifier = Modifier.padding(horizontal = 8.dp)
                )

                Spacer(modifier = Modifier.height(100.dp))
            }
        }
    }
}

@Composable
private fun SliderSetting(
    title: String,
    description: String,
    value: Float,
    valueRange: ClosedFloatingPointRange<Float>,
    valueFormatter: (Float) -> String,
    onValueChange: (Float) -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.Medium,
                    color = VantaColors.White
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = VantaColors.DarkTextSecondary
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            Text(
                text = valueFormatter(value),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = VantaColors.PinkVibrant
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Slider(
            value = value,
            onValueChange = onValueChange,
            valueRange = valueRange,
            colors = SliderDefaults.colors(
                thumbColor = VantaColors.PinkVibrant,
                activeTrackColor = VantaColors.PinkVibrant,
                inactiveTrackColor = VantaColors.DarkSurface
            )
        )
    }
}

@Composable
private fun Divider() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(VantaColors.DarkSurface)
    )
}
