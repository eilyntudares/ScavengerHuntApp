# Project 1 - ScavengerHuntApp

Submitted by: **Eilyn Tudares**

**ScavengerHuntApp** is an iOS app that lets users create scavenger hunt tasks, attach photos from their photo library, and visualize where each photo was taken on a map. Once a photo is attached, the task is marked as completed and the updated status is reflected on the task list.

Time spent: 5 hours spent in total

## Required Features

The following **required** functionality is completed:

- [x] App displays list of tasks
- [x] User can create new tasks dynamically
- [x] When a task is tapped it navigates the user to a task detail view
- [x] When user adds a photo to complete the task, it marks the task as complete
- [x] When adding photo of task, the location is added (if available from metadata)
- [x] User returns to home page (list of tasks) and the status of the task is updated to complete


The following **additional** features are implemented:

- [x] Tasks persist locally using `UserDefaults`
- [x] Users can delete tasks from the list
- [x] Custom map annotations with pins
- [x] Minimal UI polish with SwiftUI

## Video Walkthrough


https://www.loom.com/share/1ac674e83666466b933830c1397f77bf

## Notes

One challenge was removing UIKit storyboard references so the app could launch purely in SwiftUI. Another was testing location metadata: most simulator images don’t have GPS data, so I had to drag in real photos with metadata or run the app on a physical device to see pins on the map.

## License

    Copyright 2025 Eilyn Tudares

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
