$baseUrl = "http://localhost:5136/api"

Write-Host "=========================================================="
Write-Host "             HIREFLOW EDGE CASE TEST SUITE                "
Write-Host "=========================================================="

# Test 1: Freelancer Login
Write-Host "`n[1] Testing Freelancer Login..."
$freeLogin = @{
    email = "freelancer@hireflow.com"
    password = "Freelancer@123!"
} | ConvertTo-Json
$freeRes = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body $freeLogin
$freeToken = $freeRes.token
$freeHeaders = @{ Authorization = "Bearer " + $freeToken }
Write-Host "-> Success! Freelancer UserId=$($freeRes.user.userId), Role=$($freeRes.user.role), Balance=$($freeRes.user.creditBalance)"

# Test 2: Employer Login
Write-Host "`n[2] Testing Employer Login..."
$empLogin = @{
    email = "employer@hireflow.com"
    password = "Employer@123!"
} | ConvertTo-Json
$empRes = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body $empLogin
$empToken = $empRes.token
$empHeaders = @{ Authorization = "Bearer " + $empToken }
Write-Host "-> Success! Employer UserId=$($empRes.user.userId), Role=$($empRes.user.role), Balance=$($empRes.user.creditBalance)"

# Test 3: Public Admin Registration (MUST FAIL WITH 403 Forbidden)
Write-Host "`n[3] Testing Edge Case: Public Admin Registration..."
$adminRegBody = @{
    fullName = "Malicious Admin"
    email = "fakeadmin_$(Get-Random)@test.com"
    password = "Password@123!"
    role = "Admin"
} | ConvertTo-Json
try {
    $res = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -ContentType "application/json" -Body $adminRegBody
    Write-Host "-> FAILED! Admin registration should have been rejected but succeeded." -ForegroundColor Red
} catch {
    Write-Host "-> PASSED! Correctly rejected with: $($_.Exception.Message)" -ForegroundColor Green
}

# Test 4: Suspended User Login
Write-Host "`n[4] Testing Edge Case: Suspended User Login Blocked..."
$adminLogin = @{
    email = "admin@hireflow.com"
    password = "Admin@HireFlow2026!"
} | ConvertTo-Json
$adminRes = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body $adminLogin
$adminToken = $adminRes.token
$adminHeaders = @{ Authorization = "Bearer " + $adminToken }
Write-Host "-> Admin Login Success. Token obtained."

$tempEmail = "test_suspend_$(Get-Random)@hireflow.com"
$tempReg = @{
    fullName = "Temp User"
    email = $tempEmail
    password = "Password@123!"
    role = "Freelancer"
} | ConvertTo-Json
$regRes = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -ContentType "application/json" -Body $tempReg
$tempUserId = $regRes.user.userId
Write-Host "-> Created temp user: $tempEmail (Id: $tempUserId)"

$suspendBody = @{ isActive = $false } | ConvertTo-Json
$suspendRes = Invoke-RestMethod -Uri "$baseUrl/admin/users/$tempUserId/status" -Method Patch -Headers $adminHeaders -ContentType "application/json" -Body $suspendBody
Write-Host "-> Admin suspended user: $($suspendRes.message)"

try {
    $loginSuspended = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body (@{ email = $tempEmail; password = "Password@123!" } | ConvertTo-Json)
    Write-Host "-> FAILED! Suspended user was able to login." -ForegroundColor Red
} catch {
    Write-Host "-> PASSED! Suspended user login blocked: $($_.Exception.Message)" -ForegroundColor Green
}

# Test 5: Unlock Employer Contact Idempotency (4 credits first, 0 credits second)
Write-Host "`n[5] Testing Edge Case: Unlock Contact Idempotency..."
$projectsRes = Invoke-RestMethod -Uri "$baseUrl/projects" -Method Get
$project = $projectsRes.items[0]
$projectId = $project.projectId

# Check initial balance
$balBefore = (Invoke-RestMethod -Uri "$baseUrl/credits/balance" -Method Get -Headers $freeHeaders).balance
Write-Host "-> ProjectId=$projectId, Freelancer balance: $balBefore credits"

# Unlock 1st time
$unlock1 = Invoke-RestMethod -Uri "$baseUrl/projects/$projectId/contact-unlock" -Method Post -Headers $freeHeaders
$balAfter1 = (Invoke-RestMethod -Uri "$baseUrl/credits/balance" -Method Get -Headers $freeHeaders).balance
Write-Host "-> Unlock 1: Contact=$($unlock1.contactEmail), Balance After 1: $balAfter1 credits"

