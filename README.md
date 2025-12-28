# Travel Budget Planner 📱💸

A Flutter-based mobile application that helps travelers plan, track, and control their travel expenses in real time using Firebase.

---

## 📌 Project Information

- **Project Title:** Travel Budget Planner  
- **Platform:** Android (Phase 1), iOS (Optional – Phase 2)  
- **Technology Stack:** Flutter, Firebase Authentication, Cloud Firestore, Riverpod  
- **Prepared by:** Isyraq Haziq (2225321)  
- **Date:** 28 December 2025  

---

## 📖 Introduction

Many travelers plan a budget at the start of a trip, but real spending is difficult to control because expenses occur frequently across different categories such as food, transport, and shopping. These expenses may also involve multiple currencies and group payments. Without a simple tracking system, overspending is often realized only near the end of the trip.

The **Travel Budget Planner** app helps users set trip budgets, log expenses quickly, and monitor remaining balances in real time. It also provides basic analytics to support better financial decisions while traveling. This app is designed to be simple, visual, and accessible for students, families, and group travelers.

---

## ❗ Problem Statement

- Travelers struggle to track expenses consistently during trips  
- Manual tracking using notes or spreadsheets is inconvenient  
- Group expenses often cause confusion about who paid and how much  
- Existing budgeting apps are either too complex or not travel-focused  

---

## 🎯 Objectives

- Create trips with destination, dates, and home currency  
- Set overall and category-based budgets  
- Enable fast and simple expense logging  
- Display real-time budget calculations (Spent vs Remaining)  
- Provide alerts at budget thresholds (80%, 100%)  
- Store and sync data securely using Firebase Firestore  

---

## 👥 Target Users

- Students and backpackers with limited travel budgets  
- Families managing category-based travel expenses  
- Group travelers tracking shared expenses  
- Frequent travelers who want trip history and spending summaries  

---

## 🚀 Features & Functionalities

### Feature Priority

| Module | MVP (Phase 1) | Phase 2 |
|------|---------------|---------|
| Authentication | Email / Google Login | Biometric Unlock |
| Trips | Create, edit, archive trips | Collaborators & invite links |
| Budgeting | Overall & category budgets | Smart budget suggestions |
| Expenses | Add / edit / delete expenses | Receipt scan & attachments |
| Multi-currency | Store expense currency | Auto exchange rates |
| Analytics | Category breakdown & trends | Export PDF / CSV |
| Alerts | 80% / 100% warnings | Custom rules |
| Sync | Firestore realtime sync | Offline-first support |

---

## 🖥️ Core Screens & UI Components

- **Trips Screen**  
  Trip list cards, search bar, “New Trip” button  

- **Trip Dashboard**  
  Summary cards (Spent, Remaining), category progress bars, recent expenses  

- **Add Expense (Bottom Sheet)**  
  Quick input form with save action  

- **Analytics Screen**  
  Simple charts and category breakdown  

- **Settings**  
  Home currency, notifications, account actions  

UI follows Flutter Material design using `Scaffold`, `BottomNavigationBar`, and `FloatingActionButton`.

---

## 🎨 Proposed UI Mockups (Wireframes)

1. Trips (Home)  
2. Trip Dashboard  
3. Add Expense (Bottom Sheet)  
4. Analytics  

*(Wireframes to be added in design phase)*

---

## 🏗️ Architecture & Technical Design

### High-Level Architecture





### Widget Structure (Simplified)

- AppRoot  
- AuthGate  
- MainShell (Scaffold)  
- BottomNavigationBar (Trips | Analytics | Settings)  
- TripsScreen  
- TripDetailsScreen  
- AddExpenseSheet  

### State Management (Riverpod)

- `authProvider` – current user session  
- `tripsProvider` – stream of trips  
- `tripProvider(tripId)` – trip details & budgets  
- `expensesProvider(tripId)` – expense stream  
- `analyticsProvider(tripId)` – computed summaries  

Riverpod is chosen for scalability and clean dependency management.

---

## 🗄️ Data Model (Cloud Firestore)

### Collections Structure

#### Users
users/{uid}
- name
- email
- homecurrency
- created At

#### Trips
trips/{tripld}

- title
- destination
- startDate
- endDate
- homeCurrency
- ownerld
- memberIds
- totalBudget
- createdAt

#### Budgets (Subcollection)
trips/{tripld}/budget/{budgetId}

- categoryName
- limitAmount

#### Expenses (Subcollection)
trips/{tripId}/expenses/{expensesId}

- amount
- currency
- amountHome(optional)
- categoryName
- paidByUserId
- note
- expenseDate
- createdAt


---

## 🔄 App Flow

### Navigation Flow
open App -> Login/Register -> trips Screen
->Open trip -> Trip Dashboard
->Add Expense ->Analytics -> Settings


### Sequence: Add Expense

1. User enters expense details  
2. Data submitted via Riverpod controller  
3. Expense saved to Firestore  
4. Dashboard updates automatically  

---

## 📋 Scope & Limitations

### Scope
- Single user and basic group expense tracking  
- Manual currency conversion  
- Basic analytics  
- Android platform support  

### Limitations
- No bank or payment API integration  
- No AI-based insights  
- Limited offline functionality  
- No receipt OCR in Phase 1  

---

## ⚙️ Non-Functional Requirements

- **Performance:** Updates reflected in under 1 second  
- **Usability:** Expense entry within 3 taps  
- **Security:** Firebase Authentication & Firestore rules  
- **Scalability:** Cloud-based backend  
- **Reliability:** Real-time synchronization  

---

## 🗓️ Development Timeline

| Week | Task |
|----|----|
| 1 | Requirements & UI mockups |
| 2 | Firebase & Authentication |
| 3 | Trip & Budget modules |
| 4 | Expense & Analytics |
| 5 | Testing & final polish |

---

## 📚 References

- Flutter. Material components – https://docs.flutter.dev  
- Flutter. Scaffold, BottomNavigationBar, FloatingActionButton – https://api.flutter.dev  
- Firebase. Cloud Firestore data model – https://firebase.google.com  
- FlutterFire. Firestore usage – https://firebase.flutter.dev  
- Riverpod. Provider concepts – https://riverpod.dev  

---




