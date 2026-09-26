import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Item de la barra inferior de marca.
class BrandTabItem {
  const BrandTabItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barra inferior flotante: pastilla redondeada, iconos compactos (22)
/// y pestaña activa en degradado azul con háptico al cambiar.
class BrandTabBar extends StatelessWidget {
  const BrandTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<BrandTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 80 : 25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _TabButton(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final BrandTabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: active ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: active ? AppTheme.brandGradientStrong : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppTheme.brandBlue.withAlpha(70),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 21,
              color: active ? CupertinoColors.white : AppTheme.iosGrey,
            ),
            if (active) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Título grande estilo iOS (Large Title 34) + subtítulo gris.
class LargeTitle extends StatelessWidget {
  const LargeTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.displayLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.iosGrey,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Título de sección estilo iOS (22, bold) con aire superior.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.sectionGap, bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}

/// Contenedor agrupado estilo Ajustes de iOS: fondo blanco, radio 14,
/// divisores finos entre filas.
class GroupedSection extends StatelessWidget {
  const GroupedSection({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 0.5,
      indent: 68,
      color: Theme.of(context).dividerColor,
    );
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) divider,
          ],
        ],
      ),
    );
  }
}

/// Fila táctil estilo iOS: 64px, título 17 + subtítulo gris + accesorio.
class AppleRow extends StatelessWidget {
  const AppleRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            if (showChevron) ...[
              const SizedBox(width: 6),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 18,
                color: AppTheme.iosGrey,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Buscador estilo iOS.
class AppleSearchField extends StatelessWidget {
  const AppleSearchField({super.key, this.onChanged, this.placeholder});

  final ValueChanged<String>? onChanged;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CupertinoSearchTextField(
        placeholder: placeholder ?? 'Buscar',
        onChanged: onChanged,
      ),
    );
  }
}

/// Botón primario: degradado azul de marca, ancho completo, alto 52.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null && !loading
              ? null
              : AppTheme.brandGradient,
          color: onPressed == null && !loading ? AppTheme.iosGrey : null,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandBlue.withAlpha(70),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CupertinoButton(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Fondo nocturno con resplandores azules (pantallas de marca).
class BrandNight extends StatelessWidget {
  const BrandNight({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandNight,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.1, -0.5),
                  radius: 1.1,
                  colors: [Color(0xFF1D4ED8), Color(0x00000000)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.1, 1.1),
                  radius: 1.0,
                  colors: [Color(0xFF0A2540), Color(0x00000000)],
                ),
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// Tarjeta héroe con degradado azul de marca y texto blanco.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.children,
    this.onTap,
    this.gradient = AppTheme.brandGradientStrong,
  });

  final List<Widget> children;
  final VoidCallback? onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandBlue.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

/// Botón secundario iOS (texto azul).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 17)),
      ),
    );
  }
}

/// Indicador de carga centrado.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Estado vacío: icono tenue + texto gris + acción.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.icon,
    this.action,
  });

  final String title;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 56, color: AppTheme.iosGrey.withAlpha(150)),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.iosGrey,
                  ),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Insignia de tonalidad: pastilla suave, legible en servicio.
class KeyBadge extends StatelessWidget {
  const KeyBadge({super.key, required this.musicalKey, this.large = false});

  final String musicalKey;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 20 : 12,
        vertical: large ? 12 : 7,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.iosBlueDark.withAlpha(45)
            : AppTheme.iosBlue.withAlpha(22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        musicalKey,
        style: TextStyle(
          fontSize: large ? 30 : 17,
          fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.iosBlueDark : AppTheme.iosBlue,
        ),
      ),
    );
  }
}

/// Página base: fondo agrupado + scroll con padding generoso.
class ApplePage extends StatelessWidget {
  const ApplePage({
    super.key,
    required this.children,
    this.floatingAction,
  });

  final List<Widget> children;
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingAction,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.screenPadding),
          children: children,
        ),
      ),
    );
  }
}
