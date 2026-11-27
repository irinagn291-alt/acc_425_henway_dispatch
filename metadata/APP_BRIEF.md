<!-- gf-brief source=e00c07cdda0e00cba3b384409f4433167307dc78db6e766ab21638b85d20c37a written=2026-11-27T09:25:20+03:00 -->
# Henway Dispatch

## What it is

Henway Dispatch is a timed traffic-control puzzle game. Players switch two road signals and guide flocks across a central island while keeping cars, tractors, and trains moving. It is for players who enjoy juggling queues, timing crossings, and replaying shifts for better scores.

## Launch and onboarding

1. The app opens on “Dispatch desk” beneath the “HENWAY DISPATCH” masthead, with a crossing illustration. There is no mandatory tutorial or setup.
2. On a fresh install, the “NEXT SHIFT” card shows “Farm”, “2:31”, and “Guide your first flocks from the west bank.” Tap “Start shift” to begin the first shift immediately. “Shift map” and “Daily shift” are also available from the start.
3. The question-mark icon, labelled “Field guide” for accessibility, opens the optional instructions. Its “Dispatch desk” button returns to the desk.
4. On a later cold launch, an unfinished shift appears under “SHIFT IN PROGRESS” with its district, remaining time, and “Resume shift”. A finished current shift makes “Last shift report” available.

## Screens

There is no tab bar. Every screen outside “Dispatch desk” has a house icon labelled “Dispatch desk” for accessibility. It returns to the desk and pauses any active shift. The copy quoted below is the English UI.

### “Dispatch desk”

- The “NEXT SHIFT” card shows the recommended campaign district, its guidance, and the shift duration. “Start shift” opens the crossing. If a shift is unfinished, the card instead shows “SHIFT IN PROGRESS”, remaining time, and “Resume shift”, which returns to that crossing and restarts the clock.
- “Shift map” opens the district and shift picker.
- “Daily shift” opens the challenge for the current UTC date. The row shows the district and date separated by “ · ”, with the date in year-month-day order. After a result, it also shows a star icon and the best star count for that date.
- “Last shift report” opens the report for the current finished shift. It appears only while that finished shift is still the current one.
- The question-mark icon labelled “Field guide” opens the instructions.

### “Shift map”

- “Farm”, “Market”, “Mill”, and “Station” are district buttons. Tapping one updates the highlighted selection, the “DISTRICT” card, and the grid of nine shifts. “Farm” is selected on cold launch.
- The district cards show:
  - “Farm” — “Guide your first flocks from the west bank.”
  - “Market” — “Expect flocks from both sides of the road.”
  - “Mill” — “Leave room for tractors and their trailers.”
  - “Station” — “Keep the tracks clear for scheduled trains.”
- Each tile shows “SHIFT” and a number from “01” through “09”. It shows the duration before a result exists and the best saved score with any earned stars afterward. Tap a tile to start that shift or resume it if it is already the active shift. All 36 shifts are available from the start.
- Choosing a different shift while one is unfinished opens “Replace the current shift?” with the message “Your finished shifts and records are saved.” “Start shift” replaces the unfinished run. “Cancel” dismisses the alert and keeps that run.

### Active crossing — “Farm”, “Market”, “Mill”, or “Station”

- The district name is the screen title. “Time left” shows the countdown, “Delivered” shows delivered birds out of the total, and “Island” shows birds on the island out of its capacity. The overhead illustration shows flocks, the island, road signals, traffic, and tracks in “Station”.
- The pause icon is labelled “Pause shift” for accessibility. It freezes the clock and disables the lane controls. The icon becomes a play button labelled “Resume shift”, which continues the run.
- “West lane” and “East lane” each have a signal button showing its current state. Tap “Traffic” to switch that lane to “Birds”. Tap “Birds” to reopen it to “Traffic”.
- “To island” sends up to three waiting birds from that lane’s bank to the island. “To bank” sends up to three birds from the island through that lane to their destination bank. The number beside each button shows how many birds are waiting for that move. Each lane also shows a count followed by “queued”.
- “Timetable” pauses the shift and opens its schedule. “Field guide” pauses it and opens the instructions.
- The live guidance reads, as conditions change: “Set the waiting flock’s lane to birds, then send it to the island.”, “Open the exit lane for birds, then send the flock to the bank.”, “Open idle lanes to traffic while the next flock approaches.”, “Open the busiest road to traffic to clear the queue.”, or “Hold the flock until the train clears.” When paused, it reads “Shift paused. Resume when you are ready.”
- Delivering every bird or running out of time opens “Shift report” automatically.

### “Timetable”

- Shows the current district and elapsed shift time. In “Station”, “TRAIN RESERVATIONS” lists three “Scheduled train” entries with their scheduled times.
- “FLOCK ARRIVALS” lists the full shift schedule, with arrival times, “West bank” or “East bank”, and the number of birds in each flock.
- “Resume shift” returns to the crossing and continues the clock. The house icon returns to “Dispatch desk” with the shift paused.

### “Shift report”

- Shows the district name in uppercase, a score, zero to three filled stars, and “All flocks delivered” or “Shift ended”.
- Lists “Delivered”, “Shift time”, “Flock waiting time”, “Traffic waiting time”, and “Longest queue”.
- “Crossing replay” opens the busiest excerpt of this run, paused at its first frame.
- “Try this shift again” starts the same shift from the beginning.
- “Shift map” opens the district and shift picker.

### “Crossing replay”

