# Testing Guide: Vault PDF Fixes

## Quick Test in Xcode

1. **Open the project in Xcode**
   ```bash
   open "/Users/joel/Downloads/On phoneapp/On phoneapp.xcodeproj"
   ```

2. **Build and Run** (Cmd+R)
   - If you get any build errors, please share them with me
   - The code should compile without errors

## Test Scenarios

### Test 1: Scan a Multi-Page Document as PDF
1. Open the app and go to **Vault**
2. Tap the **"+"** button (top right)
3. Select **"Scan Document"**
4. Scan **2-3 pages** (use any paper, receipts, etc.)
   - After each page, tap **"Keep Scan"**
   - Continue scanning until you have multiple pages
   - Tap **"Save"** when done
5. In the Add to Vault screen:
   - Give it a title (e.g., "Test PDF Doc")
   - Select a category
   - Tap **"Save"**

**Expected Result:**
- Document appears in grid/list view with a small red "PDF" badge
- Thumbnail shows the first page of the PDF

### Test 2: View All Pages of PDF
1. Tap on the PDF document you just created
2. In the detail view, you should see:
   - The first page displayed
   - Page counter: "Page 1 of X" (where X is total pages)
   - Left/right navigation arrows
3. **Navigate through pages:**
   - Tap the right arrow to go to next page
   - Tap the left arrow to go back
   - Each page should render correctly
4. **View full PDF:**
   - Tap **"View All Pages"** button
   - Should open a full-screen viewer
   - Swipe left/right to navigate pages
   - Pinch to zoom on each page
   - Tap **"Done"** to return

**Expected Result:**
- All pages render correctly
- Navigation is smooth
- Page counter updates as you navigate

### Test 3: Export PDF (Share)
1. Open the PDF document
2. Tap the **share button** (square with arrow, top right)
3. Try sharing to:
   - **Files app**: Save it somewhere
   - **Mail**: Attach to email
   - **AirDrop**: Send to another device (if available)

**Expected Result:**
- Share sheet appears immediately (no black screen)
- File shows as `.pdf` format
- File name matches the document title
- Recipient can open the PDF and see all pages

### Test 4: Export Image (for comparison)
1. Go back to Vault main screen
2. Tap **"+"** → **"Upload from Photos"**
3. Select any photo from your library
4. Save it with a title
5. Open the saved image
6. Tap **share button**
7. Try sharing to Files/Mail

**Expected Result:**
- Shares as `.jpg` file
- Image quality is good
- Share works smoothly

### Test 5: Grid/List View Display
1. Create a few different documents:
   - At least 1 multi-page PDF scan
   - At least 1 single-page photo
2. Switch between grid and list views (button top left)

**Expected Result:**
- **Grid view**: PDFs show thumbnail of first page + PDF badge
- **List view**: PDFs show thumbnail of first page + PDF badge
- **Grid view**: Images show normally
- **List view**: Images show normally
- Thumbnails load smoothly

## If You Encounter Issues

### Issue: Build errors in Xcode
- **Take a screenshot** of the error
- Share the error message with me

### Issue: PDF not showing thumbnail
- Check the console for error messages starting with ❌
- The PDF might be corrupted or empty

### Issue: Share not working
- Check if device is locked (files are encrypted)
- Try unlocking device first

### Issue: Scanned pages look weird
- This is normal for some paper types
- Make sure there's good lighting when scanning

## Debug Console Messages

Watch for these console messages (helpful for troubleshooting):
- `✅ VaultStorageManager: Successfully saved...` - File saved OK
- `✅ KeychainHelper: Successfully saved key...` - Encryption key stored
- `❌ VaultStorageManager: Failed to...` - Something went wrong
- `❌ Failed to create temporary PDF file` - Share preparation failed

## Success Indicators

✅ Multi-page scanning creates a PDF
✅ PDF thumbnails display in grid/list
✅ Can navigate through all pages
✅ Can view full-screen PDF viewer
✅ Export creates .pdf file (not .png)
✅ Share sheet works reliably
✅ No black screens

## Questions to Verify

- [ ] Can you scan multiple pages?
- [ ] Do you see all pages in the detail view?
- [ ] Does the share/export create a PDF file?
- [ ] Can the exported PDF be opened elsewhere?
- [ ] Do PDF thumbnails show in the list?

