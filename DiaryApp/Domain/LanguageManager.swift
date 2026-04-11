// MARK: - Language Manager
import Foundation
import Combine

enum AppLanguage: String, CaseIterable {
    case english    = "en"
    case ukrainian  = "uk"
    case spanish    = "es"
    case polish     = "pl"
    case german     = "de"
    case french     = "fr"
    case portuguese = "pt"

    var displayName: String {
        switch self {
        case .english:    return "English"
        case .ukrainian:  return "Українська"
        case .spanish:    return "Español"
        case .polish:     return "Polski"
        case .german:     return "Deutsch"
        case .french:     return "Français"
        case .portuguese: return "Português"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english:    return "en_US"
        case .ukrainian:  return "uk_UA"
        case .spanish:    return "es_ES"
        case .polish:     return "pl_PL"
        case .german:     return "de_DE"
        case .french:     return "fr_FR"
        case .portuguese: return "pt_BR"
        }
    }
}

// MARK: - Translation table (keyed by English string)
// es / pl / de / fr / pt
private let translations: [String: [AppLanguage: String]] = [
    // Navigation / Tabs
    "Diary":        [.spanish: "Diario",        .polish: "Dziennik",    .german: "Tagebuch",    .french: "Journal",       .portuguese: "Diário"],
    "Statistics":   [.spanish: "Estadísticas",  .polish: "Statystyki",  .german: "Statistiken", .french: "Statistiques",  .portuguese: "Estatísticas"],
    "Search":       [.spanish: "Buscar",         .polish: "Szukaj",      .german: "Suchen",      .french: "Rechercher",    .portuguese: "Pesquisar"],

    // Settings sections
    "Settings":     [.spanish: "Ajustes",        .polish: "Ustawienia",  .german: "Einstellungen", .french: "Paramètres", .portuguese: "Configurações"],
    "SECURITY":     [.spanish: "SEGURIDAD",      .polish: "BEZPIECZEŃSTWO", .german: "SICHERHEIT", .french: "SÉCURITÉ",  .portuguese: "SEGURANÇA"],
    "REMINDERS":    [.spanish: "RECORDATORIOS",  .polish: "PRZYPOMNIENIA", .german: "ERINNERUNGEN", .french: "RAPPELS",  .portuguese: "LEMBRETES"],
    "APPEARANCE":   [.spanish: "APARIENCIA",     .polish: "WYGLĄD",      .german: "AUSSEHEN",    .french: "APPARENCE",    .portuguese: "APARÊNCIA"],
    "LANGUAGE":     [.spanish: "IDIOMA",         .polish: "JĘZYK",       .german: "SPRACHE",     .french: "LANGUE",        .portuguese: "IDIOMA"],
    "AI ASSISTANT": [.spanish: "ASISTENTE IA",   .polish: "ASYSTENT AI", .german: "KI-ASSISTENT", .french: "ASSISTANT IA", .portuguese: "ASSISTENTE IA"],

    // Settings rows
    "Face ID / Touch ID": [.spanish: "Face ID / Touch ID", .polish: "Face ID / Touch ID", .german: "Face ID / Touch ID", .french: "Face ID / Touch ID", .portuguese: "Face ID / Touch ID"],
    "Auto Lock":    [.spanish: "Bloqueo auto",   .polish: "Auto-blokada", .german: "Auto-Sperre", .french: "Verrou auto",  .portuguese: "Bloqueio auto"],
    "Daily Reminder": [.spanish: "Recordatorio diario", .polish: "Codzienne przypomnienie", .german: "Tägliche Erinnerung", .french: "Rappel quotidien", .portuguese: "Lembrete diário"],
    "Streak Goal":  [.spanish: "Meta de racha",  .polish: "Cel serii",   .german: "Streak-Ziel", .french: "Objectif série", .portuguese: "Meta de sequência"],
    "Dark Theme":   [.spanish: "Tema oscuro",    .polish: "Ciemny motyw", .german: "Dunkles Design", .french: "Thème sombre", .portuguese: "Tema escuro"],
    "Accent Color": [.spanish: "Color de acento", .polish: "Kolor akcentu", .german: "Akzentfarbe", .french: "Couleur d'accent", .portuguese: "Cor de destaque"],
    "Language":     [.spanish: "Idioma",         .polish: "Język",       .german: "Sprache",     .french: "Langue",        .portuguese: "Idioma"],
    "AI Tips":      [.spanish: "Consejos IA",    .polish: "Porady AI",   .german: "KI-Tipps",    .french: "Conseils IA",   .portuguese: "Dicas IA"],
    "Sign Out":     [.spanish: "Cerrar sesión",  .polish: "Wyloguj",     .german: "Abmelden",    .french: "Se déconnecter", .portuguese: "Sair"],

    // Common actions
    "Cancel":       [.spanish: "Cancelar",       .polish: "Anuluj",      .german: "Abbrechen",   .french: "Annuler",       .portuguese: "Cancelar"],
    "Delete":       [.spanish: "Eliminar",       .polish: "Usuń",        .german: "Löschen",     .french: "Supprimer",     .portuguese: "Excluir"],
    "Edit":         [.spanish: "Editar",         .polish: "Edytuj",      .german: "Bearbeiten",  .french: "Modifier",      .portuguese: "Editar"],
    "Save":         [.spanish: "Guardar",        .polish: "Zapisz",      .german: "Speichern",   .french: "Enregistrer",   .portuguese: "Salvar"],
    "Done":         [.spanish: "Listo",          .polish: "Gotowe",      .german: "Fertig",      .french: "Terminer",      .portuguese: "Concluído"],

    // Diary list
    "New Entry":    [.spanish: "Nueva entrada",  .polish: "Nowy wpis",   .german: "Neuer Eintrag", .french: "Nouvelle entrée", .portuguese: "Nova entrada"],
    "No entries yet": [.spanish: "Sin entradas aún", .polish: "Brak wpisów", .german: "Noch keine Einträge", .french: "Pas encore d'entrées", .portuguese: "Sem entradas ainda"],
    "day":          [.spanish: "día",            .polish: "dzień",       .german: "Tag",         .french: "jour",          .portuguese: "dia"],
    "days":         [.spanish: "días",           .polish: "dni",         .german: "Tage",        .french: "jours",         .portuguese: "dias"],
    "word":         [.spanish: "palabra",        .polish: "słowo",       .german: "Wort",        .french: "mot",           .portuguese: "palavra"],
    "words":        [.spanish: "palabras",       .polish: "słów",        .german: "Wörter",      .french: "mots",          .portuguese: "palavras"],
    "entry":        [.spanish: "entrada",        .polish: "wpis",        .german: "Eintrag",     .french: "entrée",        .portuguese: "entrada"],
    "entries":      [.spanish: "entradas",       .polish: "wpisów",      .german: "Einträge",    .french: "entrées",       .portuguese: "entradas"],

    // Search
    "Search entries...": [.spanish: "Buscar entradas...", .polish: "Szukaj wpisów...", .german: "Einträge suchen...", .french: "Chercher des entrées...", .portuguese: "Pesquisar entradas..."],
    "Enter a query to search": [.spanish: "Escribe para buscar", .polish: "Wpisz zapytanie", .german: "Suchbegriff eingeben", .french: "Entrez une recherche", .portuguese: "Digite para pesquisar"],
    "Nothing found": [.spanish: "Nada encontrado", .polish: "Nic nie znaleziono", .german: "Nichts gefunden", .french: "Rien trouvé", .portuguese: "Nada encontrado"],
    "All":          [.spanish: "Todos",          .polish: "Wszystkie",   .german: "Alle",        .french: "Tous",          .portuguese: "Todos"],
    "Today":        [.spanish: "Hoy",            .polish: "Dzisiaj",     .german: "Heute",       .french: "Aujourd'hui",   .portuguese: "Hoje"],
    "This Week":    [.spanish: "Esta semana",    .polish: "Ten tydzień", .german: "Diese Woche", .french: "Cette semaine", .portuguese: "Esta semana"],
    "Tags:":        [.spanish: "Etiquetas:",     .polish: "Tagi:",       .german: "Tags:",       .french: "Tags:",         .portuguese: "Tags:"],

    // Stats
    "Entries":      [.spanish: "Entradas",       .polish: "Wpisy",       .german: "Einträge",    .french: "Entrées",       .portuguese: "Entradas"],
    "Words":        [.spanish: "Palabras",       .polish: "Słowa",       .german: "Wörter",      .french: "Mots",          .portuguese: "Palavras"],
    "Streak":       [.spanish: "Racha",          .polish: "Seria",       .german: "Streak",      .french: "Série",         .portuguese: "Sequência"],
    "Mood This Month": [.spanish: "Humor este mes", .polish: "Nastrój w miesiącu", .german: "Stimmung diesen Monat", .french: "Humeur ce mois", .portuguese: "Humor este mês"],
    "Activity (Year)": [.spanish: "Actividad (año)", .polish: "Aktywność (rok)", .german: "Aktivität (Jahr)", .french: "Activité (année)", .portuguese: "Atividade (ano)"],
    "Top Tags":     [.spanish: "Principales tags", .polish: "Popularne tagi", .german: "Top-Tags", .french: "Tags populaires", .portuguese: "Tags principais"],
    "No data for this month": [.spanish: "Sin datos este mes", .polish: "Brak danych", .german: "Keine Daten", .french: "Pas de données", .portuguese: "Sem dados"],
    "No tags yet":  [.spanish: "Sin etiquetas",  .polish: "Brak tagów",  .german: "Keine Tags",  .french: "Pas de tags",   .portuguese: "Sem tags"],
    "Day":          [.spanish: "Día",            .polish: "Dzień",       .german: "Tag",         .french: "Jour",          .portuguese: "Dia"],
    "Mood":         [.spanish: "Humor",          .polish: "Nastrój",     .german: "Stimmung",    .french: "Humeur",        .portuguese: "Humor"],

    // Entry editor
    "Add mood":     [.spanish: "Añadir humor",   .polish: "Dodaj nastrój", .german: "Stimmung hinzufügen", .french: "Ajouter humeur", .portuguese: "Adicionar humor"],
    "Add tag":      [.spanish: "Añadir etiqueta", .polish: "Dodaj tag",  .german: "Tag hinzufügen", .french: "Ajouter tag",  .portuguese: "Adicionar tag"],
    "Write your thoughts...": [.spanish: "Escribe tus pensamientos...", .polish: "Napisz swoje myśli...", .german: "Schreibe deine Gedanken...", .french: "Écrivez vos pensées...", .portuguese: "Escreva seus pensamentos..."],

    // Confirmation dialogs
    "Delete entry?": [.spanish: "¿Eliminar entrada?", .polish: "Usunąć wpis?", .german: "Eintrag löschen?", .french: "Supprimer l'entrée?", .portuguese: "Excluir entrada?"],
    "This action cannot be undone": [.spanish: "Esta acción no se puede deshacer", .polish: "Tej akcji nie można cofnąć", .german: "Nicht rückgängig machbar", .french: "Action irréversible", .portuguese: "Ação irreversível"],

    // Dates
    "Today,":       [.spanish: "Hoy,",           .polish: "Dzisiaj,",    .german: "Heute,",      .french: "Aujourd'hui,",  .portuguese: "Hoje,"],
    "Yesterday,":   [.spanish: "Ayer,",          .polish: "Wczoraj,",    .german: "Gestern,",    .french: "Hier,",         .portuguese: "Ontem,"],

    // Auth
    "Sign in with Google": [.spanish: "Iniciar sesión con Google", .polish: "Zaloguj przez Google", .german: "Mit Google anmelden", .french: "Connexion avec Google", .portuguese: "Entrar com Google"],
    "Welcome back": [.spanish: "Bienvenido",     .polish: "Witaj ponownie", .german: "Willkommen zurück", .french: "Bon retour", .portuguese: "Bem-vindo"],

    // Onboarding
    "Get Started":  [.spanish: "Comenzar",       .polish: "Zaczynamy",   .german: "Loslegen",    .french: "Commencer",     .portuguese: "Começar"],

    // AI
    "Question":     [.spanish: "Pregunta",       .polish: "Pytanie",     .german: "Frage",       .french: "Question",      .portuguese: "Pergunta"],
    "Pattern":      [.spanish: "Patrón",         .polish: "Wzorzec",     .german: "Muster",      .french: "Modèle",        .portuguese: "Padrão"],

    // Appearance values
    "System":       [.spanish: "Sistema",        .polish: "System",      .german: "System",      .french: "Système",       .portuguese: "Sistema"],
    "Light":        [.spanish: "Claro",          .polish: "Jasny",       .german: "Hell",        .french: "Clair",         .portuguese: "Claro"],
    "Dark":         [.spanish: "Oscuro",         .polish: "Ciemny",      .german: "Dunkel",      .french: "Sombre",        .portuguese: "Escuro"],

    // Auto-lock values
    "Immediately":  [.spanish: "Inmediatamente", .polish: "Natychmiast", .german: "Sofort",      .french: "Immédiatement", .portuguese: "Imediatamente"],
    "1 minute":     [.spanish: "1 minuto",       .polish: "1 minuta",    .german: "1 Minute",    .french: "1 minute",      .portuguese: "1 minuto"],
    "5 minutes":    [.spanish: "5 minutos",      .polish: "5 minut",     .german: "5 Minuten",   .french: "5 minutes",     .portuguese: "5 minutos"],
    "15 minutes":   [.spanish: "15 minutos",     .polish: "15 minut",    .german: "15 Minuten",  .french: "15 minutes",    .portuguese: "15 minutos"],
    "30 minutes":   [.spanish: "30 minutos",     .polish: "30 minut",    .german: "30 Minuten",  .french: "30 minutes",    .portuguese: "30 minutos"],
    "1 hour":       [.spanish: "1 hora",         .polish: "1 godzina",   .german: "1 Stunde",    .french: "1 heure",       .portuguese: "1 hora"],
]

// MARK: - LanguageManager

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "app_language") }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        language = AppLanguage(rawValue: raw) ?? .english
    }

    /// Two-param helper. For EN returns `en`, for UK returns `uk`,
    /// for other languages looks up `en` as key in the translation table.
    func l(_ en: String, _ uk: String) -> String {
        switch language {
        case .english:   return en
        case .ukrainian: return uk
        default:         return translations[en]?[language] ?? en
        }
    }

    /// Multi-language helper for strings that need explicit per-language values.
    func l(_ t: [AppLanguage: String]) -> String {
        t[language] ?? t[.english] ?? ""
    }

    var locale: Locale { Locale(identifier: language.localeIdentifier) }
    var isUkrainian: Bool { language == .ukrainian }
}
