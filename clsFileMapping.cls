VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsFileMapping"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' =============================================================================
'
' File Mapping Class Module
' Date: July 12, 2001
'
' Created By : Chris Vega [gwapo@models.com]
'
' =============================================================================

' Ender: Added some helper functions
'        Added #If False Then ... Const.. #End If declarations
'         So that corresponding Enum letter case doesn't change if you mistype it
          
Option Explicit

' =============================================================================
' API Declarations
' =============================================================================
Private Declare Sub GetSystemInfo Lib "kernel32" (lpSystemInfo As SYSTEM_INFO)

Private Type SYSTEM_INFO
        dwOemID As Long
        dwPageSize As Long
        lpMinimumApplicationAddress As Long
        lpMaximumApplicationAddress As Long
        dwActiveProcessorMask As Long
        dwNumberOrfProcessors As Long
        dwProcessorType As Long
        dwAllocationGranularity As Long
        dwReserved As Long
End Type


Private Declare Function GetFileSize _
                         Lib "kernel32" _
                         (ByVal hFile As Long, _
                          lpFileSizeHigh As Long) As Long

Private Declare Function CreateFile _
                         Lib "kernel32" Alias _
                         "CreateFileA" _
                         (ByVal lpFileName As String, _
                          ByVal dwDesiredAccess As Long, _
                          ByVal dwShareMode As Long, _
                          lpSecurityAttributes As SecurityAttributes, _
                          ByVal dwCreationDisposition As Long, _
                          ByVal dwFlagsAndAttributes As Long, _
                          ByVal hTemplateFile As Long) As Long

Private Declare Function CreateFileMapping _
                         Lib "kernel32" Alias _
                         "CreateFileMappingA" _
                         (ByVal hFile As Long, _
                          lpFileMappigAttributes As SecurityAttributes, _
                          ByVal flProtect As Long, _
                          ByVal dwMaximumSizeHigh As Long, _
                          ByVal dwMaximumSizeLow As Long, _
                          ByVal lpName As String) As Long

Private Declare Function OpenFileMapping _
                         Lib "kernel32" Alias _
                         "OpenFileMappingA" _
                         (ByVal dwDesiredAccess As Long, _
                          ByVal bInheritHandle As Long, _
                          ByVal lpName As String) As Long

Private Declare Function MapViewOfFileEx _
                         Lib "kernel32" _
                         (ByVal hFileMappingObject As Long, _
                          ByVal dwDesiredAccess As Long, _
                          ByVal dwFileOffsetHigh As Long, _
                          ByVal dwFileOffsetLow As Long, _
                          ByVal dwNumberOfBytesToMap As Long, _
                          lpBaseMemPointer As Any) As Long

Private Declare Function MapViewOfFile _
                         Lib "kernel32" _
                         (ByVal hFileMappingObject As Long, _
                          ByVal dwDesiredAccess As Long, _
                          ByVal dwFileOffsetHigh As Long, _
                          ByVal dwFileOffsetLow As Long, _
                          ByVal dwNumberOfBytesToMap As Long) As Long

Private Declare Function UnmapViewOfFile _
                         Lib "kernel32" _
                         (lpBaseMemPointer As Any) As Long

Private Declare Function FlushViewOfFile _
                         Lib "kernel32" _
                         (lpBaseAddress As Any, _
                          ByVal dwNumberOfBytesToFlush As Long) As Long

Private Declare Function CloseHandle _
                         Lib "kernel32" _
                         (ByVal hObject As Long) As Long

Private Declare Sub CopyMemory _
                    Lib "kernel32" Alias _
                    "RtlMoveMemory" _
                    (Destination As Any, _
                     Source As Any, _
                     ByVal length As Long)

' =============================================================================
' Security Attributes
' =============================================================================
Private Type SecurityAttributes
        nLength As Long                     ' Size In Bytes
        lpSecurityDescriptor As Long        ' Pointer to Security Descriptor
        bInheritHandle As Long              ' Specifies whether the returned
End Type                                    ' handle is inherited when a new
                                            ' process is created.

' =============================================================================
' Handle Constant
' =============================================================================
Private Const InvalidHandle = -1            ' Bad Handle Value
Private Const ClosedHandle = 0              ' Closed Hanlde Value

' =============================================================================
' Data Sizes
' =============================================================================
Public Enum e_BinaryData
    DefineByte = 1                          '  8 Bits Data
    DefineWord = 2                          ' 16 Bits Data
    DefineDoubleWord = 4                    ' 32 Bits Data
    DefineQuadWord = 8                      ' 64 Bits Data
End Enum

#If False Then
    Const DefineByte = 1                          '  8 Bits Data
    Const DefineWord = 2                          ' 16 Bits Data
    Const DefineDoubleWord = 4                    ' 32 Bits Data
    Const DefineQuadWord = 8                      ' 64 Bits Data
#End If

