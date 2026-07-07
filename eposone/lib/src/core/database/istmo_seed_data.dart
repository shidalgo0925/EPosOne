import 'package:isar/isar.dart';
import 'package:eposone/src/features/products/domain/entities/category.dart';
import 'package:eposone/src/features/products/domain/entities/product.dart';
import 'package:eposone/src/features/products/domain/entities/modifier_group.dart';
import 'package:eposone/src/features/products/domain/entities/modifier.dart';
import 'package:eposone/src/features/products/domain/entities/product_modifier_link.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page.dart';
import 'package:eposone/src/features/pos/domain/entities/pos_page_item.dart';
import 'package:eposone/src/features/pos/domain/entities/order_type.dart';
import 'package:eposone/src/features/settings/data/repositories/business_config_repository.dart';
import 'package:eposone/src/core/database/istmo_catalog_images.dart';

/// Catálogo real — Restaurante / Bar Istmo (menú PDF, precios con ITBMS incluido).
Future<void> seedIstmoCatalog(Isar isar) async {
  await _clearCatalog(isar);

  final now = DateTime.now();

  Category cat(String id, String name, String color, int order) => Category(
        localId: id,
        name: name,
        color: color,
        sortOrder: order,
        createdAt: now,
        updatedAt: now,
      );

  final categories = <Category>[
    cat('istmo_cat_entradas', 'Entradas', '#F58220', 1),
    cat('istmo_cat_platos', 'Platos Fuertes', '#1A3A5C', 2),
    cat('istmo_cat_pizzas', 'Pizzas', '#9C27B0', 3),
    cat('istmo_cat_acomp', 'Acompañamientos', '#607D8B', 4),
    cat('istmo_cat_postres', 'Postres', '#795548', 5),
    cat('istmo_cat_cerv_istmo', 'Cervezas Istmo', '#FF9800', 6),
    cat('istmo_cat_cocteles', 'Cócteles', '#E91E63', 7),
    cat('istmo_cat_vinos', 'Vinos y Espumantes', '#673AB7', 8),
    cat('istmo_cat_licores', 'Licores', '#3F51B5', 9),
    cat('istmo_cat_cerv', 'Cervezas', '#2196F3', 10),
    cat('istmo_cat_bebidas', 'Bebidas', '#009688', 11),
  ];

  final cEnt = 'istmo_cat_entradas';
  final cPlat = 'istmo_cat_platos';
  final cPizza = 'istmo_cat_pizzas';
  final cAcomp = 'istmo_cat_acomp';
  final cPost = 'istmo_cat_postres';
  final cCervI = 'istmo_cat_cerv_istmo';
  final cCoct = 'istmo_cat_cocteles';
  final cVino = 'istmo_cat_vinos';
  final cLic = 'istmo_cat_licores';
  final cCerv = 'istmo_cat_cerv';
  final cBeb = 'istmo_cat_bebidas';

  Product p(
    String key,
    String name,
    double price,
    String categoryId, {
    String? description,
  }) =>
      Product(
        localId: 'istmo_p_$key',
        name: name,
        price: price,
        sku: 'IST-$key',
        description: description,
        categoryId: categoryId,
        stock: 0,
        createdAt: now,
        updatedAt: now,
      );

  final products = <Product>[
    // —— Entradas ——
    p('ceviche', 'Ceviche de Pescado', 8.56, cEnt,
        description: 'Coronado con encurtido y vegetales, chips de plátano'),
    p('nachos_media', 'Nachos — Media orden', 8.56, cEnt,
        description: 'Queso cheddar, mozzarella, frijol, pico de gallo, sour cream, guacamole, jalapeño'),
    p('nachos_full', 'Nachos — Orden completa', 14.98, cEnt),
    p('nachos_extra', 'Extras de Nachos (pulled pork o pollo)', 4.28, cEnt),
    p('aranitas', 'Arañitas Fritas', 12.84, cEnt),
    p('ensalada_istmo', 'Ensalada Istmo', 8.56, cEnt),
    p('papas_trufadas', 'Papas Trufadas', 8.56, cEnt),
    p('empanada_pollo', 'Empanada de Pollo (7 uds)', 8.56, cEnt),
    p('istmo_wings', 'Istmo Wings', 13.38, cEnt, description: 'Asadas o apanadas, salsas a elección'),
    p('chicharrones', 'Chicharrones', 13.38, cEnt),
    p('patacon', 'Patacón Istmo', 10.70, cEnt),
    p('taconhambre', 'Taconhambre', 9.63, cEnt),

    // —— Platos fuertes ——
    p('wrap_pollo', 'Wrap de Pollo', 12.84, cPlat),
    p('wrap_pork', 'Wrap de Pulled Pork', 12.84, cPlat),
    p('tenders', 'Tenders de Pollo', 12.84, cPlat),
    p('istmo_burger', 'Istmo Burger', 14.98, cPlat, description: '6oz angus, tocino, mozzarella, BBQ'),
    p('cheddar_bacon', 'Clásica Cheddar Bacon', 14.98, cPlat),
    p('pulled_burger', 'Pulled Pork Burger', 13.38, cPlat),
    p('quesadillas', 'Quesadillas Istmo', 14.98, cPlat),

    // —— Pizzas ——
    p('pizza_margarita', 'Pizza Margarita', 10.70, cPizza),
    p('pizza_pepperoni', 'Pizza Pepperoni', 12.84, cPizza),
    p('pizza_feta_miel', 'Pizza Feta Miel', 12.84, cPizza),
    p('pizza_vegetales', 'Pizza Vegetales', 10.70, cPizza),
    p('combo_pizza', 'Combo Pizza Personal', 17.12, cPizza,
        description: '2 pizzas personal + 2 bebidas (limonada, soda, agua o jugo)'),

    // —— Acompañamientos ——
    p('papas_fritas', 'Papas Fritas', 4.28, cAcomp),
    p('anillos_cebolla', 'Anillos de Cebolla', 5.35, cAcomp),
    p('papas_casa', 'Papas de la Casa', 5.35, cAcomp),
    p('mini_cesar', 'Mini Ensalada César', 6.42, cAcomp),

    // —— Postres ——
    p('flan', 'Flan de la Casa', 5.35, cPost),
    p('churristmo', 'Churristmo', 6.96, cPost, description: 'Churros con sirope de chocolate y helado de vainilla'),

    // —— Cervezas Istmo (base 8 oz; tamaños vía modificador) ——
    p('cerveza_colon', 'Colón Lager', 3.75, cCervI, description: '4.1% · IBU 14 · Panameña pura'),
    p('cerveza_chiriqui', 'Chiriquí Red Ale', 3.75, cCervI, description: '5.6% · IBU 28'),
    p('cerveza_cocle', 'Coclé Caribbean Dunkel Weiss', 3.75, cCervI, description: '4.9% · IBU 12'),
    p('cerveza_darien', 'Darién IPA', 3.75, cCervI, description: '5.9% · IBU 54'),
    p('cerveza_bocas', 'Bocas Wheat Beer', 3.75, cCervI, description: '4.9% · IBU 13'),

    // —— Cócteles ——
    p('coct_margarita', 'Margarita (limón, fresa, maracuyá)', 7.49, cCoct),
    p('coct_mojito', 'Mojito (limón, maracuyá)', 8.56, cCoct),
    p('coct_aperol', 'Aperol Spritz', 8.56, cCoct),
    p('coct_caipirinha', 'Caipirinha', 8.56, cCoct),
    p('coct_cosmo', 'Cosmopolitan', 8.56, cCoct),
    p('coct_mule', 'Moscow Mule', 9.63, cCoct),
    p('coct_negroni', 'Negroni', 8.56, cCoct),
    p('coct_whiskey_sour', 'Whiskey Sour', 8.56, cCoct),
    p('coct_gin_tonic', 'Gin Tonic (Gordon\'s)', 8.56, cCoct),
    p('coct_sangria_copa', 'Sangría — Copa', 6.42, cCoct),
    p('coct_sangria_bot', 'Sangría — Botellón', 25.68, cCoct),
    p('coct_pina', 'Piña Colada', 9.10, cCoct),
    p('coct_cuello', 'Cuello Blanco', 9.63, cCoct),
    p('coct_cacao', 'Cacao Curacao', 8.56, cCoct),
    p('coct_dark_storm', 'Dark Storm', 9.63, cCoct),
    p('coct_angel', 'Angel de Piña', 8.56, cCoct),

    // —— Vinos ——
    p('vino_tinto_bot', 'Vino Tinto Tarapacá Merlot — Botella', 28.89, cVino),
    p('vino_tinto_copa', 'Vino Tinto Tarapacá Merlot — Copa', 6.42, cVino),
    p('vino_blanco_bot', 'Vino Blanco Sauvignon Blanc — Botella', 25.68, cVino),
    p('vino_blanco_copa', 'Vino Blanco Sauvignon Blanc — Copa', 5.35, cVino),
    p('espumante_bot', 'Espumante Mionetto — Botella', 38.52, cVino),
    p('espumante_copa', 'Espumante Mionetto — Copa', 6.42, cVino),
    p('punti_bot', 'Punti Ferrer País Brut — Botella', 38.52, cVino),
    p('punti_copa', 'Punti Ferrer País Brut — Copa', 6.42, cVino),

    // —— Licores (trago / botella) ——
    p('teq_dj_silver_tr', 'Don Julio Silver — Trago', 10.70, cLic),
    p('teq_dj_silver_bot', 'Don Julio Silver — Botella', 107.00, cLic),
    p('teq_dj_anejo_tr', 'Don Julio Añejo — Trago', 10.70, cLic),
    p('teq_dj_anejo_bot', 'Don Julio Añejo — Botella', 117.70, cLic),
    p('teq_dj_70_tr', 'Don Julio 70 — Trago', 10.70, cLic),
    p('teq_dj_70_bot', 'Don Julio 70 — Botella', 160.50, cLic),
    p('teq_dj_repo_tr', 'Don Julio Reposado — Trago', 10.70, cLic),
    p('teq_dj_repo_bot', 'Don Julio Reposado — Botella', 133.75, cLic),
    p('teq_cuervo_tr', 'Jose Cuervo Reposado — Trago', 5.35, cLic),
    p('teq_cuervo_bot', 'Jose Cuervo Reposado — Botella', 64.20, cLic),
    p('vod_titos_tr', 'Tito\'s Vodka — Trago', 7.49, cLic),
    p('vod_titos_bot', 'Tito\'s Vodka — Botella', 85.60, cLic),
    p('vod_absolut_tr', 'Absolut — Trago', 5.35, cLic),
    p('vod_absolut_bot', 'Absolut — Botella', 37.45, cLic),
    p('vod_ketel_tr', 'Ketel One — Trago', 10.70, cLic),
    p('vod_smirnoff_tr', 'Smirnoff — Trago', 5.35, cLic),
    p('whis_jack_tr', 'Jack Daniels — Trago', 8.56, cLic),
    p('whis_jack_bot', 'Jack Daniels — Botella', 85.60, cLic),
    p('whis_kurayoshi_tr', 'The Kurayoshi — Trago', 10.70, cLic),
    p('whis_kurayoshi_bot', 'The Kurayoshi — Botella', 107.00, cLic),
    p('whis_monkey_tr', 'Monkey Shoulder — Trago', 8.56, cLic),
    p('whis_buchanans_tr', 'Buchanan\'s 12 — Trago', 16.05, cLic),
    p('whis_oldpar_tr', 'Old Parr — Trago', 9.63, cLic),
    p('whis_singleton12_tr', 'Singleton 12 — Trago', 7.49, cLic),
    p('whis_singleton18_tr', 'Singleton 18 — Trago', 10.70, cLic),
    p('ron_zacapa_tr', 'Zacapa — Trago', 10.70, cLic),
    p('ron_zacapa_bot', 'Zacapa — Botella', 128.40, cLic),
    p('ron_abuelo7_tr', 'Ron Abuelo 7 Años — Trago', 7.49, cLic),
    p('ron_abuelo7_bot', 'Ron Abuelo 7 Años — Botella', 69.55, cLic),
    p('ron_abuelo_an_tr', 'Ron Abuelo Añejo — Trago', 5.35, cLic),
    p('ron_abuelo_an_bot', 'Ron Abuelo Añejo — Botella', 64.20, cLic),
    p('ron_diplo_tr', 'Ron Diplomatico — Trago', 11.77, cLic),
    p('ron_diplo_bot', 'Ron Diplomatico — Botella', 80.25, cLic),
    p('gin_sevilla_tr', 'Tanqueray Sevilla — Trago', 10.70, cLic),
    p('gin_sevilla_bot', 'Tanqueray Sevilla — Botella', 90.95, cLic),
    p('gin_london_tr', 'Tanqueray London — Trago', 8.56, cLic),
    p('gin_london_bot', 'Tanqueray London — Botella', 80.25, cLic),
    p('gin_ten_tr', 'Tanqueray Ten — Trago', 12.84, cLic),
    p('gin_ten_bot', 'Tanqueray Ten — Botella', 90.95, cLic),
    p('gin_hendricks_tr', 'Hendrick\'s — Trago', 10.70, cLic),
    p('mezcal_siete', 'Siete Misterios Mezcal — Trago', 7.49, cLic),

    // —— Cervezas comerciales ——
    p('cerveza_balboa', 'Balboa Manga Larga', 5.35, cCerv),
    p('cerveza_corona', 'Corona Extra', 4.82, cCerv),
    p('cerveza_erdinger', 'Erdinger Weissbier', 8.83, cCerv),
    p('cerveza_corona0', 'Corona 0%', 4.82, cCerv),

    // —— Bebidas sin alcohol ——
    p('beb_perrier', 'Perrier', 3.21, cBeb),
    p('beb_agua', 'Botella de Agua', 4.28, cBeb),
    p('beb_limonada', 'Limonada Clásica o Fresa', 3.21, cBeb),
    p('beb_limonada_coco', 'Limonada de Coco', 4.28, cBeb),
    p('beb_amapola', 'Amapola', 4.82, cBeb),
    p('beb_soda_art', 'Soda Artesanal', 7.49, cBeb),
  ];

  // Modificadores: tamaño cerveza Istmo
  final sizeGroup = ModifierGroup(
    localId: 'istmo_mg_cerv_size',
    name: 'Tamaño',
    minSelect: 1,
    maxSelect: 1,
    createdAt: now,
    updatedAt: now,
  );
  final sizeMods = [
    Modifier(
      localId: 'istmo_m_8oz',
      groupId: sizeGroup.localId,
      name: '8 oz',
      priceDelta: 0,
      createdAt: now,
      updatedAt: now,
    ),
    Modifier(
      localId: 'istmo_m_14oz',
      groupId: sizeGroup.localId,
      name: '14 oz',
      priceDelta: 2.14,
      createdAt: now,
      updatedAt: now,
    ),
    Modifier(
      localId: 'istmo_m_jarra',
      groupId: sizeGroup.localId,
      name: 'Jarra 34 oz',
      priceDelta: 8.56,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  // Modificadores: salsas wings
  final wingsGroup = ModifierGroup(
    localId: 'istmo_mg_wings_salsa',
    name: 'Salsa Wings',
    minSelect: 1,
    maxSelect: 1,
    createdAt: now,
    updatedAt: now,
  );
  final wingsMods = [
    for (final s in ['Buffalo', 'Blue Cheese', 'Honey Mustard', 'Honey BBQ Special'])
      Modifier(
        localId: 'istmo_m_w_${s.toLowerCase().replaceAll(' ', '_')}',
        groupId: wingsGroup.localId,
        name: s,
        priceDelta: 0,
        createdAt: now,
        updatedAt: now,
      ),
  ];

  // Páginas POS
  final pageComida = PosPage(
    localId: 'istmo_page_comida',
    name: 'Comida',
    sortOrder: 0,
    createdAt: now,
    updatedAt: now,
  );
  final pageBar = PosPage(
    localId: 'istmo_page_bar',
    name: 'Bar',
    sortOrder: 1,
    createdAt: now,
    updatedAt: now,
  );

  final comidaCats = [cEnt, cPlat, cPizza, cAcomp, cPost];
  final barCats = [cCervI, cCoct, cVino, cLic, cCerv, cBeb];

  final productKeys = products.map((pr) => pr.sku!.substring(4)).toList();
  final imagePaths = await installIstmoProductImages(productKeys);
  final productsWithImages = products
      .map((pr) {
        final key = pr.sku!.substring(4);
        final path = imagePaths[key];
        if (path == null) return pr;
        return pr.copyWith(imagePath: path);
      })
      .toList();

  await isar.writeTxn(() async {
    for (final c in categories) {
      await isar.categorys.put(c);
    }
    for (final pr in productsWithImages) {
      await isar.products.put(pr);
    }

    await isar.modifierGroups.put(sizeGroup);
    await isar.modifierGroups.put(wingsGroup);
    for (final m in [...sizeMods, ...wingsMods]) {
      await isar.modifiers.put(m);
    }

    for (final key in ['cerveza_colon', 'cerveza_chiriqui', 'cerveza_cocle', 'cerveza_darien', 'cerveza_bocas']) {
      await isar.productModifierLinks.put(
        ProductModifierLink(
          localId: 'istmo_link_${key}_size',
          productId: 'istmo_p_$key',
          groupId: sizeGroup.localId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await isar.productModifierLinks.put(
      ProductModifierLink(
        localId: 'istmo_link_wings_salsa',
        productId: 'istmo_p_istmo_wings',
        groupId: wingsGroup.localId,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await isar.posPages.put(pageComida);
    await isar.posPages.put(pageBar);

    var sort = 0;
    for (final catId in comidaCats) {
      await isar.posPageItems.put(
        PosPageItem(
          localId: 'istmo_pi_comida_$catId',
          pageId: pageComida.localId,
          itemType: PosPageItemType.category,
          refId: catId,
          sortOrder: sort++,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    sort = 0;
    for (final catId in barCats) {
      await isar.posPageItems.put(
        PosPageItem(
          localId: 'istmo_pi_bar_$catId',
          pageId: pageBar.localId,
          itemType: PosPageItemType.category,
          refId: catId,
          sortOrder: sort++,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  });

  // Config operativa Istmo (precios incluyen ITBMS)
  final configRepo = BusinessConfigRepository(isar);
  final config = await configRepo.getConfig();
  await configRepo.saveConfig(
    config.copyWith(
      taxIncluded: true,
      taxRate: 7,
      taxName: 'ITBMS',
      currency: 'PAB',
      currencySymbol: 'B/.',
      trackInventory: false,
      openTicketsEnabled: true,
      defaultOrderType: OrderType.dineIn,
    ).markAsModified(),
  );
}

Future<void> _clearCatalog(Isar isar) async {
  await isar.writeTxn(() async {
    await isar.posPageItems.clear();
    await isar.posPages.clear();
    await isar.productModifierLinks.clear();
    await isar.modifiers.clear();
    await isar.modifierGroups.clear();
    await isar.products.clear();
    await isar.categorys.clear();
  });
}

/// true si el catálogo actual no es Istmo (demo u otro).
Future<bool> needsIstmoCatalog(Isar isar) async {
  final products = await isar.products.where().findAll();
  if (products.isEmpty) return true;
  return products.any((p) => !(p.sku?.startsWith('IST-') ?? false));
}
