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
    - [System Diagram](#system-diagram)
    - [Workflow Diagram](#workflow-diagram)
    - [Key Components](#key-components)
      - [Frontend](#frontend)
      - [Backend Orchestration](#backend-orchestration)
      - [Models](#models)
      - [Error Handling](#error-handling)
    - [Workflow](#workflow)
      - [User Interaction Flow](#user-interaction-flow)
      - [Query Processing Flow](#query-processing-flow)
      - [Additional Calendar Processing Flow](#additional-calendar-processing-flow)
      - [Error Handling Flow](#error-handling-flow)
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
   ~~~bash
   git clone https://github.com/yourusername/airschedule.git
   ~~~
2. **Navigate to the Project Directory**
   ~~~bash
   cd airschedule
   ~~~
3. **Open the Project in Xcode**
   ~~~bash
   open AirSchedule.xcodeproj
   ~~~
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
   - Enter your query, such as "Can I make it to my Apple meeting if I take this flight?" and submit.
   
3. **Receive Responses**
   - The app will process your query, orchestrate necessary backend API calls, and display the relevant information below the flight details.
   - This may include meeting availability, travel time, weather forecasts, maps, and clothing advice based on current conditions.

## Architecture Overview

AirSchedule employs a modular and scalable architecture, ensuring flexibility, high performance, and ease of maintenance. The system is divided into frontend and backend orchestration layers, with each layer handling specific responsibilities. Additionally, distinct layers for models and error handling ensure organized data management and robust user feedback mechanisms.

### System Diagram

![System Diagram](https://github.com/AlexisWu-01/AirSchedule/raw/main/demo/architecture_diagram.svg)
<sub><i>Click the image to zoom</i></sub>

### Workflow Diagram

![Workflow Diagram](https://github.com/AlexisWu-01/AirSchedule/raw/main/demo/workflow_diagram.svg)
<sub><i>Click the image to zoom</i></sub>

### Key Components

#### Frontend

- **SwiftUI Views**
  - `FlightListView`: Displays a list of available flights.
  - `FlightDetailView`: Shows detailed information about a selected flight and handles user queries.
  - `DynamicUIRenderer`: Renders UI components dynamically based on backend-generated action plans.
  
- **ViewModels**
  - `FlightListViewModel`: Fetches flight data from `FlightService` and manages the state for `FlightListView`.
  - `FlightDetailViewModel`: Processes user queries, interacts with `LLMService`, and updates the `FlightDetailView`.
  
- **Technologies**
  - Swift, SwiftUI, Combine

#### Backend Orchestration

- **Services**
  - `LLMService`: Interfaces with OpenAI API for natural language processing, recognizing intents, actions (which APIs to use), and UI components (which UI components to render and their properties). Includes error handling for both `ActionPlans` and `UIComponents`.
  - `ActionExecutor`: Executes actions from the `ActionPlan` by interacting with various backend services.
  - `FlightService`: Fetches flight details and statuses using the Google Flights API via Serp API.
  - `CalendarService`: Manages user schedules using Apple Calendar EventKit and utilizes another `LLMService` to determine the closest event based on the user's query.
  - `MapsService`: Provides navigation data using Apple MapKit.
  - `WeatherService`: Fetches weather information using a mock API.
  - `ClothingAdviceService`: Offers clothing recommendations based on weather and event type using a mock API.
  - `ResponseGenerationService`: Formats responses and UI components based on aggregated data.
  
- **Technologies**
  - OpenAI API, MapKit, EventKit, Serp API, Mock APIs, AnyCodable, Foundation Framework

#### Models

- `ActionPlan`: Derived from user queries, includes intents, entities, actions, and UI components.
- `Action`: Specifies the API, method, and parameters for each action.
- `UIComponent`: Represents UI elements like text, maps, and images.
- `Flight`: Contains detailed flight information.

#### Error Handling

- `ErrorHandling`: Ensures meaningful user feedback in case of API failures, data inconsistencies, or unexpected user inputs.

### Workflow

#### User Interaction Flow

1. **Flight Listing:**
   - **User Action:** User opens the app and interacts with `FlightListViewModel`.
   - **Data Fetching:** `FlightListViewModel` fetches flight data from `FlightService`.
   - **UI Rendering:** Data is rendered on `FlightListView`.

2. **Flight Selection:**
   - **User Action:** User selects a flight from `FlightListView`.
   - **View Transition:** Navigates to `FlightDetailView`.

#### Query Processing Flow

1. **User Query Submission:**
   - **User Action:** User submits a query in `FlightDetailView` (e.g., "Can I make it to my Apple meeting if I take this flight?").
   
2. **Intent Recognition:**
   - **Processing:** `FlightDetailViewModel` sends the query to `LLMService`.
   - **LLMService:** Uses OpenAI API to recognize intents, determine necessary actions (which APIs to use), and identify `UIComponents` to render.
   - **Error Handling:** If `LLMService` encounters an error with `UIComponents`, it routes to `ErrorHandling`.
   
3. **Action Plan Generation:**
   - **Output:** `LLMService` generates an `ActionPlan`.
   
4. **Action Execution:**
   - **Processing:** `ActionExecutor` executes actions defined in the `ActionPlan`, interacting with `FlightService`, `CalendarService`, `MapsService`, `WeatherService`, and `ClothingAdviceService` as needed.
   
5. **Additional Calendar Processing:**
   - **Processing:** `CalendarService` utilizes another `LLMService` to determine the closest event based on the user's query.
   - **MapsService:** Determines travel time using Maps API based on the selected event.
   
6. **Response Generation:**
   - **Processing:** `ResponseGenerationService` formats the aggregated data into `UIComponents`.
   
7. **UI Rendering:**
   - **Processing:** `DynamicUIRenderer` updates the `FlightDetailView` with the new `UIComponents`.

#### Additional Calendar Processing Flow

- **CalendarService Interaction:**
  - `CalendarService` uses another instance of `LLMService` to parse the user's query and identify the closest event.
  - After identifying the event, `CalendarService` interacts with `MapsService` to calculate the travel time required to reach the event location using the Maps API.

#### Error Handling Flow

- **Error Propagation:**
  - Any failures or issues during intent recognition, action execution, or response generation are handled by `ErrorHandling`, ensuring the user receives meaningful feedback.
  - Specific error paths include:
    - `LLMService` handling errors related to `ActionPlans` and `UIComponents`.
    - `ActionExecutor` managing API failures.
    - `ResponseGenerationService` providing user feedback in case of formatting issues or data aggregation problems.

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
   ~~~bash
   git checkout -b feature/YourFeatureName
   ~~~
3. **Commit Your Changes**
   ~~~bash
   git commit -m "Add some feature"
   ~~~
4. **Push to the Branch**
   ~~~bash
   git push origin feature/YourFeatureName
   ~~~
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
