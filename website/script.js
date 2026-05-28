const dictionary = {
  zh: {
    metaTitle: "PastePaw - FuFu 的剪贴板小窝",
    metaDescription: "PastePaw 是一款可爱的 macOS 剪贴板历史工具，帮你保存最近复制过的文字和图片。",
    brandAria: "PastePaw 首页",
    navAria: "主要导航",
    navFeatures: "功能",
    navInstall: "安装",
    navMoreApps: "更多应用",
    navPrivacy: "隐私",
    navCta: "本地运行",
    softLabel: "FuFu keeps your clipboard cozy",
    heroTitle: "可爱的 macOS 剪贴板历史工具",
    heroText: "PastePaw 会在后台记录你最近复制的文字和图片。需要找回内容时，从菜单栏打开，搜索、置顶、删除，或一键复制回剪贴板。",
    primaryCta: "本地运行 PastePaw",
    secondaryCta: "查看安装方式",
    heroArtAria: "PastePaw 应用预览",
    appIconAlt: "PastePaw App 图标",
    speechTitle: "FuFu 已准备好",
    speechText: "最近复制的内容会安静地待在这里。",
    featuresTitle: "把复制过的内容找回来",
    featuresText: "轻量、直观、本地保存，适合每天反复复制文字和图片的工作流。",
    featureOneTitle: "文字和图片历史",
    featureOneText: "自动记录最近复制的文字和原图质量图片，按时间倒序展示。",
    featureTwoTitle: "置顶常用内容",
    featureTwoText: "重要内容可以置顶保存，不会跟随普通历史一起过期。",
    featureThreeTitle: "快速搜索",
    featureThreeText: "在主窗口中搜索文字历史，快速定位刚刚复制过的片段。",
    featureFourTitle: "菜单栏快捷复制",
    featureFourText: "直接从菜单栏选择最近历史，点击后复制回系统剪贴板。",
    installTitle: "本地运行",
    installText: "当前项目已经包含 macOS 应用和静态网页。使用项目脚本可以构建并打开 PastePaw。",
    privacyTitle: "只在你的 Mac 上保存",
    privacyText: "PastePaw 的历史记录保存在本机 Application Support，不同步、不上传。你可以设置保留天数，并随时清空非置顶记录。",
    moreAppsTitle: "想看看更多 FuFu 应用？",
    moreAppsText: "FuFu 也在其他小工具里陪你工作和休息。看看 SlackerBuddy，让它在桌面上提醒你喝水、休息和放松。",
    slackerBuddyAria: "打开 SlackerBuddy 网站",
    slackerBuddyAlt: "SlackerBuddy 图标",
    slackerBuddyText: "陪你休息和喝水的 FuFu 桌面宠物"
  },
  en: {
    metaTitle: "PastePaw - FuFu's Clipboard Home",
    metaDescription: "PastePaw is a cute macOS clipboard history app that keeps recently copied text and images close by.",
    brandAria: "PastePaw home",
    navAria: "Primary navigation",
    navFeatures: "Features",
    navInstall: "Install",
    navMoreApps: "More apps",
    navPrivacy: "Privacy",
    navCta: "Run locally",
    softLabel: "FuFu keeps your clipboard cozy",
    heroTitle: "A cute clipboard history app for macOS",
    heroText: "PastePaw quietly records recently copied text and images in the background. Open it from the menu bar to search, pin, delete, or copy items back to your clipboard.",
    primaryCta: "Run PastePaw locally",
    secondaryCta: "View install steps",
    heroArtAria: "PastePaw app preview",
    appIconAlt: "PastePaw app icon",
    speechTitle: "FuFu is ready",
    speechText: "Your recent clippings stay calm and close.",
    featuresTitle: "Bring copied content back",
    featuresText: "Lightweight, local, and direct for daily text and image copying workflows.",
    featureOneTitle: "Text and image history",
    featureOneText: "Automatically records recently copied text and original-quality images in reverse chronological order.",
    featureTwoTitle: "Pin frequent items",
    featureTwoText: "Keep important clippings pinned so they do not expire with regular history.",
    featureThreeTitle: "Fast search",
    featureThreeText: "Search text history from the main window and find recent snippets quickly.",
    featureFourTitle: "Menu bar quick copy",
    featureFourText: "Pick recent history directly from the menu bar and copy it back to the system clipboard.",
    installTitle: "Run locally",
    installText: "This project includes the macOS app and the static website. Use the project script to build and open PastePaw.",
    privacyTitle: "Stored only on your Mac",
    privacyText: "PastePaw saves history locally in Application Support. It does not sync or upload your data. You can choose retention days and clear non-pinned history anytime.",
    moreAppsTitle: "Want more FuFu apps?",
    moreAppsText: "FuFu can keep you company in other tiny tools too. Visit SlackerBuddy for a desktop pet that reminds you to drink water, rest, and relax.",
    slackerBuddyAria: "Open SlackerBuddy website",
    slackerBuddyAlt: "SlackerBuddy icon",
    slackerBuddyText: "FuFu desktop pet for mindful breaks"
  }
};

const languageButtons = document.querySelectorAll("[data-language-option]");
const savedLanguage = localStorage.getItem("pastepaw-language");
const initialLanguage = savedLanguage || (navigator.language.startsWith("zh") ? "zh" : "en");

function applyLanguage(language) {
  const messages = dictionary[language];
  document.documentElement.lang = language === "zh" ? "zh-CN" : "en";
  document.title = messages.metaTitle;

  document.querySelectorAll("[data-i18n]").forEach((node) => {
    node.textContent = messages[node.dataset.i18n];
  });

  document.querySelectorAll("[data-i18n-content]").forEach((node) => {
    node.setAttribute("content", messages[node.dataset.i18nContent]);
  });

  document.querySelectorAll("[data-i18n-aria]").forEach((node) => {
    node.setAttribute("aria-label", messages[node.dataset.i18nAria]);
  });

  document.querySelectorAll("[data-i18n-alt]").forEach((node) => {
    node.setAttribute("alt", messages[node.dataset.i18nAlt]);
  });

  languageButtons.forEach((button) => {
    const isActive = button.dataset.languageOption === language;
    button.setAttribute("aria-pressed", String(isActive));
  });

  localStorage.setItem("pastepaw-language", language);
}

languageButtons.forEach((button) => {
  button.addEventListener("click", () => {
    applyLanguage(button.dataset.languageOption);
  });
});

applyLanguage(initialLanguage);