' =============================================================================
' Pointer Direction
' =============================================================================
Public Enum e_PointerDirection
    MoveDirectionForward = 1                ' Forward Direction (Default)
    MoveDirectionBackward = 2               ' Backward Direction
    MoveDirectionNothing = 4                ' No Action (Move Procedures)
End Enum

#If False Then
    Const MoveDirectionForward = 1                ' Forward Direction (Default)
    Const MoveDirectionBackward = 2               ' Backward Direction
    Const MoveDirectionNothing = 4                ' No Action (Move Procedures)
#End If


' =============================================================================
' Boundary Types
' =============================================================================
Public Enum e_BoundaryPointer
    EntryPointBoundary = 1                  ' Entry Point Boundary
    ExitPointBoundary = 2                   ' Exit Point Boundary
End Enum

#If False Then
    Const EntryPointBoundary = 1                  ' Entry Point Boundary
    Const ExitPointBoundary = 2                   ' Exit Point Boundary
#End If

' =============================================================================
' Access Rights
' =============================================================================
Public Enum e_AccessRights
    FileRead = &H80000000                   ' Read Access
    FileWrite = &H40000000                  ' Write Access
    FileReadWrite = &HC0000000              ' Read and Write Access
    FileExecute = &H20000000                ' Execute Access
    FileAllAccess = &H10000000              ' All Access Rights
End Enum

#If False Then
    Const FileRead = &H80000000                   ' Read Access
    Const FileWrite = &H40000000                  ' Write Access
    Const FileReadWrite = &HC0000000              ' Read and Write Access
    Const FileExecute = &H20000000                ' Execute Access
    Const FileAllAccess = &H10000000              ' All Access Rights
#End If

' =============================================================================
' Share Mode
' =============================================================================
Public Enum e_ShareMode
    FileShareNone = &H0                     ' No Sharing
    FileShareRead = &H1                     ' Share Read of File
    FileShareWrite = &H2                    ' Share Write of File
    FileShareReadWrite = &H3                ' Share Read/Write of File
End Enum

#If False Then
    Const FileShareNone = &H0                     ' No Sharing
    Const FileShareRead = &H1                     ' Share Read of File
    Const FileShareWrite = &H2                    ' Share Write of File
    Const FileShareReadWrite = &H3                ' Share Read/Write of File
#End If

' =============================================================================
' Creation Distribution
' =============================================================================
Public Enum e_CreationDistribution
    FileCreateNew = &H1                     ' Create New (No Overwriting)
    FileCreateAlways = &H2                  ' Create New (Overwrite Existing)
    FileOpenExisting = &H3                  ' Open Existing
    FileOpenAlways = &H4                    ' Open Existing (Create New if not found)
    FileTruncateExisting = &H5              ' Append Existing
End Enum

#If False Then
    Const FileCreateNew = &H1                     ' Create New (No Overwriting)
    Const FileCreateAlways = &H2                  ' Create New (Overwrite Existing)
    Const FileOpenExisting = &H3                  ' Open Existing
    Const FileOpenAlways = &H4                    ' Open Existing (Create New if not found)
    Const FileTruncateExisting = &H5              ' Append Existing
#End If

' =============================================================================
' File Attributes
' =============================================================================
Public Enum e_FlagsAndAttributes
    FileAttributeReadOnly = &H1             ' Read-Only
    FileAttributeHidden = &H2               ' Hidden
    FileAttributeSystem = &H4               ' System
    FileAttributeDirectory = &H10           ' Directory
    FileAttributeArchive = &H20             ' Archive
    FileAttributeNormal = &H80              ' Normal
    FileAttributeTemporary = &H100          ' Temporary
    FileAttributeCompressed = &H800         ' Compressed
    FileAttributeAll = &H9B7                ' All Attributes
End Enum

#If False Then
    Const FileAttributeReadOnly = &H1             ' Read-Only
    Const FileAttributeHidden = &H2               ' Hidden
    Const FileAttributeSystem = &H4               ' System
    Const FileAttributeDirectory = &H10           ' Directory
    Const FileAttributeArchive = &H20             ' Archive
    Const FileAttributeNormal = &H80              ' Normal
    Const FileAttributeTemporary = &H100          ' Temporary
    Const FileAttributeCompressed = &H800         ' Compressed
    Const FileAttributeAll = &H9B7                ' All Attributes
#End If

' =============================================================================
' Page Protections
' =============================================================================
Public Enum e_Protection
    PageNoAccess = &H1                      ' No Access
    PageReadOnly = &H2                      ' Read Access
    PageReadWrite = &H4                     ' Read and Write Access
    PageWrite = &H8                         ' Write Access
    PageExecute = &H10                      ' Execute Access
    PageExecuteRead = &H20                  ' Execute and Read Access
    PageExecuteReadWrite = &H40             ' Execute, Read and Write Access
    PageExecuteWrite = &H80                 ' Execute and Write Access
    PageGuard = &H100                       ' Guarded
    PageNoCache = &H200                     ' No Cache
End Enum

