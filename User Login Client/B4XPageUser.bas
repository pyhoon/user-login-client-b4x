B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	#If B4J
	Private fx As JFX
	#End If
	Private xui As XUI
	Private KVS As KeyValueStore
	Private txtUserName As B4XFloatTextField
	Private txtUserEmail As B4XFloatTextField
	Private txtPassword As B4XFloatTextField
	Private txtUserLocation As B4XFloatTextField
	Private txtRegisterUserName As B4XFloatTextField
	Private txtRegisterUserEmail As B4XFloatTextField
	Private txtRegisterPassword1 As B4XFloatTextField
	Private txtRegisterPassword2 As B4XFloatTextField
	Private BtnSubmit As B4XView
	Private BtnReset As B4XView
	Private BtnCancel As B4XView
	Private imgAvatar As B4XImageView
	Private lblUserEmail As B4XView
	Private lblUserLocation As B4XView
	Private lblUserName As B4XView
	Public strMode As String	
End Sub

Public Sub Initialize As Object
	xui.SetDataFolder("KVS")
	KVS.Initialize(xui.DefaultFolder, "kvs.dat")
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	SelectMode
End Sub

Private Sub B4XPage_Appear
	'SelectMode
End Sub

Sub SelectMode
	Select Case strMode
		Case "Login"
			Root.RemoveAllViews
			Root.LoadLayout("UserLogin")
		Case "Register"
			Root.RemoveAllViews
			Root.LoadLayout("UserRegister")
		Case "About"
			Root.RemoveAllViews
			Root.LoadLayout("About")
			lblUserName.Text = Main.User.Name
			lblUserEmail.Text = Main.User.Email
			lblUserLocation.Text = Main.User.Location
			imgAvatar.Bitmap = xui.LoadBitmap(File.DirAssets, "default.png")
	End Select
End Sub

Sub RegisterUser
'	Dim parser As JSONParser
'	Dim job As HttpJob
'	Dim strError As String
'	Dim strData As String
'	Dim jsn As String
	Try
		Log("[B4XPageUser] RegisterUser")
		Dim data As Map
		data.Initialize
		data.Put("name", txtRegisterUserName.Text.Trim)
		data.Put("email", txtRegisterUserEmail.Text.Trim)
		data.Put("password", txtRegisterPassword1.Text.Trim)	
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PostString(Main.strURL & "users/register", data.As(JSON).ToString)
		Wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Dim result As Map = job.GetString.As(JSON).ToMap
			If result.Get("s") = "error" Then
				xui.MsgboxAsync(result.Get("e"), "E R R O R")
				Return
			End If

			'Dim users As List = result.Get("r")
			'If users.Size > 0 Then
				'Dim user As Map = users.Get(0)
				'Main.User.Name = user.Get("name")
				'Main.User.Email = user.Get("email")
				
				'xui.MsgboxAsync("User register successful", "M E S S A G E")
				'strMode = "Login"
				'SelectMode
			'Else
				'xui.MsgboxAsync("No data", "E R R O R")
			'End If
			
			xui.MsgboxAsync("User register successful", "M E S S A G E")
			'xui.MsgboxAsync("Please check your email for account activation!", "Registration Successful")
			strMode = "Login"
			SelectMode
		Else
			ShowConnectionError(job.ErrorMessage)
		End If
	Catch
		Log("[B4XPageUser] RegisterUser: " & LastException.Message)
		xui.MsgboxAsync("Failed to register user", "E R R O R")
	End Try
	job.Release
End Sub

