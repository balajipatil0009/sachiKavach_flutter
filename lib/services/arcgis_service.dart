import 'package:arcgis_maps/arcgis_maps.dart';

class ArcGISService {
  // Hydro Layer Config
  static const String _hydroApiKey = "AAPTxy8BH1VEsoebNVZXo8HurJ7BZH8TTjkwjihsZ8pLjndla3JzET6PDnrW5xQmO7MaGOF1wSHcSEpOMJBPMp6M8aOJI5_ImMjuHlsj9AbhwCUnEX-sBQ5Icqs6KRWp-hDccd5AayCweSZNp_hpUu-SpC9a1Va-h0CcMyQOp-hx9o08Uz0KB4SEW7ou5lB3f3TuFwiP9aIxCy48BlaRnoHmFFejKUJtfYvwnaRr25P_02s.AT1_fdxYs97P";
  static const String _hydroPortalItemId = "b4e3716297ba4943ad5bcc5cf5a60627";

  // Relief Layer ConfigR
  static const String _reliefApiKey = "AAPTxy8BH1VEsoebNVZXo8HurJ7BZH8TTjkwjihsZ8pLjncjQstvxH9wy4iH_5pqF6dcMXsS8JuZSSY6xabHwGx19-UpaL7Y6EqRsfSCp6Mco5a8_48QK69RtL1ceSDDxwbWlfu9R5buMyjFWvE1kEkxNvzOHAvVzsZZhuKzLx5I63TfIctf8fCAl-kAIQA3wE1EVy0cN2a_29mMdlMjwpdkLqaRav8extBgWCChTFkHG0qMU4iHmg4RGAT9GTG2hfp_AT1_78PyKZyE";
  static const String _reliefPortalItemId = "b4d84ac2fcbb4dce8c8e4afae4c09067";

  // Tables & Risk Zones Layer Config
  static const String _tablesApiKey = "AAPTxy8BH1VEsoebNVZXo8HurJ7BZH8TTjkwjihsZ8pLjnedcjaaegvdPru2j2icfwzvR7stp2ldqjcs76rjxWaoZeM69n8pbKrEbMESh3KcrslUAADGX_7MhqAu_Q6oi6XpQc2KjG1Rd6yBM2OtUpsJK_028s-s0KpNawh0Gzf7VHI0WyzVbUl59rQMY18d2cbXwNzLM4huyyZtSrUatDPIB_lHGl7jTFO3SBx7tn4Smh2sSDjxHkI3XX7i4CTZbreHAT1_l0xR9f8E";
  static const String _tablesPortalItemId = "74a959da69bf4721b1147a36b04be649";
  static const String _riskZonesPortalItemId = "74a959da69bf4721b1147a36b04be649";

  // Cached Map Instances
  static ArcGISMap? _cachedHydroMap;
  static ArcGISMap? _cachedReliefMap;
  static ArcGISMap? _cachedTablesMap;
  static ArcGISMap? _cachedRiskZonesMap;

  // --- INITIALIZERS ---

  /// Initializes the default environment (using Hydro key as default)
  static void initialize() {
    initializeHydro();
  }

  static void initializeHydro() {
    ArcGISEnvironment.apiKey = _hydroApiKey;
  }

  static void initializeRelief() {
    ArcGISEnvironment.apiKey = _reliefApiKey;
  }

  static void initializeTables() {
    ArcGISEnvironment.apiKey = _tablesApiKey;
  }

  static void initializeRiskZones() {
    ArcGISEnvironment.apiKey = _tablesApiKey; // Assuming same key as Tables
  }

  // --- MAP GETTERS ---

  static ArcGISMap getHydroMap() {
    _cachedHydroMap ??= ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.anonymous),
        itemId: _hydroPortalItemId,
      ),
    );
    return _cachedHydroMap!;
  }

  static ArcGISMap getReliefMap() {
    _cachedReliefMap ??= ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.anonymous),
        itemId: _reliefPortalItemId,
      ),
    );
    return _cachedReliefMap!;
  }

  static ArcGISMap getTablesMap() {
    _cachedTablesMap ??= ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.anonymous),
        itemId: _tablesPortalItemId,
      ),
    );
    return _cachedTablesMap!;
  }

  static ArcGISMap getRiskZonesMap() {
    _cachedRiskZonesMap ??= ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.anonymous),
        itemId: _riskZonesPortalItemId,
      ),
    );
    return _cachedRiskZonesMap!;
  }
}