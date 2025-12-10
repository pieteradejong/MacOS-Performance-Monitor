# Step-by-Step Setup Guide

Follow these steps **in order** to get everything working.

## Step 1: First-Time Xcode Setup (One Time Only)

**Goal:** Configure Xcode so it can build the project.

### 1.1 Open Xcode Project
```bash
open UptimeMonitor.xcodeproj
```

### 1.2 If Xcode Prompts You
- If it asks to install additional components → Click **Install**
- If it asks about schemes → Click **OK** or **Create Scheme**
- Wait for Xcode to finish loading

### 1.3 Add Missing Swift Files to Project

The project file is incomplete - we need to add all Swift files:

1. In Xcode's **Project Navigator** (left sidebar), find the `UptimeMonitor` folder
2. **Right-click** on the `UptimeMonitor` folder
3. Select **"Add Files to 'UptimeMonitor'..."**
4. In the file picker, navigate to your project folder
5. Select these **three folders**:
   - `UptimeMonitor/Models/`
   - `UptimeMonitor/Views/`
   - `UptimeMonitor/Utilities/`
6. **Important settings:**
   - ✅ **UNCHECK** "Copy items if needed"
   - ✅ **CHECK** "Create groups"
   - ✅ **CHECK** "Add to targets: UptimeMonitor"
7. Click **Add**

### 1.4 Verify Files Were Added

In Xcode's Project Navigator, you should now see:
```
UptimeMonitor/
├── UptimeMonitorApp.swift
├── Info.plist
├── Models/
│   ├── HealthStatus.swift
│   ├── SystemMonitor.swift
│   └── SystemSnapshot.swift
├── Views/
│   ├── HealthIndicatorView.swift
│   └── MenuContentView.swift
└── Utilities/
    ├── Shell.swift
    ├── UptimeParser.swift
    └── VMStatParser.swift
```

## Step 2: Build in Xcode (Verify It Works)

**Goal:** Make sure the project compiles without errors.

### 2.1 Build the Project
- Press **`⌘B`** (Command + B)
- Or go to **Product > Build**

### 2.2 Check for Errors
- Look at the bottom panel for any red errors
- If you see errors, they'll tell you what's wrong
- **Common fix:** Make sure all files are added to the target (Step 1.3)

### 2.3 Success?
- If you see **"Build Succeeded"** → ✅ Great! Move to Step 3
- If you see errors → Fix them first (usually missing files)

## Step 3: Run in Xcode (Test the App)

**Goal:** Launch the app and see it in your menu bar.

### 3.1 Run the App
- Press **`⌘R`** (Command + R)
- Or click the **Play** button in Xcode toolbar

### 3.2 What Should Happen
- Xcode will build (if needed) and launch the app
- **Look at your menu bar** (top right of screen)
- You should see an icon with uptime (like "0.0d")
- **No Dock icon** should appear (that's correct - it's a menu bar only app)

### 3.3 Test the App
- **Click the menu bar icon**
- A dropdown should appear showing:
  - Uptime
  - Load averages
  - Swap used
  - Free memory
  - System health status
  - Action buttons

### 3.4 Success?
- If the app appears in menu bar and dropdown works → ✅ Perfect!
- If not → Check Console.app for errors

## Step 4: Now You Can Work in Cursor!

**Goal:** Switch to Cursor for all future development.

### 4.1 Close Xcode (Optional)
- You can close Xcode now - you won't need it for daily work

### 4.2 Open Project in Cursor
- Cursor should already have the project open
- If not: `File > Open Folder` → Select the project folder

### 4.3 Make a Test Change
Let's verify Cursor workflow works:

1. Open `UptimeMonitor/Models/SystemMonitor.swift` in Cursor
2. Find the `updateInterval` (around line 15)
3. Change it from `10.0` to `5.0` (just to test)
4. Save the file

### 4.4 Build from Cursor Terminal
Open Cursor's terminal (`` Ctrl+` `` or View > Terminal) and run:

```bash
./build.sh
```

### 4.5 Run from Cursor Terminal
```bash
./run.sh
```

### 4.6 Verify Your Change Worked
- The app should rebuild and relaunch
- Check menu bar - metrics should update faster (every 5 seconds instead of 10)

### 4.7 Revert Test Change (Optional)
Change `updateInterval` back to `10.0` if you want.

## Step 5: Daily Workflow (Going Forward)

Now you can work entirely in Cursor:

1. **Edit code** in Cursor
2. **Build:** `./build.sh` in terminal
3. **Run:** `./run.sh` in terminal  
4. **Test:** Check menu bar app
5. **Commit:** Use Cursor's git features

**You only need Xcode again if:**
- You add new Swift files (need to add them to project)
- You need advanced debugging (breakpoints, etc.)

## Troubleshooting

### "No such module" or "Cannot find type" errors
→ Files not added to Xcode project. Go back to Step 1.3

### Build succeeds but app doesn't appear
→ Check Console.app: `open -a Console`
→ Filter by "UptimeMonitor"

### "Scheme not found" error
→ Open Xcode, Product > Scheme > Manage Schemes
→ Make sure "UptimeMonitor" scheme exists and is shared

### Terminal says "xcodebuild requires Xcode"
→ Make sure full Xcode is installed (not just Command Line Tools)
→ Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

---

**Ready? Start with Step 1!** 🚀
