# roque_advmobprog

A new Flutter project.

## Lab Activity 5: discussion

### Workflow: DummyJSON vs Firebase

**DummyJSON (REST API, token based)**

1. *Sign in:* the app sends `POST https://dummyjson.com/auth/login` with a username and password.
2. The API replies with an `accessToken` and a `refreshToken`. The app stores both in `SharedPreferences`, and that stored token is the session.
3. *Profile:* `GET /auth/me` with `Authorization: Bearer <accessToken>` returns the user's details.
4. *Token refresh:* the access token is short lived. When `/auth/me` answers 401 or 403, the app calls `POST /auth/refresh` with the refresh token, stores the new tokens and retries once. If the refresh fails, the session is cleared and the user logs in again.
5. *Sign up:* DummyJSON has no real sign up. `POST /users/add` only simulates creating a user and nothing is saved, so accounts can't be created or changed. That is why the DummyJSON profile is read-only.

**Firebase Authentication (SDK based)**

1. *Sign up:* the signup screen validates first name, last name, age, contact number, username, email and password. It then calls `createAccount` (`createUserWithEmailAndPassword`), `updateUsername` (sets the Firebase display name) and stores the extra fields on the device.
2. *Sign in:* `signIn` calls `signInWithEmailAndPassword`. There are no tokens to manage by hand. The SDK stores the session, refreshes the ID token in the background and restores the session on the next app start.
3. *Profile:* `currentUser` gives the signed-in user. `updateUsername`, `resetPasswordFromCurrentPassword` and `deleteAccount` change the account. The password change and delete first re-authenticate with the current password, because Firebase requires a recent login for sensitive actions.
4. *Sign out:* `logout()` signs out of Firebase and removes any stored DummyJSON tokens. The app then returns to the login screen.

### Main idea of `UserService`

`UserService` (`lib/services/user_service.dart`) is the single place where the screens get authentication and user data. Screens never call `FirebaseAuth` or `http` directly. They call methods such as `signIn`, `createAccount`, `signInWithDummyJson`, `getUserData` and `logout`, so a screen does not need to know which backend is behind it. `getLoginType()` reports which kind of account is signed in. `getUserData()` returns the same `UserProfile` model for both, and the profile screen shows different details and actions depending on the `LoginType`. Only `UserService` has to change if the backend changes. A global `userService` notifier gives every screen the same instance, and because the session lives in Firebase and `SharedPreferences`, a new `UserService()` sees the same session.

### Benefits of the Firebase implementation

- **No backend to build or host.** Accounts, password hashing and storage are handled by Firebase.
- **Real accounts.** Users can sign up, change their username and password, and delete their account. DummyJSON is read-only.
- **Secure sessions handled for us.** The SDK refreshes tokens automatically and keeps the user signed in across app restarts.
- **Better security.** Passwords are never stored in the app. Re-authentication is required for sensitive actions, and Firebase rate limits sign in attempts and returns clear error codes such as `invalid-credential` and `email-already-in-use`.
- **Ready to grow.** Firestore and Realtime Database security rules can use the signed-in user's `uid`, so later features such as saved orders or chat can be limited to each user's own data.
- **Cross-platform.** The same code works on Android and iOS.

## Lab Activity 3: discussion

### How the cart model, service and screen work together

1. **Model** (`lib/models/cart.dart`): `Cart` and `CartProduct` turn the JSON from DummyJSON into typed Dart objects with `fromJson` and `toJson`. They also know how to recalculate their own totals (`withQuantity`, `withProducts`).
2. **Service** (`lib/services/cart_service.dart`): `CartService` is the only place that calls the `/carts` endpoints with `http`. It returns `Cart` objects, so nothing else needs to know about URLs or JSON.
3. **Provider** (`lib/providers/cart_provider.dart`): `CartProvider` calls the service and keeps the signed-in user's cart, so the shop, the detail screen and the cart screen all see the same items.
4. **Screen** (`lib/screens/cart_screen.dart`): `CartScreen` listens to `CartProvider` and draws the items, the quantity buttons, the totals and the Confirm order button.

**Going to the same detail screen.** A `CartProduct` only holds a product's id, title, price and thumbnail, while `DetailScreen` needs a full `Product`. When a cart item is tapped, the app calls `ProductService.getProductById` (`GET /products/{id}`) and opens `DetailScreen(product: ...)`. The shop grid opens the very same `DetailScreen`, so both places share one screen.

### Updated design pattern

The project keeps the layered pattern from the last lab, with one new layer:

- `models/` describes the data (`cart.dart`, `product.dart`).
- `services/` talks to the API (`cart_service.dart`, `product_service.dart`).
- `providers/` holds state that several screens share (`theme_provider.dart`, `cart_provider.dart`).
- `screens/` and `widgets/` draw the UI (`cart_screen.dart`, `detail_screen.dart`, and so on).

