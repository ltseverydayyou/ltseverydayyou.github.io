package ltseverydayyou.dungeon;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class MainActivity extends Activity {
    private static final String HOME_URL = "https://ltseverydayyou.github.io/";
    private static final String RELEASE_API = "https://api.github.com/repos/ltseverydayyou/ltseverydayyou.github.io/releases/tags/dungeon-1.1";
    private static final String RELEASE_PAGE = "https://github.com/ltseverydayyou/ltseverydayyou.github.io/releases/tag/dungeon-1.1";
    private static final String PROFILE_ALIAS = "ltseverydayyou.dungeon.ProfileIcon";
    private static final String DARK_ALIAS = "ltseverydayyou.dungeon.DarkIcon";
    private static final String LIGHT_ALIAS = "ltseverydayyou.dungeon.LightIcon";
    private WebView webView;

    @SuppressLint({"SetJavaScriptEnabled", "AddJavascriptInterface"})
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);

        webView = new WebView(this);
        webView.setAlpha(0f);
        webView.animate().alpha(1f).setDuration(360).start();
        setContentView(webView);

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setCacheMode(WebSettings.LOAD_DEFAULT);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);

        webView.addJavascriptInterface(new HubBridge(), "HubApp");
        webView.setWebChromeClient(new WebChromeClient());
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                String scheme = uri.getScheme();
                if ("http".equalsIgnoreCase(scheme) || "https".equalsIgnoreCase(scheme)) {
                    return false;
                }
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, uri));
                } catch (ActivityNotFoundException ignored) {
                }
                return true;
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                injectHubEnhancements(view);
            }
        });

        if (savedInstanceState == null) {
            webView.loadUrl(HOME_URL + "?hub_app=1&ts=" + System.currentTimeMillis());
        } else {
            webView.restoreState(savedInstanceState);
        }

        checkForAppUpdate();
    }

    private void checkForAppUpdate() {
        new Thread(() -> {
            HttpURLConnection connection = null;
            try {
                connection = (HttpURLConnection) new URL(RELEASE_API).openConnection();
                connection.setConnectTimeout(7000);
                connection.setReadTimeout(7000);
                connection.setRequestProperty("Accept", "application/vnd.github+json");
                connection.setRequestProperty("User-Agent", "ltseverydayyou-Hub-Android");

                try (BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()))) {
                    StringBuilder json = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) json.append(line);
                    String body = new JSONObject(json.toString()).optString("body", "");
                    Matcher matcher = Pattern.compile("Android build:\\s*(\\d+)").matcher(body);
                    if (!matcher.find()) return;

                    long remoteBuild = Long.parseLong(matcher.group(1));
                    long localBuild = getInstalledVersionCode();
                    if (remoteBuild > localBuild) {
                        runOnUiThread(() -> showUpdateDialog("A newer Android build is available.", remoteBuild, localBuild));
                    }
                }
            } catch (Exception ignored) {
            } finally {
                if (connection != null) connection.disconnect();
            }
        }, "HubUpdateCheck").start();
    }

    private long getInstalledVersionCode() {
        try {
            PackageInfo info = getPackageManager().getPackageInfo(getPackageName(), 0);
            if (android.os.Build.VERSION.SDK_INT >= 28) return info.getLongVersionCode();
            return info.versionCode;
        } catch (Exception ignored) {
            return 0;
        }
    }

    private void showUpdateDialog(String message, long remoteBuild, long localBuild) {
        if (isFinishing() || isDestroyed()) return;
        new AlertDialog.Builder(this)
                .setTitle("ltseverydayyou Hub update")
                .setMessage(message + "\n\nInstalled build: " + localBuild + "\nLatest build: " + remoteBuild)
                .setNegativeButton("Later", null)
                .setPositiveButton("View update", (dialog, which) -> {
                    try {
                        startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(RELEASE_PAGE)));
                    } catch (ActivityNotFoundException ignored) {
                    }
                })
                .show();
    }

    private void injectHubEnhancements(WebView view) {
        String js = "(function(){if(window.__hubEnhanced)return;window.__hubEnhanced=true;" +
                "const s=document.createElement('style');s.textContent=`" +
                "html{scroll-behavior:smooth}body{animation:hubFade .42s ease both}" +
                "*:not(html):not(body){transition:opacity .18s ease,transform .18s ease,filter .18s ease,background-color .22s ease,border-color .22s ease,box-shadow .22s ease!important}" +
                "a,button,[role=button],input,select,textarea,.card,[class*=card],[class*=button],[class*=item],[class*=tile]{will-change:transform}" +
                "a:active,button:active,[role=button]:active{transform:scale(.965)!important}" +
                "img,video{animation:hubPop .32s ease both}" +
                "dialog,[role=dialog],[class*=modal],[class*=popup],[class*=menu]{animation:hubPop .22s ease both}" +
                "@keyframes hubFade{from{opacity:0}to{opacity:1}}@keyframes hubPop{from{opacity:0;transform:translateY(7px) scale(.985)}to{opacity:1;transform:none}}" +
                "#hubAppSettings{position:fixed;left:14px;bottom:14px;right:auto;z-index:2147483647;width:46px;height:46px;border:0;border-radius:15px;background:rgba(20,20,24,.88);color:white;font-size:22px;box-shadow:0 8px 28px rgba(0,0,0,.32);backdrop-filter:blur(12px)}" +
                "#hubIconPanel{position:fixed;left:14px;bottom:70px;right:auto;z-index:2147483647;padding:10px;border-radius:16px;background:rgba(20,20,24,.94);color:white;box-shadow:0 10px 32px rgba(0,0,0,.38);font:14px system-ui;display:none;animation:hubPop .2s ease both}" +
                "#hubIconPanel button{display:block;width:180px;margin:5px 0;padding:10px 12px;border:0;border-radius:11px;background:#2b2b31;color:white;text-align:left}`;document.head.appendChild(s);" +
                "const panel=document.createElement('div');panel.id='hubIconPanel';panel.innerHTML='<b>App icon</b><button data-i=profile>GitHub profile</button><button data-i=dark>Hub Dark</button><button data-i=light>Hub Light</button>';" +
                "const gear=document.createElement('button');gear.id='hubAppSettings';gear.textContent='⚙';gear.setAttribute('aria-label','Hub app settings');" +
                "gear.onclick=()=>panel.style.display=panel.style.display==='block'?'none':'block';panel.onclick=e=>{const b=e.target.closest('button[data-i]');if(!b)return;try{HubApp.setAppIcon(b.dataset.i)}catch(_){ }panel.style.display='none'};" +
                "document.body.append(panel,gear);" +
                "document.addEventListener('pointerdown',e=>{const t=e.target.closest('a,button,[role=button]');if(!t)return;t.animate([{filter:'brightness(1)'},{filter:'brightness(1.18)'},{filter:'brightness(1)'}],{duration:260,easing:'ease-out'})},{passive:true});" +
                "new MutationObserver(ms=>{for(const m of ms)for(const n of m.addedNodes)if(n.nodeType===1)n.animate([{opacity:0,transform:'translateY(4px)'},{opacity:1,transform:'none'}],{duration:220,easing:'ease-out'})}).observe(document.documentElement,{childList:true,subtree:true});" +
                "})();";
        view.evaluateJavascript(js, null);
    }

    public final class HubBridge {
        @JavascriptInterface
        public void setAppIcon(String icon) {
            runOnUiThread(() -> switchIcon(icon));
        }
    }

    private void switchIcon(String icon) {
        String wanted = PROFILE_ALIAS;
        if ("dark".equalsIgnoreCase(icon)) wanted = DARK_ALIAS;
        if ("light".equalsIgnoreCase(icon)) wanted = LIGHT_ALIAS;

        PackageManager pm = getPackageManager();
        setAlias(pm, PROFILE_ALIAS, PROFILE_ALIAS.equals(wanted));
        setAlias(pm, DARK_ALIAS, DARK_ALIAS.equals(wanted));
        setAlias(pm, LIGHT_ALIAS, LIGHT_ALIAS.equals(wanted));
    }

    private void setAlias(PackageManager pm, String alias, boolean enabled) {
        pm.setComponentEnabledSetting(
                new ComponentName(this, alias),
                enabled ? PackageManager.COMPONENT_ENABLED_STATE_ENABLED : PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
        );
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        webView.saveState(outState);
        super.onSaveInstanceState(outState);
    }

    @Override
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }

    @Override
    protected void onDestroy() {
        if (webView != null) {
            webView.stopLoading();
            webView.removeJavascriptInterface("HubApp");
            webView.setWebChromeClient(null);
            webView.setWebViewClient(null);
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
