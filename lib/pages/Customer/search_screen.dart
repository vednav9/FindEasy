import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../login_screen.dart';
import '../../main.dart';
import '../../models/category_model.dart';
import '../../models/provider_model.dart';
import 'provider_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double _minRating = 0.0;
  String _sortBy = 'Nearest';
  String? _selectedCategory;
  late User? _user;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    setState(() {
      _currentPosition = position;
    });
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => _signOut(context),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false,
        toolbarHeight: MediaQuery.of(context).size.height * 0.09,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BottomNavBarWrapper(
                          userType: "customer",
                          initialIndex: 3,
                        ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  backgroundImage:
                      _user?.photoURL != null
                          ? NetworkImage(_user!.photoURL!)
                          : const AssetImage('assets/login_background.png')
                              as ImageProvider,
                  radius: 23,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Search Providers",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Lato",
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 16.0,
            ),
            child: TextField(
              style: const TextStyle(color: Colors.black),
              cursorColor: Colors.black,
              onTapOutside: (event) => FocusScope.of(context).unfocus(),
              controller: _searchController,
              onChanged:
                  (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search for services...",
                hintStyle: const TextStyle(color: Colors.black),
                prefixIconColor: Colors.black,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          _buildFilterCard(),
          Expanded(child: _buildProviderList()),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildCategoryFilter(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildRatingFilter()),
                const SizedBox(width: 12),
                Expanded(child: _buildSortFilter()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Row(
      children: [
        const Text("Category: ", style: TextStyle(color: Colors.white)),
        Expanded(
          child: DropdownButton<String>(
            value: _selectedCategory,
            isExpanded: true,
            iconEnabledColor: Colors.orange,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text(
                  "All Categories",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ...categoryList.map(
                (category) => DropdownMenuItem(
                  value: category.title,
                  child: Text(
                    category.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
            onChanged: (val) => setState(() => _selectedCategory = val),
            underline: Container(height: 2, color: Colors.orange),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Row(
      children: [
        const Text("Min Rating: ", style: TextStyle(color: Colors.white)),
        Expanded(
          child: DropdownButton<double>(
            value: _minRating,
            iconEnabledColor: Colors.orange,
            items:
                [0, 1, 2, 3, 4, 5]
                    .map(
                      (r) => DropdownMenuItem<double>(
                        value: r.toDouble(),
                        child: Text(
                          r.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (val) => setState(() => _minRating = val ?? 0),
            underline: Container(height: 2, color: Colors.orange),
          ),
        ),
      ],
    );
  }

  Widget _buildSortFilter() {
    return Row(
      children: [
        const Text("Sort By: ", style: TextStyle(color: Colors.white)),
        Expanded(
          child: DropdownButton<String>(
            value: _sortBy,
            iconEnabledColor: Colors.orange,
            items: const [
              DropdownMenuItem(
                value: 'Nearest',
                child: Text("Nearest", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'Rating',
                child: Text("Rating", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'Newest',
                child: Text(
                  "Newest",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            onChanged: (val) => setState(() => _sortBy = val ?? 'Nearest'),
            underline: Container(height: 2, color: Colors.orange),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('providers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<ProviderModel> providers =
            snapshot.data!.docs
                .map((doc) => ProviderModel.fromFirestore(doc))
                .toList();

        // Apply filters
        providers =
            providers.where((p) {
              final name = p.businessName.toLowerCase();
              final services = p.servicesOffered.join(" ").toLowerCase();
              return (name.contains(_searchQuery) ||
                      services.contains(_searchQuery)) &&
                  p.rating >= _minRating &&
                  (_selectedCategory == null ||
                      p.servicesOffered.contains(_selectedCategory));
            }).toList();

        // Apply sorting
        if (_sortBy == 'Nearest' && _currentPosition != null) {
          providers.sort((a, b) {
            final aDist = a.distanceFrom(
              GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
            );
            final bDist = b.distanceFrom(
              GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
            );

            if (aDist != bDist) return aDist.compareTo(bDist);
            if (b.rating != a.rating) return b.rating.compareTo(a.rating);
            return b.bookingCount.compareTo(a.bookingCount);
          });
        } else if (_sortBy == 'Rating') {
          providers.sort((a, b) => b.rating.compareTo(a.rating));
        } else if (_sortBy == 'Newest') {
          providers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        if (providers.isEmpty) {
          return const Center(child: Text("No providers found"));
        }

        return ListView.builder(
          itemCount: providers.length,
          itemBuilder: (context, index) {
            final provider = providers[index];
            final distance =
                _currentPosition != null && provider.location != null
                    ? (provider.distanceFrom(
                              GeoPoint(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                            ) /
                            1000)
                        .toStringAsFixed(1)
                    : null;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                onTap: () {
                  if (provider.servicesOffered.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProviderDetailScreen(
                              providerId: provider.userId,
                              selectedService: provider.servicesOffered.first,
                            ),
                      ),
                    );
                  }
                },
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(provider.image),
                  radius: 25,
                ),
                title: Text(provider.businessName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Rating: ${provider.rating.toStringAsFixed(1)}"),
                    if (distance != null) Text("Distance: $distance km"),
                    Wrap(
                      spacing: 4,
                      children:
                          provider.servicesOffered
                              .map(
                                (service) => Chip(
                                  label: Text(service, style: const TextStyle(color: Colors.black)),
                                  backgroundColor: Colors.orange[100],
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
