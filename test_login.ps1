$f = Invoke-RestMethod -Uri 'http://localhost:5136/api/auth/login' -Method Post -ContentType 'application/json' -Body '{"email":"freelancer@hireflow.com","password":"Freelancer@123!"}'
Write-Host "Freelancer Login: $($f.user.fullName) - Role: $($f.user.role) - Balance: $($f.user.creditBalance)"

$e = Invoke-RestMethod -Uri 'http://localhost:5136/api/auth/login' -Method Post -ContentType 'application/json' -Body '{"email":"employer@hireflow.com","password":"Employer@123!"}'
Write-Host "Employer Login: $($e.user.fullName) - Role: $($e.user.role) - Balance: $($e.user.creditBalance)"

$a = Invoke-RestMethod -Uri 'http://localhost:5136/api/auth/login' -Method Post -ContentType 'application/json' -Body '{"email":"admin@hireflow.com","password":"Admin@HireFlow2026!"}'
Write-Host "Admin Login: $($a.user.fullName) - Role: $($a.user.role) - Balance: $($a.user.creditBalance)"

