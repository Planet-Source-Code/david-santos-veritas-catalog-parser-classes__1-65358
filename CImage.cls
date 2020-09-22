VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Image"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Const MODULE_NAME = "Veritas.Image"
Const MODULE_DESCRIPTION = "Object for parsing the IMG file of a Veritas catalog"
Const MODULE_VERSION = "0.1"

'Dim mSignature As String * 32
Dim mSignature As String * 32
Dim mMajor As Long
Dim mMinor As Long
Dim mImageCount As Long
'unknown(34) As Byte
Dim mSetNumber As Long
Dim mSetDateTime As Date
Dim mSetType As Long

Dim mSetName As String
Dim mUnknownString As String
Dim mUserName As String
Dim mDeviceName As String
Dim mVolumeName As String
Dim mMachineName As String
Dim mEngineName As String
Dim mFamilyGUID As String

Dim mDirCount As Long
Dim mFileCount As Long
Dim mFilepath As String
Dim mByteCount As Double
Dim mCorrupt As Long
Dim mInUse As Long

Dim mFamilyName As String
Dim mVolumeLabel As String
Dim mGUID As String

Property Get Signature() As String
    Signature = mSignature
End Property

Property Get Major() As Long
    Major = mMajor
End Property

Property Get Minor() As Long
    Minor = mMinor
End Property

Property Get ImageCount() As Long
    ImageCount = mImageCount
End Property

Property Get SetNumber() As Long
    SetNumber = mSetNumber
End Property

Property Get SetDateTime() As Date
    SetDateTime = mSetDateTime
End Property

Property Get SetType() As Long
    SetType = mSetType
End Property

Property Get SetName() As String
    SetName = mSetName
End Property

Property Get UnknownString() As String
    UnknownString = mUnknownString
End Property

Property Get UserName() As String
    UserName = mUserName
End Property

Property Get DeviceName() As String
    DeviceName = mDeviceName
End Property

Property Get VolumeName() As String
    VolumeName = mVolumeName
End Property

Property Get MachineName() As String
    MachineName = mMachineName
End Property

Property Get EngineName() As String
    EngineName = mEngineName
End Property

Property Get FamilyGUID() As String
    FamilyGUID = mFamilyGUID
End Property

Property Get DirCount() As Long
    DirCount = mDirCount
End Property

Property Get FileCount() As Long
    FileCount = mFileCount
End Property

Property Get Filepath() As String
    Filepath = mFilepath
End Property

Property Get ByteCount() As Double
    ByteCount = mByteCount
End Property

Property Get Corrupt() As Long
    Corrupt = mCorrupt
End Property

Property Get InUse() As Long
    InUse = mInUse
End Property

Property Get FamilyName() As String
    FamilyName = mFamilyName
End Property

Property Get VolumeLabel() As String
    VolumeLabel = mVolumeLabel
End Property

Property Get GUID() As String
    GUID = mGUID
End Property

