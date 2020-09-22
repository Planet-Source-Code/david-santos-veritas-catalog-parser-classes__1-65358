VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "FileHolder"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'---------------------------------------------------------------------------------------
' Module    : FileHolder
' DateTime  : 5/11/2006 10:04
' Author    : Ender
' Purpose   : Veritas Catalog .FH parser
'---------------------------------------------------------------------------------------
Option Explicit

'================================================================================
'                                     Things To Do
'================================================================================
' - Implement a GetFileInfo that will link the indexed file to
'   the corresponding info
' - Hanlde possible negative values?

Const MODULE_NAME = "Veritas.FileHolder"
Const MODULE_DESCRIPTION = "Object for parsing and storing file information from the FH file of a Veritas catalog"
Const MODULE_VERSION = "0.1"

'================================================================================
'                                     API Declaration
'================================================================================
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal length As Long)
Private Declare Function GetTickCount Lib "kernel32" () As Long

'================================================================================
'                                     Events
'================================================================================
Public Event Progress(ByVal section As String, ByVal Current As Long, ByVal total As Long, ByRef Cancel As Long)
Public Event Error(ByVal section As String, ByVal reason As String)

'================================================================================
'                                     UDTs
'================================================================================
Private Type INFO_ENTRY
    SetDate As Date
    Attribute1 As Long
    Attribute2 As Long
End Type

Private Type FILE_ENTRY
    FileSize As Long
    FileName As String
    FileNo As Long
    ParentFolder As Long
    FullPath As String
    Child As Long
    Next As Long
    Last As Long
End Type

'================================================================================
'                                     Local Variables
'================================================================================
Dim sSection As String
Dim mDirs() As FILE_ENTRY
Dim mFiles() As FILE_ENTRY
Dim mInfo() As INFO_ENTRY

Dim mDirCount As Long
Dim mFileCount As Long
Dim mInfoCount As Long
Dim mTotalBytes As Double

Dim mTotalBytesL As Long
Dim mTotalBytesH As Long

Dim lCancel As Long

Dim dirEntryStartL As Long
Dim fileEntryStartL As Long
Dim infoEntryStartL As Long

Dim dirEntryStartH As Long
Dim fileEntryStartH As Long
Dim infoEntryStartH As Long

Dim dirEntryLength As Long
Dim fileEntryLength As Long
Dim infoEntryLength As Long

' Used by Stack
Dim sStack() As Long
Dim lStackPtr As Long
Dim lStackDepth As Long

Dim lProgressGranularity As Long

Private Function MakeDate(ByVal UpperWord As Long, ByVal LowerWord As Long) As Date
Dim eMonths As Long
Dim eDays As Long
Dim eYears As Long
Dim eHours As Long
Dim eMins As Long
Dim eSecs As Long
    
    If UpperWord < 0 Then
        UpperWord = UpperWord + &H10000
    End If
    
    eDays = UpperWord Mod &H20
    UpperWord = UpperWord \ &H20
    eMonths = UpperWord Mod &H10
    UpperWord = UpperWord \ &H10
    eYears = UpperWord + 1980
    
    If LowerWord < 0 Then
        LowerWord = LowerWord + &H10000
    End If
    
    eSecs = (LowerWord Mod &H20) * 2
    LowerWord = LowerWord \ &H20
    eMins = LowerWord Mod &H40
    LowerWord = LowerWord \ &H40
    eHours = LowerWord
    
    MakeDate = CDate(eMonths & "/" & eDays & "/" & eYears & " " & eHours & ":" & eMins & ":" & eSecs)

End Function

