$login = Invoke-RestMethod -Uri "http://localhost:5136/api/auth/login" -Method Post -ContentType "application/json" -Body '{"email":"freelancer@hireflow.com","password":"Freelancer@123!"}'
$token = $login.token
$initBalance = $login.user.creditBalance
Write-Host "Initial Freelancer Balance: $initBalance credits" -ForegroundColor Cyan

# 1. Create MoMo Purchase
$body = @{ creditPackageId = 1; paymentProvider = "MoMo" } | ConvertTo-Json
$purchase = Invoke-RestMethod -Uri "http://localhost:5136/api/credits/purchases" -Method Post -Headers @{ Authorization = "Bearer $token" } -ContentType "application/json" -Body $body

Write-Host "Purchase Created: Id=$($purchase.creditPurchaseId), Provider=$($purchase.paymentProvider), OrderCode=$($purchase.orderCode)" -ForegroundColor Green
Write-Host "MoMo Phone: $($purchase.moMoPhoneNumber), QrUrl: $($purchase.qrImageUrl)" -ForegroundColor Yellow
Write-Host "MoMo Deeplink: $($purchase.deeplink)" -ForegroundColor Yellow

if ($purchase.paymentProvider -ne "MoMo") {
    throw "Payment provider is not MoMo!"
}

# 2. Check MoMo Status (Pending)
$check1 = Invoke-RestMethod -Uri "http://localhost:5136/api/credits/purchases/$($purchase.creditPurchaseId)/check-momo" -Headers @{ Authorization = "Bearer $token" }
Write-Host "Check 1 Status: $($check1.status) (Expected: Pending)" -ForegroundColor Gray

# 3. Simulate MoMo Payment Success
$sim = Invoke-RestMethod -Uri "http://localhost:5136/api/credits/purchases/$($purchase.creditPurchaseId)/simulate-momo-success" -Method Post -Headers @{ Authorization = "Bearer $token" }
Write-Host "Simulate Result: Status=$($sim.status), CreditsAdded=$($sim.creditsAdded), NewBalance=$($sim.newBalance)" -ForegroundColor Green

# 4. Check MoMo Status (Paid - Idempotent)
$check2 = Invoke-RestMethod -Uri "http://localhost:5136/api/credits/purchases/$($purchase.creditPurchaseId)/check-momo" -Headers @{ Authorization = "Bearer $token" }
Write-Host "Check 2 Status: $($check2.status), NewBalance=$($check2.newBalance)" -ForegroundColor Green

# 5. Verify Wallet Balance
$balRes = Invoke-RestMethod -Uri "http://localhost:5136/api/credits/balance" -Headers @{ Authorization = "Bearer $token" }
Write-Host "Final Balance: $($balRes.balance) credits (Expected: $($initBalance + 10))" -ForegroundColor Cyan

if ($balRes.balance -eq ($initBalance + 10)) {
    Write-Host "SUCCESS! MOMO PAYMENT INTEGRATION VERIFIED END-TO-END!" -ForegroundColor Green
} else {
    throw "Balance mismatch!"
}

