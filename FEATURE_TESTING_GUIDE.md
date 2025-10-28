# Feature Testing Guide - On Phone App

## Before You Start

1. **Build the app in Xcode** (Cmd+B)
2. **Run on simulator or device** (Cmd+R)
3. **Allow all permissions** when prompted (Camera, Photos, Biometric, etc.)
4. **Keep Xcode console open** to see debug messages

---

## 🎯 Test 1: Multi-Page PDF Scanning

### What's New:
- Scan multiple pages into a single PDF
- Each page is saved as part of the PDF
- Works with any document

### How to Test:

1. **Open the app** → Go to **Vault** tab
2. **Tap the "+" button** (top right)
3. **Select "Scan Document"**
4. **Scan 3-4 pages:**
   - Take a photo of page 1
   - Tap "Keep Scan"
   - Take a photo of page 2
   - Tap "Keep Scan"
   - Continue for pages 3-4
   - When done, tap "Save"
5. **In the Add to Vault screen:**
   - Title: "Test Multi-Page PDF"
   - Category: "Personal"
   - Tags: "test, multipage" (optional)
   - Tap "Save"

### Expected Result:
✅ Document appears in Vault with a small red **"PDF"** badge
✅ Thumbnail shows first page of the document
✅ No black screen during save

**Debug Console Should Show:**
```
✅ VaultStorageManager: Successfully saved and protected [filename].pdf
✅ Created PDF from X pages
```

---

## 📖 Test 2: PDF Page Navigation

### What's New:
- See all pages of a multi-page PDF
- Navigate through pages with arrow buttons
- Page counter shows current page

### How to Test:

1. **In Vault**, tap on the **multi-page PDF** you just created
2. **In the detail view:**
   - You should see the first page displayed
   - Below it: "Page 1 of 4" (or however many pages)
   - Left/Right arrow buttons on sides

3. **Test Navigation:**
   - Tap **right arrow** → goes to page 2
   - Page counter updates to "Page 2 of 4"
   - Tap **right arrow** again → page 3
   - Tap **left arrow** → goes back to page 2
   - Continue navigating through all pages

4. **Edge Cases:**
   - Left arrow should be **GRAYED OUT** when on page 1
   - Right arrow should be **GRAYED OUT** when on last page

### Expected Result:
✅ Can navigate through all pages
✅ Page counter updates correctly
✅ Arrows disable at edges
✅ Each page renders without delay

---

## 🖥️ Test 3: Full-Screen PDF Viewer

### What's New:
- View all pages in full-screen mode
- Swipeable page navigation
- Zoom and pan support

### How to Test:

1. **While viewing the PDF detail:**
   - Look for "View All Pages" button
   - Tap it

2. **In Full Screen Viewer:**
   - Should see page 1 in full screen
   - Page indicator at bottom shows "1/4"
   - At top: page counter in toolbar

3. **Test Navigation:**
   - **Swipe left** → next page
   - **Swipe right** → previous page
   - Watch the page indicator update

4. **Test Zoom:**
   - **Pinch to zoom in** on the page
   - Can see more detail
   - **Pinch to zoom out** to fit page

5. **Tap Done** button (top right) to return

### Expected Result:
✅ Full-screen viewer opens smoothly
✅ Swiping works to navigate pages
✅ Zoom/pan works for reading
✅ Page counter updates
✅ Can return with Done button

---

## 📤 Test 4: PDF Export (Most Important!)

### What's New:
- Export PDFs as actual .pdf files (NOT images!)
- No more black screen
- Works with iOS share sheet
- Can share to Mail, Messages, Files, AirDrop, etc.

### How to Test:

1. **Open your multi-page PDF** in detail view
2. **Tap the share button** (square with arrow, top right)
3. **iOS Share Sheet should appear:**
   - You should see options like:
     - Messages
     - Mail
     - Notes
     - Files
     - AirDrop
     - Print
     - Copy
   - ❌ Should NOT see white/blank screen
   - ❌ Should NOT see black screen

4. **Test Sharing to Different Apps:**

   **Option A: Save to Files**
   - Tap "Save to Files"
   - Choose "On My iPhone" or "iCloud Drive"
   - Tap "Save"
   - Check that file saved with name like "Test Multi-Page PDF.pdf"

   **Option B: Send via Mail**
   - Tap "Mail"
   - New email compose window opens
   - PDF attached as "Test Multi-Page PDF.pdf"
   - Fill in recipient and send

   **Option C: AirDrop (if on Mac nearby)**
   - Tap "AirDrop"
   - Select recipient
   - File transfers

5. **Verify the exported file:**
   - Is it actually a .pdf? ✅
   - Not a .png? ✅
   - Can you open it and see all pages? ✅

### Expected Result:
✅ Share sheet appears immediately (no delay)
✅ Standard iOS share options visible
✅ Can save to Files with .pdf extension
✅ File contains all pages
✅ Can open exported PDF and see all content

