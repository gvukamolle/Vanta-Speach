package com.vanta.speech.feature.library

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vanta.speech.R
import com.vanta.speech.ui.components.DayRecordingsBottomSheet
import com.vanta.speech.ui.components.StatCard
import com.vanta.speech.ui.components.VantaBackground
import com.vanta.speech.ui.components.calendar.CalendarView
import com.vanta.speech.ui.theme.VantaColors

@Composable
fun LibraryScreen(
    viewModel: LibraryViewModel = hiltViewModel(),
    onRecordingClick: (String) -> Unit
) {
    val displayedMonth by viewModel.displayedMonth.collectAsStateWithLifecycle()
    val selectedDate by viewModel.selectedDate.collectAsStateWithLifecycle()
    val recordingDates by viewModel.recordingDates.collectAsStateWithLifecycle()
    val totalRecordingsCount by viewModel.totalRecordingsCount.collectAsStateWithLifecycle()
    val monthRecordingsCount by viewModel.monthRecordingsCount.collectAsStateWithLifecycle()
    val recordingsForSelectedDate by viewModel.recordingsForSelectedDate.collectAsStateWithLifecycle()

    VantaBackground {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 24.dp)
                .verticalScroll(rememberScrollState())
        ) {
            // Header
            Text(
                text = stringResource(R.string.nav_history),
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = VantaColors.White,
                modifier = Modifier.padding(horizontal = 24.dp)
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Calendar
            CalendarView(
                displayedMonth = displayedMonth,
                onMonthChange = { viewModel.setDisplayedMonth(it) },
                selectedDate = selectedDate,
                onDateSelected = { date ->
                    if (recordingDates.contains(date)) {
                        viewModel.selectDate(date)
                    }
                },
                recordingDates = recordingDates,
                modifier = Modifier.padding(horizontal = 16.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Statistics cards
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    title = stringResource(R.string.stats_total),
                    value = totalRecordingsCount.toString(),
                    icon = Icons.Default.GraphicEq,
                    color = VantaColors.PinkVibrant,
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    title = stringResource(R.string.stats_month),
                    value = monthRecordingsCount.toString(),
                    icon = Icons.Default.CalendarMonth,
                    color = VantaColors.BlueVibrant,
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Empty state hint
            if (recordingDates.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 48.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Default.Folder,
                            contentDescription = null,
                            tint = VantaColors.DarkTextSecondary,
                            modifier = Modifier.height(48.dp)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = stringResource(R.string.library_empty),
                            style = MaterialTheme.typography.bodyLarge,
                            color = VantaColors.DarkTextSecondary
                        )
                    }
                }
            } else {
                // Hint text
                Text(
                    text = "Выберите день с записями на календаре",
                    style = MaterialTheme.typography.bodyMedium,
                    color = VantaColors.DarkTextSecondary,
                    modifier = Modifier.padding(horizontal = 24.dp)
                )
            }

            // Bottom padding
            Spacer(modifier = Modifier.height(100.dp))
        }
    }

    // Day recordings bottom sheet
    selectedDate?.let { date ->
        DayRecordingsBottomSheet(
            date = date,
            recordings = recordingsForSelectedDate,
            onRecordingClick = { recordingId ->
                viewModel.clearSelectedDate()
                onRecordingClick(recordingId)
            },
            onDismiss = { viewModel.clearSelectedDate() }
        )
    }
}
