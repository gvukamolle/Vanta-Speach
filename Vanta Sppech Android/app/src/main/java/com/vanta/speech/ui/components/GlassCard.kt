package com.vanta.speech.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.vanta.speech.ui.theme.VantaColors

@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 24.dp,
    glassColor: Color = VantaColors.PinkVibrant,
    glassOpacity: Float = 0.15f,
    borderOpacity: Float = 0.3f,
    content: @Composable BoxScope.() -> Unit
) {
    val shape = RoundedCornerShape(cornerRadius)

    Box(
        modifier = modifier
            .shadow(
                elevation = 20.dp,
                shape = shape,
                ambientColor = Color.Black.copy(alpha = 0.2f),
                spotColor = Color.Black.copy(alpha = 0.2f)
            )
            .clip(shape)
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        glassColor.copy(alpha = glassOpacity),
                        glassColor.copy(alpha = glassOpacity * 0.5f)
                    )
                )
            )
            .border(
                width = 1.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color.White.copy(alpha = borderOpacity),
                        Color.White.copy(alpha = borderOpacity * 0.3f)
                    )
                ),
                shape = shape
            ),
        content = content
    )
}

@Composable
fun GlassSurface(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 16.dp,
    content: @Composable BoxScope.() -> Unit
) {
    val shape = RoundedCornerShape(cornerRadius)

    Box(
        modifier = modifier
            .clip(shape)
            .background(VantaColors.DarkSurfaceElevated.copy(alpha = 0.8f))
            .border(
                width = 1.dp,
                color = Color.White.copy(alpha = 0.1f),
                shape = shape
            ),
        content = content
    )
}

@Composable
fun ElevatedGlassCard(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 24.dp,
    content: @Composable BoxScope.() -> Unit
) {
    val shape = RoundedCornerShape(cornerRadius)

    Box(
        modifier = modifier
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
            ),
        content = content
    )
}

// MARK: - Modifier Extensions (matching iOS vantaGlassCard)

/**
 * Modifier extension for applying Vanta glass card styling.
 * Matches iOS vantaGlassCard modifier.
 */
fun Modifier.vantaGlassCard(
    cornerRadius: Dp = 24.dp,
    glassColor: Color = VantaColors.PinkVibrant,
    glassOpacity: Float = 0.15f,
    borderOpacity: Float = 0.3f,
    shadowElevation: Dp = 20.dp
): Modifier {
    val shape = RoundedCornerShape(cornerRadius)
    return this
        .shadow(
            elevation = shadowElevation,
            shape = shape,
            ambientColor = Color.Black.copy(alpha = 0.25f),
            spotColor = Color.Black.copy(alpha = 0.25f)
        )
        .clip(shape)
        .background(
            brush = Brush.verticalGradient(
                colors = listOf(
                    glassColor.copy(alpha = glassOpacity),
                    glassColor.copy(alpha = glassOpacity * 0.5f)
                )
            )
        )
        .border(
            width = 1.dp,
            brush = Brush.verticalGradient(
                colors = listOf(
                    Color.White.copy(alpha = borderOpacity),
                    Color.White.copy(alpha = borderOpacity * 0.3f)
                )
            ),
            shape = shape
        )
}

/**
 * Modifier extension for prominent glass effect (elevated elements like FABs).
 */
fun Modifier.vantaGlassProminent(
    cornerRadius: Dp = 16.dp
): Modifier {
    val shape = RoundedCornerShape(cornerRadius)
    return this
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
}

/**
 * Modifier extension for surface styling (non-glass).
 */
fun Modifier.vantaSurface(
    cornerRadius: Dp = 16.dp
): Modifier {
    val shape = RoundedCornerShape(cornerRadius)
    return this
        .clip(shape)
        .background(VantaColors.DarkSurface)
        .border(
            width = 0.5.dp,
            color = VantaColors.PinkLight.copy(alpha = 0.3f),
            shape = shape
        )
}
