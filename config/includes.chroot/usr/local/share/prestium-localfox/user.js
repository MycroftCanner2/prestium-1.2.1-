// Prestium local-only Firefox (copied into the profile on every launch).
// Firefox defaults otherwise; the firewall is what keeps this browser local.
user_pref("browser.startup.homepage", "http://127.0.0.1:7070/");
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.search.update", false);
user_pref("browser.urlbar.suggest.searches", false);
user_pref("network.captive-portal-service.enabled", false);
user_pref("network.predictor.enabled", false);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("services.settings.server", "http://127.0.0.1:9/");
user_pref("media.gmp-manager.url", "http://127.0.0.1:9/");
user_pref("extensions.update.enabled", false);
user_pref("extensions.systemAddon.update.enabled", false);
user_pref("app.normandy.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("signon.rememberSignons", false);
