import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

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

/// Botón primario iOS: ancho completo, alto 52, radio 14.
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
      child: CupertinoButton.filled(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CupertinoActivityIndicator(color: CupertinoColors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 17)),
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
