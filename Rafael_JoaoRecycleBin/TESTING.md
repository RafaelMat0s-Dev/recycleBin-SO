### Note

Before running all tests make sure you are inside `Rafael_JoaoRecycleBin` directory

### Test Case 1: Create Recycle Bin File Structure

**Objective:** Verify that  ~/.recycle_bin is created

**Steps:**

1. Run: `./recycle_bin.sh`
2. Verify file structure was created in ~/.recycle_bin

**Expected Result:**

- Every file and subfolder is created in ~/.recycle_bin
- Metadata file is created
- Config file is created
- /files are created

**Actual Result:** Everything was Created Successfully
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/InitializeRecycleBinTest.png)



### Test Case 2: Delete Single File

**Objective:** Verify that a single file can be deleted successfully

**Steps:**

1. Run: `./recycle_bin.sh delete <Filename>`
2. See the Success message printed in terminal
3. Navigate to `cd ~/.recycle_bin `
4. Open ` vim metadata.csv `
5. Verify that the file was deleted sucessfully

**Expected Result:**

- Sucess Message in the terminal after running the script
- File inside the /files directory in ~/.recycle_bin
- Content Inside the metadata.csv file


**Actual Result:** Everything was Deleted Successfully
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/DeleteSingleFile.png)


### Test Case 3: Delete Multiple File un the same command

**Objective:** Verify that multiple files can be deleted successfully in one command

**Steps:**

1. Run: `./recycle_bin.sh delete <Filename1> <Filename2> <Filename3>`
2. See the Success messages printed in terminal
3. Navigate to `cd ~/.recycle_bin `
4. Open ` vim metadata.csv `
5. Verify that the files were deleted sucessfully

**Expected Result:**

- Sucess Message in the terminal after running the script
- File inside the /files directory in ~/.recycle_bin
- Content Inside the metadata.csv file


**Actual Result:** Everything was Deleted Successfully
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/DeleteMultipleFiles.png)




### Test Case 4: Delete Files that don't exist

**Objective:** Verify that recycle_bin doesn't delete a file that doesn't exist

**Steps:**

1. Run: `./recycle_bin.sh delete <Filename1> <Filename2> <Filename3>...`
2. See the Error messages printed in terminal

**Expected Result:**
- Error Message in the terminal after running the script



**Actual Result:** Everything was Deleted Successfully
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/DeleteNonExistingFile.png)



### Test Case 5: Try to Delete .recycle_bin

**Objective:** Verify that recycle_bin.sh cannot delete the .recycle_bin itself

**Steps:**

1. Run: `./recycle_bin.sh delete ~/.recycle_bin`
2. See the Error messages printed in terminal

**Expected Result:**
- Error Message in the terminal after running the script


**Actual Result:** Everything was run Successfully (Error Message as it supposed to)
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/DeleteRecycleBinFolder.png)



### Test Case 6: Restore File

**Objective:** Verify that recycle_bin restores a file successfully.

**Steps:**

Note: "|" Represents that you can chose wether a FileName or FileID
1. Run: `./recycle_bin.sh restore <Filename> | <FileID>`
2. See the Success Message Printed on Terminal
3. Navigate to the base Parent Folder
4. See that the file/folder was restored back

**Expected Result:**
- Success Message in the Terminal
- Needed File Restored back in the path


**Actual Result:** Everything was Restored Successfully
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/RestoreFile.png)



### Test Case 7: Restore File that doesn't exist in .recycle_bin

**Objective:** Verify that recycle_bin doesn't restore a file that doesn't exist

**Steps:**

1. Run: `./recycle_bin.sh restore <Filename1>`
2. See the Error messages printed in terminal

**Expected Result:**
- Error Message in the terminal after running the script


**Actual Result:** Everything was mot restored (As it should be)
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/RestoreFileThatDoesntExist.png)


### Test Case 8: Restore File to Path that doesn't exist anymore

**Objective:** Verify that recycle_bin doesn't delete a file that doesn't exist

**Steps:**

1. Run: `./recycle_bin.sh restore <Filename1>`
2. See the Success messages printed in terminal
3. Navigate to the previous existing Path
4. See that the base path and directory was created again

**Expected Result:**
- Sucess Message in the terminal
- Base parent directory was created again
- File was Restored to parent directory



**Actual Result:** Everything was Restored/Created Successfully
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/RestoreFileToNonExistingParentDirectory.png)




### Test Case 9: List Empty Recycle Bin

**Objective:** Verify that recycle_bin doesn't list files that weren't deleted (Empty Recycle Bin)

**Steps:**

1. Run: `./recycle_bin.sh list`
2. See the Messaged Printed on Terminal "Empty RecycleBin"


**Expected Result:**
-Empty Recycle Bin Printed


**Actual Result:** Everything was printed to the terminal Successfully
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/ListEmptyRecycleBin.png)




### Test Case 10: List Recycle bin with Items

**Objective:** Verify that recycle_bin lists the files in the folder

**Steps:**

1. Run: `./recycle_bin.sh list (optional --detailed)`
2. See the files table printed on the terminal

**Expected Result:**
- Sucess Files printed in the terminal

**Actual Result:** Everything was Listed Successfully
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/ListFilesTerminal.png)




### Test Case 11: Preview File 

**Objective:** Verify that the file can be previewed in the terminal

**Steps:**

1. Run: `./recycle_bin.sh preview <FileID>`
2. See the file info printed in the terminal

**Expected Result:**
- Sucess the pretended info printed in the terminal

**Actual Result:** Everything was printed / previewed Successfully
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/PreviewFileTerminal.png)



### Test Case 11: Missing Arguments (in All of Commands)

**Objective:** Verify that Commands have the error handling 

**Steps:**

Ex:
1. Run: `./recycle_bin.sh preview`
2. See the edge cased message handled in the terminal

**Expected Result:**
- Command Help printed in the terminal

**Actual Result:** [Command Message Was Printed in the terminal]
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/MissingArgumentsInCommands.png)


### Test Case 12: Delete Files or Directories without permission

**Objective:** Verify that Commands have the error handling 

**Steps:**

Ex:
1. Run: `./recycle_bin.sh delete <FileName> <Directory>`
2. See the edge cased message handled in the terminal
3. Understand the the directory/file was not deleted because of the permissions

**Expected Result:**
- Command Help printed in the terminal

**Actual Result:** [Command Message Was Printed in the terminal]
**Status:** ■ Pass ☐ Fail
**Screenshots:** [See Here](./screenshots/DeleteWithoutPermissions.png)




### For Lack of time we coudn't document all test cases here with screenshots 
### The majority of test cases are documented in the test_suite.sh file with --detailed 
## flag