#If False Then
    Const PageNoAccess = &H1                      ' No Access
    Const PageReadOnly = &H2                      ' Read Access
    Const PageReadWrite = &H4                     ' Read and Write Access
    Const PageWrite = &H8                         ' Write Access
    Const PageExecute = &H10                      ' Execute Access
    Const PageExecuteRead = &H20                  ' Execute and Read Access
    Const PageExecuteReadWrite = &H40             ' Execute, Read and Write Access
    Const PageExecuteWrite = &H80                 ' Execute and Write Access
    Const PageGuard = &H100                       ' Guarded
    Const PageNoCache = &H200                     ' No Cache
#End If

' =============================================================================
' Desired Access
' =============================================================================
Public Enum e_DesiredAccess
    FileMapCopy = &H1                       ' Copy On Write Access
    FileMapQuery = &H1                      ' Query On Write Access
    FileMapWrite = &H2                      ' Write Access
    FileMapRead = &H4                       ' Read Access
    FileMapReadWrite = &H6                  ' Read and Write Access
    FileMapExtendedReadWrite = &H7          ' Extended Read and Write Access
    FileMapAll = &HF001F                    ' All Access
End Enum

#If False Then
    Const FileMapCopy = &H1                       ' Copy On Write Access
    Const FileMapQuery = &H1                      ' Query On Write Access
    Const FileMapWrite = &H2                      ' Write Access
    Const FileMapRead = &H4                       ' Read Access
    Const FileMapReadWrite = &H6                  ' Read and Write Access
    Const FileMapExtendedReadWrite = &H7          ' Extended Read and Write Access
    Const FileMapAll = &HF001F                    ' All Access
#End If

' =============================================================================
' Set File Pointer Value
' =============================================================================
Public Enum e_SetFilePointer
    SetReplaceCurrent = &H0                 ' Set the Current File Pointer
    SetIncreaseFromCurrent = &H1            ' Increase the Current Pointer
    SetDecresseFromCurrent = &H2            ' Decrease the Current Pointer
End Enum

#If False Then
    Const SetReplaceCurrent = &H0                 ' Set the Current File Pointer
    Const SetIncreaseFromCurrent = &H1            ' Increase the Current Pointer
    Const SetDecresseFromCurrent = &H2            ' Decrease the Current Pointer
#End If


' =============================================================================
' Handles and Security Attributes Variables
' =============================================================================
Private xSec As SecurityAttributes          ' Security Attribute Structure
Private hFile As Long                       ' File Handle
Private hMapFile As Long                    ' Mapping Handle
Private hMapView As Long                    ' Entry Point Handle

' =============================================================================
' Direction Variable
' =============================================================================
Private drPointerDirection As _
        e_PointerDirection                  ' Pointer Movement Direction

' =============================================================================
' File Size Variable Variable
' =============================================================================
Private apFileSize As Long                  ' File Size
Private apFileName As String                ' File Name

' =============================================================================
' File Pointer Variable
' =============================================================================
Private apMapPointer As Long                ' Moving Map Pointer

' =============================================================================
' Boundary Variables
' =============================================================================
Private apEntryPoint As Long                ' Beginning of Mapping
Private apExitPoint As Long                 ' End of Mapping
Private apEntryAccess As Boolean            ' Beyond Entry Point Access
Private apExitAccess As Boolean             ' Beyond Exit Point Access
Private apBOM As Boolean                    ' Beginning of Mapping Reached
Private apEOM As Boolean                    ' End of Mapping Reached

' =============================================================================
' Other Variables
' =============================================================================
Private mapObjectName As String             ' Name of Mapping Object
Private mapCreated As Boolean               ' New Mapping has been created
Private dwAllocationGranularity As Long

' =============================================================================
' Open the File using the currently default Access Rights
'
' Input :
'
'       Filename                -   Full Path for the File to Open or Create
'       ofDesiredAccess         -   Access Rights (Read/Execute/Write)
'       ofShareMode             -   File Sharing for Other Application
'       ofCreationDisposition   -   How to Open/Create a File
'       ofFlagsAndAttributes    -   File Attributes
'
' Output :
'
'       True                    -   File has been Succesfully Opened/Created
'                                   Using the desired options
'       False                   -   Failed on Creation/Opening File
'
' =============================================================================
Public Function OpenFile(ofFilename As String, _
                         Optional ofAccessRights As _
                                  e_AccessRights = FileRead, _
                         Optional ofShareMode As _
                                  e_ShareMode = FileShareRead, _
                         Optional ofCreationDisposition As _
                                  e_CreationDistribution = FileOpenExisting, _
                         Optional ofFlagsAndAttributes As _
                                  e_FlagsAndAttributes = FileAttributeNormal) _
                                  As Boolean
        
    apFileName = ofFilename
    
    hFile = CreateFile(ofFilename, _
                       ofAccessRights, _
                       ofShareMode, _
                       xSec, _
                       ofCreationDisposition, _
                       ofFlagsAndAttributes, _
                       0)

    If hFile = InvalidHandle Then
        OpenFile = False
    Else
        OpenFile = True
        apFileSize = GetFileSize(hFile, 0)
    End If