Sub LoginUser
	Try
		Log("[B4XPageUser] LoginUser")
		'Utility.ShowProgressDialog("Logging in...")
		Dim strEmail As String = txtUserEmail.Text.Trim
		Dim strPassword As String = txtPassword.Text.Trim
		Dim data As Map = CreateMap("email": strEmail, "password": strPassword)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PostString(Main.strURL & "users/login", data.As(JSON).ToString)
		Wait For (job) JobDone(job As HttpJob)
		'Utility.HideProgressDialog
		If job.Success Then
			Dim result As Map = job.GetString.As(JSON).ToMap
			If result.Get("s") = "error" Then
				xui.MsgboxAsync(result.Get("e"), "E R R O R")
				Return
			End If

			Dim users As List = result.Get("r")
			If users.Size > 0 Then
				Dim user As Map = users.Get(0)
				Main.User.Name = user.Get("name")
				Main.User.Email = user.Get("email")
				Main.User.Location = user.Get("location")
				Main.User.ApiKey = user.Get("api_key")
				'Main.gUserToken = user.Get("user_token")
				
				' Write to internal storage
				Dim user As Map = CreateMap("Name": Main.User.Name, "Email": Main.User.Email, "Location": Main.User.Location, "ApiKey": Main.User.ApiKey)
				Wait For (KVS.PutMapAsync(user)) Complete (Success As Boolean)
				
				xui.MsgboxAsync("Login successful", "M E S S A G E")
				B4XPages.ShowPageAndRemovePreviousPages("MainPage")
				B4XPages.MainPage.GetToken
			Else
				xui.MsgboxAsync("No data", "E R R O R")
			End If
		Else
			ShowConnectionError(job.ErrorMessage)
		End If
	Catch
		Log("[B4XPageUser] LoginUser: " & LastException.Message)
		xui.MsgboxAsync("Failed to retrieve data", "E R R O R")
	End Try
	job.Release
End Sub

Sub UpdateProfile
	Dim parser As JSONParser
	Dim job As HttpJob
	Dim strError As String
	Dim strData As String
	Dim jsn As String
	Try
		Log("[B4XPageUser] UpdateProfile")
		Log("API Key=" & Main.User.ApiKey)
		Log("Token=" & Main.User.Token)
		Dim Map2 As Map
		Map2.Initialize
		Map2.Put("key", Main.User.ApiKey)
		Map2.Put("token", Main.User.Token)
		Map2.Put("user_name", txtUserName.Text.Trim)
		Map2.Put("user_location", txtUserLocation.Text.Trim)
		jsn = Utility.Map2Json(Map2)
		job.Initialize("", Me)
		job.PutString(Main.strURL & "users/update", jsn)
		Wait For (job) JobDone(job As HttpJob)
		'Utility.HideProgressDialog
		If job.Success Then
			strData = job.GetString
			job.Release
			Log(strData)
			parser.Initialize(strData)
			If Utility.isArray(strData) Then
				Dim List1 As List
				Dim Map1 As Map
				List1 = parser.NextArray
				Map1 = List1.Get(0)
				If -1 = Map1.Get("result") Then
					If Map1.Get("message") = "Error-No-Result" Then
						xui.MsgboxAsync("Profile not found", "E R R O R")
					Else If Map1.Get("message") = "Error-No-Value" Then
						xui.MsgboxAsync("Invalid Parameters", "E R R O R")
					Else
						xui.MsgboxAsync("Uncaught error" & CRLF & Map1.Get("message"), "E R R O R")
					End If
					Return
				End If
				xui.MsgboxAsync("Profile is updated!", "S U C C E S S")						
				Main.User.Name = txtUserName.Text.Trim
				Main.User.Location = txtUserLocation.Text.Trim
				lblUserName.Text = Main.User.Name
				lblUserLocation.Text = Main.User.Location
				BtnSubmit.Text = "Edit Profile"
				BtnCancel.Visible = False
				txtUserName.mBase.Visible = False
				txtUserName.TextField.Visible = False
				txtUserLocation.mBase.Visible = False
				txtUserLocation.TextField.Visible = False
				lblUserName.Visible = True
				lblUserLocation.Visible = True
			Else
				#If Not(B4i)
				strData = parser.NextValue
				Log(strData)				
				#End If
				xui.MsgboxAsync("Uncaught error" & CRLF & strData, "E R R O R")
			End If
		Else
			strError = job.ErrorMessage
			job.Release
			Log(strError)
			ShowConnectionError(strError)
		End If
	Catch
		job.Release
		Log("[B4XPageUser] UpdateProfile: " & LastException.Message)
		xui.MsgboxAsync("Failed to update profile", "E R R O R")
	End Try
End Sub

#If B4J
Sub lblBack_MouseClicked (EventData As MouseEvent)
	B4XPages.ShowPageAndRemovePreviousPages("MainPage")
End Sub
#Else
Sub lblBack_Click
	B4XPages.ClosePage(Me)
	B4XPages.ShowPage("MainPage")
End Sub
#End If

