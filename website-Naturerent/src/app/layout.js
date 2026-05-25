import './globals.css'

export const metadata = {
  title: 'NatureRent - Operations Portal',
  description: 'Admin panel untuk mengelola operasional NatureRent',
}

export default function RootLayout({ children }) {
  return (
    <html lang="id" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" />
        <script dangerouslySetInnerHTML={{ __html: `
          (function() {
            try {
              var saved = localStorage.getItem('naturerent_system_settings');
              var theme = 'dark'; // Default to dark premium theme!
              var accent = 'green';
              var customHex = '#1f5a3f';

              if (saved) {
                var parsed = JSON.parse(saved);
                theme = parsed.theme || 'dark';
                accent = parsed.accentColor || 'green';
                customHex = parsed.customAccentHex || '#1f5a3f';
              }

              var root = document.documentElement;

              if (theme === 'dark') {
                root.style.setProperty('--bg-primary', '#121214');
                root.style.setProperty('--bg-secondary', '#1a1a1e');
                root.style.setProperty('--bg-card', '#202024');
                root.style.setProperty('--bg-card-hover', '#26262b');
                root.style.setProperty('--text-primary', '#f3f4f6');
                root.style.setProperty('--text-secondary', '#9ca3af');
                root.style.setProperty('--text-muted', '#6b7280');
                root.style.setProperty('--border-color', '#303036');
                root.style.setProperty('--border-color-light', '#26262a');
              } else {
                root.style.setProperty('--bg-primary', '#f7f7f3');
                root.style.setProperty('--bg-secondary', '#f9fafb');
                root.style.setProperty('--bg-card', '#ffffff');
                root.style.setProperty('--bg-card-hover', '#fcfcf9');
                root.style.setProperty('--text-primary', '#1a2e1a');
                root.style.setProperty('--text-secondary', '#6b7280');
                root.style.setProperty('--text-muted', '#9ca3af');
                root.style.setProperty('--border-color', '#e5e7eb');
                root.style.setProperty('--border-color-light', '#f3f4f6');
              }

              var brandGreen = '#1f5a3f';
              var brandGreenLight = '#2d6a4f';
              var brandGreenDark = '#164a30';
              var brandEmerald = '#52b788';
              var brandMint = '#d1f4e8';

              if (accent === 'green') {
                brandGreen = '#1f5a3f'; brandGreenLight = '#2d6a4f'; brandGreenDark = '#164a30'; brandEmerald = '#52b788'; brandMint = '#d1f4e8';
              } else if (accent === 'teal') {
                brandGreen = '#0d8c75'; brandGreenLight = '#0f766e'; brandGreenDark = '#115e59'; brandEmerald = '#14b8a6'; brandMint = '#ccfbf1';
              } else if (accent === 'forest') {
                brandGreen = '#14532d'; brandGreenLight = '#166534'; brandGreenDark = '#14532d'; brandEmerald = '#22c55e'; brandMint = '#dcfce7';
              } else if (accent === 'navy') {
                brandGreen = '#1e3a8a'; brandGreenLight = '#1e40af'; brandGreenDark = '#172554'; brandEmerald = '#3b82f6'; brandMint = '#dbeafe';
              } else if (accent === 'custom' && customHex) {
                brandGreen = customHex;
                function lightDark(col, amt) {
                  var usePound = col[0] === "#";
                  if (usePound) col = col.slice(1);
                  var num = parseInt(col, 16);
                  var r = (num >> 16) + amt; if (r > 255) r = 255; else if (r < 0) r = 0;
                  var b = ((num >> 8) & 0x00FF) + amt; if (b > 255) b = 255; else if (b < 0) b = 0;
                  var g = (num & 0x0000FF) + amt; if (g > 255) g = 255; else if (g < 0) g = 0;
                  return (usePound ? "#" : "") + (g | (b << 8) | (r << 16)).toString(16).padStart(6, '0');
                }
                brandGreenLight = lightDark(customHex, 20);
                brandGreenDark = lightDark(customHex, -20);
                brandEmerald = lightDark(customHex, 40);
                brandMint = lightDark(customHex, 80);
              }

              root.style.setProperty('--brand-green', brandGreen);
              root.style.setProperty('--brand-green-light', brandGreenLight);
              root.style.setProperty('--brand-green-dark', brandGreenDark);
              root.style.setProperty('--brand-emerald', brandEmerald);
              root.style.setProperty('--brand-mint', brandMint);
              root.style.setProperty('--bg-sidebar', brandGreen);

              // Dynamically compute and inject isolated sidebar styles to prevent sidebar flicker
              var sidebarBg = brandGreen;
              var sidebarTxt = '#c2f0dc';
              var sidebarTitleTxt = '#ffffff';
              var sidebarHoverBg = brandGreenLight;
              var sidebarHoverTxt = '#ffffff';
              var sidebarActiveBg = 'rgba(255, 255, 255, 0.12)';
              var sidebarActiveTxt = '#ffffff';
              var sidebarActiveBorder = 'rgba(255, 255, 255, 0.2)';
              var sidebarBorder = brandGreenDark;

              if (theme === 'dark') {
                sidebarBg = '#121214';
                sidebarTxt = '#9ca3af';
                sidebarTitleTxt = '#f3f4f6';
                sidebarHoverBg = '#1a1a1e';
                sidebarHoverTxt = '#f3f4f6';
                sidebarActiveBg = 'rgba(82, 183, 136, 0.15)';
                sidebarActiveTxt = '#52b788';
                sidebarActiveBorder = 'rgba(82, 183, 136, 0.25)';
                sidebarBorder = '#26262a';
              }

              root.style.setProperty('--sidebar-bg', sidebarBg);
              root.style.setProperty('--sidebar-txt', sidebarTxt);
              root.style.setProperty('--sidebar-title-txt', sidebarTitleTxt);
              root.style.setProperty('--sidebar-hover-bg', sidebarHoverBg);
              root.style.setProperty('--sidebar-hover-txt', sidebarHoverTxt);
              root.style.setProperty('--sidebar-active-bg', sidebarActiveBg);
              root.style.setProperty('--sidebar-active-txt', sidebarActiveTxt);
              root.style.setProperty('--sidebar-active-border', sidebarActiveBorder);
              root.style.setProperty('--sidebar-border', sidebarBorder);
            } catch(e) {}
          })();
        ` }} />
      </head>
      <body>{children}</body>
    </html>
  )
}
