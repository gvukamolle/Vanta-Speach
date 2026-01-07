package com.vanta.speech.feature.library

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.vanta.speech.core.domain.model.Recording
import com.vanta.speech.core.domain.repository.RecordingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import javax.inject.Inject

data class RecordingsByDate(
    val date: LocalDate,
    val recordings: List<Recording>
)

@HiltViewModel
class LibraryViewModel @Inject constructor(
    private val recordingRepository: RecordingRepository
) : ViewModel() {

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // Calendar state
    private val _displayedMonth = MutableStateFlow(YearMonth.now())
    val displayedMonth: StateFlow<YearMonth> = _displayedMonth.asStateFlow()

    private val _selectedDate = MutableStateFlow<LocalDate?>(null)
    val selectedDate: StateFlow<LocalDate?> = _selectedDate.asStateFlow()

    // All recordings
    private val allRecordings: StateFlow<List<Recording>> = recordingRepository
        .getAllRecordings()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    // Recordings grouped by date
    val recordingsGroupedByDate: StateFlow<List<RecordingsByDate>> = allRecordings
        .map { recordings ->
            recordings
                .groupBy { recording ->
                    recording.createdAt
                        .atZone(ZoneId.systemDefault())
                        .toLocalDate()
                }
                .map { (date, recordings) ->
                    RecordingsByDate(
                        date = date,
                        recordings = recordings.sortedByDescending { it.createdAt }
                    )
                }
                .sortedByDescending { it.date }
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    // Dates that have recordings (for calendar markers)
    val recordingDates: StateFlow<Set<LocalDate>> = allRecordings
        .map { recordings ->
            recordings.map { recording ->
                recording.createdAt
                    .atZone(ZoneId.systemDefault())
                    .toLocalDate()
            }.toSet()
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptySet()
        )

    // Total recordings count
    val totalRecordingsCount: StateFlow<Int> = allRecordings
        .map { it.size }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = 0
        )

    // Recordings count for displayed month
    val monthRecordingsCount: StateFlow<Int> = combine(
        allRecordings,
        displayedMonth
    ) { recordings, month ->
        recordings.count { recording ->
            val recordingDate = recording.createdAt
                .atZone(ZoneId.systemDefault())
                .toLocalDate()
            YearMonth.from(recordingDate) == month
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = 0
    )

    // Recordings for selected date
    val recordingsForSelectedDate: StateFlow<List<Recording>> = combine(
        allRecordings,
        selectedDate
    ) { recordings, date ->
        if (date == null) {
            emptyList()
        } else {
            recordings.filter { recording ->
                val recordingDate = recording.createdAt
                    .atZone(ZoneId.systemDefault())
                    .toLocalDate()
                recordingDate == date
            }.sortedByDescending { it.createdAt }
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )

    fun setDisplayedMonth(month: YearMonth) {
        _displayedMonth.value = month
    }

    fun selectDate(date: LocalDate) {
        _selectedDate.value = date
    }

    fun clearSelectedDate() {
        _selectedDate.value = null
    }

    fun deleteRecording(recordingId: String) {
        viewModelScope.launch {
            recordingRepository.deleteRecording(recordingId)
        }
    }

    fun searchRecordings(query: String): StateFlow<List<Recording>> {
        return recordingRepository
            .searchRecordings(query)
            .stateIn(
                scope = viewModelScope,
                started = SharingStarted.WhileSubscribed(5000),
                initialValue = emptyList()
            )
    }
}
