B4A=true
Group=Main
ModulesStructureVersion=1
Type=StaticCode
Version=12.8
@EndOfDesignText@
'Code module
Sub Process_Globals

End Sub

' // Source: http://www.b4x.com/android/forum/threads/validate-a-correctly-formatted-email-address.39803/
Sub ValidateEmail(EmailAddress As String) As Boolean
	Dim MatchEmail As Matcher = Regex.Matcher("^(?i)[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])$", EmailAddress)
 
	If MatchEmail.Find = True Then
		'Log(MatchEmail.Match)
		Return True
	Else
		'Log("Oops, please double check your email address...")
		Return False
	End If
End Sub