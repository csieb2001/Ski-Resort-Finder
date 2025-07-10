import Foundation
import CoreLocation
import SwiftUI

class SkiResortDatabase: ObservableObject {
    
    static let shared = SkiResortDatabase()
    
    private init() {
        // Initialize ski resorts immediately on app start
        initializeSkiResorts()
    }
    
    // Weltweite Skigebiet-Datenbank mit echten Koordinaten - NO FAKE DATA
    private(set) var allSkiResorts: [SkiResort] = []
    
    private func initializeSkiResorts() {
        allSkiResorts = [
            // ÖSTERREICH - Top Skigebiete (Only real data - no fake prices!)
            SkiResort(name: "St. Anton am Arlberg", country: "Österreich", region: "Tirol", 
                      totalSlopes: 305, maxElevation: 2811, minElevation: 1304,
                      coordinate: CLLocationCoordinate2D(latitude: 47.1296, longitude: 10.2686),
                      website: "https://www.stantonamarlberg.com"),
            SkiResort(name: "Kitzbühel", country: "Österreich", region: "Tirol", 
                      totalSlopes: 179, maxElevation: 2000, minElevation: 800,
                      coordinate: CLLocationCoordinate2D(latitude: 47.4462, longitude: 12.3928),
                      website: "https://www.kitzbuehel.com"),
            SkiResort(name: "Innsbruck", country: "Österreich", region: "Tirol", 
                      totalSlopes: 300, maxElevation: 2340, minElevation: 580,
                      coordinate: CLLocationCoordinate2D(latitude: 47.2692, longitude: 11.4041),
                      website: "https://www.innsbruck.info"),
            SkiResort(name: "Zell am See-Kaprun", country: "Österreich", region: "Salzburg", 
                      totalSlopes: 138, maxElevation: 3029, minElevation: 750,
                      coordinate: CLLocationCoordinate2D(latitude: 47.2692, longitude: 12.7946),
                      website: "https://www.kitzsteinhorn.at"),
            SkiResort(name: "Sölden", country: "Österreich", region: "Tirol", 
                      totalSlopes: 144, maxElevation: 3340, minElevation: 1350,
                      coordinate: CLLocationCoordinate2D(latitude: 46.9688, longitude: 11.0003),
                      website: "https://www.soelden.com"),
            SkiResort(name: "Salzburg", country: "Österreich", region: "Salzburg", 
                      totalSlopes: 120, maxElevation: 2033, minElevation: 850,
                      coordinate: CLLocationCoordinate2D(latitude: 47.8095, longitude: 13.0550)),
            SkiResort(name: "Schladming", country: "Österreich", region: "Steiermark", 
                      totalSlopes: 123, maxElevation: 2700, minElevation: 745,
                      coordinate: CLLocationCoordinate2D(latitude: 47.3925, longitude: 13.6839),
                      website: "https://www.schladming-dachstein.at"),
            SkiResort(name: "Mayrhofen", country: "Österreich", region: "Tirol", 
                      totalSlopes: 136, maxElevation: 2500, minElevation: 630,
                      coordinate: CLLocationCoordinate2D(latitude: 47.1667, longitude: 11.8667),
                      website: "https://www.mayrhofen.at"),
            SkiResort(name: "Bad Gastein", country: "Österreich", region: "Salzburg", 
                      totalSlopes: 85, maxElevation: 2686, minElevation: 1083,
                      coordinate: CLLocationCoordinate2D(latitude: 47.1133, longitude: 13.1342)),
            SkiResort(name: "Lech Zürs", country: "Österreich", region: "Vorarlberg", 
                      totalSlopes: 305, maxElevation: 2811, minElevation: 1304,
                      coordinate: CLLocationCoordinate2D(latitude: 47.1589, longitude: 10.1397),
                      website: "https://www.lechzuers.com"),

            // SCHWEIZ - Premium Skigebiete
            SkiResort(name: "Verbier", country: "Schweiz", region: "Wallis", 
                      totalSlopes: 410, maxElevation: 3330, minElevation: 1500,
                      coordinate: CLLocationCoordinate2D(latitude: 46.0960, longitude: 7.2286),
                      website: "https://www.verbier.ch"),
            SkiResort(name: "Zermatt", country: "Schweiz", region: "Wallis", 
                      totalSlopes: 360, maxElevation: 3899, minElevation: 1562,
                      coordinate: CLLocationCoordinate2D(latitude: 46.0207, longitude: 7.7491),
                      website: "https://www.zermatt.ch"),
            SkiResort(name: "St. Moritz", country: "Schweiz", region: "Graubünden", 
                      totalSlopes: 350, maxElevation: 3303, minElevation: 1720,
                      coordinate: CLLocationCoordinate2D(latitude: 46.4908, longitude: 9.8355),
                      website: "https://www.stmoritz.ch"),
            SkiResort(name: "Davos", country: "Schweiz", region: "Graubünden", 
                      totalSlopes: 300, maxElevation: 2844, minElevation: 1124,
                      coordinate: CLLocationCoordinate2D(latitude: 46.8093, longitude: 9.8363),
                      website: "https://www.davos.ch"),
            SkiResort(name: "Saas Fee", country: "Schweiz", region: "Wallis", 
                      totalSlopes: 145, maxElevation: 3600, minElevation: 1800,
                      coordinate: CLLocationCoordinate2D(latitude: 46.1089, longitude: 7.9298),
                      website: "https://www.saas-fee.ch"),
            SkiResort(name: "Wengen", country: "Schweiz", region: "Bern", 
                      totalSlopes: 206, maxElevation: 2970, minElevation: 945,
                      coordinate: CLLocationCoordinate2D(latitude: 46.6081, longitude: 7.9225)),
            SkiResort(name: "Grindelwald", country: "Schweiz", region: "Bern", 
                      totalSlopes: 206, maxElevation: 2970, minElevation: 943,
                      coordinate: CLLocationCoordinate2D(latitude: 46.6244, longitude: 8.0414),
                      website: "https://www.grindelwald.swiss"),
            SkiResort(name: "Flims", country: "Schweiz", region: "Graubünden", 
                      totalSlopes: 224, maxElevation: 3018, minElevation: 1100,
                      coordinate: CLLocationCoordinate2D(latitude: 46.8372, longitude: 9.2842),
                      website: "https://www.flims.com"),
            SkiResort(name: "Lenzerheide", country: "Schweiz", region: "Graubünden", 
                      totalSlopes: 225, maxElevation: 2865, minElevation: 1229,
                      coordinate: CLLocationCoordinate2D(latitude: 46.7314, longitude: 9.5542),
                      website: "https://www.lenzerheide.com"),
            SkiResort(name: "Arosa", country: "Schweiz", region: "Graubünden", 
                      totalSlopes: 225, maxElevation: 2653, minElevation: 1742,
                      coordinate: CLLocationCoordinate2D(latitude: 46.7783, longitude: 9.6742),
                      website: "https://www.arosa.swiss"),

            // FRANKREICH - Domaine Skiable
            SkiResort(name: "Chamonix", country: "Frankreich", region: "Haute-Savoie", 
                      totalSlopes: 155, maxElevation: 3842, minElevation: 1035,
                      coordinate: CLLocationCoordinate2D(latitude: 45.9237, longitude: 6.8694),
                      website: "https://www.chamonix.com"),
            SkiResort(name: "Val d'Isère", country: "Frankreich", region: "Savoie", 
                      totalSlopes: 300, maxElevation: 3456, minElevation: 1550,
                      coordinate: CLLocationCoordinate2D(latitude: 45.4486, longitude: 7.0158),
                      website: "https://www.valdisere.com"),
            SkiResort(name: "Courchevel", country: "Frankreich", region: "Savoie", 
                      totalSlopes: 600, maxElevation: 3230, minElevation: 1260,
                      coordinate: CLLocationCoordinate2D(latitude: 45.4167, longitude: 6.6333),
                      website: "https://www.courchevel.com"),
            SkiResort(name: "Méribel", country: "Frankreich", region: "Savoie", 
                      totalSlopes: 600, maxElevation: 3230, minElevation: 1400,
                      coordinate: CLLocationCoordinate2D(latitude: 45.3847, longitude: 6.5667)),
            SkiResort(name: "Val Thorens", country: "Frankreich", region: "Savoie", 
                      totalSlopes: 600, maxElevation: 3230, minElevation: 2300,
                      coordinate: CLLocationCoordinate2D(latitude: 45.2956, longitude: 6.5792)),
            SkiResort(name: "Alpe d'Huez", country: "Frankreich", region: "Isère", 
                      totalSlopes: 250, maxElevation: 3330, minElevation: 1135,
                      coordinate: CLLocationCoordinate2D(latitude: 45.0917, longitude: 6.0675)),
            SkiResort(name: "Les Arcs", country: "Frankreich", region: "Savoie", 
                      totalSlopes: 425, maxElevation: 3226, minElevation: 1200,
                      coordinate: CLLocationCoordinate2D(latitude: 45.5728, longitude: 6.8164)),
            SkiResort(name: "La Plagne", country: "Frankreich", region: "Savoie", 
                      totalSlopes: 425, maxElevation: 3250, minElevation: 1250,
                      coordinate: CLLocationCoordinate2D(latitude: 45.5078, longitude: 6.6750)),

            // ITALIEN - Alpin (erweiterte Datenbank)
            SkiResort(name: "Cortina d'Ampezzo", country: "Italien", region: "Veneto", 
                      totalSlopes: 120, maxElevation: 2930, minElevation: 1224,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5411, longitude: 12.1357),
                      website: "https://www.cortinaampezzo.it"),
            SkiResort(name: "Val Gardena", country: "Italien", region: "Südtirol", 
                      totalSlopes: 175, maxElevation: 2518, minElevation: 1236,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5561, longitude: 11.6761)),
            SkiResort(name: "Madonna di Campiglio", country: "Italien", region: "Trentino", 
                      totalSlopes: 150, maxElevation: 2600, minElevation: 800,
                      coordinate: CLLocationCoordinate2D(latitude: 46.2278, longitude: 10.8269)),
            SkiResort(name: "Livigno", country: "Italien", region: "Lombardei", 
                      totalSlopes: 115, maxElevation: 2797, minElevation: 1816,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5367, longitude: 10.1344)),
            
            // Südtirol/Alto Adige - weitere Top-Gebiete
            SkiResort(name: "Drei Zinnen Dolomiten", country: "Italien", region: "Südtirol", 
                      totalSlopes: 115, maxElevation: 2200, minElevation: 1154,
                      coordinate: CLLocationCoordinate2D(latitude: 46.7400, longitude: 12.2167),
                      website: "https://www.3zinnen.info"),
            SkiResort(name: "Kronplatz", country: "Italien", region: "Südtirol", 
                      totalSlopes: 119, maxElevation: 2275, minElevation: 973,
                      coordinate: CLLocationCoordinate2D(latitude: 46.7378, longitude: 11.9511),
                      website: "https://www.kronplatz.com"),
            SkiResort(name: "Gröden", country: "Italien", region: "Südtirol", 
                      totalSlopes: 178, maxElevation: 2518, minElevation: 1236,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5561, longitude: 11.6761),
                      website: "https://www.valgardena.it"),
            SkiResort(name: "Alta Badia", country: "Italien", region: "Südtirol", 
                      totalSlopes: 130, maxElevation: 2778, minElevation: 1324,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5806, longitude: 11.8806),
                      website: "https://www.altabadia.org"),
            SkiResort(name: "Seiser Alm", country: "Italien", region: "Südtirol", 
                      totalSlopes: 60, maxElevation: 2350, minElevation: 1680,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5522, longitude: 11.6394),
                      website: "https://www.seiseralm.it"),
            SkiResort(name: "Meran 2000", country: "Italien", region: "Südtirol", 
                      totalSlopes: 40, maxElevation: 2300, minElevation: 1670,
                      coordinate: CLLocationCoordinate2D(latitude: 46.6833, longitude: 11.1833),
                      website: "https://www.meran2000.com"),
            
            // Trentino - weitere Gebiete
            SkiResort(name: "Val di Sole", country: "Italien", region: "Trentino", 
                      totalSlopes: 150, maxElevation: 3016, minElevation: 1121,
                      coordinate: CLLocationCoordinate2D(latitude: 46.3000, longitude: 10.8333),
                      website: "https://www.valdisole.net"),
            SkiResort(name: "Folgaria", country: "Italien", region: "Trentino", 
                      totalSlopes: 104, maxElevation: 2100, minElevation: 1000,
                      coordinate: CLLocationCoordinate2D(latitude: 45.9167, longitude: 11.1667),
                      website: "https://www.folgaria.info"),
            SkiResort(name: "Paganella", country: "Italien", region: "Trentino", 
                      totalSlopes: 50, maxElevation: 2125, minElevation: 1000,
                      coordinate: CLLocationCoordinate2D(latitude: 46.1500, longitude: 11.0500),
                      website: "https://www.paganella.net"),
            SkiResort(name: "San Martino di Castrozza", country: "Italien", region: "Trentino", 
                      totalSlopes: 60, maxElevation: 2357, minElevation: 1404,
                      coordinate: CLLocationCoordinate2D(latitude: 46.2667, longitude: 11.8000),
                      website: "https://www.sanmartino.com"),
            
            // Lombardei - weitere Gebiete
            SkiResort(name: "Bormio", country: "Italien", region: "Lombardei", 
                      totalSlopes: 50, maxElevation: 3012, minElevation: 1225,
                      coordinate: CLLocationCoordinate2D(latitude: 46.4667, longitude: 10.3667),
                      website: "https://www.bormio.eu"),
            SkiResort(name: "Ponte di Legno", country: "Italien", region: "Lombardei", 
                      totalSlopes: 100, maxElevation: 3016, minElevation: 1121,
                      coordinate: CLLocationCoordinate2D(latitude: 46.2667, longitude: 10.5167),
                      website: "https://www.pontedilegno.com"),
            SkiResort(name: "Madesimo", country: "Italien", region: "Lombardei", 
                      totalSlopes: 60, maxElevation: 2948, minElevation: 1550,
                      coordinate: CLLocationCoordinate2D(latitude: 46.3500, longitude: 9.4333),
                      website: "https://www.madesimo.com"),
            SkiResort(name: "Chiesa in Valmalenco", country: "Italien", region: "Lombardei", 
                      totalSlopes: 60, maxElevation: 2950, minElevation: 1200,
                      coordinate: CLLocationCoordinate2D(latitude: 46.2667, longitude: 9.8833),
                      website: "https://www.valmalenco.it"),
            
            // Aostatal - Top-Gebiete
            SkiResort(name: "Courmayeur", country: "Italien", region: "Aostatal", 
                      totalSlopes: 100, maxElevation: 2755, minElevation: 1210,
                      coordinate: CLLocationCoordinate2D(latitude: 45.7969, longitude: 6.9661),
                      website: "https://www.courmayeur.it"),
            SkiResort(name: "Cervinia", country: "Italien", region: "Aostatal", 
                      totalSlopes: 360, maxElevation: 3883, minElevation: 1524,
                      coordinate: CLLocationCoordinate2D(latitude: 45.9333, longitude: 7.6333),
                      website: "https://www.cervinia.it"),
            SkiResort(name: "La Thuile", country: "Italien", region: "Aostatal", 
                      totalSlopes: 160, maxElevation: 2641, minElevation: 1175,
                      coordinate: CLLocationCoordinate2D(latitude: 45.7167, longitude: 6.9500),
                      website: "https://www.lathuile.it"),
            SkiResort(name: "Pila", country: "Italien", region: "Aostatal", 
                      totalSlopes: 70, maxElevation: 2750, minElevation: 1800,
                      coordinate: CLLocationCoordinate2D(latitude: 45.7000, longitude: 7.3167),
                      website: "https://www.pila.it"),
            SkiResort(name: "Champoluc", country: "Italien", region: "Aostatal", 
                      totalSlopes: 180, maxElevation: 3275, minElevation: 1212,
                      coordinate: CLLocationCoordinate2D(latitude: 45.8167, longitude: 7.7167),
                      website: "https://www.monterosaski.com"),
            
            // Piemont - weitere Gebiete
            SkiResort(name: "Sestriere", country: "Italien", region: "Piemont", 
                      totalSlopes: 400, maxElevation: 2823, minElevation: 1350,
                      coordinate: CLLocationCoordinate2D(latitude: 44.9583, longitude: 6.8833),
                      website: "https://www.sestriere.it"),
            SkiResort(name: "Bardonecchia", country: "Italien", region: "Piemont", 
                      totalSlopes: 100, maxElevation: 2750, minElevation: 1312,
                      coordinate: CLLocationCoordinate2D(latitude: 45.0781, longitude: 6.7097),
                      website: "https://www.bardonecchia.it"),
            SkiResort(name: "Sauze d'Oulx", country: "Italien", region: "Piemont", 
                      totalSlopes: 400, maxElevation: 2823, minElevation: 1350,
                      coordinate: CLLocationCoordinate2D(latitude: 44.9667, longitude: 6.8500),
                      website: "https://www.sauze.it"),
            SkiResort(name: "Limone Piemonte", country: "Italien", region: "Piemont", 
                      totalSlopes: 80, maxElevation: 2200, minElevation: 1000,
                      coordinate: CLLocationCoordinate2D(latitude: 44.2000, longitude: 7.5667),
                      website: "https://www.limonepiemonte.it"),
            
            // Veneto - weitere Gebiete
            SkiResort(name: "Arabba", country: "Italien", region: "Veneto", 
                      totalSlopes: 63, maxElevation: 2950, minElevation: 1602,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5000, longitude: 11.8833),
                      website: "https://www.arabba.it"),
            SkiResort(name: "Alleghe", country: "Italien", region: "Veneto", 
                      totalSlopes: 80, maxElevation: 2200, minElevation: 979,
                      coordinate: CLLocationCoordinate2D(latitude: 46.4167, longitude: 12.0333),
                      website: "https://www.alleghe.bl.it"),
            SkiResort(name: "Falcade", country: "Italien", region: "Veneto", 
                      totalSlopes: 100, maxElevation: 2400, minElevation: 1145,
                      coordinate: CLLocationCoordinate2D(latitude: 46.3333, longitude: 11.8333),
                      website: "https://www.falcade.com"),
            
            // Friaul-Julisch Venetien
            SkiResort(name: "Tarvisio", country: "Italien", region: "Friaul", 
                      totalSlopes: 24, maxElevation: 1570, minElevation: 750,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5000, longitude: 13.5833),
                      website: "https://www.promotarvisio.org"),
            SkiResort(name: "Sella Nevea", country: "Italien", region: "Friaul", 
                      totalSlopes: 60, maxElevation: 1789, minElevation: 1200,
                      coordinate: CLLocationCoordinate2D(latitude: 46.4000, longitude: 13.4500),
                      website: "https://www.sellanevea.it"),
            
            // Dolomiti Superski - Sella Ronda Region
            SkiResort(name: "La Villa (Alta Badia)", country: "Italien", region: "Südtirol", 
                      totalSlopes: 130, maxElevation: 2778, minElevation: 1324,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5806, longitude: 11.8806),
                      website: "https://www.altabadia.org"),
            SkiResort(name: "Corvara (Alta Badia)", country: "Italien", region: "Südtirol", 
                      totalSlopes: 130, maxElevation: 2778, minElevation: 1465,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5500, longitude: 11.8833),
                      website: "https://www.altabadia.org"),
            SkiResort(name: "Colfosco (Alta Badia)", country: "Italien", region: "Südtirol", 
                      totalSlopes: 130, maxElevation: 2778, minElevation: 1645,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5333, longitude: 11.9000),
                      website: "https://www.altabadia.org"),
            SkiResort(name: "Sella Ronda", country: "Italien", region: "Dolomiten", 
                      totalSlopes: 500, maxElevation: 2778, minElevation: 1236,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5500, longitude: 11.7500),
                      website: "https://www.sellaronda.info"),
            SkiResort(name: "Stern (Würzjoch)", country: "Italien", region: "Südtirol", 
                      totalSlopes: 25, maxElevation: 2000, minElevation: 1450,
                      coordinate: CLLocationCoordinate2D(latitude: 46.6833, longitude: 11.8167),
                      website: "https://www.gitschberg-jochtal.com"),
            SkiResort(name: "Dolomiti Superski", country: "Italien", region: "Dolomiten", 
                      totalSlopes: 1200, maxElevation: 3269, minElevation: 1236,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5500, longitude: 11.7000),
                      website: "https://www.dolomitisuperski.com"),

            // DEUTSCHLAND - Kleinere Gebiete
            SkiResort(name: "Garmisch-Partenkirchen", country: "Deutschland", region: "Bayern", 
                      totalSlopes: 60, maxElevation: 2720, minElevation: 708,
                      coordinate: CLLocationCoordinate2D(latitude: 47.4922, longitude: 11.0955),
                      website: "https://www.gapa.de"),
            SkiResort(name: "Oberstdorf", country: "Deutschland", region: "Bayern", 
                      totalSlopes: 130, maxElevation: 2224, minElevation: 813,
                      coordinate: CLLocationCoordinate2D(latitude: 47.4097, longitude: 10.2794)),
            SkiResort(name: "Berchtesgaden", country: "Deutschland", region: "Bayern", 
                      totalSlopes: 60, maxElevation: 1874, minElevation: 600,
                      coordinate: CLLocationCoordinate2D(latitude: 47.6300, longitude: 13.0019)),
            SkiResort(name: "Winterberg", country: "Deutschland", region: "Nordrhein-Westfalen", 
                      totalSlopes: 27, maxElevation: 838, minElevation: 580,
                      coordinate: CLLocationCoordinate2D(latitude: 51.1956, longitude: 8.5356)),
            SkiResort(name: "Feldberg", country: "Deutschland", region: "Baden-Württemberg", 
                      totalSlopes: 14, maxElevation: 1493, minElevation: 1000,
                      coordinate: CLLocationCoordinate2D(latitude: 47.8742, longitude: 8.0039)),
            SkiResort(name: "Willingen", country: "Deutschland", region: "Hessen", 
                      totalSlopes: 17, maxElevation: 838, minElevation: 540,
                      coordinate: CLLocationCoordinate2D(latitude: 51.2944, longitude: 8.6119)),
            SkiResort(name: "Braunlage", country: "Deutschland", region: "Niedersachsen", 
                      totalSlopes: 15, maxElevation: 971, minElevation: 520,
                      coordinate: CLLocationCoordinate2D(latitude: 51.7247, longitude: 10.6097)),
            SkiResort(name: "Wurmberg", country: "Deutschland", region: "Niedersachsen", 
                      totalSlopes: 12, maxElevation: 971, minElevation: 540,
                      coordinate: CLLocationCoordinate2D(latitude: 51.7542, longitude: 10.6242)),

            // USA - Top Destinations
            SkiResort(name: "Aspen", country: "USA", region: "Colorado", 
                      totalSlopes: 337, maxElevation: 3813, minElevation: 2399,
                      coordinate: CLLocationCoordinate2D(latitude: 39.1911, longitude: -106.8175),
                      website: "https://www.aspensnowmass.com"),
            SkiResort(name: "Vail", country: "USA", region: "Colorado", 
                      totalSlopes: 348, maxElevation: 3527, minElevation: 2476,
                      coordinate: CLLocationCoordinate2D(latitude: 39.6403, longitude: -106.3742),
                      website: "https://www.vail.com"),
            SkiResort(name: "Park City", country: "USA", region: "Utah", 
                      totalSlopes: 348, maxElevation: 3048, minElevation: 2103,
                      coordinate: CLLocationCoordinate2D(latitude: 40.6461, longitude: -111.4980)),
            SkiResort(name: "Jackson Hole", country: "USA", region: "Wyoming", 
                      totalSlopes: 133, maxElevation: 3185, minElevation: 1925,
                      coordinate: CLLocationCoordinate2D(latitude: 43.5872, longitude: -110.8281)),

            // KANADA
            SkiResort(name: "Whistler Blackcomb", country: "Kanada", region: "British Columbia", 
                      totalSlopes: 200, maxElevation: 2284, minElevation: 675,
                      coordinate: CLLocationCoordinate2D(latitude: 50.1163, longitude: -122.9574),
                      website: "https://www.whistlerblackcomb.com"),
            SkiResort(name: "Banff", country: "Kanada", region: "Alberta", 
                      totalSlopes: 139, maxElevation: 2730, minElevation: 1630,
                      coordinate: CLLocationCoordinate2D(latitude: 51.1784, longitude: -115.5708)),

            // JAPAN
            SkiResort(name: "Niseko", country: "Japan", region: "Hokkaido", 
                      totalSlopes: 61, maxElevation: 1308, minElevation: 308,
                      coordinate: CLLocationCoordinate2D(latitude: 42.8048, longitude: 140.6874)),
            SkiResort(name: "Hakuba", country: "Japan", region: "Honshu", 
                      totalSlopes: 200, maxElevation: 1831, minElevation: 760,
                      coordinate: CLLocationCoordinate2D(latitude: 36.7000, longitude: 137.8333)),

            // NORWEGEN
            SkiResort(name: "Lillehammer", country: "Norwegen", region: "Oppland", 
                      totalSlopes: 50, maxElevation: 1050, minElevation: 200,
                      coordinate: CLLocationCoordinate2D(latitude: 61.1153, longitude: 10.4662)),
            SkiResort(name: "Trysil", country: "Norwegen", region: "Hedmark", 
                      totalSlopes: 68, maxElevation: 1132, minElevation: 415,
                      coordinate: CLLocationCoordinate2D(latitude: 61.3167, longitude: 12.2667)),
            SkiResort(name: "Hemsedal", country: "Norwegen", region: "Buskerud", 
                      totalSlopes: 53, maxElevation: 1450, minElevation: 620,
                      coordinate: CLLocationCoordinate2D(latitude: 60.8667, longitude: 8.5500)),

            // SCHWEDEN
            SkiResort(name: "Åre", country: "Schweden", region: "Jämtland", 
                      totalSlopes: 89, maxElevation: 1420, minElevation: 380,
                      coordinate: CLLocationCoordinate2D(latitude: 63.3986, longitude: 13.0819)),
            SkiResort(name: "Sälen", country: "Schweden", region: "Dalarna", 
                      totalSlopes: 112, maxElevation: 943, minElevation: 350,
                      coordinate: CLLocationCoordinate2D(latitude: 61.1500, longitude: 13.1500)),

            // FINNLAND
            SkiResort(name: "Levi", country: "Finnland", region: "Lappland", 
                      totalSlopes: 43, maxElevation: 531, minElevation: 201,
                      coordinate: CLLocationCoordinate2D(latitude: 67.8047, longitude: 24.8094)),
            SkiResort(name: "Ylläs", country: "Finnland", region: "Lappland", 
                      totalSlopes: 63, maxElevation: 719, minElevation: 280,
                      coordinate: CLLocationCoordinate2D(latitude: 67.5833, longitude: 24.1167)),

            // SCHOTTLAND
            SkiResort(name: "Cairn Gorm", country: "Schottland", region: "Highlands", 
                      totalSlopes: 30, maxElevation: 1245, minElevation: 630,
                      coordinate: CLLocationCoordinate2D(latitude: 57.1139, longitude: -3.6694)),
            SkiResort(name: "Glenshee", country: "Schottland", region: "Highlands", 
                      totalSlopes: 40, maxElevation: 1110, minElevation: 650,
                      coordinate: CLLocationCoordinate2D(latitude: 56.8667, longitude: -3.4167)),

            // NEUSEELAND
            SkiResort(name: "Queenstown", country: "Neuseeland", region: "Südinsel", 
                      totalSlopes: 220, maxElevation: 1943, minElevation: 1630,
                      coordinate: CLLocationCoordinate2D(latitude: -45.0312, longitude: 168.6626)),
            SkiResort(name: "Wanaka", country: "Neuseeland", region: "Südinsel", 
                      totalSlopes: 138, maxElevation: 1960, minElevation: 1340,
                      coordinate: CLLocationCoordinate2D(latitude: -44.7000, longitude: 169.1500)),

            // SLOWENIEN
            SkiResort(name: "Kranjska Gora", country: "Slowenien", region: "Gorenjska", 
                      totalSlopes: 20, maxElevation: 1570, minElevation: 810,
                      coordinate: CLLocationCoordinate2D(latitude: 46.4833, longitude: 13.7833)),
            SkiResort(name: "Mariborsko Pohorje", country: "Slowenien", region: "Podravska", 
                      totalSlopes: 42, maxElevation: 1347, minElevation: 325,
                      coordinate: CLLocationCoordinate2D(latitude: 46.5069, longitude: 15.6100)),

            // IRLAND
            SkiResort(name: "Ski Club of Ireland", country: "Irland", region: "Wicklow", 
                      totalSlopes: 3, maxElevation: 380, minElevation: 300,
                      coordinate: CLLocationCoordinate2D(latitude: 53.1424, longitude: -6.2597)),

            // TEST SKIGEBIET - Nur für Testing/Entwicklung
            SkiResort(name: "Test Skigebiet", country: "Test", region: "Test Region", 
                      totalSlopes: 50, maxElevation: 2000, minElevation: 800,
                      coordinate: CLLocationCoordinate2D(latitude: 47.0000, longitude: 10.0000),
                      website: "https://test-skigebiet.com")
        ]
    }
    
    // Search method for filtering resorts - erweiterte Volltext-Suche
    func searchResorts(query: String) -> [SkiResort] {
        if query.isEmpty {
            return allSkiResorts
        } else {
            return allSkiResorts.filter { resort in
                // Standard-Felder
                resort.name.localizedCaseInsensitiveContains(query) ||
                resort.country.localizedCaseInsensitiveContains(query) ||
                resort.region.localizedCaseInsensitiveContains(query) ||
                // Website-Suche (falls vorhanden)
                (resort.website?.localizedCaseInsensitiveContains(query) ?? false) ||
                // Numerische Werte als Text
                String(resort.totalSlopes).contains(query) ||
                String(resort.maxElevation).contains(query) ||
                String(resort.minElevation).contains(query) ||
                // Spezielle Suchbegriffe
                (query.localizedCaseInsensitiveContains("pisten") && resort.totalSlopes > 0) ||
                (query.localizedCaseInsensitiveContains("slopes") && resort.totalSlopes > 0) ||
                (query.localizedCaseInsensitiveContains("hoch") && resort.maxElevation > 2000) ||
                (query.localizedCaseInsensitiveContains("high") && resort.maxElevation > 2000) ||
                (query.localizedCaseInsensitiveContains("groß") && resort.totalSlopes > 200) ||
                (query.localizedCaseInsensitiveContains("large") && resort.totalSlopes > 200) ||
                (query.localizedCaseInsensitiveContains("klein") && resort.totalSlopes < 50) ||
                (query.localizedCaseInsensitiveContains("small") && resort.totalSlopes < 50) ||
                (query.localizedCaseInsensitiveContains("test") && resort.name.contains("Test"))
            }
        }
    }
}