End Function

' =============================================================================
' Create the Mapping Object.
'
' Input :
'
'   mfMapName                   -   Name for this Mapping Object, To
'                                   Multiple Views, Use Named Mapping and
'                                   call OpenMap Method using the same Name
'   mfProtection                -   Page Protection
'
' Output :
'
'   True                        -   Mapping Object has been succesfully Created
'   False                       -   Failed to Create Mapping Object
' =============================================================================
Public Function MapFile(Optional mfMapName As String, _
                        Optional mfProtection As _
                                 e_Protection = PageReadOnly) As Boolean

    If hFile = InvalidHandle Then
        MapFile = False
    Else
        If hMapFile = ClosedHandle Then
            Dim mfMapObjName
            If IsMissing(mfMapName) Or _
               Trim(mfMapName) & "?" = "?" Then _
                mfMapObjName = 0 _
            Else _
                mfMapObjName = mfMapName
                
            hMapFile = CreateFileMapping(hFile, _
                                         xSec, _
                                         mfProtection, _
                                         0, _
                                         0, _
                                         mfMapObjName)

            If hMapFile = ClosedHandle Then
                MapFile = False
            Else
                MapFile = True
                mapCreated = True
                If mfMapObjName <> 0 Then _
                    mapObjectName = mfMapObjName _
                Else _
                    mapObjectName = ""
            End If
        End If
    End If
End Function

' =============================================================================
' Opens the Previously Created Mapping Object.
'
' Input :
'
'   omMappingObjectName         -   Name of Previouly Created Mapping Object
'   omDesiredAccess             -   Desired Access, must not conflict with the
'                                   Map Object Creations
'   omInheritHandle             -   Specifies whether the returned handle is to
'                                   be inherited by a new process during process
'                                   creation
' Output :
'
'   True                        -   Mapping Object has been succesfully Opened
'   False                       -   Failed to Open the Mapping Object
' =============================================================================
Public Function OpenMap(omMappingObjectName As String, _
                        Optional omDesiredAccess As e_DesiredAccess = FileMapRead, _
                        Optional omInheritHandle As Boolean = False) As Boolean

    If hMapFile = ClosedHandle Then
        hMapFile = OpenFileMapping(omDesiredAccess, _
                                   omInheritHandle, _
                                   omMappingObjectName)
        If hMapFile = ClosedHandle Then
            OpenMap = False
        Else
            OpenMap = True
            mapCreated = False
        End If
    Else
        OpenMap = False
    End If
End Function

' =============================================================================
' Open the View for the Mapping Object
'
' Input :
'   ovDesiredAccess             -   How to Map the File (Access Rights)
'   ovFileOffsetHigh            -   High Order for File Offset
'   ovFileOffsetLow             -   Low Order for File Offset
'   ovNumberOfBytesToMap        -   Number of Bytes to Map ( 0 = Entire File )
'
' Output :
'
'   True                        -   View has been succefully Opened
'   False                       -   Failed to Open a View
'
' =============================================================================

Public Function OpenView(Optional ovDesiredAccess As e_DesiredAccess = FileMapRead, _
                         Optional ovFileOffsetHigh As Long = 0, _
                         Optional ovFileOffsetLow As Long = 0, _
                         Optional ovNumberOfBytesToView As Long = 0) As Boolean
                         
        If hMapView = ClosedHandle Then
            hMapView = MapViewOfFile(hMapFile, _
                                     ovDesiredAccess, _
                                     ovFileOffsetHigh, _
                                     ovFileOffsetLow, _
                                     ovNumberOfBytesToView)
                                         
            If hMapView = 0 Then
                OpenView = False
            Else
                OpenView = True
                apEntryPoint = hMapView
                apMapPointer = hMapView
                apBOM = True
                apEOM = False
                        
                If ovNumberOfBytesToView = 0 Then _
                    apExitPoint = apEntryPoint + apFileSize _
                Else _
                    apExitPoint = apEntryPoint + ovNumberOfBytesToView
            End If
        Else
            OpenView = False
        End If
End Function

' =============================================================================
' Retrieve Mapping Name
'
' Output :
'
'   Name of the Named Mapping Object, if the Mapping has been created with Name
'   Otherwise returns blank string (NULL)
' =============================================================================
Public Function GetMappingName() As String
    GetMappingName = mapObjectName
End Function

' =============================================================================
' Retrieve File Handle
'
' Output :
'
'   Returns the File Handle if File is Open, Otherwise will return Invalid
'   Handle Value (-1)
' =============================================================================
Public Function GetFileHandle() As Long
    GetFileHandle = hFile
End Function

' =============================================================================
' Retrieve Mapping Handle
'
' Output :
'
'   Returns the Mapping Object Handle or NULL if no Mapping Object is present
' =============================================================================
Public Function GetMappingHandle() As Long
    GetMappingHandle = hMapFile
