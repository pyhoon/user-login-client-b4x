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
	Private imgAvatar As B4XImageView
	Private lblUserName As B4XView
	Private lblUserEmail As B4XView
	Private lblUserLocation As B4XView
	Private txtUserName As B4XFloatTextField
	Private txtUserLocation As B4XFloatTextField
	Private BtnEdit As B4XView
	Private BtnCancel As B4XView
End Sub

Public Sub Initialize As Object
	xui.SetDataFolder("KVS")
	KVS.Initialize(xui.DefaultFolder, "kvs.dat")
	Return Me
End Sub

Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("UserProfile")
	B4XPages.SetTitle(Me, "User Profile")
End Sub

Private Sub B4XPage_Appear
	lblUserName.Text = Main.User.Name
	lblUserEmail.Text = Main.User.Email
	lblUserLocation.Text = Main.User.Location
	txtUserName.Text = Main.User.Name
	txtUserLocation.Text = Main.User.Location
	imgAvatar.Bitmap = xui.LoadBitmap(File.DirAssets, "default.png")
End Sub

#If B4J
Sub lblBack_MouseClicked (EventData As MouseEvent)
	B4XPages.ClosePage(Me)
#Else
Sub lblBack_Click
#End If
	B4XPages.ShowPage("MainPage")
End Sub

Sub BtnCancel_Click
	lblUserName.Text = Main.User.Name
	lblUserLocation.Text = Main.User.Location
	BtnEdit.Text = "E D I T"
	BtnCancel.Visible = False
	lblUserName.Visible = True
	lblUserLocation.Visible = True
	txtUserName.mBase.Visible = False
	txtUserLocation.mBase.Visible = False
End Sub

Sub BtnEdit_Click
	If BtnEdit.Text = "E D I T" Then
		BtnEdit.Text = "U P D A T E"
		BtnCancel.Visible = True
		txtUserName.Text = lblUserName.Text
		txtUserLocation.Text = lblUserLocation.Text
		lblUserName.Visible = False
		lblUserLocation.Visible = False
		txtUserName.mBase.Visible = True
		txtUserLocation.mBase.Visible = True
	Else
		'BtnEdit.Text = "E D I T"
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
End Sub

Sub ShowConnectionError(strError As String)
	If strError.Contains("Unable to resolve host") Then
		xui.MsgboxAsync("Connection failed.", "E R R O R")
	Else If strError.Contains("timeout") Then
		xui.MsgboxAsync("Connection timeout.", "E R R O R")
	Else
		xui.MsgboxAsync(strError, "E R R O R")
	End If
End Sub

Sub UpdateProfile
	Try
		Log("[B4XPageUserProfile] UpdateProfile")
		Dim data As Map
		data.Initialize
		data.Put("key", Main.User.ApiKey)
		data.Put("token", Main.User.Token)
		data.Put("user_name", txtUserName.Text.Trim)
		data.Put("user_location", txtUserLocation.Text.Trim)
		Dim job As HttpJob
		job.Initialize("", Me)
		job.PutString(Main.strURL & "users/update", data.As(JSON).ToString)
		job.GetRequest.SetHeader("Authorization", "Bearer " & Main.User.Token)
		Wait For (job) JobDone(job As HttpJob)
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
				Main.User.Location = user.Get("location")
				Dim user As Map = CreateMap("Name": Main.User.Name, "Location": Main.User.Location)
				Wait For (KVS.PutMapAsync(user)) Complete (Success As Boolean)
				If Success Then
					'Log(Main.User)
					'For Each key As String In KVS.ListKeys
					'	Log(key & ":" & KVS.Get(key))
					'Next
					lblUserName.Text = Main.User.Name
					lblUserLocation.Text = Main.User.Location
					xui.MsgboxAsync(result.Get("m"), "M E S S A G E")
					BtnEdit.Text = "E D I T"
					BtnCancel.Visible = False
					txtUserName.mBase.Visible = False
					'txtUserName.TextField.Visible = False
					txtUserLocation.mBase.Visible = False
					'txtUserLocation.TextField.Visible = False
					lblUserName.Visible = True
					lblUserLocation.Visible = True
				Else
					xui.MsgboxAsync(LastException, "E R R O R")
				End If
			End If
		Else
			ShowConnectionError(job.ErrorMessage)
		End If
	Catch
		Log("[B4XPageUserProfile] UpdateProfile: " & LastException.Message)
		xui.MsgboxAsync("Failed to update profile", "E R R O R")
	End Try
	job.Release
End Sub