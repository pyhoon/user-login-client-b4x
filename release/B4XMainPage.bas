B4A=true
Group=Main
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
'#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region
' LibDownloader: ide://run?file=%JAVABIN%\java.exe&Args=-jar&Args=%ADDITIONAL%\..\B4X\libget-non-ui.jar&Args=%PROJECT%&Args=true
' Export as zip: ide://run?File=%B4X%\Zipper.jar&Args=%PROJECT_NAME%.zip

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Public URL As String = "http://192.168.50.42:8080/api/" ' Change to your Web API Server URL
	Private KVS As KeyValueStore
	Private Drawer As B4XDrawer
	Private B4XGifView1 As B4XGifView
	Private CLVL As CustomListView
	Private CLVM As CustomListView
	Private pnlTop As B4XView
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
	Private Retry As Boolean
	Public lblProfileName As B4XView
	Public UserLoginPage As B4XPageUserLogin
	Public UserProfilePage As B4XPageUserProfile
	Public UserRegisterPage As B4XPageUserRegister
	Public ChangePasswordPage As B4XPageChangePassword
	Public ResetpasswordPage As B4XPageResetPassword
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
	xui.SetDataFolder("KVS")
	KVS.Initialize(xui.DefaultFolder, "kvs.dat")
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Wait For (ShowSplashScreen) Complete (Unused As Boolean)
	Root.RemoveAllViews
	B4XPages.SetTitle(Me, "App")
	Drawer.Initialize(Me, "Drawer", Root, 400dip)
	Drawer.LeftPanel.LoadLayout("LeftMenu")
	Drawer.CenterPanel.LoadLayout("MainPage")
	LoadSlideMenu
	If Retry Then
		GetUserList
	End If
End Sub

Private Sub B4XPage_Appear
	If lblProfileName.IsInitialized And NullOrEmpty(Main.User.Name) = False Then lblProfileName.Text = Main.User.Name
	If Main.User.IsInitialized = False Then
		Retry = True
		Return
	End If
	GetUserList
End Sub

Private Sub B4XPage_Resize (Width As Int, Height As Int)
	If Drawer.IsInitialized Then Drawer.Resize(Width, Height)
End Sub

Sub ShowSplashScreen As ResumableSub
	#If B4i
	Main.NavControl.NavigationBarVisible = False
	#End If	
	Root.LoadLayout("Splash")
	B4XPages.SetTitle(Me, "Loading...")
	B4XGifView1.SetGif(File.DirAssets, "loading.gif")
	
	UserLoginPage.Initialize
	UserProfilePage.Initialize
	UserRegisterPage.Initialize
	B4XPages.AddPage("UserLogin", UserLoginPage)
	B4XPages.AddPage("UserProfile", UserProfilePage)
	B4XPages.AddPage("UserRegister", UserRegisterPage)
	
	ChangePasswordPage.Initialize
	ResetpasswordPage.Initialize
	B4XPages.AddPage("ChangePassword", ChangePasswordPage)
	B4XPages.AddPage("ResetPassword", ResetpasswordPage)
	
	Wait For (KVS.GetMapAsync(Array("Name", "Email", "Location", "ApiKey", "Token"))) Complete (M As Map)
	If M.IsInitialized Then
		Main.User.Initialize
		Main.User.Name = M.GetDefault("Name", "")
		Main.User.Email = M.GetDefault("Email", "")
		Main.User.Location = M.GetDefault("Location", "")
		Main.User.APIKey = M.GetDefault("ApiKey", "")
		Main.User.Token = M.GetDefault("Token", "")
	End If
	Return True
End Sub

Sub GetToken As ResumableSub
	Dim Success As Boolean
	Try
		Log("[B4XMainPage] GetToken")
		Dim data As Map = CreateMap("email": Main.User.Email, "apikey": Main.User.ApiKey)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PostString(URL & "users/token", data.As(JSON).ToString)
		Wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Dim response As Map = job.GetString.As(JSON).ToMap
			If response.Get("s") = "error" Then
				Dim error As String = response.Get("e")
				xui.MsgboxAsync(error, "E R R O R")
			Else
				Dim result As List = response.Get("r")
				Dim user As Map = result.Get(0)
				Main.User.Token = user.Get("token")
				Main.User.Token_Expiry = user.Get("token_expiry")
				Dim Token As Map = CreateMap("Token": Main.User.Token, "Token_Expiry": Main.User.Token_Expiry)
				Wait For (KVS.PutMapAsync(Token)) Complete (Success As Boolean)
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
		If Main.User.IsInitialized = False Then
			Log("User not initialized")
			Return
		End If
		
		If NullOrEmpty(Main.User.Token) Then
			Log("No Token")
			If NullOrEmpty(Main.User.Email) Then
				Log("No Email")
				Drawer.LeftOpen = True
				Return
			End If
			If NullOrEmpty(Main.User.ApiKey) Then
				Log("No Api key")
				Drawer.LeftOpen = True
				Return
			End If
			' Refreshing token
			Wait For (GetToken) Complete (Success As Boolean)
			Log("GetToken=" & Success)
			' Retry
			If Success Then
				Log("Retrying GetUserList...")
				GetUserList
			End If
			Return
		End If

		Dim job As HttpJob
		job.Initialize("", Me)
		job.Download(URL & "users/list")
		job.GetRequest.SetHeader("Authorization", "Bearer " & Main.User.Token)
		Wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Dim result As Map = job.GetString.As(JSON).ToMap
			If result.Get("s") = "error" Then
				If 401 = result.Get("a") Then
					Log("Invalid token")
					' Refreshing token
					Wait For (GetToken) Complete (Success As Boolean)
					Log(Success)
					' Retry
					If Success Then
						GetUserList
					End If
					Return
				End If
				xui.MsgboxAsync(result.Get("e"), "E R R O R")
				Return
			End If
			
			CLVM.Clear
			Dim users As List = result.Get("r")
			For Each user As Map In users
				Dim strUserName As String = user.Get("name")
				Dim strUserEmail As String = user.Get("email")
				Dim strUserStatus As String = user.Get("online")
				Dim intUserLastOnline As Int = user.Get("last_online")
				Dim HowLong As String

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