' Read File & Directory attributes
Private Sub ReadInfo(filemap As clsFileMapping)
Dim bufsize As Long
Dim endptr As Long
Dim maxFiles As Long
Dim lTemp As Long
Dim upperDate As Long
Dim lowerDate As Long
Dim LastUpdate As Long
Dim i As Long

    If lCancel = 1 Then Exit Sub

    maxFiles = mFileCount + mDirCount
    
    sSection = "CAT_INFO_READ"
    
    ReDim Preserve mInfo(maxFiles)
    i = 0
    
    If filemap.OpenViewEx(FileMapRead, infoEntryStartH, infoEntryStartL, infoEntryLength) Then
        endptr = filemap.GetFilePointer + bufsize
        
        Do While filemap.GetFilePointer < endptr
            With mInfo(i)
                'unknown
                Call filemap.ReadData(DefineDoubleWord)
                'unknown
                Call filemap.ReadData(DefineDoubleWord)
                
                'Date & Time
                upperDate = filemap.ReadData(DefineWord)
                lowerDate = filemap.ReadData(DefineWord)
                
                .SetDate = MakeDate(upperDate, lowerDate)
                
                .Attribute1 = filemap.ReadData(DefineDoubleWord)
                .Attribute2 = filemap.ReadData(DefineDoubleWord)
            End With
            
            i = i + 1
            If i > maxFiles Then
                maxFiles = maxFiles * 2
                ReDim Preserve mInfo(maxFiles)
            End If
        
            If GetTickCount - LastUpdate >= lProgressGranularity Then
                RaiseEvent Progress(sSection, i, maxFiles, lCancel)
                LastUpdate = GetTickCount
            End If
        
        Loop
        
        filemap.CloseView
    
    End If
    
    If i > 0 And i <> maxFiles Then
    ReDim Preserve mInfo(i - 1)
    End If
End Sub

Private Sub ReadDir(filemap As clsFileMapping)
Dim i As Long
Dim mHeader As Long
Dim mRecSize As Long
Dim mUnknown1 As Long
Dim mFileNo As Long
Dim mUnknown3 As Long
Dim mLevel As Long
Dim mDirName As String
Dim lastLevel As Long
Dim bufsize As Long
Dim endptr As Long
Dim maxDirs As Long
Dim lastPos As Long

       
    If lCancel = 1 Then Exit Sub
       
    ' normally this should be the case:
    lastLevel = -1
    maxDirs = mDirCount
    
    ' skip root folder which is always(?) blank
    ' lastLevel = 0
    ' mDirCount = mDirCount - 1
    ' maxDirs = mDirCount - 1
    
    lStackDepth = 100
    lStackPtr = 0
    ReDim sStack(lStackDepth)
    
    If filemap.OpenViewEx(FileMapRead, dirEntryStartH, dirEntryStartL, dirEntryLength) Then
        endptr = filemap.GetFilePointer + dirEntryLength
        
        sStack(lStackPtr) = -1
        lStackPtr = lStackPtr + 1
        
        ReDim mDirs(maxDirs)
        
        lCancel = 0
        
        Do While filemap.GetFilePointer < endptr
            lastPos = filemap.GetFilePointer
            mHeader = filemap.ReadData(DefineWord)
            mRecSize = filemap.ReadData(DefineWord)
            mUnknown1 = filemap.ReadData(DefineDoubleWord)
            mFileNo = filemap.ReadData(DefineDoubleWord)
            mUnknown3 = filemap.ReadData(DefineDoubleWord)
            mLevel = filemap.ReadData(DefineWord)
            mDirName = filemap.ReadString(mRecSize - &H12)
            
            filemap.SetFilePointer lastPos + mRecSize, SetReplaceCurrent
                
            If mLevel > lastLevel Then
                sStack(lStackPtr) = i - 1
                lStackPtr = lStackPtr + 1
            End If
            
            If mLevel < lastLevel Then
                Do While lastLevel > mLevel
                    lStackPtr = lStackPtr - 1
                    lastLevel = lastLevel - 1
                Loop
            End If
                        
            With mDirs(i)
                .FileNo = mFileNo
                .FileName = mDirName
                .ParentFolder = sStack(lStackPtr - 1)
                .Last = -1
                .Child = -1
            End With
            
            lastLevel = mLevel
            i = i + 1
            
            'RaiseEvent Progress(FHP_READDIR, CLng((i / maxDirs) * 100), lCancel)
                    
            If lCancel = 1 Then Exit Do
                    
        Loop
        
        filemap.CloseView
        
    End If

    Erase sStack

