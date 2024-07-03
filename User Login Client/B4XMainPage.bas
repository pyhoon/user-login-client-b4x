B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region

'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip

Sub Class_Globals
	Private Root As B4XView
	#If B4J
	Private fx As JFX
	#End If	
	Private xui As XUI
	Private KVS As KeyValueStore
	Private Drawer As B4XDrawer
	Private B4XGifView1 As B4XGifView
	Public PageUser As B4XPageUser
	Public PagePassword As B4XPagePassword
	Private CLVL As CustomListView
	Private CLVM As CustomListView
	Private pnlTop As B4XView
	Private lblProfileName As B4XView
	Private lblMenuIcon As B4XView
	Private lblMenuText As B4XView
	Private pnlStatus As B4XView
	Private lblName As B4XView
	Private btnMenu As B4XView
	Private pnlBlur As B4XView
	Private imgAvatar As B4XImageView
	Private lblViewUserName As B4XView
	Private lblViewUserLocation As B4XView
	Private txtViewUserLocation As B4XView
	Private lblViewUserStatus As B4XView
End Sub

Public Sub Initialize
	xui.SetDataFolder("KVS")
	KVS.Initialize(xui.DefaultFolder, "kvs.dat")
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)	
	Root = Root1
	Wait For (ShowSplashScreen) Complete (Unused As Boolean)	
	Root.RemoveAllViews
	
	B4XPages.SetTitle(Me, "APP")
	Drawer.Initialize(Me, "Drawer", Root, 400dip)
	Drawer.LeftPanel.LoadLayout("LeftMenu")
	Drawer.CenterPanel.LoadLayout("HomePage")
	
	Wait For (KVS.GetMapAsync(Array("Name", "Email", "Location", "ApiKey", "Token"))) Complete (M As Map)
	If M.IsInitialized Then
		Main.User.Initialize
		Main.User.Name = M.GetDefault("Name", "")
		Main.User.Email = M.GetDefault("Email", "")
		Main.User.Location = M.GetDefault("Location", "")
		Main.User.APIKey = M.GetDefault("ApiKey", "")
		Main.User.Token = M.GetDefault("Token", "")
	End If

	LoadSlideMenu
	If Main.User.Token.EqualsIgnoreCase("") = False Then
		GetUserList
	End If
	
	PageUser.Initialize
	B4XPages.AddPage("Login", PageUser)
	B4XPages.AddPage("Register", PageUser)	
	B4XPages.AddPage("About", PageUser)
	
	PagePassword.Initialize
	B4XPages.AddPage("PasswordChange", PagePassword)
	B4XPages.AddPage("PasswordReset", PagePassword)
End Sub

Private Sub B4XPage_Appear
	If Main.User.IsInitialized And Main.User.Token.EqualsIgnoreCase("") = False Then
		GetUserList
	End If
End Sub

Private Sub B4XPage_Resize (Width As Int, Height As Int)
	If Drawer.IsInitialized Then Drawer.Resize(Width, Height)
End Sub

Sub ShowSplashScreen As ResumableSub
	#If B4i
	Main.NavControl.NavigationBarVisible = False
	#End If	
	Root.LoadLayout("Splash")
	B4XPages.SetTitle(Me, "App")
	B4XGifView1.SetGif(File.DirAssets, "loading.gif")
	Sleep(2000)
	Return True
End Sub

Sub GetToken As ResumableSub
	Dim Success As Boolean
	Try
		Log("[B4XMainPage] GetToken")
		'Utility.ShowProgressDialog("Refreshing User Token...")
		Dim data As Map = CreateMap("email": Main.User.Email, "apikey": Main.User.ApiKey)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PostString(Main.strURL & "users/token", data.As(JSON).ToString)
		Wait For (job) JobDone(job As HttpJob)
		'Utility.HideProgressDialog
		If job.Success Then
			Dim Map1 As Map = job.GetString.As(JSON).ToMap
			If Map1.Get("s") = "error" Then
				xui.MsgboxAsync(Map1.Get("e"), "E R R O R")
			Else
				Dim result As List = Map1.Get("r")
				Dim user As Map = result.Get(0)
				Main.User.Token = user.Get("user_token")
				'Log(Main.User.Token)
				' Write to internal storage
				Wait For (KVS.PutMapAsync(CreateMap("Token": Main.User.Token))) Complete (WriteSuccess As Boolean)
				Success = True
				'For Each key As String In KVS.ListKeys
				'	Log(key & ":" & KVS.Get(key))
				'Next
				LoadSlideMenu
				GetUserList
			End If
		Else
			ShowConnectionError(job.ErrorMessage)
		End If
	Catch
		Log("[B4XMainPage] GetToken: " & LastException.Message)
		xui.MsgboxAsync("Failed to get access token", "E R R O R")
	End Try
	job.Release
	Return Success