**Debug Console Should Show:**
```
🔄 prepareForSharing called for: Test Multi-Page PDF, type: pdf
✅ Loaded PDF data, size: XXXXX bytes
✅ Created temp PDF file at: /path/to/temp/Test Multi-Page PDF.pdf
✅ Share sheet should present now
```

---

## 🖼️ Test 5: Image Thumbnail Display

### What's New:
- PDFs show first page as thumbnail (not black square)
- Images show normally
- Both have visual indicators

### How to Test:

1. **Upload an image to Vault:**
   - Tap "+"
   - Select "Upload from Photos"
   - Choose any photo
   - Save with title "Test Image"

2. **View Vault Grid:**
   - Switch to **Grid View** (button at top left)
   - See your multi-page PDF thumbnail (first page preview)
   - See your image thumbnail
   - PDF should have small red **"PDF"** badge

3. **View Vault List:**
   - Switch to **List View** (button at top left)
   - Same behavior - PDF thumbnail and image thumbnail
   - Both should load quickly

### Expected Result:
✅ PDF thumbnails show first page (not black/blank)
✅ Image thumbnails show normally
✅ PDF badge visible for PDFs
✅ Grid and list views work correctly

---

## 🔐 Test 6: File Sharing (Merged Fix)

### What's New:
- Fixed white screen issue in share sheet
- UIActivityViewController properly presented
- Works reliably

### How to Test:

1. **Test with both PDF and Image:**
   - Open your multi-page PDF
   - Tap share → verify sheet appears
   - Go back
   - Open your test image
   - Tap share → verify sheet appears

2. **Try multiple times:**
   - First share attempt
   - Cancel
   - Try again
   - Should work every time (no white screen)

3. **Test with different share destinations:**
   - Mail
   - Messages
   - Files
   - Notes
   - Reminders
   - Any other app available

### Expected Result:
✅ Share sheet always appears
✅ No white/blank screen
✅ Multiple share attempts work
✅ Can share to any destination

---

## 🏠 Test 7: Home Page

### What Already Works:
- Live time display (updates every second)
- Date with full formatting
- Gradient background
- Toolbox graphic

### How to Test:

1. **From Vault, go back to Home tab**
2. **Verify:**
   - ✅ Time displays correctly
   - ✅ Time updates every second (watch seconds change)
   - ✅ Date shows full format (e.g., "Monday, October 28, 2025")
   - ✅ Toolbox graphic visible in background
   - ✅ Blue gradient background
   - ✅ "Your essential toolkit" tagline visible

### Expected Result:
✅ Home page displays beautifully
✅ All elements render correctly
✅ Time updates in real-time

---

## 🔍 Console Debugging Checklist

Watch for these messages in Xcode console:

### Good Signs ✅
```
✅ VaultStorageManager: Successfully saved and protected [file].pdf
✅ KeychainHelper: Successfully saved key for [file]
✅ Loaded PDF data, size: XXXXX bytes
✅ Created temp PDF file at: /path/to/temp/[file].pdf
```

### Bad Signs ❌
```
❌ VaultStorageManager: Failed to load PDF data
❌ Failed to create temporary PDF file
❌ Failed to encrypt data
❌ KeychainHelper: Failed to save key
```

---

## 📋 Test Completion Checklist

Use this to track your progress:

### PDF Scanning & Viewing
- [ ] Can scan 3+ pages into one PDF
- [ ] PDF appears in vault with badge
- [ ] Can navigate pages with arrows
- [ ] Page counter shows correct count
- [ ] Full-screen viewer works
- [ ] Can swipe through all pages

### Export & Sharing
- [ ] Share button shows iOS share sheet (no black screen)
- [ ] Exported file is .pdf (not .png)
- [ ] Can save to Files
- [ ] Can share via Mail/Messages
- [ ] Can open exported PDF and see all pages

### General
- [ ] No crashes during testing
- [ ] No error messages in console
- [ ] Home page displays correctly
- [ ] Grid/List view work for both PDFs and images
- [ ] Image thumbnails show correctly

---

## If Something Goes Wrong

### Black/White Screen on Export:
- Check console for errors
- Try again - may be timing issue
- Restart app if needed

### PDF Won't Display:
- Verify scanner captured pages (should show 3+ count)
- Check encryption isn't causing issue
- Look for debug messages in console

### Thumbnail Not Loading:
- First load may be slow (rendering first page)
- Restart vault to clear cache
- Check file permissions

### Share Sheet Doesn't Appear:
- Device may need unlock (files are encrypted)
- Try again after waiting 2 seconds
- Restart app

---

## Success Criteria

✅ All features work without crashes
✅ Can scan, view, and export multi-page PDFs
✅ Share sheet appears reliably
✅ Exported files are correct format
✅ Home page displays beautifully
✅ No error messages in console

You're all set for testing! Start with Test 1 and work your way through. 🚀
