# Classboard

Classboard is a macOS-only SwiftUI timetable app for university students. The MVP focuses on the core desktop experience: seeing the current class, next class, and today's schedule from a macOS Widget without opening the main app.

## Features

- SwiftUI macOS main app with `NavigationSplitView`
- Weekly timetable grid view
- Course management with add, edit, delete
- Multiple schedules per course
- Validation for empty names, invalid time ranges, duplicate schedule rows
- Non-blocking overlap warning for schedules that conflict with other courses
- SwiftData persistence in an App Group container
- Widget data snapshot saved as Codable JSON in the App Group container
- WidgetKit small, medium, and large families
- Timeline entries around class start and end times
- Empty states for no courses and no classes today
- Basic unit tests for schedule calculation

## Tech Stack

- Swift
- SwiftUI
- SwiftData
- WidgetKit
- App Groups
- XCTest

The deployment target is macOS 14.0 because SwiftData is part of the MVP.

## Project Structure

```text
Classboard/
  Classboard.xcodeproj
  Classboard/
    App/
    Models/
    Data/
    Services/
    Shared/
    Utilities/
    Views/
    Components/
  ClassboardWidget/
  ClassboardTests/
```

## Data Design

`Course` and `ClassSchedule` are SwiftData models. A course owns multiple schedule rows, and deleting a course cascades to its schedules.

The main app is the source of truth. After create, update, or delete, `WidgetSyncService` writes a `TimetableSnapshot` JSON file to:

```text
App Group container/timetable-snapshot.json
```

The widget reads only that snapshot. This avoids relying on SwiftData store access from the widget extension process and keeps widget rendering graceful if the store is unavailable.

## Widget Timeline

`TimetableTimelineProvider` loads the snapshot, calculates the current class, next class, and today's classes, then creates timeline entries around:

- the current timeline request date
- class start times
- class end times
- upcoming day boundaries

The widget does not attempt minute-by-minute refreshes.

## Run in Xcode

1. Open `Classboard.xcodeproj`.
2. Select the `Classboard` project.
3. Set your Apple Developer Team, such as `Personal Team`, for:
   - `Classboard`
   - `ClassboardWidgetExtension`
   - `ClassboardTests`
4. Confirm these bundle IDs:
   - `com.heo.classboard`
   - `com.heo.classboard.widget`
   - `com.heo.classboard.tests`
5. Enable App Groups for both app and widget targets.
6. Keep this existing App Group for both targets to preserve app/widget data compatibility:

```text
group.com.heo.unitimetable
```

If you change the App Group ID in Signing & Capabilities, update `AppConfiguration.appGroupIdentifier` and both entitlement files and migrate existing data first.

## Testing

The project includes `ScheduleCalculatorTests` for:

- before today's first class
- current class
- between classes
- after today's last class
- gap days
- Friday after class to next Monday
- weekend classes
- multiple schedules for one course

The project is expected to build and test with Xcode using the shared `Classboard` scheme.

## MVP Limitations

- No iCloud sync
- No login or server
- No school timetable import
- No calendar integration
- No iOS or watchOS companion app
- Color selection is a curated palette, not a freeform color picker
- Conflict detection is a warning only

## Recommended Next Steps

1. Open in Xcode and finish signing/App Group setup.
2. Run the app target and add a few real courses.
3. Add the widget to the desktop and verify snapshot updates after create/edit/delete.
4. Add import/export once the MVP flow feels right.
