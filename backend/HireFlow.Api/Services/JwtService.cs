using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using HireFlow.Api.Entities;
using Microsoft.IdentityModel.Tokens;

namespace HireFlow.Api.Services;

public interface IJwtService
{
    (string Token, int ExpiryMinutes) GenerateToken(User user);
}

public class JwtService : IJwtService
{
    private readonly IConfiguration _configuration;

    public JwtService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public (string Token, int ExpiryMinutes) GenerateToken(User user)
    {
        var secret = _configuration["Jwt:Secret"] ?? "HireFlow_Super_Secure_Secret_Key_For_Development_32_Chars_Long";
        var issuer = _configuration["Jwt:Issuer"] ?? "HireFlowApi";
        var audience = _configuration["Jwt:Audience"] ?? "HireFlowApp";
        var expiryMinutes = int.TryParse(_configuration["Jwt:ExpiryMinutes"], out var exp) ? exp : 1440; // Default 24h

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new(ClaimTypes.Email, user.Email),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.Role, user.Role),
            new("isActive", user.IsActive.ToString())
        };

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(expiryMinutes),
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = credentials
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);

        return (tokenHandler.WriteToken(token), expiryMinutes);
    }
}