Sub BtnSubmit_Click
	'IME.HideKeyboard
	Select Case strMode
		Case "Login"
			If txtUserEmail.Text.Trim = "" Then
				xui.MsgboxAsync("Please enter your Email", "E R R O R")
				Return
			End If
			'If Utility.ValidateEmail(txtUserEmail.Text.Trim) = False Then
			'	xui.MsgboxAsync("Email format is incorrect", "E R R O R")
			'	Return
			'End If
			If txtPassword.Text.Trim = "" Then
				xui.MsgboxAsync("Please enter your Password", "E R R O R")
				Return
			End If
			LoginUser
			Return
		Case "Register"
			If txtRegisterUserName.Text.Trim = "" Then
				xui.MsgboxAsync("Please enter your Name", "E R R O R")
				Return
			End If
			If txtRegisterUserEmail.Text.Trim = "" Then
				xui.MsgboxAsync("Please enter your Email", "E R R O R")
				Return
			End If
			'If Utility.ValidateEmail(txtRegisterUserEmail.Text.Trim) = False Then
			'	xui.MsgboxAsync("Email format is incorrect", "E R R O R")
			'	Return
			'End If
			If txtRegisterPassword1.Text.Trim = "" Then
				xui.MsgboxAsync("Please enter your Password", "E R R O R")
				Return
			End If
			If txtRegisterPassword2.Text.Trim = "" Then
				xui.MsgboxAsync("Please repeat your Password", "E R R O R")
				Return
			End If
			If txtRegisterPassword1.Text.Trim <> txtRegisterPassword2.Text.Trim Then
				xui.MsgboxAsync("Password not match", "E R R O R")
				Return
			End If
			'#If B4J
			Dim sf As Object = xui.Msgbox2Async("Are you sure to register?", "C O N F I R M", "Y E S", "", "N O", Null)
			Wait For (sf) Msgbox_Result (Result As Int)
			If Result = xui.DialogResponse_Positive Then
				RegisterUser
			End If
			'#Else If B4i
			'Msgbox2("Msg", "Are you sure to register?", "C O N F I R M", Array ("Y E S", "N O"))
			'Wait For Msg_Click (ButtonText As String)
			'If ButtonText = "Y E S" Then
			'	RegisterUser
			'End If
			'#Else
			'Msgbox2Async("Are you sure to register?", "C O N F I R M", "Y E S", "", "N O", Null, True)
			'Wait For Msgbox_Result (Result As Int)
			'If Result = DialogResponse.POSITIVE Then
			'	RegisterUser
			'End If
			'#End If
			Return
		Case "About"
			If BtnSubmit.Text = "Edit Profile" Then
				BtnSubmit.Text = "Update Profile"
				BtnCancel.Visible = True
				txtUserName.Text = lblUserName.Text
				txtUserLocation.Text = lblUserLocation.Text
				lblUserName.Visible = False
				lblUserLocation.Visible = False
				txtUserName.mBase.Visible = True
				txtUserName.TextField.Visible = True
				txtUserLocation.mBase.Visible = True
				txtUserLocation.TextField.Visible = True
			Else
				If txtUserName.Text.Trim = "" Then
					xui.MsgboxAsync("Please enter your Name", "E R R O R")
					Return
				End If
				If txtUserLocation.Text.Trim = "" Then
					xui.MsgboxAsync("Please enter your Location", "E R R O R")									
					Return
				End If
				UpdateProfile
			End If
	End Select
End Sub

Sub BtnCancel_Click
	lblUserName.Text = Main.User.Name
	lblUserLocation.Text = Main.User.Location
	BtnSubmit.Text = "Edit Profile"
	BtnCancel.Visible = False
	txtUserName.mBase.Visible = False
	txtUserName.TextField.Visible = False
	txtUserLocation.mBase.Visible = False
	txtUserLocation.TextField.Visible = False
	lblUserName.Visible = True
	lblUserLocation.Visible = True
End Sub

Sub BtnReset_Click
	B4XPages.MainPage.PagePassword.strMode = "Reset Password"
	#If B4J
		B4XPages.ShowPageAndRemovePreviousPages("PasswordReset")
	#Else
		B4XPages.ShowPage("PasswordReset")
	#End If
End Sub

Sub txtUserEmail_EnterPressed
	If strMode = "Login" Then
		txtPassword.RequestFocusAndShowKeyboard
	End If	
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