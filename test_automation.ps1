$login = Invoke-RestMethod -Uri "http://localhost:5136/api/auth/login" -Method Post -ContentType "application/json" -Body '{"email":"admin@hireflow.com","password":"Admin@HireFlow2026!"}'
$res = Invoke-RestMethod -Uri "http://localhost:5136/api/admin/automation/trigger" -Method Post -Headers @{ Authorization = "Bearer $($login.token)" }
Write-Host "Automation trigger response:"
$res | ConvertTo-Json -Depth 5
