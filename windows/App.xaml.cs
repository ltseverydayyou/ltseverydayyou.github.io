using System.IO;
using System.Text;
using System.Windows;
using System.Windows.Threading;

namespace LtseverydayyouHub;

public partial class App : Application
{
    private static readonly string LogDirectory = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "ltseverydayyou Hub");

    private static readonly string CrashLogPath = Path.Combine(LogDirectory, "crash.log");

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        DispatcherUnhandledException += OnDispatcherUnhandledException;
        AppDomain.CurrentDomain.UnhandledException += OnDomainUnhandledException;
        TaskScheduler.UnobservedTaskException += OnUnobservedTaskException;

        try
        {
            Directory.CreateDirectory(LogDirectory);
            File.AppendAllText(CrashLogPath,
                $"\n[{DateTimeOffset.Now:O}] Starting ltseverydayyou Hub {Environment.ProcessPath}\n");

            var window = new MainWindow();
            MainWindow = window;
            window.Show();
        }
        catch (Exception ex)
        {
            ShowFatalStartupError(ex);
            Shutdown(-1);
        }
    }

    private static void OnDispatcherUnhandledException(object sender, DispatcherUnhandledExceptionEventArgs e)
    {
        WriteCrash("DispatcherUnhandledException", e.Exception);
        MessageBox.Show(
            "ltseverydayyou Hub hit an unexpected error and recovered it.\n\n" +
            "A diagnostic log was written to:\n" + CrashLogPath + "\n\n" +
            e.Exception.Message,
            "ltseverydayyou Hub",
            MessageBoxButton.OK,
            MessageBoxImage.Error);
        e.Handled = true;
    }

    private static void OnDomainUnhandledException(object sender, UnhandledExceptionEventArgs e)
    {
        if (e.ExceptionObject is Exception ex)
            WriteCrash("AppDomain.UnhandledException", ex);
        else
            WriteText("AppDomain.UnhandledException", e.ExceptionObject?.ToString() ?? "Unknown fatal error");
    }

    private static void OnUnobservedTaskException(object? sender, UnobservedTaskExceptionEventArgs e)
    {
        WriteCrash("TaskScheduler.UnobservedTaskException", e.Exception);
        e.SetObserved();
    }

    private static void ShowFatalStartupError(Exception ex)
    {
        WriteCrash("Fatal startup error", ex);
        MessageBox.Show(
            "ltseverydayyou Hub could not finish starting.\n\n" +
            "A diagnostic log was written to:\n" + CrashLogPath + "\n\n" +
            ex.GetType().Name + ": " + ex.Message,
            "ltseverydayyou Hub startup error",
            MessageBoxButton.OK,
            MessageBoxImage.Error);
    }

    public static void WriteCrash(string stage, Exception ex)
    {
        WriteText(stage, ex.ToString());
    }

    public static void WriteText(string stage, string text)
    {
        try
        {
            Directory.CreateDirectory(LogDirectory);
            var builder = new StringBuilder();
            builder.AppendLine();
            builder.Append('[').Append(DateTimeOffset.Now.ToString("O")).Append("] ").AppendLine(stage);
            builder.AppendLine(text);
            File.AppendAllText(CrashLogPath, builder.ToString());
        }
        catch
        {
        }
    }
}
