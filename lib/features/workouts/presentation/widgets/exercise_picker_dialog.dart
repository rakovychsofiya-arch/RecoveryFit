import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/usecases/get_exercises_usecase.dart';

class ExercisePickerDialog extends StatefulWidget {
  final GetExercisesUseCase getExercisesUseCase;

  const ExercisePickerDialog({
    super.key,
    required this.getExercisesUseCase,
  });

  @override
  State<ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<ExercisePickerDialog> {
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  String _selectedCategory = 'Всі';
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Всі',
    'Груди',
    'Спина',
    'Ноги',
    'Плечі',
    'Руки',
    'Кор',
  ];

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filter);
  }

  Future<void> _loadExercises() async {
    final list = await widget.getExercisesUseCase();
    if (!mounted) return;
    setState(() {
      _allExercises = list;
      _filteredExercises = list;
      _loading = false;
    });
  }

  void _filter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        final matchesCategory = _selectedCategory == 'Всі' || ex.category == _selectedCategory;
        final matchesQuery = ex.name.toLowerCase().contains(query);
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Оберіть вправу',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Пошук вправи...',
              prefixIcon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryLight.withAlpha(50),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                      _filter();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExercises.isEmpty
                    ? const Center(child: Text('Вправ не знайдено'))
                    : ListView.separated(
                        itemCount: _filteredExercises.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final ex = _filteredExercises[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withAlpha(25),
                              child: const Icon(Icons.fitness_center, color: AppTheme.primaryColor),
                            ),
                            title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${ex.category} • ${_equipmentLabel(ex.equipment.name)}'),
                            trailing: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                            onTap: () {
                              Navigator.pop(context, ex);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _equipmentLabel(String eq) {
    switch (eq) {
      case 'barbell':
        return 'Штанга';
      case 'dumbbells':
        return 'Гантелі';
      case 'machine':
        return 'Тренажер';
      case 'bodyweight':
        return 'Власна вага';
      default:
        return eq;
    }
  }
}
