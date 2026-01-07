package com.vanta.speech.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vanta.speech.R
import com.vanta.speech.core.domain.model.RecordingMode
import com.vanta.speech.ui.theme.VantaColors
import java.time.Duration
import java.util.Locale

/**
 * Floating pill-shaped microphone button matching iOS design.
 * Shows different content based on recording state and mode.
 */
@Composable
fun FloatingMicButton(
    mode: RecordingMode,
    isRecording: Boolean,
    isPaused: Boolean = false,
    isProcessing: Boolean = false,
    duration: Duration = Duration.ZERO,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()

    val scale = if (isPressed) 0.96f else 1f
    val shape = RoundedCornerShape(28.dp)

    Box(
        modifier = modifier
            .scale(scale)
            .shadow(
                elevation = 30.dp,
                shape = shape,
                ambientColor = VantaColors.PinkVibrant.copy(alpha = 0.2f),
                spotColor = VantaColors.PinkVibrant.copy(alpha = 0.3f)
            )
            .clip(shape)
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        VantaColors.DarkSurfaceElevated,
                        VantaColors.DarkSurface
                    )
                )
            )
            .border(
                width = 1.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        VantaColors.PinkLight.copy(alpha = 0.4f),
                        VantaColors.PinkLight.copy(alpha = 0.1f)
                    )
                ),
                shape = shape
            )
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            )
            .padding(horizontal = 32.dp, vertical = 14.dp)
            .widthIn(min = 160.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            when {
                isProcessing -> {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = VantaColors.White,
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Text(
                        text = "Обработка...",
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = VantaColors.White
                    )
                }
                isRecording -> {
                    RecordingContent(
                        isPaused = isPaused,
                        duration = duration,
                        isRealtime = mode == RecordingMode.REALTIME
                    )
                }
                else -> {
                    IdleContent(mode = mode)
                }
            }
        }
    }
}

@Composable
private fun RecordingContent(
    isPaused: Boolean,
    duration: Duration,
    isRealtime: Boolean
) {
    // Pulsing indicator
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(800),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseScale"
    )
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0.6f,
        animationSpec = infiniteRepeatable(
            animation = tween(800),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulseAlpha"
    )

    val indicatorColor = when {
        isPaused -> VantaColors.RecordingPaused
        isRealtime -> Color(0xFF34C759) // Green for realtime
        else -> VantaColors.PinkVibrant
    }

    // Pulsing dot
    if (!isPaused) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .scale(pulseScale)
                .clip(CircleShape)
                .background(indicatorColor.copy(alpha = pulseAlpha))
        )
    } else {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(indicatorColor)
        )
    }

    Spacer(modifier = Modifier.width(10.dp))

    // Icon - waveform for standard, text for realtime
    Icon(
        imageVector = if (isRealtime) Icons.Default.TextFields else Icons.Default.GraphicEq,
        contentDescription = null,
        tint = VantaColors.White,
        modifier = Modifier.size(20.dp)
    )

    Spacer(modifier = Modifier.width(8.dp))

    // Timer
    Text(
        text = formatDuration(duration),
        style = MaterialTheme.typography.bodyLarge,
        fontWeight = FontWeight.SemiBold,
        color = VantaColors.White,
        letterSpacing = 1.sp
    )
}

@Composable
private fun IdleContent(mode: RecordingMode) {
    val icon: ImageVector
    val text: String

    when (mode) {
        RecordingMode.STANDARD -> {
            icon = Icons.Default.Mic
            text = stringResource(R.string.button_record) // "Записать" like iOS
        }
        RecordingMode.REALTIME -> {
            icon = Icons.Default.TextFields
            text = stringResource(R.string.mode_realtime)
        }
        RecordingMode.IMPORT -> {
            icon = Icons.Default.Download
            text = stringResource(R.string.mode_import)
        }
    }

    Icon(
        imageVector = icon,
        contentDescription = null,
        tint = VantaColors.White,
        modifier = Modifier.size(24.dp)
    )

    Spacer(modifier = Modifier.width(10.dp))

    Text(
        text = text,
        style = MaterialTheme.typography.bodyLarge,
        fontWeight = FontWeight.SemiBold,
        color = VantaColors.White
    )
}

private fun formatDuration(duration: Duration): String {
    val hours = duration.toHours()
    val minutes = duration.toMinutes() % 60
    val seconds = duration.seconds % 60

    return if (hours > 0) {
        String.format(Locale.US, "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format(Locale.US, "%02d:%02d", minutes, seconds)
    }
}