End Function

' =============================================================================
' Retrieve MappingView Handle
'
' Output :
'
'   Returns the Mapping View Handle or NULL if no Mapping View is present
' =============================================================================
Public Function GetMappingViewHandle() As Long
    GetMappingViewHandle = hMapView
End Function

' =============================================================================
' Retrieve File Pointer
'
' Output :
'
'   Returns the File Pointer or NULL if View is not Open
' =============================================================================
Public Function GetFilePointer() As Long
    GetFilePointer = apMapPointer
End Function

' =============================================================================
' Retrieve Entry Point
'
' Output :
'
'   Returns the Mapping View Entry Point
' =============================================================================
Public Function GetFileEntryPoint() As Long
    GetFileEntryPoint = apEntryPoint
End Function

' =============================================================================
' Retrieve Exit Point
'
' Output :
'
'   Returns the Mapping View Exit Point
' =============================================================================
Public Function GetFileExitPoint() As Long
    GetFileExitPoint = apExitPoint
End Function

' =============================================================================
' Close the View of this Mapping
'
' Input :
'
'   FlushMapBackToFile              -   True = Save the Map to Disk
'                                       False = Do NOT Save
'   NumberOfBytesToSave             -   Number Of Bytes To Save, Starting From
'                                       the Entry Point
' =============================================================================
Public Sub CloseView(Optional FlushMapBackToFile As Boolean = False, _
                     Optional NumberOfBytesToSave As Long = 0)
    If FlushMapBackToFile Then FlushViewOfFile hMapView, NumberOfBytesToSave
    UnmapViewOfFile hMapView
    hMapView = ClosedHandle
End Sub

' =============================================================================
' Close the Mapping Object (Must not be in used!)
' =============================================================================
Public Sub CloseMap()
    CloseHandle hMapFile
    hMapFile = ClosedHandle
    apExitPoint = ClosedHandle
    apEntryPoint = ClosedHandle
End Sub

' =============================================================================
' Invoke a CloseHandle Function to Terminate
' Refference of File within our Thread, All Mapping Objects
' will also be closed
' =============================================================================
Public Sub CloseFile()
    CloseHandle hFile
    hFile = InvalidHandle
    apFileSize = ClosedHandle
End Sub

' =============================================================================
' Allows Direct Reading from Memory Pointed by MemPointer
' with definition of bytes used as in Asm (DB, DW, DD, DX)
'
' Must have Reading Priviledge on the Page to Read Data
'
' NOTE: This function cannot be used outside for Safety-Purpose of Illegal
'       Usage that will cause an Exception to your Application
' =============================================================================
Private Function ReadMem(ByVal MemPointer As Long, _
                         SizeInBytes As e_BinaryData)
    Select Case SizeInBytes
        Case DefineByte
            Dim DB As Byte
            CopyMemory DB, ByVal MemPointer, 1
            ReadMem = DB
        Case DefineWord
            Dim DW As Integer
            CopyMemory DW, ByVal MemPointer, 2
            ReadMem = DW
        Case DefineDoubleWord
            Dim DD As Long
            CopyMemory DD, ByVal MemPointer, 4
            ReadMem = DD
        Case DefineQuadWord
            Dim DX As Double
            CopyMemory DX, ByVal MemPointer, 8
            ReadMem = DX
    End Select

End Function

' =============================================================================
' Allows Direct Writing to Memory Pointed by MemPointer
' with definition of bytes used as in Asm (DB, DW, DD, DX)
'
' Must have Writing Priviledge on the Page to Write Data
'
' NOTE: This function cannot be used outside for Safety-Purpose of Illegal
'       Usage that will cause an Exception to your Application
' =============================================================================
Private Sub WriteMem(ByVal MemPointer As Long, _
                     SizeInBytes As e_BinaryData, _
                     ByVal DataToWrite)
    CopyMemory ByVal MemPointer, VarPtr(DataToWrite), SizeInBytes
End Sub

' =============================================================================
' Beginning Of Mapping Property (Read-Only)
' =============================================================================
Public Property Get BOM() As Boolean
    BOM = apBOM
End Property

' =============================================================================
' End Of Mapping Property (Read-Only)
' =============================================================================
Public Property Get EOM() As Boolean
    EOM = apEOM
End Property

' =============================================================================
' Set BOM and EOM Values
' =============================================================================
Private Sub setXOM()
    If apMapPointer <= apEntryPoint Then apBOM = True Else apBOM = False
    If apMapPointer >= apExitPoint Then apEOM = True Else apEOM = False
End Sub

' =============================================================================
' Check BOM and EOM According to Direction
' =============================================================================
Private Function IsEndOfLine() As Boolean
    setXOM
    If drPointerDirection <> MoveDirectionNothing Then
        If drPointerDirection = MoveDirectionForward Then
            IsEndOfLine = apEOM
        Else
            If drPointerDirection = MoveDirectionBackward Then _
            IsEndOfLine = apBOM
        End If
    Else
        IsEndOfLine = False
    End If
