package com.vanta.speech.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import com.vanta.speech.core.domain.model.RecordingMode
import com.vanta.speech.ui.theme.VantaColors

@Composable
fun ModePicker(
    selectedMode: RecordingMode,
    onModeSelected: (RecordingMode) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    val modes = RecordingMode.entries
    val selectedIndex = modes.indexOf(selectedMode)
    val density = LocalDensity.current

    val containerShape = RoundedCornerShape(16.dp)
    val segmentShape = RoundedCornerShape(12.dp)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
    ) {
        // Background container with glass effect
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp)
                .clip(containerShape)
                .background(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            VantaColors.DarkSurfaceElevated,
                            VantaColors.DarkSurface
                        )
                    )
                )
                .border(
                    width = 1.dp,
                    color = VantaColors.White.copy(alpha = 0.1f),
                    shape = containerShape
                )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(4.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                modes.forEachIndexed { index, mode ->
                    val isSelected = index == selectedIndex

                    val backgroundColor by animateColorAsState(
                        targetValue = if (isSelected) {
                            VantaColors.PinkVibrant
                        } else {
                            Color.Transparent
                        },
                        animationSpec = tween(200),
                        label = "bgColor"
                    )

                    val textColor by animateColorAsState(
                        targetValue = if (isSelected) {
                            VantaColors.White
                        } else {
                            VantaColors.DarkTextSecondary
                        },
                        animationSpec = tween(200),
                        label = "textColor"
                    )

                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(40.dp)
                            .clip(segmentShape)
                            .background(backgroundColor)
                            .clickable(
                                enabled = enabled,
                                indication = null,
                                interactionSource = remember { MutableInteractionSource() }
                            ) {
                                onModeSelected(mode)
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = stringResource(mode.labelResId),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium,
                            color = textColor
                        )
                    }
                }
            }
        }
    }
}
