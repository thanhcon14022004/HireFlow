$employerLogin = Invoke-RestMethod -Uri 'http://localhost:5136/api/auth/login' -Method Post -ContentType 'application/json' -Body '{"email":"employer@hireflow.com","password":"Employer@123!"}'
$empToken = $employerLogin.token

# Test 1: Invalid budget Min > Max
try {
    Invoke-RestMethod -Uri 'http://localhost:5136/api/projects' -Method Post -Headers @{ Authorization = "Bearer $empToken" } -ContentType 'application/json' -Body '{"title":"Test Min Max","description":"Desc","budgetMin":10000000,"budgetMax":5000000}'
    Write-Host 'FAILED: Budget validation was not triggered' -ForegroundColor Red
} catch {
    Write-Host "PASSED 1: Min > Max budget blocked: $($_.Exception.Message)" -ForegroundColor Green
}

# Test 2: Invalid deadline in the past
try {
    Invoke-RestMethod -Uri 'http://localhost:5136/api/projects' -Method Post -Headers @{ Authorization = "Bearer $empToken" } -ContentType 'application/json' -Body '{"title":"Test Past Deadline","description":"Desc","deadline":"2020-01-01T00:00:00Z"}'
    Write-Host 'FAILED: Past deadline validation was not triggered' -ForegroundColor Red
} catch {
    Write-Host "PASSED 2: Past deadline blocked: $($_.Exception.Message)" -ForegroundColor Green
}

# Test 3: Self-report user
try {
    $empId = $employerLogin.user.userId
    $body = @{ targetType = "User"; targetId = $empId; reason = "Self report" } | ConvertTo-Json
    Invoke-RestMethod -Uri 'http://localhost:5136/api/reports' -Method Post -Headers @{ Authorization = "Bearer $empToken" } -ContentType 'application/json' -Body $body
    Write-Host 'FAILED: Self report was not triggered' -ForegroundColor Red
} catch {
    Write-Host "PASSED 3: Self-report blocked: $($_.Exception.Message)" -ForegroundColor Green
}

# Test 4: Invalid report target type
try {
    Invoke-RestMethod -Uri 'http://localhost:5136/api/reports' -Method Post -Headers @{ Authorization = "Bearer $empToken" } -ContentType 'application/json' -Body '{"targetType":"Hacker","targetId":999,"reason":"Hacking"}'
    Write-Host 'FAILED: Invalid report target type was not triggered' -ForegroundColor Red
} catch {
    Write-Host "PASSED 4: Invalid report target type blocked: $($_.Exception.Message)" -ForegroundColor Green
}
