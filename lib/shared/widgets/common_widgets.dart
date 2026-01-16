import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// 1. 어두운 배경의 카드 위젯 (DarkCard)
class DarkCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const DarkCard({super.key, required this.child, this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

// 2. 검색 필드 (SearchField)
class SearchField extends StatelessWidget {
  final String hint;
  const SearchField({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
          filled: true,
          fillColor: AppTheme.surface,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
        ),
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      ),
    );
  }
}

// 3. 필터 바 (FilterBar)
class FilterBar extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final Function(String) onSelect;

  const FilterBar({super.key, required this.filters, required this.selectedFilter, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onSelect(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 4. 지표 카드 (MetricCard)
class MetricCard extends StatelessWidget {
  final String title, value, trend;
  final IconData icon;
  final Color color;

  const MetricCard({super.key, required this.title, required this.value, required this.trend, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: color),
              if(trend.isNotEmpty)
                Text(trend, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ]),
        ],
      ),
    );
  }
}