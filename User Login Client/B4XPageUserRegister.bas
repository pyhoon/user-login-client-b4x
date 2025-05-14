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
	Private txtRegisterUserName As B4XFloatTextField
	Private txtRegisterUserEmail As B4XFloatTextField
	Private txtRegisterPassword1 As B4XFloatTextField
	Private txtRegisterPassword2 As B4XFloatTextField
End Sub

Public Sub Initialize As Object
	xui.SetDataFolder("KVS")
	KVS.Initialize(xui.DefaultFolder, "kvs.dat")
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("UserRegister")
	B4XPages.SetTitle(Me, "User Register")
End Sub

#If B4J
Sub lblBack_MouseClicked (EventData As MouseEvent)
	B4XPages.ClosePage(Me)
#Else
Sub lblBack_Click
#End If
	B4XPages.ShowPage("MainPage")
End Sub

Private Sub BtnRegisterUser_Click
	If txtRegisterUserName.Text.Trim = "" Then
		xui.MsgboxAsync("Please enter your Name", "E R R O R")
		Return
	End If
	If txtRegisterUserEmail.Text.Trim = "" Then
		xui.MsgboxAsync("Please enter your Email", "E R R O R")
		Return
	End If
	If Main.VALIDATE_EMAIL Then
		If Utility.ValidateEmail(txtRegisterUserEmail.Text.Trim) = False Then
			xui.MsgboxAsync("Email format is incorrect", "E R R O R")
			Return
		End If
	End If
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

Sub RegisterUser
	Try
		Log("[B4XPageUserRegister] RegisterUser")
		Dim data As Map
		data.Initialize
		data.Put("name", txtRegisterUserName.Text.Trim)
		data.Put("email", txtRegisterUserEmail.Text.Trim)
		data.Put("password", txtRegisterPassword1.Text.Trim)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PostString(B4XPages.MainPage.URL & "users/register", data.As(JSON).ToString)
		Wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Dim result As Map = job.GetString.As(JSON).ToMap
			If result.Get("s") = "error" Then
				xui.MsgboxAsync(result.Get("e"), "E R R O R")
				Return
			End If

			'Dim users As List = result.Get("r")
			xui.MsgboxAsync("User register successful", "M E S S A G E")
			'xui.MsgboxAsync("Please check your email for account activation!", "Registration Successful")
			'Log("Back to MainPage...")
			'B4XPages.ShowPageAndRemovePreviousPages("MainPage")
			'B4XPages.MainPage.LoadSlideMenu
		Else
			ShowConnectionError(job.ErrorMessage)
		End If
	Catch
		Log("[B4XPageUserRegister] RegisterUser: " & LastException.Message)
		xui.MsgboxAsync("Failed to register user", "E R R O R")
	End Try
	job.Release
End Sub