- “BUSIEST MOMENT” shows a short excerpt of the crossing. “Shift time”, “Island”, “Delivered”, “West queue”, and “East queue” update for the selected moment.
- The segmented timeline has one button per recorded moment in the excerpt. Each segment is labelled with its elapsed time for accessibility. Tapping one jumps to that moment and pauses playback.
- “Play replay” advances through the excerpt. “Pause replay” holds the current moment. Playback stops at the end. Tapping “Play replay” again from the last segment starts at the beginning of the excerpt.
- “Shift report” returns to the report for the same run.

### “Field guide”

- “Signals” — “Tap Traffic to give birds the signal. A vehicle already moving must clear first.”
- “Cross in two stages” — “Send up to three birds to the island. Open their exit lane, then tap To bank to deliver them.”
- “Traffic queues” — “Tap Birds to let cars pass. Long queues can block the neighbouring lane.” In U.S. English the exact copy is “Tap Birds to let cars pass. Long queues can block the neighboring lane.”
- “Score” — “Deliver every flock before time runs out. Shorter waits for birds and traffic earn more stars.”
- When opened from the desk, the bottom “Dispatch desk” button returns there. When opened during a shift, the bottom “Resume shift” button returns to the crossing and continues the clock.

## Features

- “Shift map” with 36 timed shifts, nine each in “Farm”, “Market”, “Mill”, and “Station”. “Farm” sends flocks from the west bank. Later districts use both banks, “Mill” introduces tractors and trailers, and “Station” adds scheduled trains.
- “Daily shift” with a shared challenge for each UTC date and a locally saved best result for that date.
- “West lane” and “East lane” controls for “Traffic”, “Birds”, “To island”, and “To bank”, with a limited-capacity island, vehicle queues, and live guidance.
- “Timetable” for “FLOCK ARRIVALS” and, in “Station”, “TRAIN RESERVATIONS”.
- “Pause shift” and “Resume shift”, including resuming an unfinished run after relaunch.
- “Shift report” with score, stars, delivery count, elapsed time, waiting times, longest queue, and “Try this shift again”.
- “Crossing replay” with playback and individual moment selection.
- “Field guide” with instructions on signals, two-stage crossings, traffic queues, and scoring.

## Behaviours that can look like bugs

- **The first crossing has disabled buttons.** Both signals start on “Traffic”. At the start of the first “Farm” shift, three birds are waiting at the west bank. Tap “Traffic” under “West lane”, then tap “To island” once the lane is clear. Once those birds are on the island, set “East lane” to “Birds” and tap its “To bank”.
- **A lane can show “Birds” while “To island” or “To bank” stays disabled.** The move needs waiting birds, a clear lane, and a running shift. “To island” also needs free island space, including room already reserved by birds on their way there. Wait for moving birds, cars, tractors, or trailers to clear, or send birds off the island with the appropriate “To bank”. In “Station”, wait if a train is passing or a crossing would overlap an upcoming reservation.
- **A signal can show “Traffic” while the queue still waits.** A long queue can block the neighbouring lane. When the hint reads “Open the busiest road to traffic to clear the queue.”, tap “Birds” on the busier lane to switch it to “Traffic” if needed, then let the queue drain.
- **Leaving the crossing freezes it.** “Timetable”, “Field guide”, the house icon, and switching away from the app pause the shift. Use “Resume shift” or the play icon to continue. The schedule lists all arrival and reservation times, including those already passed.
- **Another shift may require confirmation.** At “Replace the current shift?”, tap “Start shift” to give up the unfinished run and begin the selected one, or “Cancel” to keep it. Selecting the same active shift resumes it directly. “Try this shift again” on the report starts a fresh run immediately.
- **The desk recommendation can repeat or loop.** “NEXT SHIFT” recommends the first campaign shift where all flocks have yet to be delivered. A partial result can earn a score and a star while leaving that shift in the recommendation. After all 36 shifts are completed, the recommendation goes back to the first “Farm” shift.
- **Results are initially missing.** New “SHIFT” tiles show durations, “Daily shift” has no star count, and “Last shift report” is hidden. Finish a run to see its report and populate the relevant record. Starting another run replaces the current report and replay, while best records remain on the map or daily card.
- **The replay ends quickly.** “Crossing replay” shows up to seven recorded moments around “BUSIEST MOMENT”. Use the timeline segments to inspect them, or tap “Play replay” from the final segment to start the excerpt again.
- **A save can fail.** The app displays “Progress could not be saved on this device.” The notice has no action button.

## Starter content and resume

A fresh install includes all 36 campaign shifts, the current “Daily shift”, and the “Field guide”. Scores, stars, and shift reports start empty. An unfinished shift keeps its elapsed time, signals, birds, traffic, and queues when the player leaves or relaunches. Use “Resume shift” on “Dispatch desk” to continue. There is one current shift at a time.

## Permissions

None.

## Absent

Login or accounts, in-app purchases, ads, analytics, user-generated content, account deletion, and an App Tracking Transparency prompt are all absent.

## Data and support

The current shift and its report and replay, plus best campaign and daily results, are stored on the device. There is no account sync. There is no on-screen Contact or Support control, settings screen, or progress-reset control. “Field guide” provides gameplay help.

## Scanning and health

None.

## Platform

Supports iPhone and iPad on iOS or iPadOS 17.0 or later. The build enables portrait, upside-down portrait, and both landscape orientations, subject to the device’s supported orientations.

The native interface has English, U.S. English, British English, Arabic, Bengali, and Traditional Chinese localizations. “HENWAY DISPATCH” stays in English. In right-to-left layouts, the crossing illustration and lane controls retain their physical west-left and east-right positions. Gameplay is the same across regions, and “Daily shift” uses the UTC date.

## Category

Games — Puzzle.