End Sub

Sub GetUserList
	Try
		Log("[B4XMainPage] GetUserList")
		'Utility.ShowProgressDialog("Retrieving user list...")
					
		Dim job As HttpJob
		job.Initialize("", Me)
		job.Download(Main.strURL & "users/list")
		job.GetRequest.SetHeader("Authorization", "Bearer " & Main.User.Token)
		Wait For (job) JobDone(job As HttpJob)
		'Utility.HideProgressDialog
		If job.Success Then
			Dim result As Map = job.GetString.As(JSON).ToMap
			If result.Get("s") = "error" Then
				xui.MsgboxAsync(result.Get("e"), "E R R O R")
				' Retry
				Log(result.Get("a"))
				If 401 = result.Get("a") Then
					Wait For (GetToken) Complete (Success As Boolean)
					Log(Success)
				End If
				Return
			End If
			
			CLVM.Clear
			Dim users As List = result.Get("r")
			For Each user As Map In users
				Dim strUserName As String = user.Get("user_name")
				Dim strUserEmail As String = user.Get("user_email")
				Dim strUserStatus As String = user.Get("online")
				Dim intUserLastOnline As Int = user.Get("last_online")
				Dim HowLong As String
				'Log(intUserLastOnline)
				If intUserLastOnline < 600 Then
					If intUserLastOnline > 60 Then
						intUserLastOnline = intUserLastOnline / 60
						HowLong = $" (${intUserLastOnline} minutes ago)"$
					Else
						HowLong = $" (online now)"$
					End If
				End If
				CLVM.Add(CreateList($"${strUserName}${HowLong}"$, strUserStatus, CLVM.AsView.Width), strUserEmail)
			Next
		Else
			ShowConnectionError(job.ErrorMessage)
		End If
	Catch
		Log("[B4XMainPage] GetUserList: " & LastException.Message)
		xui.MsgboxAsync("Failed to retrieve data", "E R R O R")
	End Try
	job.Release
End Sub

Sub GetUserInfo(user_email As String)
	Try
		Log("[B4XMainPage] GetUserInfo")
		'Utility.ShowProgressDialog("Retrieving data...")
		
		Dim jsn As Map = CreateMap("email": user_email)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PostString(Main.strURL & "users/profile", jsn.As(JSON).ToString)
		job.GetRequest.SetHeader("Authorization", "Bearer " & Main.User.Token)
		Wait For (job) JobDone(job As HttpJob)
		'Utility.HideProgressDialog
		If job.Success Then
			Dim result As Map = job.GetString.As(JSON).ToMap
			If result.Get("s") = "error" Then
				xui.MsgboxAsync(result.Get("e"), "E R R O R")
				Return
			End If

			Dim users As List = result.Get("r")
			For Each user As Map In users
				lblViewUserName.Text = user.Get("user_name")
				txtViewUserLocation.Text = user.Get("user_location")
				If user.Get("online") = "Y" Then
					lblViewUserStatus.Text = "Online"
					lblViewUserStatus.TextColor = xui.Color_RGB(50, 205, 50)
				Else
					lblViewUserStatus.Text = "Offline"
					lblViewUserStatus.TextColor = xui.Color_RGB(105, 105, 105)
				End If
			Next
			If users.Size > 0 Then
				pnlBlur.Visible = True
				Drawer.GestureEnabled = False
		#If Not(B4i)
				btnMenu.Enabled = False
		#End If
			End If
		Else
			ShowConnectionError(job.ErrorMessage)
		End If
	Catch
		Log("[B4XMainPage] GetUserInfo: " & LastException.Message)
		xui.MsgboxAsync("Failed to retrieve data", "E R R O R")
	End Try
	job.Release
End Sub

#If B4A
Sub btnMenu_Click
	Drawer.LeftOpen = Not(Drawer.LeftOpen)
End Sub
#End If
#If B4J
Sub btnMenu_MouseClicked (EventData As MouseEvent)
	Drawer.LeftOpen = Not(Drawer.LeftOpen)
End Sub
#End If