Sub GetUserInfo (user_email As String)
	Try
		Log("[B4XMainPage] GetUserInfo")
		Dim jsn As Map = CreateMap("email": user_email)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PostString(URL & "users/profile", jsn.As(JSON).ToString)
		job.GetRequest.SetHeader("Authorization", "Bearer " & Main.User.Token)
		Wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Dim response As Map = job.GetString.As(JSON).ToMap
			If response.Get("s") = "error" Then
				Dim error As String = response.Get("e")
				xui.MsgboxAsync(error, "E R R O R")
				Return
			End If

			Dim results As List = response.Get("r")
			For Each user As Map In results
				lblViewUserName.Text = user.Get("name")
				txtViewUserLocation.Text = user.Get("location")
				If user.Get("online") = "Y" Then
					lblViewUserStatus.Text = "Online"
					lblViewUserStatus.TextColor = xui.Color_RGB(50, 205, 50)
				Else
					lblViewUserStatus.Text = "Offline"
					lblViewUserStatus.TextColor = xui.Color_RGB(105, 105, 105)
				End If
			Next
			If results.Size > 0 Then
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
Sub BtnMenu_Click
	Drawer.LeftOpen = Not(Drawer.LeftOpen)
End Sub
#End If
#If B4J
Sub BtnMenu_MouseClicked (EventData As MouseEvent)
	Drawer.LeftOpen = Not(Drawer.LeftOpen)
End Sub
#End If

Sub CLVL_ItemClick (Index As Int, Value As Object)
	Drawer.LeftOpen = False
	Select Case Value
		Case "Log in"
			#If B4J
			B4XPages.ClosePage(Me)
			#End If
			B4XPages.ShowPage("UserLogin")
		Case "Register"
			#If B4J
			B4XPages.ClosePage(Me)
			#End If
			B4XPages.ShowPage("UserRegister")
		Case "Change Password"
			#If B4J
			B4XPages.ClosePage(Me)
			#End If
			B4XPages.ShowPage("ChangePassword")
		Case "User Profile"
			#If B4J
			B4XPages.ClosePage(Me)
			#End If
			B4XPages.ShowPage("UserProfile")
		Case "Log out"
			KVS.Remove("Token")
			Dim newuser As User
			newuser.Initialize
			Main.User = newuser
			CLVM.Clear
			Sleep(500)
			LoadSlideMenu
			Drawer.LeftOpen = True
	End Select
End Sub

Public Sub LoadSlideMenu
	CLVL.Clear
	lblProfileName.Text = IIf(NullOrEmpty(Main.User.Name), "Guest", Main.User.Name)
	If NullOrEmpty(Main.User.ApiKey) Then
		Log("LoadSlideMenu (Logout)")
		CLVL.Add(CreateMenu(Chr(0xF090), "Log in", CLVL.AsView.Width), "Log in")
		CLVL.Add(CreateMenu(Chr(0xF234), "Register", CLVL.AsView.Width), "Register")
	Else
		Log("LoadSlideMenu (Login)")
		CLVL.Add(CreateMenu(Chr(0xF05A), "My Profile", CLVL.AsView.Width), "User Profile")
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

Sub ShowConnectionError (strError As String)
	If strError.Contains("Unable to resolve host") Then
		xui.MsgboxAsync("Connection failed.", "E R R O R")
	Else If strError.Contains("timeout") Then
		xui.MsgboxAsync("Connection timeout.", "E R R O R")
	Else
		xui.MsgboxAsync(strError, "E R R O R")
	End If
End Sub

Sub CLVM_ItemClick (Index As Int, Value As Object)
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

Sub NullOrEmpty (Value As Object) As Boolean
	Return Value = Null Or Value.As(String).EqualsIgnoreCase("null") Or Value.As(String).EqualsIgnoreCase("")
End Sub