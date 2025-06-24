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
	Private txtOldPassword As B4XFloatTextField
	Private txtUserPassword1 As B4XFloatTextField
	Private txtUserPassword2 As B4XFloatTextField
End Sub

Public Sub Initialize As Object
	xui.SetDataFolder("KVS")
	KVS.Initialize(xui.DefaultFolder, "kvs.dat")
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("ChangePassword")
	B4XPages.SetTitle(Me, "Change Password")
End Sub

#If B4J
Sub lblBack_MouseClicked (EventData As MouseEvent)
	B4XPages.ClosePage(Me)
#Else
Sub lblBack_Click
#End If
	B4XPages.ShowPage("MainPage")
End Sub

Private Sub BtnChangePassword_Click
	If txtOldPassword.Text.Trim = "" Then
		xui.MsgboxAsync("Please enter your Current Password", "E R R O R")
		Return
	End If
	If txtUserPassword1.Text.Trim = "" Then
		xui.MsgboxAsync("Please enter your New Password", "E R R O R")
		Return
	End If
	If txtUserPassword2.Text.Trim = "" Then
		xui.MsgboxAsync("Please confirm your Password", "E R R O R")
		Return
	End If
	If txtUserPassword1.Text.Trim <> txtUserPassword2.Text.Trim Then
		xui.MsgboxAsync("Password not match", "E R R O R")
		Return
	End If
	Dim sf As Object = xui.Msgbox2Async("Are you sure to change password?", "C O N F I R M", "Y E S", "", "N O", Null)
	Wait For (sf) Msgbox_Result (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		ChangePassword
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

Sub ChangePassword
	Try
		Log("[B4XPagePassword] ChangePassword")
		Dim data As Map
		data.Initialize
		data.Put("email", Main.User.Email)
		data.Put("old", txtOldPassword.Text.Trim)
		data.Put("new", txtUserPassword1.Text.Trim)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PutString(B4XPages.MainPage.URL & "users/change-password", data.As(JSON).ToString)
		job.GetRequest.SetHeader("Authorization", "Bearer " & Main.User.Token)
		Wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Dim result As Map = job.GetString.As(JSON).ToMap
			If result.Get("s") = "error" Then
				If result.Get("e") = "User Token Expired" Then
					RefreshToken
					Return
				End If
				xui.MsgboxAsync(result.Get("e"), "E R R O R")
				Return
			End If

			Dim users As List = result.Get("r")
			If users.Size > 0 Then
				Dim user As Map = users.Get(0)
				Main.User.ApiKey = user.Get("api_key")
				Main.User.Token = user.Get("token")
				Dim user As Map = CreateMap("ApiKey": Main.User.ApiKey, "Token": Main.User.Token)
				Wait For (KVS.PutMapAsync(user)) Complete (Success As Boolean)
				If Success Then
					xui.MsgboxAsync(result.Get("m"), "M E S S A G E")
					B4XPages.ShowPageAndRemovePreviousPages("MainPage")
				Else
					Log(LastException)
					xui.MsgboxAsync(LastException, "E R R O R")
				End If
			Else
				Log("No data")
				xui.MsgboxAsync("No data", "E R R O R")
			End If
		Else
			ShowConnectionError(job.ErrorMessage)
		End If
	Catch
		Log("[B4XPagePassword] ChangePassword: " & LastException.Message)
		xui.MsgboxAsync("Failed to update password", "E R R O R")
	End Try
	job.Release
End Sub

Sub RefreshToken
	Try
		Log("Refreshing Token...")
		Dim data As Map = CreateMap("email": Main.User.Email, "apikey": Main.User.ApiKey)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PostString(B4XPages.MainPage.URL & "users/token", data.As(JSON).ToString)
		Wait For (job) JobDone(job As HttpJob)
		If job.Success Then
			Dim Map1 As Map = job.GetString.As(JSON).ToMap
			If Map1.Get("s") = "error" Then
				Log(Map1.Get("e"))
			Else
				Dim result As List = Map1.Get("r")
				Dim user As Map = result.Get(0)
				Main.User.Token = user.Get("token")
				Dim user As Map = CreateMap("Token": Main.User.Token)
				Wait For (KVS.PutMapAsync(user)) Complete (Success As Boolean)
				If Success Then
					ChangePassword
				Else
					Log(LastException)
					xui.MsgboxAsync(LastException, "E R R O R")
				End If
			End If
		Else
			Log(job.ErrorMessage)
		End If
	Catch
		Log(LastException)
	End Try
	job.Release
End Sub