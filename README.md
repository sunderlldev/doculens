# DocuLens – Document Scanner & Organizer for iOS

![image]()

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

## Project Structure
```
doculens/
 ├── Controllers/
 ├── Views/
 ├── Assets.xcassets/
 ├── Base.lproj/
 ├── doculens.xcdatamodeld/
 └── Info.plist
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
