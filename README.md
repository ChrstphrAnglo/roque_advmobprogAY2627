# roque_advmobprog

A new Flutter project.

## Lab Activity 2: Discussion

### Model, Service, and Screen Interaction

The app follows a layered architecture:  
- **Model (`product.dart`)** – defines the data shape and handles JSON parsing via `Product.fromJson()`.  
- **Service (`product_service.dart`)** – handles network calls (`http.get()`), checks status, and maps raw JSON to typed `Product` objects.  
- **Screen (`product_screen.dart`)** – consumes the service in `initState()` and uses a `FutureBuilder` to manage loading, error, and data states declaratively.

Each layer only communicates with its direct neighbor, ensuring separation of concerns: the UI never touches raw JSON, and the service never imports Flutter widgets.

### New Design Pattern: Provider

This activity introduces **Provider** for app‑wide state management. `ThemeProvider` (a `ChangeNotifier`) manages dark mode state. It is registered at the root via `ChangeNotifierProvider`, making it available to all descendants without prop drilling.

- `context.watch<ThemeProvider>()` is used to rebuild widgets when the theme changes (e.g., `MaterialApp`’s theme).  
- `context.read<ThemeProvider>()` is used to trigger actions (e.g., `toggleTheme()`) without unnecessary rebuilds.

This pattern complements the existing model‑service‑screen structure by clearly separating **data state** (per‑screen, fetched via services) from **UI state** (app‑wide, managed via Provider).