B4J=true
Group=User
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private KVS As KeyValueStore
	Private txtUserEmail As B4XFloatTextField
	Private txtPassword As B4XFloatTextField
End Sub

Public Sub Initialize As Object
	xui.SetDataFolder("KVS")
	KVS.Initialize(xui.DefaultFolder, "kvs.dat")
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("UserLogin")
	B4XPages.SetTitle(Me, "User Login")
End Sub

#If B4J
Sub lblBack_MouseClicked (EventData As MouseEvent)
	B4XPages.ClosePage(Me)
#Else
Sub lblBack_Click
#End If
	B4XPages.ShowPage("MainPage")
End Sub

Sub txtUserEmail_EnterPressed
	txtPassword.RequestFocusAndShowKeyboard
End Sub

Private Sub BtnUserLogin_Click
	If txtUserEmail.Text.Trim = "" Then
		xui.MsgboxAsync("Please enter your Email", "E R R O R")
		Return
	End If
	If Main.VALIDATE_EMAIL Then
		If Utility.ValidateEmail(txtUserEmail.Text.Trim) = False Then
			xui.MsgboxAsync("Email format is incorrect", "E R R O R")
			Return
		End If
	End If
	If txtPassword.Text.Trim = "" Then
		xui.MsgboxAsync("Please enter your Password", "E R R O R")
		Return
	End If
	LoginUser
End Sub

Private Sub BtnForgotPassword_Click
	#If B4J
	B4XPages.ClosePage(Me)
	#End If
	B4XPages.ShowPage("ResetPassword")
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

Sub LoginUser
	Try
		Log("[B4XPageUserLogin] LoginUser")
		Dim data As Map = CreateMap("email": txtUserEmail.Text.Trim, "password": txtPassword.Text.Trim)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PostString(B4XPages.MainPage.URL & "users/login", data.As(JSON).ToString)
		Wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Log(job.GetString)
			Dim response As Map = job.GetString.As(JSON).ToMap
			If response.Get("s") = "error" Then
				Dim error As String = response.Get("e")
				xui.MsgboxAsync(error, "E R R O R")
				Return
			End If

			Dim result As List = response.Get("r")
			If result.Size > 0 Then
				Dim user As Map = result.Get(0)
				Main.User.Initialize
				Main.User.Name = user.Get("name")
				Main.User.Email = user.Get("email")
				Main.User.Location = user.Get("location")
				Main.User.ApiKey = user.Get("api_key")

				Dim user As Map = CreateMap("Email": Main.User.Email, _
				"Name": Main.User.Name, _
				"Location": Main.User.Location, _
				"ApiKey": Main.User.ApiKey)
				Wait For (KVS.PutMapAsync(user)) Complete (Success As Boolean)
				If Success Then
					'Log(Main.User)
					'For Each key As String In KVS.ListKeys
					'	Log(key & ":" & KVS.Get(key))
					'Next
				
					'xui.MsgboxAsync("Login successful", "M E S S A G E")
					Log("Back to MainPage...")
					B4XPages.ShowPageAndRemovePreviousPages("MainPage")
					B4XPages.MainPage.LoadSlideMenu
					'B4XPages.MainPage.GetToken
				Else
					xui.MsgboxAsync(LastException, "E R R O R")
				End If
			Else
				xui.MsgboxAsync("No data", "E R R O R")
			End If
		Else
			Dim response As Map = job.ErrorMessage.As(JSON).ToMap
			Dim error As String = response.Get("e")
			ShowConnectionError(error)
		End If
	Catch
		Log("[B4XPageUserLogin] LoginUser: " & LastException.Message)
		xui.MsgboxAsync("Failed to retrieve data", "E R R O R")
	End Try
	job.Release
End Sub