End Sub

Private Sub ReadFile(filemap As clsFileMapping)
Dim mHeader As Long
Dim mRecSize As Long
Dim mUnknown1 As Long
Dim mFileNo As Long
Dim mFileSize As Long
Dim headnode As Long
Dim i As Long
Dim mFileName As String
Dim bufsize As Long
Dim LastUpdate As Long
Dim maxFiles As Long
Dim lastPos As Long
Dim n As Long

    If lCancel = 1 Then Exit Sub
    
    maxFiles = mFileCount
    ReDim mFiles(maxFiles)
    
    i = 0
    
    headnode = 1
    
    If filemap.OpenViewEx(FileMapRead, fileEntryStartH, fileEntryStartL, fileEntryLength) Then
        sSection = "CAT_FILE_READ"
    
        Do While filemap.GetFilePointer < filemap.GetFileExitPoint
            lastPos = filemap.GetFilePointer
            
            mHeader = filemap.ReadData(DefineWord)
            mRecSize = filemap.ReadData(DefineWord)
            mUnknown1 = filemap.ReadData(DefineDoubleWord)
            mFileNo = filemap.ReadData(DefineDoubleWord)
            
            ' Parent Folder should always be folder with lesser FileNo
            If headnode < mDirCount Then
                Do While mFileNo > mDirs(headnode).FileNo
                    headnode = headnode + 1
                    If headnode >= mDirCount Then Exit Do
                Loop
            End If
            
            '  Not really needed becuase we're getting the filecount from the IMG
            'If i > maxFiles Then
            '    maxFiles = maxFiles * 2
            '    ReDim Preserve mFiles(maxFiles)
            'End If
            
            Select Case mHeader
            Case 1                'small file (1 byte ~ 64k bytes)
                mFileSize = filemap.ReadData(DefineWord)
                mFileName = filemap.ReadString(mRecSize - &HE)
                
            Case 2                'large file (64k bytes ~ 16M bytes)
                mFileSize = filemap.ReadData(DefineDoubleWord)
                mFileName = filemap.ReadString(mRecSize - &H10)
    
            Case 4                'empty file (0 bytes)
                mFileSize = 0
                mFileName = filemap.ReadString(mRecSize - &HC)
                
            Case Else
                filemap.SetFilePointer filemap.GetFileExitPoint, SetReplaceCurrent
                Err.Raise vbObjectError, MODULE_NAME & ".ReadFile", "Unknown header 0x" & Hex(mHeader)
                lCancel = 1
                
            End Select
            
            If lCancel = 0 Then
                mFiles(i).ParentFolder = headnode - 1
                mFiles(i).FileNo = mFileNo
                mFiles(i).FileName = mFileName
                mFiles(i).FileSize = mFileSize
                
                ' The following code was added to help find files belonging to
                ' a certain folder. Instead of searching the entire file array
                ' and comparing each ParentFolder, we can create a sort of linked
                ' list using the Child and Next properties.
                
                ' initialize values
                mFiles(i).Child = -1
                mFiles(i).Last = -1
                mFiles(i).Next = -1
                
                ' Check if parent folder already has a file attached
                If mDirs(mFiles(i).ParentFolder).Child = -1 Then
                    ' this will be the first file in the folder's file list
                    mDirs(mFiles(i).ParentFolder).Child = i
                    mDirs(mFiles(i).ParentFolder).Last = i
                Else
                    ' Attach the file to the end of folder's file list
                    n = mDirs(mFiles(i).ParentFolder).Last
                    mFiles(n).Next = i
                    mDirs(mFiles(i).ParentFolder).Last = i
                End If
                
                filemap.SetFilePointer lastPos + mRecSize, SetReplaceCurrent
            End If
            
            i = i + 1
        
            If GetTickCount - LastUpdate >= lProgressGranularity Then
                RaiseEvent Progress(sSection, i, maxFiles, lCancel)
                LastUpdate = GetTickCount
            End If
            
            If lCancel = 1 Then Exit Do
        
        Loop
    
        mFileCount = i
        If i > 0 Then ReDim Preserve mFiles(i - 1)
    
    End If
    
