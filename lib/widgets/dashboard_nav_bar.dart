import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Bottom navigation shared by the dashboard sections, matching the wireframe:
/// teal bar, dark-teal SVG icons, white circle highlight on the active item.
class DashboardNavBar extends StatelessWidget {
  const DashboardNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// 0 home, 1 jobs, 2 scan, 3 analytics, 4 logout.
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _teal = Color(0xFF0D9488);
  static const _iconColor = Color(0xFF1B2D2B);

  static const _homeSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 11.2 12 4l9 7.2"/>
  <path d="M5.4 9.9V20h13.2V9.9"/>
  <path d="M9.8 20v-5.4h4.4V20"/>
</svg>
''';

  static const _jobsSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3.5" y="7.5" width="17" height="12" rx="2"/>
  <path d="M9 7.5V6a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v1.5"/>
  <path d="M3.5 12.5h17"/>
</svg>
''';

  static const _scanSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 8.5V6a2 2 0 0 1 2-2h2.5M15.5 4H18a2 2 0 0 1 2 2v2.5M20 15.5V18a2 2 0 0 1-2 2h-2.5M8.5 20H6a2 2 0 0 1-2-2v-2.5"/>
  <path d="M4 12h16"/>
</svg>
''';

  static const _analyticsSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="8"/>
  <path d="M12 12V4"/>
  <path d="M12 12l5.6 5.6"/>
</svg>
''';

  static const _logoutSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
  <path d="M9.5 4H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h3.5"/>
  <path d="M15 8l4 4-4 4"/>
  <path d="M19 12H9.5"/>
</svg>
''';

  static const _icons = [_homeSvg, _jobsSvg, _scanSvg, _analyticsSvg, _logoutSvg];
  static const _labels = ['Home', 'Jobs', 'Scan', 'Analytics', 'Logout'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _teal,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < _icons.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Tooltip(
                    message: _labels[i],
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: i == currentIndex
                          ? const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: SvgPicture.string(
                        _icons[i],
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          _iconColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
