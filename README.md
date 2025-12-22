# DocuLens – Document Scanner & Organizer for iOS

![image](assets/doculens-mobile.webp)

DocuLens is an **offline-first iOS document management app** that allows users to scan, extract, organize and classify documents using **folders and tags**, with a clean and consistent user experience.

The app is designed with a future cloud sync architecture in mind, but currently works **100% offline**, using Core Data and the iOS file system.

---

## Smart Document Scanning & Organization
DocuLens is an iOS application designed to scan, extract information, and organize documents efficiently.  

## Project Overview
DocuLens transforms your device into a powerful document management tool.  
The app scans documents, extracts relevant metadata, organizes them into folders, and prepares information for future syncing with cloud storage and a PostgreSQL backend.

This repository contains the **iOS client**, developed entirely with UIKit and Storyboards.

## Features (Current & Planned)

### Implemented (Testing Phase)
- Custom UI for home screen and tab bar
- Recent documents list (UI prototype)
- Launch screen and branded app icon
- Base Core Data model (Folder, Document, Tag)
- Local-only mode enabled for testing

### In Development
- Document scanner using VisionKit & Vision OCR
- Document metadata extraction
- PDF and image export with metadata
- Folder-based organization with subfolders
- Thumbnail generation for scanned documents

### Planned Features (Online Mode)
- User accounts (PostgreSQL + API)
- Cloud synchronization
- Search engine powered by OCR index
- Tags and advanced filtering
- Secure iCloud Backup

## Technologies Used
- Swift 5
- UIKit + Storyboards
- Core Data
- Vision & VisionKit (soon)
- Xcode 16.4

## Installation
```bash
git clone https://github.com/jaycodev/doculens.git
cd doculens
```
Open in Xcode 16.4, build, and run.

---

## Architecture Overview

### Offline Mode (Current)

- **Core Data** for persistence
- **Local file system** for document storage
- **Vision** for OCR
- **PDFKit** for PDF rendering
- **UIKit** + Storyboard
- No login required

The architecture is prepared for future cloud synchronization but does not depend on it.

---

## 🧬 Core Data Model

### Entities

**Document**
- id (UUID)
- title (String)
- createdAt (Date)
- filePath (String)
- mimeType (String)
- originalFilename (String?)
- extractedFields (Binary?)
- thumbnail (Binary?)
- folder (Folder?)
- tags (Set<Tag>)

**Folder**
- id (UUID)
- name (String)
- createdAt (Date)
- documents (Set<Document>)
- parent (Folder?)
- children (Set<Folder>)

**Tag**
- id (UUID)
- name (String)
- documents (Set<Document>)

---

## Project Structure

```text
doculens/
 ├── Modules/
 │   ├── Home/
 │   ├── Files/
 │   ├── Folder/
 │   ├── Tags/
 │   └── Details/
 ├── Utils/
 │   ├── Loader.swift
 │   ├── Notifications.swift
 ├── CoreData/
 │   └── doculens.xcdatamodeld
 ├── Resources/
 │   └── Base.lproj
 ├── Assets.xcassets
 └── AppDelegate.swift
```

## Architecture Overview

### Offline Mode (Current)
- Core Data storage
- Local filesystem
- No login required

### Online Mode (Planned)
- PostgreSQL backend
- REST API 
- Cloud file storage
- User accounts

## Security Notes
- No API keys required in current phase.
- Local secure storage.
- Cloud credentials excluded in future.

## 🧪 Current Status
Actively developing UI, Core Data tests, and OCR pipeline.
