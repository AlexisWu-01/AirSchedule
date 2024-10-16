# AirSchedule

AirSchedule is a comprehensive travel information application designed to help users manage their flights and related activities seamlessly. By leveraging advanced language models and integrating multiple backend services, AirSchedule provides real-time flight details, meeting schedules, weather forecasts, navigation assistance, and personalized clothing advice. Whether you're planning your travel itinerary or ensuring you can make it to important meetings on time, AirSchedule is your go-to solution.

## Table of Contents

- [AirSchedule](#airschedule)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Installation](#installation)
    - [Prerequisites](#prerequisites)
    - [Steps](#steps)
  - [Usage](#usage)
  - [Architecture Overview](#architecture-overview)
    - [Key Components](#key-components)
      - [**Frontend**](#frontend)
      - [**Backend Orchestration**](#backend-orchestration)
      - [**Workflow**](#workflow)
  - [Technologies Used](#technologies-used)
  - [Contributing](#contributing)
  - [Contact](#contact)

## Features

- **Flight Management**: View detailed information about your flights, including departure and arrival times, delays, legroom, and more.
- **Meeting Integration**: Sync your calendar to check if your flight timings allow you to attend scheduled meetings.
- **Real-Time Navigation**: Calculate travel time from the airport to your meeting location using integrated maps.
- **Weather Forecasts**: Get up-to-date weather information for your destination upon arrival.
- **Personalized Clothing Advice**: Receive clothing recommendations based on the weather and event type.
- **Dynamic UI Rendering**: The interface dynamically adjusts to display relevant information based on user queries.
- **Robust Error Handling**: Handles various edge cases and provides meaningful feedback to users in case of issues.

## Installation

### Prerequisites

- **Xcode**: Ensure you have the latest version of Xcode installed.
- **Swift**: The project is built using Swift. Ensure you have the appropriate Swift version compatible with the project.

### Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/airschedule.git
   ```
2. **Navigate to the Project Directory**
   ```bash
   cd airschedule
   ```
3. **Open the Project in Xcode**
   ```bash
   open AirSchedule.xcodeproj
   ```
4. **Configure API Keys**
   - Navigate to `AirSchedule/Services/APIKeys.swift`.
   - Replace placeholder values with your actual API keys for OpenAI and any other integrated services.
5. **Build and Run**
   - Select the appropriate simulator or connect your device.
   - Click the **Run** button in Xcode to build and launch the application.

## Usage

1. **View Flights**
   - Upon launching the app, you'll see a list of available flights.
   - Select a flight (e.g., "AS 3478") to view detailed information.

2. **Ask Questions**
   - In the flight detail view, locate the input field labeled "Ask about your flight."
   - Enter your query, such as "Can I make it to my apple meeting if I take this flight?" and submit.
   
3. **Receive Responses**
   - The app will process your query, orchestrate necessary backend API calls, and display the relevant information below the flight details.
   - This may include meeting availability, travel time, weather forecasts, maps, and clothing advice based on current conditions.

## Architecture Overview

AirSchedule employs a modular and scalable architecture, ensuring flexibility, high performance, and ease of maintenance. The system is divided into frontend and backend orchestration layers, with each layer handling specific responsibilities.

### Key Components

#### **Frontend**

- **SwiftUI Views**
  - **FlightListView**: Displays a list of available flights.
  - **FlightDetailView**: Shows detailed information about a selected flight and handles user queries.
  - **DynamicUIRenderer**: Renders UI components dynamically based on the action plans generated by the backend.

- **ViewModels**
  - **FlightDetailViewModel**: Manages the state and logic for the `FlightDetailView`, including processing user queries and updating UI components.

#### **Backend Orchestration**

- **Services**
  - **LLMService**: Interfaces with the OpenAI API to parse user queries and generate actionable plans.
  - **ActionExecutor**: Executes the steps outlined in the action plans by interacting with various backend services.
  - **FlightService**: Retrieves flight details, statuses, and calculates travel times.
  - **CalendarService**: Manages user schedules and retrieves meeting details.
  - **MapsService**: Calculates travel time and provides navigation data.
  - **WeatherService**: Fetches current and forecasted weather information for specified locations.
  - **ClothingAdviceService**: Provides clothing recommendations based on weather conditions and event types.
  - **ResponseGenerationService**: Formats responses and UI components based on aggregated data.

- **Models**
  - **ActionPlan**: Represents the plan of actions derived from user queries, including intents, entities, actions, and UI components.
  - **Action**: Defines individual actions to be executed, specifying the API, method, and parameters.
  - **UIComponent**: Represents UI elements to be rendered, such as text, maps, and images.
  - **Flight**: Contains detailed information about a specific flight.

- **Error Handling**
  - Comprehensive error handling mechanisms ensure that the application can gracefully handle API failures, data inconsistencies, and unexpected user inputs, providing meaningful feedback to users.

#### **Workflow**

1. **User Interaction**
   - Users interact with the frontend by selecting flights and submitting queries.

2. **Intent Recognition**
   - The `LLMService` processes user queries using the OpenAI API to extract intents and entities, generating an `ActionPlan`.

3. **Action Execution**
   - The `ActionExecutor` sequentially performs the actions defined in the `ActionPlan`, interacting with various backend services to retrieve and process necessary data.

4. **UI Rendering**
   - The `DynamicUIRenderer` updates the UI based on the results of the executed actions, providing users with the requested information in a clear and organized manner.

## Technologies Used

- **Swift & SwiftUI**: Primary language and framework for building the application's frontend.
- **Combine**: Manages asynchronous events and data flows within the app.
- **OpenAI API**: Powers the natural language understanding and generation capabilities of the app.
- **Foundation Framework**: Provides essential data types, collections, and operating-system services.
- **MapKit**: Integrates mapping and navigation features.
- **AnyCodable**: Allows for flexible decoding of JSON data with unknown structures.

## Contributing

Contributions are welcome! If you'd like to improve AirSchedule, please follow these steps:

1. **Fork the Repository**
2. **Create a New Branch**
   ```bash
   git checkout -b feature/YourFeatureName
   ```
3. **Commit Your Changes**
   ```bash
   git commit -m "Add some feature"
   ```
4. **Push to the Branch**
   ```bash
   git push origin feature/YourFeatureName
   ```
5. **Open a Pull Request**

Please ensure your code adheres to the project's coding standards and includes relevant tests.

<!-- ## License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute this software as long as you credit the original creation. -->

## Contact

For any questions or suggestions, feel free to reach out:

- **Email**: wuxinyi2000@gmail.com
- **GitHub**: [@AlexisWu-01](https://github.com/AlexisWu-01)

---

© 2024 AirSchedule. All rights reserved.

