package com.vanta.speech.ui.components.calendar

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vanta.speech.ui.theme.VantaColors
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.TextStyle
import java.util.Locale

@Composable
fun CalendarView(
    displayedMonth: YearMonth,
    onMonthChange: (YearMonth) -> Unit,
    selectedDate: LocalDate?,
    onDateSelected: (LocalDate) -> Unit,
    recordingDates: Set<LocalDate>,
    modifier: Modifier = Modifier
) {
    val russianLocale = Locale("ru")
    val daysOfWeek = remember {
        listOf(
            DayOfWeek.MONDAY,
            DayOfWeek.TUESDAY,
            DayOfWeek.WEDNESDAY,
            DayOfWeek.THURSDAY,
            DayOfWeek.FRIDAY,
            DayOfWeek.SATURDAY,
            DayOfWeek.SUNDAY
        )
    }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
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
                shape = RoundedCornerShape(24.dp)
            )
            .padding(16.dp)
    ) {
        // Month navigation header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(
                onClick = { onMonthChange(displayedMonth.minusMonths(1)) }
            ) {
                Icon(
                    imageVector = Icons.Default.ChevronLeft,
                    contentDescription = "Предыдущий месяц",
                    tint = VantaColors.White
                )
            }

            Text(
                text = "${displayedMonth.month.getDisplayName(TextStyle.FULL_STANDALONE, russianLocale).replaceFirstChar { it.uppercase() }} ${displayedMonth.year}",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = VantaColors.White
            )

            IconButton(
                onClick = { onMonthChange(displayedMonth.plusMonths(1)) }
            ) {
                Icon(
                    imageVector = Icons.Default.ChevronRight,
                    contentDescription = "Следующий месяц",
                    tint = VantaColors.White
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Days of week header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            daysOfWeek.forEach { dayOfWeek ->
                Text(
                    text = dayOfWeek.getDisplayName(TextStyle.SHORT, russianLocale)
                        .replaceFirstChar { it.uppercase() },
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Medium,
                    color = VantaColors.DarkTextSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Calendar grid
        val firstDayOfMonth = displayedMonth.atDay(1)
        val lastDayOfMonth = displayedMonth.atEndOfMonth()
        val firstDayOfWeek = firstDayOfMonth.dayOfWeek

        // Calculate offset for Monday start (Monday = 0, Sunday = 6)
        val startOffset = (firstDayOfWeek.value - 1) // Monday is 1, so offset is 0 for Monday

        val daysInMonth = displayedMonth.lengthOfMonth()
        val totalCells = startOffset + daysInMonth
        val rows = (totalCells + 6) / 7 // Round up to get number of rows

        val today = LocalDate.now()

        Column(
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            repeat(rows) { row ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    repeat(7) { col ->
                        val cellIndex = row * 7 + col
                        val dayNumber = cellIndex - startOffset + 1

                        if (dayNumber in 1..daysInMonth) {
                            val date = displayedMonth.atDay(dayNumber)
                            val isToday = date == today
                            val hasRecordings = recordingDates.contains(date)
                            val isSelected = date == selectedDate

                            CalendarDayCell(
                                day = dayNumber,
                                isToday = isToday,
                                hasRecordings = hasRecordings,
                                isSelected = isSelected,
                                onClick = { onDateSelected(date) },
                                modifier = Modifier.weight(1f)
                            )
                        } else {
                            // Empty cell
                            Box(modifier = Modifier.weight(1f).aspectRatio(1f))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CalendarDayCell(
    day: Int,
    isToday: Boolean,
    hasRecordings: Boolean,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .aspectRatio(1f)
            .padding(2.dp)
            .clip(CircleShape)
            .then(
                when {
                    isSelected -> Modifier.background(VantaColors.PinkVibrant)
                    hasRecordings -> Modifier.background(VantaColors.PinkVibrant.copy(alpha = 0.2f))
                    else -> Modifier
                }
            )
            .then(
                if (isToday && !isSelected) {
                    Modifier.border(
                        width = 2.dp,
                        color = VantaColors.PinkVibrant,
                        shape = CircleShape
                    )
                } else {
                    Modifier
                }
            )
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() }
            ) { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = day.toString(),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (isSelected || isToday) FontWeight.Bold else FontWeight.Normal,
            color = when {
                isSelected -> VantaColors.White
                hasRecordings -> VantaColors.PinkVibrant
                else -> VantaColors.White
            },
            fontSize = 14.sp
        )
    }
}
