# DocuLens – Document Scanner & Organizer for iOS

![image](assets/doculens-mobile.webp)

DocuLens is a professional document management solution for iOS, designed to scan, extract metadata, and categorize information using an offline-first approach. The application leverages UIKit and Core Data to provide a robust hierarchical organization system through folders and tags.

---

## Technical Specifications

The project is developed entirely in **Swift** for the iOS platform, using a modular architecture that separates UI, business logic, and persistence layers.

### Core Technologies

- **UI Framework:** UIKit (Storyboards and Programmatic UI)
- **Persistence:** Core Data with SQLite storage
- **Authentication:** Firebase Auth (Native support for Apple Sign-In and Google Sign-In)
- **Document Processing:** Vision and VisionKit for OCR and smart scanning
- **Session Management:** SceneDelegate for dynamic routing based on authentication state

---

## Implemented Features

### Document Management

- **Smart Scanning:** VisionKit integration for edge detection and perspective correction.
- **OCR Recognition:** Automatic text extraction for document indexing.
- **Hierarchical Structure:** Folder system with subfolder support and many-to-many relationships with tags.
- **Local Storage:** Documents are managed directly within the iOS file system, linked via unique identifiers in Core Data.

### Authentication & Onboarding

- **Identity Providers:** Full login flows with Apple (native style) and Google (official branding).
- **Guest Mode:** Full app functionality without registration, storing user data locally via UserDefaults.
- **Welcome Flow:** Interactive onboarding system based on UIPageViewController to guide users during their first access.

---

## Project Structure

```text
doculens/
├── App/
│   ├── AppDelegate.swift       
│   └── SceneDelegate.swift     
├── Modules/
│   ├── Home/                   # Dashboard and recent activity
│   ├── Files/                  # General document listing
│   ├── Folder/                 # Directory logic and navigation
│   ├── Tags/                   # Metadata classification
│   └── Login/                  # Auth provider implementation
├── CoreData/
│   └── doculens.xcdatamodeld   # Entity definitions (Document, Folder, Tag)
├── Utils/
│   ├── Loader.swift            # UI loading indicators
│   └── Notifications.swift     # Internal observer patterns
└── Resources/                  # Assets, icons, and Storyboards
```

---

## Technologies Used

- **Swift 5**
- **UIKit + Storyboards**
- **Core Data**
- **Vision & VisionKit** (Coming soon)
- **Xcode 16.4**

---

## Data Model (Core Data)

The model is optimized for data integrity, using **Non-Optional** constraints on critical fields to ensure Swift type safety and prevent runtime crashes.

### Entities

**Document**

- `id`: UUID (Non-optional)
- `title`: String (Non-optional)
- `createdAt`: Date (Non-optional)
- `filePath`: String (Non-optional)
- `thumbnail`: Binary Data (Optional)

**Folder**

- `id`: UUID (Non-optional)
- `name`: String (Non-optional)
- _Relationships:_ Supports subfolders via self-referential parent/children links.

**Tag**

- `id`: UUID (Non-optional)
- `name`: String (Non-optional)

---

## Installation & Setup

### Prerequisites

- **Xcode 16.4** or higher.
- **iOS 17.0+** deployment target.

### Steps

1. **Clone the repository:**

```bash
git clone [https://github.com/jaycodev/doculens.git](https://github.com/jaycodev/doculens.git)
cd doculens
```

2. **Configuration:**

- **Firebase:** Add your `GoogleService-Info.plist` to the project root.
- **URL Schemes:** Add the `REVERSED_CLIENT_ID` to the **URL Types** in the project's Info tab for Google Sign-In support.

3. **Build:**

- Open `doculens.xcodeproj` in **Xcode 16.4**.
- Press `Cmd + R` to build and run on a simulator or physical device.

---