# Unlock 2nd time (must charge 0 credits)
$unlock2 = Invoke-RestMethod -Uri "$baseUrl/projects/$projectId/contact-unlock" -Method Post -Headers $freeHeaders
$balAfter2 = (Invoke-RestMethod -Uri "$baseUrl/credits/balance" -Method Get -Headers $freeHeaders).balance
Write-Host "-> Unlock 2: Contact=$($unlock2.contactEmail), Balance After 2: $balAfter2 credits"

if ($balAfter1 -eq $balAfter2) {
    Write-Host "-> PASSED! Re-unlock charged 0 additional credits (idempotent permanent unlock)." -ForegroundColor Green
} else {
    Write-Host "-> FAILED! Charged extra credits on second attempt." -ForegroundColor Red
}

# Test 6: Fake PDF upload check (Magic bytes check)
Write-Host "`n[6] Testing Edge Case: CV Upload Magic Bytes Validation..."
$fakePdfPath = "$PSScriptRoot\fake.pdf"
[System.IO.File]::WriteAllText($fakePdfPath, "This is plain text, not a valid PDF file format!")
try {
    $boundary = [System.Guid]::NewGuid().ToString()
    $fileBytes = [System.IO.File]::ReadAllBytes($fakePdfPath)
    $LF = "`r`n"
    $bodyParts = (
        "--$boundary$LF" +
        "Content-Disposition: form-data; name=`"file`"; filename=`"fake.pdf`"$LF" +
        "Content-Type: application/pdf$LF$LF"
    )
    $endBoundary = "$LF--$boundary--$LF"
    $enc = [System.Text.Encoding]::UTF8
    $combinedBytes = $enc.GetBytes($bodyParts) + $fileBytes + $enc.GetBytes($endBoundary)
    
    $req = [System.Net.HttpWebRequest]::Create("$baseUrl/documents/cv")
    $req.Method = "POST"
    $req.Headers["Authorization"] = "Bearer " + $freeToken
    $req.ContentType = "multipart/form-data; boundary=$boundary"
    $req.ContentLength = $combinedBytes.Length
    $stream = $req.GetRequestStream()
    $stream.Write($combinedBytes, 0, $combinedBytes.Length)
    $stream.Close()
    
    $resp = $req.GetResponse()
    Write-Host "-> FAILED! Fake PDF was accepted." -ForegroundColor Red
} catch [System.Net.WebException] {
    $respStream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($respStream)
    $errorContent = $reader.ReadToEnd()
    Write-Host "-> PASSED! Fake PDF rejected by server magic bytes validation: $errorContent" -ForegroundColor Green
} finally {
    if (Test-Path $fakePdfPath) { Remove-Item $fakePdfPath }
}

# Test 7: Duplicate Application Block (Unique FreelancerId + ProjectId)
Write-Host "`n[7] Testing Edge Case: Duplicate Project Application..."
# First upload a valid minimal PDF
$validPdfBytes = [System.Text.Encoding]::ASCII.GetBytes("%PDF-1.4 valid test pdf format with magic header %%EOF")
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"
$bodyParts = (
    "--$boundary$LF" +
    "Content-Disposition: form-data; name=`"file`"; filename=`"my_cv.pdf`"$LF" +
    "Content-Type: application/pdf$LF$LF"
)
$endBoundary = "$LF--$boundary--$LF"
$enc = [System.Text.Encoding]::UTF8
$combinedBytes = $enc.GetBytes($bodyParts) + $validPdfBytes + $enc.GetBytes($endBoundary)

$req = [System.Net.HttpWebRequest]::Create("$baseUrl/documents/cv")
$req.Method = "POST"
$req.Headers["Authorization"] = "Bearer " + $freeToken
$req.ContentType = "multipart/form-data; boundary=$boundary"
$req.ContentLength = $combinedBytes.Length
$stream = $req.GetRequestStream()
$stream.Write($combinedBytes, 0, $combinedBytes.Length)
$stream.Close()
$resp = $req.GetResponse()
$reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
$cvJson = $reader.ReadToEnd() | ConvertFrom-Json
$docId = $cvJson.documentId
Write-Host "-> Uploaded valid CV: DocumentId=$docId"

# Apply to Project first time (if not yet applied)
$appBody = @{
    documentId = $docId
    coverLetter = "Toi muon nop ho so."
} | ConvertTo-Json

