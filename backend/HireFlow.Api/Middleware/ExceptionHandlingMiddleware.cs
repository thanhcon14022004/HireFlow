using System.Net;
using System.Text.Json;
using HireFlow.Api.DTOs;

namespace HireFlow.Api.Middleware;

public class AppException : Exception
{
    public HttpStatusCode StatusCode { get; }
    public string Code { get; }

    public AppException(string message, string code = "BAD_REQUEST", HttpStatusCode statusCode = HttpStatusCode.BadRequest)
        : base(message)
    {
        Code = code;
        StatusCode = statusCode;
    }
}

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;
    private readonly IWebHostEnvironment _env;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger, IWebHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (AppException appEx)
        {
            _logger.LogWarning("AppException: [{Code}] {Message}", appEx.Code, appEx.Message);
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)appEx.StatusCode;

            var errorResponse = new ErrorResponse(appEx.Code, appEx.Message);
            await context.Response.WriteAsync(JsonSerializer.Serialize(errorResponse));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled server error occurred: {Message}", ex.Message);
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;

            var message = _env.IsDevelopment()
                ? $"Internal server error: {ex.Message}"
                : "Đã xảy ra lỗi hệ thống, vui lòng thử lại sau.";

            var errorResponse = new ErrorResponse("INTERNAL_SERVER_ERROR", message);
            await context.Response.WriteAsync(JsonSerializer.Serialize(errorResponse));
        }
    }
}
