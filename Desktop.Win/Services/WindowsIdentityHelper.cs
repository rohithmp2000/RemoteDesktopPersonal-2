using System.Runtime.Versioning;
using System.Security.Principal;

namespace Remotely.Desktop.Win.Services;

[SupportedOSPlatform("windows")]
public static class WindowsIdentityHelper
{
    /// <summary>
    /// Checks if the current process is running with administrator privileges.
    /// </summary>
    /// <returns>True if running as administrator, false otherwise.</returns>
    public static bool IsRunningAsAdministrator()
    {
        try
        {
            using var identity = WindowsIdentity.GetCurrent();
            var principal = new WindowsPrincipal(identity);
            return principal.IsInRole(WindowsBuiltInRole.Administrator);
        }
        catch
        {
            // If we can't determine, assume not admin
            return false;
        }
    }

    /// <summary>
    /// Gets a user-friendly message explaining administrator privilege status.
    /// </summary>
    /// <returns>Status message for logging or display.</returns>
    public static string GetPrivilegeStatusMessage()
    {
        return IsRunningAsAdministrator()
            ? "Running with administrator privileges."
            : "Running without administrator privileges. Some features (like Block Remote Input) may not work.";
    }
}