End Function

' =============================================================================
' Apply Fix for Pointers Beyond Boundary
' =============================================================================
Private Sub FixPointer(ResetBoundary As e_BoundaryPointer)
    If ResetBoundary = EntryPointBoundary Then
        If apBOM Then apMapPointer = apEntryPoint
    Else
        If apEOM Then apMapPointer = apExitPoint
    End If
End Sub

' =============================================================================
' Move File Pointer to MoveDirection One SizeInBytes
' =============================================================================
Public Sub MovePointer(Optional SizeInBytes As e_BinaryData = DefineByte, _
                            Optional MoveDirection As e_PointerDirection)
    
    If IsMissing(MoveDirection) Then MoveDirection = drPointerDirection
    
    If Not MoveDirection = MoveDirectionNothing Then
        If MoveDirection = MoveDirectionBackward Then
            ' Decrement Mapping Pointer
            apMapPointer = apMapPointer - SizeInBytes
            setXOM
            If apBOM And Not apEntryAccess Then FixPointer EntryPointBoundary
        Else
            ' Increment Mapping Pointer
            apMapPointer = apMapPointer + SizeInBytes
            setXOM
            If apEOM And Not apExitAccess Then FixPointer ExitPointBoundary
        End If
    End If
End Sub

' =============================================================================
' Read Single SizeInBytes Data and Move the Pointer
' =============================================================================
Public Function ReadData(Optional SizeInBytes As e_BinaryData = DefineByte)
    ReadData = ReadMem(apMapPointer, SizeInBytes)
    MovePointer SizeInBytes, drPointerDirection
End Function

' =============================================================================
' Write Single SizeInBytes Data and Move the Pointer
' =============================================================================
Public Sub WriteData(ByVal DataToWrite, _
                          Optional SizeInBytes As e_BinaryData = DefineByte)
    WriteMem apMapPointer, SizeInBytes, DataToWrite
    MovePointer SizeInBytes, drPointerDirection
End Sub

' =============================================================================
' Direction Property (Default is Forward)
' =============================================================================
Public Property Let PointerDirection(pdDirection As e_PointerDirection)
    drPointerDirection = pdDirection
End Property

Public Property Get PointerDirection() As e_PointerDirection
    PointerDirection = drPointerDirection
End Property

' =============================================================================
' BEntryAccess Property
'   Beyond Entry Point Access
' =============================================================================
Public Property Let BEntryAccess(bEntry As Boolean)
    apEntryAccess = bEntry
End Property

Public Property Get BEntryAccess() As Boolean
    BEntryAccess = apEntryAccess
End Property

' =============================================================================
' BExitAccess Property
'   Beyond Entry Point Access
' =============================================================================
Public Property Let BExitAccess(bExit As Boolean)
    apExitAccess = bExit
End Property

Public Property Get BExitAccess() As Boolean
    BExitAccess = apExitAccess
End Property

' =============================================================================
' Read Single Byte Data Without Moving the Pointer
'   Same as :
'               object.PointerDirection = MoveDirectionNothing
'               xByte = object.ReadData(DefineByte)
'   ASM :
'               mov     esi, dword ptr [apMapPointer]
'               lodsb
' =============================================================================
Public Function lodsb() As Byte
    lodsb = ReadMem(apMapPointer, DefineByte)
End Function

' =============================================================================
' Write Single Byte Data Without Moving the Pointer
'   Same as :
'               object.PointerDirection = MoveDirectionNothing
'               object.WriteData(xByte, DefineByte)
'   ASM :
'               mov     edi, dword ptr [apMapPointer]
'               mov     al, [DataToLoad]
'               stosb
' =============================================================================
Public Function stosb(ByVal al_ As Byte)
    WriteMem apMapPointer, DefineByte, ByVal al_
End Function

' =============================================================================
' Read Single Word Data Without Moving the Pointer
'   Same as :
'               object.PointerDirection = MoveDirectionNothing
'               xWord = object.ReadData(DefineWord)
'   ASM :
'               mov     esi, dword ptr [apMapPointer]
'               lodsw
' =============================================================================
Public Function lodsw() As Integer
    lodsw = ReadMem(apMapPointer, DefineWord)
End Function

' =============================================================================
' Write Single Word Data Without Moving the Pointer
'   Same as :
'               object.PointerDirection = MoveDirectionNothing
'               object.WriteData(xWord, DefineWord)
'   ASM :
'               mov     edi, dword ptr [apMapPointer]
'               mov     ax, [DataToLoad]
'               stosw
' =============================================================================
Public Function stosw(ByVal ax_ As Integer)
    WriteMem apMapPointer, DefineWord, ByVal ax_
End Function

