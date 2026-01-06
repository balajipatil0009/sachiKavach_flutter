import 'package:arcgis_maps/arcgis_maps.dart';

class ArcGISService {
  // Hydro Layer Config
  static const String _hydroApiKey = "AAPTxy8BH1VEsoebNVZXo8HurJ7BZH8TTjkwjihsZ8pLjndyFcQ0EQq2mdA6IWBNOIGgBeeE2bIl34XlFf3sLnO_hTrU9Bhxdq7PvriXYVkMkFV1qoBYRu-L19q9KmnqEDNY52DlarvUmpHlBpAZqMnXO5JtmgHldC2bMexjAtQtyYlnwS50chQmvEOt_3FEP82OCKJnIIOUbq03ORuJA_rAUSC4mOVCdlqjQQtNSyit4Mqev66SAepxh3t4WPNCeEXwAT1_sDEh4a0h";
  static const String _hydroPortalItemId = "13650e51564f40ca9bb10b01efa028c1";

  // Relief Layer Config
  static const String _reliefApiKey = "AAPTxy8BH1VEsoebNVZXo8HurJ7BZH8TTjkwjihsZ8pLjncjQstvxH9wy4iH_5pqF6dcMXsS8JuZSSY6xabHwGx19-UpaL7Y6EqRsfSCp6Mco5a8_48QK69RtL1ceSDDxwbWlfu9R5buMyjFWvE1kEkxNvzOHAvVzsZZhuKzLx5I63TfIctf8fCAl-kAIQA3wE1EVy0cN2a_29mMdlMjwpdkLqaRav8extBgWCChTFkHG0qMU4iHmg4RGAT9GTG2hfp_AT1_78PyKZyE";
  static const String _reliefPortalItemId = "b4d84ac2fcbb4dce8c8e4afae4c09067";

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

  static ArcGISMap getHydroMap() {
    return ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.anonymous),
        itemId: _hydroPortalItemId,
      ),
    );
  }

  static ArcGISMap getReliefMap() {
    return ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.anonymous),
        itemId: _reliefPortalItemId,
      ),
    );
  }

  // Tables Layer Config
  static const String _tablesApiKey = "AAPTxy8BH1VEsoebNVZXo8HurJ7BZH8TTjkwjihsZ8pLjnedcjaaegvdPru2j2icfwzvR7stp2ldqjcs76rjxWaoZeM69n8pbKrEbMESh3KcrslUAADGX_7MhqAu_Q6oi6XpQc2KjG1Rd6yBM2OtUpsJK_028s-s0KpNawh0Gzf7VHI0WyzVbUl59rQMY18d2cbXwNzLM4huyyZtSrUatDPIB_lHGl7jTFO3SBx7tn4Smh2sSDjxHkI3XX7i4CTZbreHAT1_l0xR9f8E";
  static const String _tablesPortalItemId = "74a959da69bf4721b1147a36b04be649";

  // Risk Zones Layer Config (Same as Tables for now per request)
  static const String _riskZonesApiKey = "AAPTxy8BH1VEsoebNVZXo8HurJ7BZH8TTjkwjihsZ8pLjnedcjaaegvdPru2j2icfwzvR7stp2ldqjcs76rjxWaoZeM69n8pbKrEbMESh3KcrslUAADGX_7MhqAu_Q6oi6XpQc2KjG1Rd6yBM2OtUpsJK_028s-s0KpNawh0Gzf7VHI0WyzVbUl59rQMY18d2cbXwNzLM4huyyZtSrUatDPIB_lHGl7jTFO3SBx7tn4Smh2sSDjxHkI3XX7i4CTZbreHAT1_l0xR9f8E";
  static const String _riskZonesPortalItemId = "74a959da69bf4721b1147a36b04be649";

  static void initializeTables() {
    ArcGISEnvironment.apiKey = _tablesApiKey;
  }

  static void initializeRiskZones() {
    ArcGISEnvironment.apiKey = _riskZonesApiKey;
  }

  static ArcGISMap getTablesMap() {
    return ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.anonymous),
        itemId: _tablesPortalItemId,
      ),
    );
  }

  static ArcGISMap getRiskZonesMap() {
    return ArcGISMap.withItem(
      PortalItem.withPortalAndItemId(
        portal: Portal.arcGISOnline(connection: PortalConnection.anonymous),
        itemId: _riskZonesPortalItemId,
      ),
    );
  }
}