Sub CLVL_ItemClick (Index As Int, Value As Object)
	Drawer.LeftOpen = False
	Select Case Value
		Case "Log in"
			PageUser.strMode = "Login"
			#If B4J
			B4XPages.ShowPageAndRemovePreviousPages("Login")
			#Else			
			B4XPages.ShowPage("Login")
			#End If
		Case "Register"
			PageUser.strMode = "Register"
			#If B4J
			'B4XPages.ShowPageAndRemovePreviousPages("Register")
			B4XPages.ClosePage(Me)
			B4XPages.ShowPage("Register")
			#Else			
			B4XPages.ShowPage("Register")
			#End If
		Case "Change Password"
			PagePassword.strMode = "Change Password"
			#If B4J
			B4XPages.ShowPageAndRemovePreviousPages("PasswordChange")
			#Else
			B4XPages.ShowPage("PasswordChange")
			#End If						
		Case "About Me"
			PageUser.strMode = "About"
			#If B4J
			'B4XPages.ShowPageAndRemovePreviousPages("About")
			B4XPages.ClosePage(Me)
			B4XPages.ShowPage("About")
			#Else			
			B4XPages.ShowPage("About")
			#End If			
		Case "Log out"
			Wait For (KVS.PutMapAsync(CreateMap("Token": ""))) Complete (WriteSuccess As Boolean)
			'Log(WriteSuccess)

			Wait For (KVS.GetMapAsync(Array("Name", "Email", "Location", "ApiKey", "Token"))) Complete (M As Map)
			If M.IsInitialized Then
				Main.User.Initialize
				Main.User.Name = M.GetDefault("Name", "")
				Main.User.Email = M.GetDefault("Email", "")
				Main.User.Location = M.GetDefault("Location", "")
				Main.User.APIKey = M.GetDefault("ApiKey", "")
				Main.User.Token = M.GetDefault("Token", "")
			End If
			
			LoadSlideMenu
			CLVM.Clear
	End Select
End Sub

Public Sub LoadSlideMenu
	'Log("LoadSlideMenu")
	CLVL.Clear
	If Main.User.Token.EqualsIgnoreCase("") Then
		CLVL.Add(CreateMenu(Chr(0xF090), "Log in", CLVL.AsView.Width), "Log in")
		CLVL.Add(CreateMenu(Chr(0xF234), "Register", CLVL.AsView.Width), "Register")
	Else
		lblProfileName.Text = Main.User.Name
		CLVL.Add(CreateMenu(Chr(0xF05A), "About Me", CLVL.AsView.Width), "About Me")
		CLVL.Add(CreateMenu(Chr(0xF013), "Change Password", CLVL.AsView.Width), "Change Password")
		CLVL.Add(CreateMenu(Chr(0xF08B), "Log out", CLVL.AsView.Width), "Log out")
	End If
	CLVL.AnimationDuration = 0
	imgAvatar.Bitmap = xui.LoadBitmap(File.DirAssets, "default.png")
End Sub

Private Sub CreateMenu(MenuIcon As String, MenuText As String, Width As Long) As B4XView
	Dim Height As Int = 60dip
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, Height)
	p.LoadLayout("MenuItem")
	lblMenuIcon.Text = MenuIcon
	lblMenuText.Text = MenuText
	Return p
End Sub

Private Sub CreateList(ListText As String, ListStatus As String, Width As Long) As B4XView
	Dim Height As Int = 60dip
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, Width, Height)	
	p.LoadLayout("ListItem")
	lblName.Text = ListText
	If ListStatus = "Y" Then		
		pnlStatus.Color = xui.Color_Green
	Else
		pnlStatus.Color = xui.Color_Gray
	End If
	Return p
End Sub

Sub ShowConnectionError(strError As String)
	If strError.Contains("Unable to resolve host") Then
		xui.MsgboxAsync("Connection failed.", "E R R O R")
	Else If strError.Contains("timeout") Then
		xui.MsgboxAsync("Connection timeout.", "E R R O R")
	Else
		xui.MsgboxAsync(strError, True)
	End If
End Sub

Sub CLVM_ItemClick (Index As Int, Value As Object)
	'If pnlBlur.Visible Then Return
	GetUserInfo(Value)
End Sub

Private Sub BtnClose_Click
	pnlBlur.Visible = False
	Drawer.GestureEnabled = True
	#If Not(B4i)
	btnMenu.Enabled = True
	#End If	
End Sub

Sub NoScroll_Click
	Log("NoScroll")
End Sub