End Sub

' Wraps ReadDir and ReadFiles
Public Sub OpenFile(FileName As String, Optional bReadInfo As Boolean = False)
Dim tTotalBytes As Double

    lCancel = 0
    
    If Dir(FileName) = "" Then
        Err.Raise vbObjectError, MODULE_NAME & ".OpenFile", "File not found!"
        Exit Sub
    End If
    
    Dim myFMap As New clsFileMapping
    
    If myFMap.OpenFile(FileName) Then
        If myFMap.MapFile("VERITAS_FILEMAP", PageReadOnly) Then
            If myFMap.OpenView(FileMapRead, , , 1024) Then
                 
                myFMap.SeekEx &H78&
                
                infoEntryStartL = myFMap.ReadData(DefineDoubleWord)
                infoEntryStartH = myFMap.ReadData(DefineDoubleWord)
                infoEntryLength = myFMap.ReadData(DefineDoubleWord): Call myFMap.ReadData(DefineDoubleWord)
                
                dirEntryStartL = myFMap.ReadData(DefineDoubleWord)
                dirEntryStartH = myFMap.ReadData(DefineDoubleWord)
                dirEntryLength = myFMap.ReadData(DefineDoubleWord): Call myFMap.ReadData(DefineDoubleWord)
                
                fileEntryStartL = myFMap.ReadData(DefineDoubleWord)
                fileEntryStartH = myFMap.ReadData(DefineDoubleWord)
                fileEntryLength = myFMap.ReadData(DefineDoubleWord): Call myFMap.ReadData(DefineDoubleWord)
                
                mTotalBytesL = myFMap.ReadData(DefineDoubleWord)
                mTotalBytesH = myFMap.ReadData(DefineDoubleWord)
                If mTotalBytesL < 0 Then
                    mTotalBytes = CDbl(mTotalBytesL) + 4294967296#
                Else
                    mTotalBytes = CDbl(mTotalBytesL)
                End If
                mTotalBytes = mTotalBytes + CDbl(mTotalBytesH) * 4294967296#
                
                mDirCount = myFMap.ReadData(DefineDoubleWord): Call myFMap.ReadData(DefineDoubleWord)
                mFileCount = myFMap.ReadData(DefineDoubleWord): Call myFMap.ReadData(DefineDoubleWord)
                
                myFMap.CloseView
            
                If bReadInfo Then
                    sSection = "CAT_INFO_START"
                    RaiseEvent Progress(sSection, 0, 0, lCancel)
                    ReadInfo myFMap
                End If
            
                sSection = "CAT_DIR_START"
                RaiseEvent Progress(sSection, 0, 0, lCancel)
                ReadDir myFMap
                
                sSection = "CAT_FILE_START"
                RaiseEvent Progress(sSection, 0, 0, lCancel)
                ReadFile myFMap
            
            End If
            myFMap.CloseMap
        End If
        myFMap.CloseFile
    End If
    
    If lCancel Then
        'Err.Raise vbObjectError, MODULE_NAME & ".OpenFile", "Action was cancelled"
        RaiseEvent Error("CAT_CANCEL", "Action was cancelled")
        Exit Sub
    End If
    
    RaiseEvent Progress("CAT_COMPLETE", 0, 0, lCancel)
    
    Exit Sub
End Sub