try {
    $appRes1 = Invoke-RestMethod -Uri "$baseUrl/projects/$projectId/applications" -Method Post -Headers $freeHeaders -ContentType "application/json" -Body $appBody
    Write-Host "-> Initial Application succeeded: Id=$($appRes1.applicationId)"
} catch {
    Write-Host "-> Freelancer already applied to ProjectId=$projectId."
}

# Apply to SAME Project second time (MUST FAIL WITH 409 Conflict)
try {
    $appRes2 = Invoke-RestMethod -Uri "$baseUrl/projects/$projectId/applications" -Method Post -Headers $freeHeaders -ContentType "application/json" -Body $appBody
    Write-Host "-> FAILED! Duplicate application was allowed!" -ForegroundColor Red
} catch {
    Write-Host "-> PASSED! Duplicate application blocked correctly: $($_.Exception.Message)" -ForegroundColor Green
}

# Test 8: Employer Project Publishing (5 credits deducted)
Write-Host "`n[8] Testing Employer Project Publishing (-5 credits)..."
$empBalBefore = (Invoke-RestMethod -Uri "$baseUrl/credits/balance" -Method Get -Headers $empHeaders).balance
Write-Host "-> Employer balance before publish: $empBalBefore credits"

$newProjBody = @{
    title = "Tuyen Senior Cloud Architect $(Get-Random)"
    description = "Thiet ke va trien khai kien truc Microservices tren Azure"
    skills = @("Azure", "Kubernetes", "DevOps")
    budgetMin = 40000000
    budgetMax = 60000000
    experienceLevel = "Lead"
} | ConvertTo-Json

$pubRes = Invoke-RestMethod -Uri "$baseUrl/projects" -Method Post -Headers $empHeaders -ContentType "application/json" -Body $newProjBody
Write-Host "-> Published ProjectId=$($pubRes.projectId), Message=$($pubRes.message)"
$empBalAfter = (Invoke-RestMethod -Uri "$baseUrl/credits/balance" -Method Get -Headers $empHeaders).balance
Write-Host "-> Employer balance after publish: $empBalAfter credits (Charged $($empBalBefore - $empBalAfter) credits)"
if ($empBalBefore - $empBalAfter -eq 5) {
    Write-Host "-> PASSED! Deducted exactly 5 credits for publishing project." -ForegroundColor Green
} else {
    Write-Host "-> FAILED! Expected 5 credits deduction." -ForegroundColor Red
}

# Test 9: Credit Purchase Flow
Write-Host "`n[9] Testing Credit Purchase Flow (Simulated Gateway)..."
$packages = Invoke-RestMethod -Uri "$baseUrl/credits/packages" -Method Get
$pkg = $packages[0]
Write-Host "-> Purchasing Package: $($pkg.name) (Credits: +$($pkg.creditAmount), Price: $($pkg.priceAmount) $($pkg.currencyCode))"

$purchaseReq = @{
    creditPackageId = $pkg.creditPackageId
} | ConvertTo-Json

$purchaseRes = Invoke-RestMethod -Uri "$baseUrl/credits/purchases" -Method Post -Headers $freeHeaders -ContentType "application/json" -Body $purchaseReq
$purchaseId = $purchaseRes.creditPurchaseId
Write-Host "-> Purchase created: PurchaseId=$purchaseId, Ref=$($purchaseRes.providerReference)"

# Complete payment via simulate-success endpoint
$completeRes = Invoke-RestMethod -Uri "$baseUrl/credits/purchases/$purchaseId/simulate-success" -Method Post -Headers $freeHeaders
Write-Host "-> Payment completed! Status=$($completeRes.status), New Balance=$($completeRes.newBalance) credits"
Write-Host "-> PASSED! Credit purchase successfully processed." -ForegroundColor Green

# Test 10: Credit Transactions History
Write-Host "`n[10] Testing Credit Transactions History..."
$txHistory = Invoke-RestMethod -Uri "$baseUrl/credits/transactions" -Method Get -Headers $freeHeaders
Write-Host "-> Freelancer Transactions count: $($txHistory.Count)"
foreach ($tx in $txHistory | Select-Object -First 5) {
    Write-Host "   - TxId: $($tx.transactionId), Type: $($tx.transactionType), Amount: $($tx.amount), Desc: $($tx.description)"
}

Write-Host "`n=========================================================="
Write-Host "           ALL 10 EDGE CASE TESTS COMPLETED               "
Write-Host "=========================================================="
