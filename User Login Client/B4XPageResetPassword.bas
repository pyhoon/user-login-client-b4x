B4J=true
Group=Password
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
	Private KVS As KeyValueStore
	Private txtResetUserEmail As B4XFloatTextField
End Sub

Public Sub Initialize As Object
	xui.SetDataFolder("KVS")
	KVS.Initialize(xui.DefaultFolder, "kvs.dat")
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("ResetPassword")
	B4XPages.SetTitle(Me, "Reset Password")
End Sub

#If B4J
Sub lblBack_MouseClicked (EventData As MouseEvent)
	B4XPages.ClosePage(Me)
#Else
Sub lblBack_Click
#End If
	B4XPages.ShowPage("MainPage")
End Sub

Private Sub BtnResetPassword_Click
	If txtResetUserEmail.Text.Trim = "" Then
		xui.MsgboxAsync("Please enter your Email", "E R R O R")
		Return
	End If
	If Main.VALIDATE_EMAIL Then
		If Utility.ValidateEmail(txtResetUserEmail.Text.Trim) = False Then
			xui.MsgboxAsync("Email format is incorrect", "E R R O R")
			Return
		End If
	End If
	Dim sf As Object = xui.Msgbox2Async("Are you sure to reset password?", "C O N F I R M", "Y E S", "", "N O", Null)
	Wait For (sf) Msgbox_Result (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		ResetPassword
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

Sub ResetPassword
	Try
		Log("[B4XPagePassword] ResetPassword")
		Dim data As Map
		data.Initialize
		data.Put("email", txtResetUserEmail.Text.Trim)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PostString(B4XPages.MainPage.URL & "users/reset-password", data.As(JSON).ToString)
		Wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Dim result As Map = job.GetString.As(JSON).ToMap
			If result.Get("s") = "error" Then
				xui.MsgboxAsync(result.Get("e"), "E R R O R")
				Return
			End If
			'Dim users As List = result.Get("r")
			' if email not used, password default to "password"
			Wait For (KVS.PutMapAsync(CreateMap("ApiKey": Null, "Token": Null))) Complete (Success As Boolean)
			If Success Then
				Log("Api Key set to Null")
				xui.MsgboxAsync(result.Get("m"), "M E S S A G E")
			Else
				Log(LastException)
			End If
		Else
			ShowConnectionError(job.ErrorMessage)
		End If
	Catch
		Log("[B4XPagePassword] ResetPassword: " & LastException.Message)
		xui.MsgboxAsync("Failed to reset password", "E R R O R")
	End Try
	job.Release
End Sub