' =============================================================================
' Read Double Word Data Without Moving the Pointer
'   Same as :
'               object.PointerDirection = MoveDirectionNothing
'               xDWord = object.ReadData(DefineDoubleWord )
'   ASM :
'               mov     esi, dword ptr [apMapPointer]
'               lodsd
' =============================================================================
Public Function lodsd() As Long
    lodsd = ReadMem(apMapPointer, DefineDoubleWord)
End Function

' =============================================================================
' Write Double Word Data Without Moving the Pointer
'   Same as :
'               object.PointerDirection = MoveDirectionNothing
'               object.WriteData(xWord, DefineWord)
'   ASM :
'               mov     edi, dword ptr [apMapPointer]
'               mov     eax, [DataToLoad]
'               stosd
' =============================================================================
Public Function stosd(ByVal eax_ As Long)
    WriteMem apMapPointer, DefineDoubleWord, ByVal eax_
End Function

' =============================================================================
' Read Quad Word Data Without Moving the Pointer
'   Same as :
'               object.PointerDirection = MoveDirectionNothing
'               xDWord = object.ReadData(DefineDoubleWord )
'   ASM :
'               mov     esi, dword ptr [apMapPointer]
'               lodsd
'               xchg    eax, edx
'               lodsd
'               ; QWord is in [edx:eax]
' =============================================================================
Public Function lodsq() As Double
    lodsq = ReadMem(apMapPointer, DefineQuadWord)
End Function

' =============================================================================
' Write Double Word Data Without Moving the Pointer
'   Same as :
'               object.PointerDirection = MoveDirectionNothing
'               object.WriteData(xWord, DefineWord)
'   ASM :
'               mov     edi, dword ptr [apMapPointer]
'               mov     eax, dword ptr [DataToLoad]
'               stosd
'               mov     eax, dword ptr [DataToLoad - 32]
'               stosd
' =============================================================================
Public Function stosq(ByVal edx_eax_ As Double)
    WriteMem apMapPointer, DefineWord, ByVal edx_eax_
End Function

' =============================================================================
' Read Multiple SizeInBytes Data and Move the Pointer
'   CountOfReadDatas will contain the succesful read
' =============================================================================
Public Function ReadStream(CountOfDataToRead As Long, _
                           Optional ByRef CountOfReadDatas As Long, _
                           Optional SizeInBytes As e_BinaryData = DefineByte)
                           
    If CountOfDataToRead < 1 Then
        ReadStream = InvalidHandle
        If Not IsMissing(CountOfReadDatas) Then CountOfReadDatas = 0
        Exit Function
    End If
    
    Dim ReadDatas()
    Dim DataCounter As Long
    
    DataCounter = 0
    
    Do While DataCounter < CountOfDataToRead
        ReDim Preserve ReadDatas(DataCounter)
        ReadDatas(DataCounter) = ReadData(SizeInBytes)
        If IsEndOfLine Then Exit Do
        DataCounter = DataCounter + 1
    Loop
    
    If Not IsMissing(CountOfReadDatas) Then _
       CountOfReadDatas = DataCounter + 1
    
    ReadStream = ReadDatas
End Function

' =============================================================================
' Write Multiple SizeInBytes Data and Move the Pointer
'   CountOfWrittenDatas will contain the succesful read
'
' Input :
'
'   DataStreamArray             -   Must be an Array of Data Stream, Data Set to
'                                   Be Written.
'   CountOfDataToWrite          -   Number of Data to write
'   CountOfWrittenDatas         -   Number of Data has been written
' =============================================================================
Public Sub WriteStream(ByVal DataStreamArray, _
                       ByVal CountOfDataToWrite As Long, _
                       Optional ByRef CountOfWrittenDatas As Long, _
                       Optional SizeInBytes As e_BinaryData = DefineByte)

    If CountOfDataToWrite < 1 Or Not IsArray(DataStreamArray) Then
        If Not IsMissing(CountOfWrittenDatas) Then CountOfWrittenDatas = 0
        Exit Sub
    End If

    Dim DataCounter As Long

    DataCounter = 0
    If CountOfDataToWrite > UBound(DataStreamArray) Then _
       CountOfDataToWrite = UBound(DataStreamArray)
    
    Do While DataCounter < CountOfDataToWrite
        WriteData DataStreamArray(DataCounter), SizeInBytes
        If IsEndOfLine Then Exit Do
        DataCounter = DataCounter + 1
    Loop
    
    If Not IsMissing(CountOfWrittenDatas) Then _
       CountOfWrittenDatas = DataCounter + 1
End Sub