'Dim success As Boolean
Public Function OpenFile(ByVal FileName As String) As Boolean
Dim ptr As Long
Dim lTemp As Long
Dim lStrPtr As Long
Dim hFile As Long

    If Dir(FileName) = "" Then Exit Function

    hFile = FreeFile
    
    Open FileName For Binary As hFile
    Get hFile, , mSignature
    
    If mSignature <> "VERITAS SOFTWARE - CATALOG FILE" & Chr(0) Then
        Close hFile
        Err.Raise vbObjectError + 1, "Veritas.OpenFile", "Error opening " & FileName & ". Header not found"
        Exit Function
    End If
        
    Get hFile, , mMajor
    Get hFile, , mMinor
    Get hFile, , mImageCount
    
    ptr = &H51
    Seek hFile, ptr
    Get hFile, , lStrPtr
    
    lStrPtr = lStrPtr + &H51 - 8
    
    ptr = &H61
    Seek hFile, ptr
    Get hFile, , mSetNumber
    
    ptr = &H65
    Seek hFile, ptr
    Get hFile, , lTemp
    lTemp = lTemp And (&HFFFF&)
    
    Dim eMonths As Integer
    Dim eDays As Integer
    Dim eYears As Integer
    
    eDays = lTemp Mod &H20
    lTemp = lTemp \ &H20
    eMonths = lTemp Mod &H10
    lTemp = lTemp \ &H10
    eYears = lTemp + 1980
    
    ptr = &H67
    Seek hFile, ptr
    Get hFile, , lTemp
    lTemp = lTemp And (&HFFFF&)
    
    Dim eHours As Integer
    Dim eMins As Integer
    Dim eSecs As Integer
    
    eSecs = (lTemp Mod &H20) * 2
    lTemp = lTemp \ &H20
    eMins = lTemp Mod &H40
    lTemp = lTemp \ &H40
    eHours = lTemp
    
    mSetDateTime = CDate(eMonths & "/" & eDays & "/" & eYears & " " & eHours & ":" & eMins & ":" & eSecs)
    
    Get hFile, , mSetType
    
    ptr = &H7D
    Seek hFile, ptr
    Get hFile, , mDirCount
    
    ptr = &H81
    Seek hFile, ptr
    Get hFile, , mFileCount

    ptr = &H89
    Seek hFile, ptr
    Dim templong As Long
    Get hFile, , templong
    
    If templong < 0 Then
        mByteCount = templong + 4294967296#
        Get hFile, , templong
        mByteCount = mByteCount + templong * 4294967296#
    Else
        mByteCount = templong
    End If
    
    
    ptr = lStrPtr
    Seek hFile, ptr
    mSetName = ReadCSTR(hFile)
    mUnknownString = ReadCSTR(hFile)
    mUserName = ReadCSTR(hFile)
    mDeviceName = ReadCSTR(hFile)
    mVolumeName = ReadCSTR(hFile)
    mEngineName = ReadCSTR(hFile)
    mMachineName = ReadCSTR(hFile)
    
    ptr = &H31D
    Seek hFile, ptr
    mFamilyName = ReadCSTR(hFile)
    mVolumeLabel = ReadCSTR(hFile)
    mFilepath = FileName

    ptr = &H2D5
    Seek hFile, ptr
    mGUID = ReadGUID(hFile)
    Close hFile

    OpenFile = True

End Function

Private Function ReadCSTR(handle As Long) As String
Dim tempbyte(256) As Byte
Dim buffer(1) As Byte
Dim sTemp As String

    i = 0
    Get handle, , buffer
    While Not (buffer(0) = 0 And buffer(1) = 0)
        tempbyte(i) = buffer(0)
        tempbyte(i + 1) = buffer(1)
        i = i + 2
        Get handle, , buffer
    Wend
    
    sTemp = StrConv(tempbyte, vbUnicode)
    sTemp = StrConv(sTemp, vbFromUnicode)
    ReadCSTR = Left(sTemp, InStr(1, sTemp, Chr(0)) - 1)
End Function

' Reads a GUID directly from file
Private Function ReadGUID(handle As Long) As String
    Dim buffer(7) As Byte
    
    Get handle, , buffer
    For i = 3 To 0 Step -1
        ReadGUID = ReadGUID & Hex(buffer(i))
    Next
    
    ReadGUID = ReadGUID & "-"
    For i = 5 To 4 Step -1
        ReadGUID = ReadGUID & Hex(buffer(i))
    Next
    
    ReadGUID = ReadGUID & "-"
    For i = 7 To 6 Step -1
        ReadGUID = ReadGUID & Hex(buffer(i))
    Next
    
    ReadGUID = ReadGUID & "-"
    
    Get handle, , buffer
    For i = 0 To 1
        ReadGUID = ReadGUID & Hex(buffer(i))
    Next
    
    ReadGUID = ReadGUID & "-"
    For i = 2 To 7
        ReadGUID = ReadGUID & Hex(buffer(i))
    Next
    
    ReadGUID = "{" & ReadGUID & "}"

End Function
