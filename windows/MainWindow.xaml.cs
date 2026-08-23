using Microsoft.Web.WebView2.Core;
using System.Diagnostics;
using System.Text.Json;
using System.Windows;

namespace LtseverydayyouHub;

public partial class MainWindow : Window
{
    private const string HomeUrl = "https://ltseverydayyou.github.io/";

    public MainWindow()
    {
        InitializeComponent();
        Loaded += OnLoaded;
        Opacity = 0;
        BeginAnimation(OpacityProperty, new System.Windows.Media.Animation.DoubleAnimation(0, 1, TimeSpan.FromMilliseconds(320)));
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        await Browser.EnsureCoreWebView2Async();
        Browser.CoreWebView2.Settings.AreDevToolsEnabled = false;
        Browser.CoreWebView2.Settings.AreDefaultContextMenusEnabled = true;
        Browser.CoreWebView2.NavigationCompleted += OnNavigationCompleted;
        Browser.CoreWebView2.WebMessageReceived += OnWebMessageReceived;
        Browser.CoreWebView2.NewWindowRequested += (_, args) =>
        {
            args.Handled = true;
            Process.Start(new ProcessStartInfo(args.Uri) { UseShellExecute = true });
        };
        Browser.Source = new Uri(HomeUrl + "?hub_windows=1&ts=" + DateTimeOffset.UtcNow.ToUnixTimeMilliseconds());
    }

    private async void OnNavigationCompleted(object? sender, CoreWebView2NavigationCompletedEventArgs e)
    {
        if (!e.IsSuccess) return;
        await Browser.CoreWebView2.ExecuteScriptAsync(EnhancementScript);
    }

    private void OnWebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        try
        {
            using var doc = JsonDocument.Parse(e.WebMessageAsJson);
            var root = doc.RootElement;
            if (!root.TryGetProperty("action", out var action)) return;
            switch (action.GetString())
            {
                case "home":
                    Browser.Source = new Uri(HomeUrl + "?hub_windows=1");
                    break;
                case "reload":
                    Browser.Reload();
                    break;
                case "browser":
                    Process.Start(new ProcessStartInfo(Browser.Source?.ToString() ?? HomeUrl) { UseShellExecute = true });
                    break;
            }
        }
        catch
        {
        }
    }

    private const string EnhancementScript = """
(() => {
  if (window.__hubWindowsEnhanced) return;
  window.__hubWindowsEnhanced = true;
  const style = document.createElement('style');
  style.textContent = `
    html{scroll-behavior:smooth}body{animation:hubFade .42s ease both}
    *:not(html):not(body){transition:opacity .18s ease,transform .18s ease,filter .18s ease,background-color .22s ease,border-color .22s ease,box-shadow .22s ease!important}
    a,button,[role=button],input,select,textarea,.card,[class*=card],[class*=button],[class*=item],[class*=tile]{will-change:transform}
    a:active,button:active,[role=button]:active{transform:scale(.965)!important}
    img,video{animation:hubPop .32s ease both}
    dialog,[role=dialog],[class*=modal],[class*=popup],[class*=menu]{animation:hubPop .22s ease both}
    @keyframes hubFade{from{opacity:0}to{opacity:1}}@keyframes hubPop{from{opacity:0;transform:translateY(7px) scale(.985)}to{opacity:1;transform:none}}
    #hubWinSettings{position:fixed;left:14px;bottom:14px;z-index:2147483647;width:46px;height:46px;border:0;border-radius:15px;background:rgba(20,20,24,.9);color:#fff;font-size:22px;box-shadow:0 8px 28px rgba(0,0,0,.32);backdrop-filter:blur(12px)}
    #hubWinPanel{position:fixed;left:14px;bottom:70px;z-index:2147483647;padding:10px;border-radius:16px;background:rgba(20,20,24,.95);color:white;box-shadow:0 10px 32px rgba(0,0,0,.38);font:14px system-ui;display:none;animation:hubPop .2s ease both}
    #hubWinPanel button{display:block;width:180px;margin:5px 0;padding:10px 12px;border:0;border-radius:11px;background:#2b2b31;color:#fff;text-align:left}
  `;
  document.head.appendChild(style);
  const panel = document.createElement('div');
  panel.id = 'hubWinPanel';
  panel.innerHTML = '<b>ltseverydayyou Hub</b><button data-a="home">Home</button><button data-a="reload">Reload</button><button data-a="browser">Open in browser</button>';
  const gear = document.createElement('button');
  gear.id = 'hubWinSettings'; gear.textContent = '⚙'; gear.setAttribute('aria-label','Hub desktop settings');
  gear.onclick = () => panel.style.display = panel.style.display === 'block' ? 'none' : 'block';
  panel.onclick = e => { const b=e.target.closest('button[data-a]'); if(!b)return; chrome.webview.postMessage({action:b.dataset.a}); panel.style.display='none'; };
  document.body.append(panel, gear);
  document.addEventListener('pointerdown', e => { const t=e.target.closest('a,button,[role=button]'); if(!t)return; t.animate([{filter:'brightness(1)'},{filter:'brightness(1.18)'},{filter:'brightness(1)'}],{duration:260,easing:'ease-out'}); }, {passive:true});
  new MutationObserver(ms => { for(const m of ms) for(const n of m.addedNodes) if(n.nodeType===1) n.animate([{opacity:0,transform:'translateY(4px)'},{opacity:1,transform:'none'}],{duration:220,easing:'ease-out'}); }).observe(document.documentElement,{childList:true,subtree:true});
})();
""";
}