Private Sub BuildDirPath(ByVal Index As Long)
Dim sPath As String
Dim sAddPath As String
Dim i As Long
Dim j As Long
    
    sPath = Space(512)
    j = 512
    
    i = Index
    
    Do While i >= 0
        sAddPath = mDirs(i).FileName & "\"
        Mid$(sPath, j - Len(sAddPath), Len(sAddPath)) = sAddPath
        j = j - Len(sAddPath)
        i = mDirs(i).ParentFolder
    Loop
    mDirs(Index).FullPath = Trim$(sPath)
End Sub

Property Get DirPath(Index) As String
    If mDirs(Index).FullPath = "" Then BuildDirPath Index
    DirPath = mDirs(Index).FullPath
End Property

Property Get DirName(Index) As String
    DirName = mDirs(Index).FileName
End Property

Property Get DirParentID(Index) As Long
    DirParentID = mDirs(Index).ParentFolder
End Property

Property Get DirID(Index) As Long
    DirID = mDirs(Index).FileNo
End Property

Property Get FileName(Index) As String
    FileName = mFiles(Index).FileName
End Property

Property Get FilePath(Index) As String
    If mDirs(mFiles(Index).ParentFolder).FullPath = "" Then BuildDirPath mFiles(Index).ParentFolder
    FilePath = mDirs(mFiles(Index).ParentFolder).FullPath & mFiles(Index).FileName
End Property

Property Get FileParentID(Index) As Long
    FileParentID = mFiles(Index).ParentFolder
End Property

Property Get FileID(Index) As Long
    FileID = mFiles(Index).FileNo
End Property

Property Get FileCount() As Long
    FileCount = mFileCount
End Property

Property Get DirCount() As Long
    DirCount = mDirCount
End Property

Property Get TotalBytes() As Double
    TotalBytes = mTotalBytes
End Property

Private Sub Class_Initialize()
    ' not much change if we lessen the frequency of updates...
    lProgressGranularity = 100
End Sub

Private Sub Class_Terminate()
    ' do we really need to explicitly erase
    ' the arrays here?
    Erase mFiles
    Erase mDirs
End Sub

Public Function GetFolderFiles(Index, Optional Filter As String = "") As Variant
Dim i As Long
Dim aFiles() As String
Dim r As New RegExp
Dim n As Long

    r.Pattern = Filter
    r.IgnoreCase = True
    r.Global = True

    If IsNumeric(Index) Then
        n = mDirs(Index).Child
        Do While n > -1
            If r.Execute(mFiles(n).FileName).Count > 0 Then
                ReDim Preserve aFiles(i)
                aFiles(i) = mFiles(n).FileName
                i = i + 1
            End If
            
            n = mFiles(n).Next
        
        Loop
        
        If i > 0 Then GetFolderFiles = aFiles
        ' should return Empty if no files found
        
    Else
        For i = 0 To UBound(mDirs)
            If mDirs(i).FullPath = Index Then
                GetFolderFiles = GetFolderFiles(i)
                Exit For
            End If
        Next
    End If
End Function

Public Function GetFolderFileCount(Index, Optional Filter As String = "") As Long
Dim i As Long
Dim r As New RegExp
Dim n As Long
Dim matches As Object

    r.Pattern = Filter
    r.IgnoreCase = True
    r.Global = True
    
    If IsNumeric(Index) Then
        n = mDirs(Index).Child
        Do While n > -1
            Set matches = r.Execute(mFiles(n).FileName)
            If matches.Count > 0 Then
                i = i + 1
            End If
            n = mFiles(n).Next
        Loop
        GetFolderFileCount = i
    Else
        For i = 0 To UBound(mDirs)
            If mDirs(i).FullPath = Index Then
                GetFolderFileCount = GetFolderFileCount(i, Filter)
                Exit For
            End If
        Next
    End If
End Function

Public Sub Cancel()
    lCancel = 1
End Sub