Screens never build URLs or parse JSON. They ask a provider, which asks a service, which returns models. `product_detail_screen.dart` was renamed to `detail_screen.dart` to match the required structure.

### Using the Cart endpoint by id

DummyJSON has three ways to read carts:

- `GET /carts` returns every cart (`getAllCarts`).
- `GET /carts/{id}` returns one cart by its own id (`getCartById`), for example `/carts/6`.
- `GET /carts/user/{userId}` returns the cart that belongs to one user (`getCartByUserId`), for example `/carts/user/6`. The reply is `{ "carts": [ ... ] }`, so the service takes the first entry. An unknown user gives a 404, which the service turns into an empty cart.

Each signed-in user has their own cart, keyed by user id. The cart starts empty because the DummyJSON carts come pre-filled with sample products, so `getCartByUserId` is available but not called on load. A DummyJSON login has a numeric user id and uses it directly. A Firebase account has no numeric id, so its uid is mapped to a stable number from 1 to 208, so each Firebase account always adds to the cart under the same user id.

**Add to cart.** `POST /carts/add` with `{"userId": 6, "products": [{"id": 144, "quantity": 1}]}` is sent when Add to cart is tapped on the detail screen. DummyJSON only simulates this: it replies with the product that was added, and nothing is saved on the server. The provider merges that reply into the cart and saves it on the device under that user's id. Quantity changes and removals are saved the same way, for the same reason.

### Enhancements

1. **Cart screen** renders the cart endpoint, and each item opens the shared detail screen.
2. **Chat as a FloatingActionButton** replaces the chat tab, and it is hidden while the cart tab is open.
3. **Cart by user id and add to cart** use `/carts/user/{userId}` and `/carts/add`.

## Lab Activity 4: discussion

### How the user model, service and screens work together

1. **Sign in** (`signin_screen.dart`): a DummyJSON login calls `UserService.loginUser(username, password)`, which sends `POST /auth/login`. A Firebase login calls `UserService.signIn`. The screen never talks to `http` or `FirebaseAuth` itself.
2. **Service** (`lib/services/user_service.dart`): after a DummyJSON login, `saveUserData` writes the tokens and the user fields (`id`, `username`, `email`, `firstName`, `lastName`, `gender`, `image`, ...) to `SharedPreferences`. Firebase keeps its own session, and the extra signup details are stored on the device.
3. **Model** (`lib/models/user.dart`): `UserProfile` is the one shape every screen reads. `UserProfile.fromDummyJson` builds it from the API response or the saved copy, and the Firebase branch builds it from the Firebase user. (It is called `UserProfile` because `User` is already a FirebaseAuth class.)
4. **Screen** (`profile_screen.dart`): `getUserData()` returns a `UserProfile` from the saved data, so the profile opens instantly and works offline. Pull to refresh calls `getUserData(refresh: true)`, which asks the server again. The screen then draws the avatar, name, `@username` and the Email, Gender, User ID and other rows.

### Persistent authentication (splash screen)

`splash_screen.dart` plays the logo animation and calls `UserService.isLoggedIn()`. That is true when Firebase has restored its session or when DummyJSON tokens are saved. The splash then opens `/home` or `/signin`. Logging out removes the tokens and the saved user, so the next start goes to the sign in screen.

### Updated design pattern

The layers are the same as Lab 3: `models/` (data), `services/` (API and storage), `providers/` (shared state) and `screens/` (UI). New in this lab are `splash_screen.dart` and `signin_screen.dart` (the old login screen, renamed) and `models/user.dart` (renamed from `user_profile.dart`). A small `utils/logout.dart` is shared by Settings and Profile.

### Firebase and DummyJSON work the same way

Both login types go through the same `UserService` methods and the same `UserProfile`, so every feature works for both:

- **Persistent sign in:** the splash screen restores either kind of session.
- **Profile:** both show the same rows. Firebase signup now also asks for gender, so that row is filled for both.
- **Cart:** each account has its own cart (see below).
- **Chat:** both kinds of account are added to the Firestore `Users` list, so they can find and message each other. DummyJSON users are stored as `dummyjson_<id>` so their ids never clash with a Firebase uid.
- **Log out:** available on the profile and in Settings for both.

The only difference is account changes (username, password, delete account). DummyJSON is read-only, so those actions exist only for Firebase accounts.

### Rendering the cart by user id from the saved data

`CartProvider.load()` calls `getUserData()` and reads the saved user. `UserProfile.cartUserId` gives the numeric id for the cart: a DummyJSON user's own id, or a stable number from 1 to 208 mapped from a Firebase uid. The provider reads and saves the cart under `cart_<user id>` in `SharedPreferences`, so each account sees only its own cart, and it is still there after a restart or another login. `POST /carts/add` is called with that `cartUserId`, and the reply is merged into the saved cart. The profile shows the id in its **Cart user** row.
