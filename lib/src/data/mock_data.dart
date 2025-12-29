import '../models/models.dart';

class MockData {
  // === RESTAURANTS ===
  static final List<Restaurant> restaurants = [
    Restaurant(
      id: 'r1',
      name: 'EESİGORTA Burger & More',
      description: 'Burger, patates ve özel soslar',
      heroImageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=1200&q=80',
      minOrderTl: 200,
      minDeliveryMin: 25,
      maxDeliveryMin: 40,
      rating: 4.7,
    ),
    Restaurant(
      id: 'r2',
      name: 'Napoli Pizza House',
      description: 'Odun ateşinde pizza çeşitleri',
      heroImageUrl: 'https://images.unsplash.com/photo-1548365328-9f547c3c7f85?w=1200&q=80',
      minOrderTl: 180,
      minDeliveryMin: 30,
      maxDeliveryMin: 45,
      rating: 4.6,
    ),
  ];

  static Restaurant restaurantById(String id) {
    return restaurants.firstWhere(
      (r) => r.id == id,
      orElse: () => restaurants.first,
    );
  }

  static List<Restaurant> popularRestaurants() {
    final list = [...restaurants];
    list.sort((a, b) => b.rating.compareTo(a.rating));
    return list;
  }

  // === CATEGORIES ===
  static List<Category> categoriesForRestaurant(String restaurantId) {
    return [
      Category(id: '${restaurantId}_c1', restaurantId: restaurantId, title: 'Burger'),
      Category(id: '${restaurantId}_c2', restaurantId: restaurantId, title: 'Pizza'),
      Category(id: '${restaurantId}_c3', restaurantId: restaurantId, title: 'Döner'),
      Category(id: '${restaurantId}_c4', restaurantId: restaurantId, title: 'İçecek'),
    ];
  }

  // === PRODUCTS ===
  static List<Product> productsForRestaurant(String restaurantId) {
    final cats = categoriesForRestaurant(restaurantId);

    final burgerCat = cats[0].id;
    final pizzaCat = cats[1].id;

    return [
      Product(
        id: '${restaurantId}_p1',
        restaurantId: restaurantId,
        categoryId: burgerCat,
        name: 'Klasik Burger',
        description: 'Dana köfte, marul, domates',
        imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=900&q=80',
        priceTl: 180,
        isPopular: true,
      ),
      Product(
        id: '${restaurantId}_p2',
        restaurantId: restaurantId,
        categoryId: pizzaCat,
        name: 'Pepperoni Pizza',
        description: 'Mozzarella, pepperoni',
        imageUrl: 'https://images.unsplash.com/photo-1548365328-9f547c3c7f85?w=900&q=80',
        priceTl: 220,
      ),
    ];
  }

  // === SEARCH SUPPORT ===
  static List<Product> get products {
    final all = <Product>[];
    for (final r in restaurants) {
      all.addAll(productsForRestaurant(r.id));
    }
    return all;
  }
}