' =============================================================================
' Set File Pointer
'
' Input :
'
'   sfpPointerValue             -   Value to Add, Subtract to Current Pointer or
'                                   Value to Reset the Current Pointer, you must
'                                   set the property BEntryAccess and/or
'                                   BExitAccess to False (Default) to let the
'                                   Sub perform Strict Pointer Movement (ie.
'                                   take care of later Exception Problems)
'   sfpSetAction                -   0 = Replace the Current Pointer
'                                   1 = Increase the Current Pointer
'                                   2 = Decrease the Cureent Pointer
'   SizeInBytes                 -   Length-Steps on Movement, Ignored if
'                                   sfpSetAction = 0
' =============================================================================
Public Sub SetFilePointer(sfpPointerValue As Long, _
                          sfpSetAction As e_SetFilePointer, _
                          Optional SizeInBytes As e_BinaryData = DefineByte)
    Dim MoveCount As Long
    Select Case sfpSetAction
        Case SetReplaceCurrent
            If sfpPointerValue < apEntryPoint Then
                If apEntryAccess Then apMapPointer = sfpPointerValue _
                                 Else apMapPointer = apEntryPoint
            Else
                If sfpPointerValue > apExitPoint Then
                    If apExitAccess Then apMapPointer = sfpPointerValue _
                                    Else apMapPointer = apExitPoint
                Else
                    apMapPointer = sfpPointerValue
                End If
            End If
        Case SetIncreaseFromCurrent
            MoveCount = 0
            Do While Not MoveCount = sfpPointerValue
                MovePointer SizeInBytes, MoveDirectionForward
                If IsEndOfLine Then Exit Do
                MoveCount = MoveCount + 1
            Loop
        Case SetDecresseFromCurrent
            MoveCount = 0
            Do While Not MoveCount = sfpPointerValue
                MovePointer SizeInBytes, MoveDirectionBackward
                If IsEndOfLine Then Exit Do
                MoveCount = MoveCount + 1
            Loop
    End Select
End Sub

' =============================================================================
' Class Initialization
' =============================================================================
Private Sub Class_Initialize()
Dim mySysInfo As SYSTEM_INFO

    ' Initialize Default Values for Globals
    ' =================================================================
    hFile = InvalidHandle
    hMapFile = ClosedHandle
    hMapView = ClosedHandle

    ' Initialize Default Values for Direction and Entry Point
    ' =================================================================
    drPointerDirection = MoveDirectionForward
    apEntryPoint = 0
    apExitPoint = 0
    apMapPointer = 0
    apEntryAccess = False       ' Deny Beyond Entry Point Access
    apExitAccess = False        ' Deny Beyond Exit Point Access
    
    ' added by Ender
    GetSystemInfo mySysInfo
    dwAllocationGranularity = mySysInfo.dwAllocationGranularity
    
End Sub

' =============================================================================
' Class Termination
' =============================================================================
Private Sub Class_Terminate()

    If hMapView <> ClosedHandle Then CloseView
    If hMapFile <> ClosedHandle Then CloseMap
    If hFile <> InvalidHandle Then CloseFile
    
End Sub

' =============================================================================
' Wrapper/Helper Functions
' =============================================================================

' Opens a view using the correct granularity-adjusted offset and view size
' and seeks to the actual location in the view you expect
Public Function OpenViewEx(Optional ovDesiredAccess As e_DesiredAccess = FileMapRead, _
                         Optional ovFileOffsetHigh As Long = 0, _
                         Optional ovFileOffsetLow As Long = 0, _
                         Optional ovNumberOfBytesToView As Long = 0) As Boolean
Dim NewOffset As Double
Dim viewsize As Long
Dim OrigOffset As Double
    
    OrigOffset = CDbl(ovFileOffsetHigh) * 4294967296# + CDbl(ovFileOffsetLow)
    
    NewOffset = (OrigOffset \ dwAllocationGranularity) * dwAllocationGranularity
    viewsize = CLng(OrigOffset Mod dwAllocationGranularity) + ovNumberOfBytesToView
    
    If OpenView(ovDesiredAccess, CLng((NewOffset / 4294967296#) And &HFFFFFFFF), CLng(NewOffset And &HFFFFFFFF), viewsize) Then
        SeekEx CLng(OrigOffset - NewOffset)
        OpenViewEx = True
    End If
    
End Function

' Exposed in case you want to write your own external OpenView handler
' and you need the allocation granularity
Property Get AllocationGranularity() As Long
    AllocationGranularity = dwAllocationGranularity
End Property

' Quite useful! :)
Property Get FileSize() As Long
    FileSize = apFileSize
End Property

Property Get FileName() As String
    FileName = apFileName
End Property

' Seeks to an offset from the beginning of the file
' without having to do the pointer math
Public Sub SeekEx(offset As Long)
    SetFilePointer apEntryPoint + offset, SetReplaceCurrent
End Sub

' A function to read a Unicode string
Public Function ReadString(Size As Long) As String
Dim aB() As Byte
Dim sTemp As String
Dim i As Long
    
    ReDim aB(Size)
    CopyMemory aB(0), ByVal apMapPointer, Size
    
    sTemp = StrConv(aB, vbUnicode)
    sTemp = StrConv(sTemp, vbFromUnicode)
    
    i = InStr(1, sTemp, Chr(0))
    If i > 0 Then sTemp = Left$(sTemp, i - 1)
    
    ReadString = sTemp
    
    MovePointer Size, drPointerDirection
End Function


