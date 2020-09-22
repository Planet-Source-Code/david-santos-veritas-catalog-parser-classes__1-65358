==============================
 Veritas Catalog File Parsers
==============================

 NOTE: For an in-depth view into the catalog file format, read the specs.

Intro
------------------
 Here are two VB classes you can use to parse the contents of Veritas .IMG and .FH catalog
 files.
 
 Thanks goes to Chris Vega's clsFileMapping class, the original you can get at 
 
    http://www.freevbcode.com/ShowCode.asp?ID=3370
    
 They require a bit more work but they are fully functional for most requirements.
 
==========================================================================================
  FileHolder Class
==========================================================================================
 File    : CFileHolder.cls
 Name    : FileHolder
 Purpose : Parses the .FH file
 Requires: clsFileMapping.cls (modified)
 
==========================================================================================
  Events  
==========================================================================================
  
   NOTE: You will need do declare an instance of this class WithEvents in order to get these events
         to fire.

   Progress(ByVal section As String, ByVal Current As Long, ByVal total As Long, ByRef Cancel As Long) 
 
     This event will be raised every 100 milliseconds while the class is reading from the the files section.

      "Section" will contain one of the following strings, hopefully self explanatory (if you've read the 
      file format specification). This may be subject to change in the future.
        
        CAT_INFO_START
        CAT_INFO_READ
        CAT_DIR_START
        CAT_DIR_READ
        CAT_FILE_START
        CAT_FILE_READ
        CAT_COMPLETE
        
      "Current" will contain the current count of items processed. This will be zero if the section 
        is not within a pocessing loop, i.e. when beginning a section.
      
      "Total" will contain the total count of items to be processed. This will be zero if the section 
        is not within a processing loop, i.e. when beginning a section.

      "Cancel" should be set to 1 if the user wishes to cancel during processing.
        Note: This parameter may be dropped in favor of the Cancel ethod (see below).

  Error(ByVal section As String, ByVal reason As String) 

      "Section" will contain one of the following strings. This may be subject to change in the future.

        CAT_INFO_READ
        CAT_DIR_READ
        CAT_FILE_READ

      "Reason" will contain a short description of the cause of the error
      
      The Error event can also be used to signal the end of processing. 

==========================================================================================
 Properties  
==========================================================================================

   DirCount 
 
      Returns the total number of folders 

   DirName(Index)

      Returns only the name of a specified folder, not including the full path 

   DirParentID(Index) 

      Returns the FileNo of the specified folder's parent folder  

   DirPath(Index)

      Returns full path of a specified folder

   DirID(Index)

      Returns the FileNo of the specified folder

   FileCount

      Returns the total number of files in the catalog

   FileID(Index)

      Returns the FileNo of the specified file

   FileName(Index) 

      Returns only the name of a specified file, not including the full path 

   FileParentID(Index)

      Returns the FileNo of the specified file's parent folder  

   FilePath(Index)

      Returns full path of a specified file

   TotalBytes

      Returns the total number of bytes used by the files

==========================================================================================
 Methods 
==========================================================================================

   Cancel
   
      Flags the parser to cancel. 
   
   GetFolderFileCount(Index, Filter)

      Returns the number of files in a specified folder matching mathcing the filter. The Index can be an array 
      index based on DirCount or the full path of a folder as returned by DirPath.  The Filter value is a valid 
      regular expression.
   
   GetFolderFiles(Index, Filter)

      Returns an array of files matching the filter in a specified folder of the type Variant. The return value 
      will be Empty if the folder contains no files matching the Filter. The Index can be an array index based 
      on DirCount or the full path of a folder as returned by DirPath.  The Filter value is a valid regular 
      expression.
   
   OpenFile(filename, bReadInfo)

      Parses the specified .FH file. The optional bReadInfo, if set to True, will cause the parser to read the 
      file attribute information. Currently is no way to return file attributes properly. For this reason and 
      the fact that parsing the attributes takes more time, added with the view that file attributes are not
      absolutely important, bReadInfo defaults to False.


==========================================================================================
  Image Class
==========================================================================================
 File    : CImage.cls
 Name    : Image
 Purpose : Parses the .IMG file

==========================================================================================
 Properties  
==========================================================================================

   ByteCount
   Corrupt
   DeviceName 
   DirCount 
   EngineName 
   FamilyGUID 
   FamilyName 
   FileCount 
   FilePath 
   GUID 
   ImageCount 
   InUse 
   MachineName 
   Major 
   Minor 
   SetDateTime 
   SetName 
   SetNumber 
   SetType 
   Signature 
   UnknownString 
   UserName 
   VolumeLabel 
   VolumeName 

==========================================================================================
 Methods
==========================================================================================

   OpenFile(filename)
  
     parses the specified .IMG file