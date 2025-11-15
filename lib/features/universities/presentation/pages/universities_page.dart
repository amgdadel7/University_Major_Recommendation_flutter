import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../data/models/university_model.dart';

enum SortOption {
  name,
  location,
  majorsCount,
  newest,
  oldest,
}

enum ViewMode {
  grid,
  list,
}

class UniversitiesPage extends StatefulWidget {
  const UniversitiesPage({super.key});

  @override
  State<UniversitiesPage> createState() => _UniversitiesPageState();
}

class _UniversitiesPageState extends State<UniversitiesPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  String _searchQuery = '';
  List<UniversityModel> _universities = [];
  List<UniversityModel> _filteredUniversities = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter and Sort State
  SortOption _sortOption = SortOption.name;
  ViewMode _viewMode = ViewMode.list;
  String? _selectedLocation;
  int? _minMajors;
  int? _maxMajors;
  Set<int> _favoriteIds = {};
  bool _showFilterSheet = false;
  bool _showFavoritesOnly = false;
  final TextEditingController _minMajorsController = TextEditingController();
  final TextEditingController _maxMajorsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUniversities();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorite_universities') ?? [];
      setState(() {
        _favoriteIds = favorites.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'favorite_universities',
        _favoriteIds.map((e) => e.toString()).toList(),
      );
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFavorite(int universityId) async {
    setState(() {
      if (_favoriteIds.contains(universityId)) {
        _favoriteIds.remove(universityId);
      } else {
        _favoriteIds.add(universityId);
      }
    });
    await _saveFavorites();
    _applyFilters();
  }

  Future<void> _loadUniversities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final universities = await _apiService.getUniversities();
      setState(() {
        _universities = universities;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading universities: ${e.toString()}'),
            backgroundColor: AppColors.errorLight,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadUniversities,
            ),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<UniversityModel> filtered = List.from(_universities);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((uni) {
        return uni.name.toLowerCase().contains(query) ||
            (uni.englishName?.toLowerCase().contains(query) ?? false) ||
            (uni.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Location filter
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filtered = filtered.where((uni) {
        return uni.location?.toLowerCase() == _selectedLocation!.toLowerCase();
      }).toList();
    }

    // Majors count filter
    if (_minMajors != null) {
      filtered = filtered.where((uni) {
        return (uni.totalMajors ?? 0) >= _minMajors!;
      }).toList();
    }
    if (_maxMajors != null) {
      filtered = filtered.where((uni) {
        return (uni.totalMajors ?? 0) <= _maxMajors!;
      }).toList();
    }

    // Favorites filter
    if (_showFavoritesOnly) {
      filtered = filtered.where((uni) {
        return _favoriteIds.contains(uni.universityId);
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_sortOption) {
        case SortOption.name:
          return a.name.compareTo(b.name);
        case SortOption.location:
          return (a.location ?? '').compareTo(b.location ?? '');
        case SortOption.majorsCount:
          return (b.totalMajors ?? 0).compareTo(a.totalMajors ?? 0);
        case SortOption.newest:
          return (b.createdAt ?? DateTime(1970))
              .compareTo(a.createdAt ?? DateTime(1970));
        case SortOption.oldest:
          return (a.createdAt ?? DateTime(1970))
              .compareTo(b.createdAt ?? DateTime(1970));
      }
    });

    setState(() {
      _filteredUniversities = filtered;
    });
  }

  List<String> get _availableLocations {
    final locations = _universities
        .where((uni) => uni.location != null && uni.location!.isNotEmpty)
        .map((uni) => uni.location!)
        .toSet()
        .toList();
    locations.sort();
    return locations;
  }

  bool get _hasActiveFilters {
    return _selectedLocation != null ||
        _minMajors != null ||
        _maxMajors != null ||
        _showFavoritesOnly;
  }

  void _resetFilters() {
    setState(() {
      _selectedLocation = null;
      _minMajors = null;
      _maxMajors = null;
      _showFavoritesOnly = false;
    });
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minMajorsController.dispose();
    _maxMajorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'universities.title'.tr(),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                        const SizedBox(height: 4),
                        Text(
                          '${_filteredUniversities.length} ${'universities.total'.tr()}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadUniversities,
                    tooltip: 'common.refresh'.tr(),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Enhanced Search Bar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'universities.search'.tr(),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _applyFilters();
                            },
                          ),
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: _hasActiveFilters
                                ? AppColors.primaryLight.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.tune_rounded,
                              color: _hasActiveFilters
                                  ? AppColors.primaryLight
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            onPressed: () {
                              setState(() {
                                _showFilterSheet = true;
                              });
                              _showFilterBottomSheet();
                            },
                            tooltip: 'universities.filter'.tr(),
                          ),
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.grey[800]?.withValues(alpha: 0.5)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primaryLight,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 12),
              
              // Active Filters and View Mode
              Row(
                children: [
                  // Sort Button
                  PopupMenuButton<SortOption>(
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_rounded, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'universities.sort_by'.tr(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    onSelected: (value) {
                      setState(() {
                        _sortOption = value;
                      });
                      _applyFilters();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: SortOption.name,
                        child: Text('universities.sort_name'.tr()),
                      ),
                      PopupMenuItem(
                        value: SortOption.location,
                        child: Text('universities.sort_location'.tr()),
                      ),
                      PopupMenuItem(
                        value: SortOption.majorsCount,
                        child: Text('universities.sort_majors'.tr()),
                      ),
                      PopupMenuItem(
                        value: SortOption.newest,
                        child: Text('universities.sort_newest'.tr()),
                      ),
                      PopupMenuItem(
                        value: SortOption.oldest,
                        child: Text('universities.sort_oldest'.tr()),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // View Mode Toggle
                  ToggleButtons(
                    isSelected: [_viewMode == ViewMode.list, _viewMode == ViewMode.grid],
                    onPressed: (index) {
                      setState(() {
                        _viewMode = index == 0 ? ViewMode.list : ViewMode.grid;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Icon(Icons.view_list, size: 20),
                      Icon(Icons.grid_view, size: 20),
                    ],
                  ),
                ],
              ),
              
              // Active Filters Chips
              if (_hasActiveFilters) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_selectedLocation != null)
                      Chip(
                        label: Text(_selectedLocation!),
                        avatar: const Icon(Icons.location_on, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedLocation = null;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_minMajors != null || _maxMajors != null)
                      Chip(
                        label: Text(
                          '${_minMajors ?? 0} - ${_maxMajors ?? '∞'} ${'universities.majors_count'.tr()}',
                        ),
                        avatar: const Icon(Icons.school, size: 16),
                        onDeleted: () {
                          setState(() {
                            _minMajors = null;
                            _maxMajors = null;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_showFavoritesOnly)
                      Chip(
                        label: Text('universities.favorites'.tr()),
                        avatar: const Icon(Icons.favorite, size: 16),
                        onDeleted: () {
                          setState(() {
                            _showFavoritesOnly = false;
                          });
                          _applyFilters();
                        },
                      ),
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: Text('universities.reset_filters'.tr()),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Universities List/Grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _ErrorState(
                      message: _errorMessage!,
                      onRetry: _loadUniversities,
                    )
                  : _filteredUniversities.isEmpty
                      ? _EmptyState(
                          isSearching: _searchQuery.isNotEmpty || _hasActiveFilters,
                          onClearSearch: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _resetFilters();
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: _loadUniversities,
                          child: _viewMode == ViewMode.list
                              ? ListView.separated(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _filteredUniversities.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final university = _filteredUniversities[index];
                                    return _UniversityCard(
                                      university: university,
                                      isFavorite: _favoriteIds.contains(university.universityId),
                                      onTap: () {
                                        context.push('/university/${university.universityId}');
                                      },
                                      onFavoriteToggle: () => _toggleFavorite(university.universityId),
                                      viewMode: _viewMode,
                                    ).animate()
                                        .fadeIn(delay: Duration(milliseconds: 300 + (index * 50)))
                                        .slideX(begin: -0.2, end: 0);
                                  },
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(20),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _filteredUniversities.length,
                                  itemBuilder: (context, index) {
                                    final university = _filteredUniversities[index];
                                    return _UniversityCard(
                                      university: university,
                                      isFavorite: _favoriteIds.contains(university.universityId),
                                      onTap: () {
                                        context.push('/university/${university.universityId}');
                                      },
                                      onFavoriteToggle: () => _toggleFavorite(university.universityId),
                                      viewMode: _viewMode,
                                    ).animate()
                                        .fadeIn(delay: Duration(milliseconds: 300 + (index * 50)))
                                        .scale(begin: const Offset(0.8, 0.8));
                                  },
                                ),
                        ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    // Update controllers with current values
    _minMajorsController.text = _minMajors?.toString() ?? '';
    _maxMajorsController.text = _maxMajors?.toString() ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'universities.filter_by'.tr(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Location Filter
                    Text(
                      'universities.location'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: InputDecoration(
                        hintText: 'universities.all_locations'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('universities.all'.tr()),
                        ),
                        ..._availableLocations.map((location) {
                          return DropdownMenuItem<String>(
                            value: location,
                            child: Text(location),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          _selectedLocation = value;
                        });
                        setState(() {
                          _selectedLocation = value;
                        });
                        _applyFilters();
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Majors Count Filter
                    Text(
                      'universities.majors_count'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: _minMajorsController,
                            decoration: InputDecoration(
                              labelText: 'universities.min_majors'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: _minMajors?.toString() ?? '',
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                _minMajors = value.isEmpty ? null : int.tryParse(value);
                              });
                              setState(() {
                                _minMajors = value.isEmpty ? null : int.tryParse(value);
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: _maxMajorsController,
                            decoration: InputDecoration(
                              labelText: 'universities.max_majors'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: _maxMajors?.toString() ?? '',
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                _maxMajors = value.isEmpty ? null : int.tryParse(value);
                              });
                              setState(() {
                                _maxMajors = value.isEmpty ? null : int.tryParse(value);
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Favorites Filter
                    SwitchListTile(
                      title: Text('universities.favorites'.tr()),
                      subtitle: Text('universities.show_favorites_only'.tr()),
                      value: _showFavoritesOnly,
                      onChanged: (value) {
                        setModalState(() {
                          _showFavoritesOnly = value;
                        });
                        setState(() {
                          _showFavoritesOnly = value;
                        });
                        _applyFilters();
                      },
                    ),
                    
                    const Spacer(),
                    
                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('universities.apply'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      setState(() {
        _showFilterSheet = false;
      });
    });
  }
}

class _UniversityCard extends StatelessWidget {
  final UniversityModel university;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final ViewMode viewMode;

  const _UniversityCard({
    required this.university,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.viewMode,
  });

  String get _shortName {
    final name = university.englishName ?? university.name;
    final words = name.split(' ');
    if (words.length > 1) {
      return words.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join('');
    }
    return name.length > 10 ? name.substring(0, 10).toUpperCase() : name.toUpperCase();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareUniversity(UniversityModel university) async {
    final text = '${university.name}\n${university.englishName ?? ''}\n${university.location ?? ''}\n${university.website ?? ''}';
    await Share.share(
      text,
      subject: university.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (viewMode == ViewMode.grid) {
      return _buildGridCard(context, theme, isDark);
    } else {
      return _buildListCard(context, theme, isDark);
    }
  }

  Widget _buildListCard(BuildContext context, ThemeData theme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // University Header
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.primaryGradientLight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.school_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              '${university.totalMajors ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.white,
                            ),
                            onPressed: onFavoriteToggle,
                            tooltip: isFavorite ? 'universities.remove_from_favorites'.tr() : 'universities.add_to_favorites'.tr(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: Colors.white),
                            onPressed: () => _shareUniversity(university),
                            tooltip: 'universities.share'.tr(),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _shortName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // University Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      university.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (university.englishName != null && university.englishName != university.name) ...[
                      const SizedBox(height: 4),
                      Text(
                        university.englishName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (university.location != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              university.location!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Quick Actions - Contact Buttons
                    Row(
                      children: [
                        if (university.website != null && university.website!.isNotEmpty)
                          Expanded(
                            child: _ContactButton(
                              icon: Icons.language_rounded,
                              label: 'Website',
                              backgroundColor: Colors.blue.withValues(alpha: 0.1),
                              iconColor: Colors.blue,
                              onTap: () => _launchUrl(university.website!),
                            ),
                          ),
                        if (university.phone != null && university.phone!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ContactButton(
                              icon: Icons.phone_rounded,
                              label: 'Phone',
                              backgroundColor: Colors.green.withValues(alpha: 0.1),
                              iconColor: Colors.green,
                              onTap: () => _launchPhone(university.phone!),
                            ),
                          ),
                        ],
                        if (university.email != null && university.email!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ContactButton(
                              icon: Icons.email_rounded,
                              label: 'Email',
                              backgroundColor: Colors.blue.withValues(alpha: 0.15),
                              iconColor: Colors.blue[700]!,
                              onTap: () => _launchEmail(university.email!),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                        label: Text(
                          '← ${'universities.view_details'.tr()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, ThemeData theme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // University Header
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.primaryGradientLight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${university.totalMajors ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                                size: 18,
                              ),
                              onPressed: onFavoriteToggle,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                              onPressed: () => _shareUniversity(university),
                              padding: const EdgeInsets.only(left: 4),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _shortName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // University Info
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        university.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (university.location != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                university.location!,
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'universities.view_details'.tr(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorLight,
            ),
            const SizedBox(height: 20),
            Text(
              'Error loading universities',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onClearSearch;

  const _EmptyState({
    required this.isSearching,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.school_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              isSearching
                  ? 'universities.no_results'.tr()
                  : 'universities.no_universities'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? 'universities.try_different_search'.tr()
                  : 'universities.check_back_later'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (isSearching) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onClearSearch,
                child: Text('universities.reset_filters'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
